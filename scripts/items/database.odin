// Binary file format for inventory items.

package main

import "core:fmt"
import "core:os"
import "core:mem"

global_arena: mem.ArenaAllocator; // Declare a global arena allocator.

// Generic helper to write a value's bytes to a file.
write_val :: proc(T: type, file: os.File, ptr: ^T) -> int {
    data: []u8 = mem.as_bytes(ptr)
    return os.write(file, data)
}

// Generic helper to read bytes from a file into a value.
read_val :: proc(T: type, file: os.File, ptr: ^T) -> int {
    data: []u8 = mem.as_bytes(ptr)[0:min(size_of(T), len(mem.as_bytes(ptr)))]
    return os.read(file, data)
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

// Write an inventory item to a binary file.
write_inventory_item :: proc(file: os.File, item: InventoryItem) -> bool {
    log_operation("Adding item", item)
    buffer := buf.make(BUFFER_SIZE) // Use a constant for buffer size.
    defer buf.destroy(&buffer)

    write_inventory_item_to_buffer(&buffer, item)

    bytes_written := os.write(file, buffer.data[:buffer.len])
    return bytes_written == buffer.len
}

// Read one inventory item from the file. Returns (success, item).
read_inventory_item :: proc(file: os.File) -> (bool, InventoryItem) {
    var item: InventoryItem
    var bytes_read: int = 0 // Tracks the number of bytes read from the file

    // Read the fixed-size fields
    bytes_read = read_val(file, &item.id)
    if bytes_read != size_of(item.id) {
        fmt.println("Error: Failed to read item ID. Bytes read:", bytes_read)
        return false, item
    }

    bytes_read = read_val(file, &item.quantity)
    if bytes_read != size_of(item.quantity) {
        fmt.println("Error: Failed to read item quantity. Bytes read:", bytes_read)
        return false, item
    }

    bytes_read = read_val(file, &item.price)
    if bytes_read != size_of(item.price) { 
        fmt.println("Error: failed to read item price.")
        return false, item
    }

    // Read the name
    bytes_read = read_val(file, &item.name.count) // Read the count
    if bytes_read != size_of(item.name.count) { return false, item }

    item.name.data = mem.alloc(item.name.count) // Allocate memory for the name
    bytes_read = os.read(file, item.name.data[:item.name.count]) // Read the data
    if bytes_read != item.name.count {
        mem.free(item.name.data)
        return false, item
    }

    // Read the manufacturer
    bytes_read = read_val(file, &item.manufacturer.count) // Read the count
    if bytes_read != size_of(item.manufacturer.count) { return false, item }

    item.manufacturer.data = mem.alloc(item.manufacturer.count) // Allocate memory for the manufacturer
    bytes_read = os.read(file, item.manufacturer.data[:item.manufacturer.count]) // Read the data
    if bytes_read != item.manufacturer.count {
        mem.free(item.name.data)
        mem.free(item.manufacturer.data)
        return false, item
    }

    return true, item
}

// Read all inventory items.
read_inventory_items :: proc(file: os.File) -> []InventoryItem {
    os.seek(file, 0, os.SEEK_SET)
    items: []InventoryItem = nil
    for {
        success, item := read_inventory_item(file)
        if !success { break }
        items = append(items, item)
    }
    return items
}

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
update_inventory_quantity :: proc(file: os.File, search_id: i32, sold_quantity: i32) -> bool {
    os.seek(file, 0, os.SEEK_SET);
    for {
        start_pos := os.tell(file);
        success, item := read_inventory_item(file);
        if !success { break; }
        if item.id == search_id {
            item.quantity -= sold_quantity;
            offset := size_of(item.id) +
                      size_of(item.name.count) +
                      item.name.count +
                      size_of(item.manufacturer.count) +
                      item.manufacturer.count;
            os.seek(file, start_pos + offset, os.SEEK_SET);
            data: []u8 = mem.as_bytes(&item.quantity)[0:size_of(item.quantity)];
            os.write(file, data);
            return true;
        }
    }
    return false;
}

update_inventory_price :: proc(file: os.File, search_id: i32, new_price: i32) -> bool {
    os.seek(file, 0, os.SEEK_SET)
    for {
        start_pos := os.tell(file)
        success, item := read_inventory_item(file)
        if !success { break }
        if item.id == search_id {
            item.price = new_price
            os.seek(file, start_pos, os.SEEK_SET)
            write_val(i32, file, &item.price)
            return true
        }
    }
    return false
}

test_database :: proc(file: os.File) {
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

    success = write_inventory_item(file, new_item2)
    if success {
        fmt.println("Second item added to inventory.")
    } else {
        fmt.println("Failed to add second item.")
    }
}

test_write_and_read_item :: proc() {
    file, err := os.open("test_inventory.dat", os.O_RDWR | os.O_CREATE, 0666)
    if err != nil {
        fmt.println("Failed to open test file.")
        return
    }
    defer os.close(file)

    item := InventoryItem{
        id = 1,
        quantity = 10,
        price = 100,
        name = StringData{count = 5, data = "Apple".to_bytes()},
        manufacturer = StringData{count = 7, data = "FarmInc".to_bytes()},
    }

    success := write_inventory_item(file, item)
    assert(success, "Failed to write item")

    os.seek(file, 0, os.SEEK_SET)
    success, read_item := read_inventory_item(file)
    assert(success, "Failed to read item")
    assert(read_item.id == item.id, "Item ID mismatch")
    assert(read_item.name.count == item.name.count, "Name count mismatch")
}

main :: proc() {
    file, err := os.open("inventory.dat", os.O_RDWR | os.O_CREATE, 0666)
    if err != nil {
        fmt.println("Failed to open file")
        return
    }
    defer os.close(file)

    // Call test_database for testing purposes
    test_database(file)
}