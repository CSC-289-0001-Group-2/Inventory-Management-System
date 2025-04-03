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


// Global Struct Definitions
// Struct for binary serialization
StringData :: struct {
    count: int,    // Number of bytes in the string
    data: []u8,    // String content as a byte array
}

// Struct for in-memory operations
InventoryItem :: struct {
    id: i32,
    quantity: i32,
    price: f32,
    name: string,          // Use string for in-memory operations
    manufacturer: string,  // Use string for in-memory operations
}

InventoryDatabase :: struct {
    items: []InventoryItem, // Dynamic array of inventory items
}

BUFFER_SIZE :: 1024

log_operation :: proc(operation: string, item: InventoryItem) {
    fmt.println("[LOG]", operation, "Item ID:", item.id)
}

add_item :: proc(db: ^InventoryDatabase, id: i32, quantity: i32, price: f32, name: string, manufacturer: string) {
    // Initialize the dynamic array if it hasn't been initialized
    if db.items == nil {
        db.items = make([dynamic]InventoryItem, 0, 10)[:]; // Create a dynamic array with an initial capacity of 10
    }

    // Create a new InventoryItem
    new_item: InventoryItem = InventoryItem{
        id = id,
        quantity = quantity,
        price = price,
        name = name,
        manufacturer = manufacturer,
    };

    // Append the new item to the database
    _, err := runtime.append_elem(&db.items, new_item); // Pass a pointer to the dynamic array
    if err != nil {
        fmt.println("Error appending item to database:", err);
    } else {
        fmt.println("Item successfully added to database:", new_item.id);
    }
}

serialize_inventory :: proc(database: InventoryDatabase) -> bytes.Buffer {
    buffer := bytes.Buffer{}
    
    item_count := len(database.items)
    buffer.write_u32(item_count)
    
    for item in database.items {
        buffer.write_bytes(item.id)
        buffer.write_bytes(item.quantity)
        buffer.write_bytes(item.price)
        
        name_data := item.name.to_bytes()
        buffer.write_u32(len(name_data))
        buffer.write(name_data)
        
        manufacturer_data := item.manufacturer.to_bytes()
        buffer.write_u32(len(manufacturer_data))
        buffer.write(manufacturer_data)
    }
        
    return buffer
}


write_item :: proc(file_name: string, item: InventoryItem) -> bool {
    log_operation("Adding item", item)
    
    temp_db: InventoryDatabase
    temp_db.items = append(temp_db.items, item)
    
    buffer := serialize_inventory(temp_db)
    success := os.write_entire_file(file_name, buffer.data, true)
    if !success {
        fmt.println("Error writing to file:", file_name)
        return false
    }
    return true
}
save_inventory :: proc(file_name: string, database: InventoryDatabase) -> bool {
    buffer := serialize_inventory(database)
    success := os.write_entire_file(file_name, buffer.data, true)
    if !success {
        fmt.println("Error writing inventory to file:", file_name)
        return false
    }
    return true
}


// Reader
read_inventory :: proc(file_name: string) -> []InventoryItem {
    // Read entire file into memory
    file_data, success := os.read_entire_file(file_name)
    if !success {
        fmt.println("Error: Unable to read file:", file_name)
        return nil
    }

    // Create a bytes.Reader
    reader: bytes.Reader
    bytes.reader_init(&reader, file_data)

    // Read item count
    count: i32
    count_bytes: [4]u8 = transmute([4]u8) count
    n, _ := bytes.reader_read(&reader, count_bytes[:])
        if n != 4 {
        fmt.println("Error: Failed to read item count.")
        return nil
    }

    items: []InventoryItem = make([]InventoryItem, count)

    // Read each inventory item
    for i in 0..<count {
        item: InventoryItem

        // Read fixed-size fields
        id_bytes: [4]u8 = transmute([4]u8) item.id
        n, _ = bytes.reader_read(&reader, id_bytes[:]) // ✅ Convert fixed array to slice
        if n != 4 { fmt.println("Error: Failed to read item ID."); return nil }

        price_bytes := transmute([4]u8) item.price
        n, _ = bytes.reader_read(&reader, price_bytes[:])
        if n != 4 { fmt.println("Error: Failed to read item price."); return nil }
        
        quantity_bytes := transmute([4]u8) item.quantity
        n, _ = bytes.reader_read(&reader, quantity_bytes[:])
        if n != 4 { fmt.println("Error: Failed to read item quantity."); return nil }

        // Read name data
        name_count: i32
        name_count_bytes := transmute([4]u8) name_count
        n, _ = bytes.reader_read(&reader, name_count_bytes[:])
        if n != 4 { fmt.println("Error: Failed to read name count."); return nil }
                
        name_data := make([]u8, name_count)
        n, _ = bytes.reader_read(&reader, name_data)
        if n != name_count { fmt.println("Error: Failed to read name data."); return nil }
        item.name = string(name_data)

        // Read manufacturer count data
        manufacturer_count: i32
        manufacturer_count_bytes := transmute([4]u8) manufacturer_count
        n, _ = bytes.reader_read(&reader, manufacturer_count_bytes[:])
        if n != 4 {
            fmt.println("Error: Failed to read manufacturer count.")
            return nil
        }

        manufacturer_data := make([]u8, manufacturer_count)
        n, _ = bytes.reader_read(&reader, manufacturer_data)
        if n != manufacturer_count { fmt.println("Error: Failed to read manufacturer data."); return nil }
        item.manufacturer = string(manufacturer_data)
        
        // Store item in the array
        items[i] = item
    }

    return items
}


