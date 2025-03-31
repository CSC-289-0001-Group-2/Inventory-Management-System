// Binary file format for inventory items.

package items

import "core:fmt"
import "core:os"
import "core:mem"
import "core:io"
import "core:bufio"

// not currently making use - need to implement
global_arena: mem.ArenaAllocator; // Declare a global arena allocator.

// Generic helper to write a value's bytes to a file.
write_val :: proc(T: type, file: io.Stream, ptr: ^T) -> int {
    data: []u8 = mem.as_bytes(ptr)
    return os.write(stream, data)
}

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
    price: i32,            // Price as an integer (e.g., cents for precision)
    name: StringData,      // Name of the item
    manufacturer: StringData, // Manufacturer of the item
}

BUFFER_SIZE :: 1024

log_operation :: proc(operation: string, item: InventoryItem) {
    fmt.println("[LOG]", operation, "Item ID:", item.id)
}


// Write an inventory item to a binary file using buffered I/O.
write_inventory_item :: proc(handle: os.Handle, item: InventoryItem) -> bool {
    log_operation("Adding item", item)
    
    // Allocate a write buffer using context.allocator.
    writer_buffer := make([]u8, BUFFER_SIZE, context.allocator)
    writer := bufio.Writer{
        wr: handle, // underlying stream
        buf: writer_buffer,
        buf_allocator: context.allocator,
        n: 0,
        err: io.Error.None,
        max_consecutive_empty_writes: 0,
    }
    
    // Write the inventory item into the buffered writer.
    write_inventory_item_to_buffer(&writer, item)
    
    // Flush the buffered writer to write any remaining data.
    bufio.writer_flush(&writer)
    
    // Check for errors
    if writer.err != io.Error.None {
        fmt.println("Buffered write error:", writer.err)
        // Destroy the writer before returning
        bufio.writer_destroy(&writer)
        return false
    }
    
    // Destroy the writer to release resources
    bufio.writer_destroy(&writer)
    return true
}

// Read one inventory item from the stream. Returns (success, item).
read_inventory_item :: proc(handle: os.Handle) -> (bool, InventoryItem) {
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
    bytes_read = os.read(reader.rd, mem.slice_from_ptr(item.name.data, item.name.count))
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
    bytes_read = os.read(reader.rd, mem.slice_from_ptr(item.manufacturer.data, item.manufacturer.count))
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
        success, item := read_inventory_item(handle)
        if !success { break }
        items = append(items, item)
    }
    return items
}

// Change this to find item by name.
// Find an inventory item by id.
find_inventory_item :: proc(file: os.File, search_id: i32) -> (bool, InventoryItem) {
    os.seek(file, 0, os.SEEK_SET)
    for {
        success, item := read_inventory_item(file)
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
        success, item := read_inventory_item(handle)
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

update_inventory_price :: proc(handle: os.Handle, search_id: i32, new_price: i32) -> bool {
    os.seek(handle, 0, os.SEEK_SET)
    for {
        start_pos := os.tell(handle)
        success, item := read_inventory_item(handle)
        if !success { break }
        if item.id == search_id {
            item.price = new_price
            // Calculate offset: assume price follows id and quantity.
            offset := size_of(item.id) + size_of(item.quantity)
            os.seek(handle, start_pos + offset, os.SEEK_SET)
            write_val(i32, handle, &item.price)
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
        price = 99, // Price in cents
        name = StringData{
            count = len(name1),
            data = &name1[0],
        },
        manufacturer = StringData{
            count = len(manufacturer1),
            data = &manufacturer1[0],
        },
    }

    success := write_inventory_item(file, new_item1)
    if success {
        fmt.println("First item added to inventory.")
    } else {
        fmt.println("Failed to add first item.")
    }

    name2 := "Swords".to_bytes()
    manufacturer2 := "Camelot".to_bytes()

    new_item2: InventoryItem = InventoryItem{
        id = 2,
        quantity = 5,
        price = 29999, // Price in cents
        name = StringData{
            count = len(name2),
            data = &name2[0],
        },
        manufacturer = StringData{
            count = len(manufacturer2),
            data = &manufacturer2[0],
        },
    }

    success = write_inventory_item(handle, new_item2)
    if success {
        fmt.println("Second item added to inventory.")
    } else {
        fmt.println("Failed to add second item.")
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
        price = 100,
        name = StringData{count = 5, data = "Apple".to_bytes()},
        manufacturer = StringData{count = 7, data = "FarmInc".to_bytes()},
    }

    success := write_inventory_item(handle, item)
    assert(success, "Failed to write item")

    os.seek(handle, 0, os.SEEK_SET)
    success, read_item := read_inventory_item(handle)
    assert(success, "Failed to read item")
    assert(read_item.id == item.id, "Item ID mismatch")
    assert(read_item.name.count == item.name.count, "Name count mismatch")
}

// Test the read_full_inventory function.
main :: proc() {
    handle, err := os.open("inventory.dat", os.O_RDWR | os.O_CREATE, 0666)
    if err != nil {
        fmt.println("Failed to open file")
        return
    }
    defer os.close(handle)

    // Call test_database for testing purposes.
    test_database(handle)
}
