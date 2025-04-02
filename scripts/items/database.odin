// Binary file format for inventory items.
// Item, in our use, means something that a store would sell. Example: 'Apple' item. 'Sword' item. 'Skateboard' item.

package items

import "core:fmt"
import "core:os"
import "core:mem"
import "core:bytes"
import vmem "core:mem/virtual"

/*
// need to implement
arena := vmem.Arena
*/


// Generic helper to read bytes from a file into a value.
read_val :: proc(T: type, file: io.Stream, ptr: ^T) -> int {
    data: []u8 = mem.as_bytes(ptr)[0:min(size_of(T), len(mem.as_bytes(ptr)))]
    return os.read(stream, data)
}

StringData :: struct {
    count: int,            // Number of bytes in the string
    data: ^u8,             // Pointer to the string data
}

InventoryItem :: struct {
    id: i32,               // Item ID
    quantity: i32,         // Quantity of the item
    price: f32,            // Price as float (e.g., $5.99)
    name: StringData,      // Name of the item
    manufacturer: StringData, // Manufacturer of the item
}

BUFFER_SIZE :: 1024

log_operation :: proc(operation: string, item: InventoryItem) {
    fmt.println("[LOG]", operation, "Item ID:", item.id)
}

// Serialization
serialize_item :: proc(item: InventoryItem, allocator: memory.Allocator) -> []u8 {
    // Calculate total size needed: 
    // - 2 * i32 (id + quantity) → 8 bytes
    // - 1 * f32 (price) → 4 bytes
    // - 2 * int (string lengths) → depends on architecture (typically 8-16 bytes)
    // - Actual string bytes (name and manufacturer)
    total_size := 8 + 4 + 8 + item.name.count + item.manufacturer.count

    buffer := mem.alloc(allocator, total_size) // Allocate buffer for all data
    offset := 0 // Initialize the offset

    // Convert values to byte representation - offset works similar to specifying an index in Python
    // Offset += 4 is telling the script to look 4 bytes past the last 'object' copied, aka one index away
    mem.copy(buffer[offset: offset+4], transmute([4]u8)item.id)
    offset += 4
    mem.copy(buffer[offset: offset+4], transmute([4]u8)item.quantity)
    offset += 4
    mem.copy(buffer[offset: offset+4], transmute([4]u8)item.price)
    offset += 4
    mem.copy(buffer[offset: offset+4], transmute([4]u8)item.name.count)
    offset += 4
    mem.copy(buffer[offset: offset+4], transmute([4]u8)item.manufacturer.count)
    offset += 4

    // Copy string data
    mem.copy(buffer[offset: offset + item.name.count], item.name.data)
    offset += item.name.count

    mem.copy(buffer[offset: offset + item.manufacturer.count], item.manufacturer.data)
    offset += item.manufacturer.count

    return buffer
}


// Write an inventory item to a binary file
write_item :: proc(file_name: string, item: InventoryItem) -> bool {
    log_operation("Adding item", item)

    // Serialize InventoryItem into a byte slice
    serialized_data := serialize_item(item)
    
    // Write the data to a binary file
    success := os.write_entire_file(file_name, serialized_data, true)
    
    if !success {
        fmt.println("Error writing to file:", file_name)
        return false
    }

    return true
}


// Read one inventory item from the stream. Returns (success, item).
read_item :: proc(handle: os.Handle) -> (bool, InventoryItem) {
    item: InventoryItem
    bytes_read: int = 0 // Tracks the number of bytes read

    // Wrap the handle in a buffered reader.
    reader_buffer := make([]u8, BUFFER_SIZE, context.allocator)
    reader := bufio.Reader{
        rd: handle,
        buf: reader_buffer,
        buf_allocator: context.allocator,
        r: 0,
        w: 0,
        err: io.Error.None,
        last_byte: -1,
        last_rune_size: -1,
        max_consecutive_empty_reads: 0,
    }

    // Read the fixed-size fields using read_val
    bytes_read = read_val(i32, reader.rd, &item.id)
    if bytes_read != size_of(item.id) {
        fmt.println("Error: Failed to read item ID. Bytes read:", bytes_read)
        bufio.reader_destroy(&reader)
        return false, item
    }

    bytes_read = read_val(i32, reader.rd, &item.quantity)
    if bytes_read != size_of(item.quantity) {
        fmt.println("Error: Failed to read item quantity. Bytes read:", bytes_read)
        bufio.reader_destroy(&reader)
        return false, item
    }

    bytes_read = read_val(i32, reader.rd, &item.price)
    if bytes_read != size_of(item.price) {
        fmt.println("Error: Failed to read item price.")
        bufio.reader_destroy(&reader)
        return false, item
    }

    // Read the name count.
    bytes_read = read_val(int, reader.rd, &item.name.count)
    if bytes_read != size_of(item.name.count) {
        bufio.reader_destroy(&reader)
        return false, item
    }

    // Allocate memory for the name and read the data.
    item.name.data = mem.alloc(item.name.count)
    bytes_read = os.read(reader.rd, mem.slice_ptr(item.name.data, item.name.count))
    if bytes_read != item.name.count {
        mem.free(item.name.data)
        bufio.reader_destroy(&reader)
        return false, item
    }

    // Read the manufacturer count.
    bytes_read = read_val(int, reader.rd, &item.manufacturer.count)
    if bytes_read != size_of(item.manufacturer.count) {
        mem.free(item.name.data)
        bufio.reader_destroy(&reader)
        return false, item
    }

    // Allocate memory for the manufacturer and read the data.
    item.manufacturer.data = mem.alloc(item.manufacturer.count)
    bytes_read = os.read(reader.rd, mem.slice_ptr(item.manufacturer.data, item.manufacturer.count))
    if bytes_read != item.manufacturer.count {
        mem.free(item.name.data)
        mem.free(item.manufacturer.data)
        bufio.reader_destroy(&reader)
        return false, item
    }

    bufio.reader_destroy(&reader)
    return true, item
}