// Functions
// Change this to find item by name.
// Find an inventory item by id.
find_item :: proc(file: os.Handle, search_id: i32) -> (bool, InventoryItem) {
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

// read_item reads a single InventoryItem from the file.
read_item :: proc(file: os.Handle) -> (bool, InventoryItem) {
    item: InventoryItem

    // Read fixed-size fields
    id_bytes: [4]u8
    n, _ := os.read(file, id_bytes[:])
    if n != 4 { return false, item }
    item.id = transmute(i32) id_bytes

    quantity_bytes: [4]u8
    n, _ = os.read(file, quantity_bytes[:])
    if n != 4 { return false, item }
    item.quantity = transmute(i32) quantity_bytes
    n, _ = os.read(file, quantity_bytes[:])
    if n != 4 { return false, item }
    item.quantity = transmute(i32) quantity_bytes

    price_bytes: [4]u8
    n, _ = os.read(file, price_bytes[:])
    if n != 4 { return false, item }
    item.price = transmute(f32) price_bytes

    // Read name
    name_count_bytes: [4]u8
    n, _ = os.read(file, name_count_bytes[:])
    if n != 4 { return false, item }
    name_count := transmute(i32) name_count_bytes

    name_data := make([]u8, name_count)
    n, _ = os.read(file, name_data)
    if n != name_count { return false, item }
    item.name = string(name_data)

    // Read manufacturer
    manufacturer_count_bytes: [4]u8
    n, _ = os.read(file, manufacturer_count_bytes[:])
    if n != 4 { return false, item }
    manufacturer_count := transmute(i32) manufacturer_count_bytes

    manufacturer_data := make([]u8, manufacturer_count)
    n, _ = os.read(file, manufacturer_data)
    if n != manufacturer_count { return false, item }
    item.manufacturer = string(manufacturer_data)

    return true, item
}

// remove_item :: 

// full_inventory_value ::

// all_items_by_manufacturer ::

// Write a test for the read_full_inventory function.

// Write a test to print all inventory items

// Test functions for the inventory system.
test_database :: proc(handle: os.Handle) {
    name1 := "Apples"
    manufacturer1 := "FarmFresh"

    new_item1: InventoryItem = InventoryItem{
        id = 1,
        quantity = 50,
        price = 0.99, // $0.99
        name = name1,
        manufacturer = manufacturer1,
    }

    success := write_item(file, new_item1)
    if success {
        fmt.println("First item added to inventory.")
    } else {
        fmt.println("Failed to add first item.")
    }

    name2 := "Sword"
    manufacturer2 := "Camelot"

    new_item2: InventoryItem = InventoryItem{
        id = 2,
        quantity = 5,
        price = 299.99, // $299.99
        name = name2,
        manufacturer = manufacturer2,
    }

    success = write_item(handle, new_item2)
    if success {
        fmt.println("Second item added to inventory.")
    } else {
        fmt.println("Failed to add second item.")
    }

    name3 := "Skateboard"
    manufacturer3 := "Birdhouse"

    new_item3: InventoryItem = InventoryItem{
        id = 3,
        quantity = 50,
        price = 60, // $60 - should still have price at f32 even though it looks like i32
        name = name3,
        manufacturer = manufacturer3,
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
        name = "Apple",
        manufacturer = "FarmInc",
    }

    success := write_item(handle, item)
    assert(success, "Failed to write item")

    os.seek(handle, 0, os.SEEK_SET)
    success, read_item := read_item(handle)
    assert(success, "Failed to read item")
    assert(read_item.id == item.id, "Item ID mismatch")
    assert(read_item.name == item.name, "Name mismatch")
}

// Write a test to print all inventory items

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

    defer os.close(filename)

    // Call test_database for testing purposes.
    test_database(handle)
}