// Read all inventory items from the stream.
read_full_inventory :: proc(handle: os.Handle) -> []InventoryItem {
    // Reset stream position to start.
    os.seek(handle, 0, os.SEEK_SET)
    items: []InventoryItem = nil
    for {
        success, item := read_item(handle)
        if !success { break }
        items = append(items, item)
    }
    return items
}

// Change this to find item by name.
// Find an inventory item by id.
find_item :: proc(file: os.File, search_id: i32) -> (bool, InventoryItem) {
    os.seek(file, 0, os.SEEK_SET)
    for {
        success, item := read_item(file)
        if !success { break }
        if item.id == search_id {
            return true, item
        }
    }
    return false, InventoryItem{}
}

// Update an inventory item's quantity.
// Reads the item, updates the quantity, then seeks back to the quantity field.
update_inventory_quantity :: proc(handle: os.Handle, search_id: i32, sold_quantity: i32) -> bool {
    os.seek(handle, 0, os.SEEK_SET)
    for {
        start_pos := os.tell(handle)
        success, item := read_item(handle)
        if !success { break }
        if item.id == search_id {
            item.quantity -= sold_quantity
            // Calculate offset: assume quantity immediately follows id.
            offset := size_of(item.id)
            // Seek to the quantity field.
            os.seek(handle, start_pos + offset, os.SEEK_SET)
            data: []u8 = mem.as_bytes(&item.quantity)[0:size_of(item.quantity)]
            os.write(handle, data)
            return true
        }
    }
    return false
}

update_inventory_price :: proc(handle: os.Handle, search_id: i32, new_price: f32) -> bool {
    os.seek(handle, 0, os.SEEK_SET)
    for {
        start_pos := os.tell(handle)
        success, item := read_item(handle)
        if !success { break }
        if item.id == search_id {
            item.price = new_price
            serialized_item := serialize_item(item) // Serialize the entire struct
            os.seek(handle, start_pos, os.SEEK_SET)  // Seek back to item's position
            os.write(handle, serialized_item)  // Overwrite full item
            return true
        }
    }
    return false
}

// remove_item :: 

// full_inventory_value ::

// all_items_by_manufacturer ::

// Test functions for the inventory system.
test_database :: proc(handle: os.Handle) {
    name1 := "Apples".to_bytes()
    manufacturer1 := "FarmFresh".to_bytes()

    new_item1: InventoryItem = InventoryItem{
        id = 1,
        quantity = 50,
        price = 0.99, // $0.99
        name = StringData{
            count = len(name1),
            data = &name1[0],
        },
        manufacturer = StringData{
            count = len(manufacturer1),
            data = &manufacturer1[0],
        },
    }

    success := write_item(file, new_item1)
    if success {
        fmt.println("First item added to inventory.")
    } else {
        fmt.println("Failed to add first item.")
    }

    name2 := "Sword".to_bytes()
    manufacturer2 := "Camelot".to_bytes()

    new_item2: InventoryItem = InventoryItem{
        id = 2,
        quantity = 5,
        price = 299.99, // $299.99
        name = StringData{
            count = len(name2),
            data = &name2[0],
        },
        manufacturer = StringData{
            count = len(manufacturer2),
            data = &manufacturer2[0],
        },
    }

    success = write_item(handle, new_item2)
    if success {
        fmt.println("Second item added to inventory.")
    } else {
        fmt.println("Failed to add second item.")
    }

    name3 := "Skateboard".to_bytes()
    manufacturer3 := "Birdhouse".to_bytes()

    new_item3: InventoryItem = InventoryItem{
        id = 3,
        quantity = 50,
        price = 60, // $60 - should still have price at f32 even though it looks like i32
        name = StringData{
            count = len(name3),
            data = &name3[0],
        },
        manufacturer = StringData{
            count = len(manufacturer3),
            data = &manufacturer3[0],
        },
    }

    success = write_item(handle, new_item2)
    if success {
        fmt.println("Third item added to inventory.")
    } else {
        fmt.println("Failed to add third item.")
    }
}

test_write_and_read_item :: proc() {
    handle, err := os.open("test_inventory.dat", os.O_RDWR | os.O_CREATE, 0666)
    if err != nil {
        fmt.println("Failed to open test file.")
        return
    }
    defer os.close(handle)

    item := InventoryItem{
        id = 1,
        quantity = 10,
        price = 1.00,
        name = StringData{count = 5, data = "Apple".to_bytes()},
        manufacturer = StringData{count = 7, data = "FarmInc".to_bytes()},
    }

    success := write_item(handle, item)
    assert(success, "Failed to write item")

    os.seek(handle, 0, os.SEEK_SET)
    success, read_item := read_item(handle)
    assert(success, "Failed to read item")
    assert(read_item.id == item.id, "Item ID mismatch")
    assert(read_item.name.count == item.name.count, "Name count mismatch")
}

// Write a test for the read_full_inventory function.


main :: proc() {
    filename := "inventory.dat"

    // Read the file
    contents, err := os.read_entire_file(mem.default_allocator, filename)
    if err != nil {
        fmt.println("Failed to open file:", err)
        return
    }

    defer mem.default_allocator.free(contents) // Free the allocated memory after use

    fmt.println("File contents:\n", string(contents))

    os.close(filename)

    // Call test_database for testing purposes.
    test_database(handle)
}
