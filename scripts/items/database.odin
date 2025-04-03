// Binary file format for inventory items.
// Item, in our use, means something that a store would sell. Example: 'Apple' item. 'Sword' item. 'Skateboard' item.

package items

import "core:fmt"
import "core:os"
import "core:mem"
import "core:bytes"
import vmem "core:mem/virtual"

BUFFER_SIZE :: 1024
<<<<<<< Updated upstream
<<<<<<< Updated upstream

<<<<<<< Updated upstream

// Global Struct Definitions
// Struct for binary serialization
StringData :: struct {
    count: int,    // Number of bytes in the string
    data: []u8,    // String content as a byte array
=======
=======

>>>>>>> Stashed changes
arena: vmem.Arena // Declare the arena variable
vmem.arena_init_growing(&arena, BUFFER_SIZE)
// Create an allocator from the arena
allocator := vmem.arena_allocator(&arena)

StringData :: struct {
    count:  int,            // Number of bytes in the string
    data:   ^u8,            // Pointer to the string data
<<<<<<< Updated upstream
>>>>>>> Stashed changes
}

// Struct for in-memory operations
InventoryItem :: struct {
<<<<<<< Updated upstream
    id: i32,
    quantity: i32,
    price: f32,
    name: string,          // Use string for in-memory operations
    manufacturer: string,  // Use string for in-memory operations
}

InventoryDatabase :: struct {
    items: []InventoryItem, // Dynamic array of inventory items
=======
    id:           i32,         // Item ID
    quantity:     i32,         // Quantity of the item
    price:        f32,         // Price as float (e.g., $5.99)
    name:         StringData,  // Name of the item
    manufacturer: StringData  // Manufacturer of the item
>>>>>>> Stashed changes
}

// Global Variables
inventory_items: []InventoryItem
serialized_items: [][]u8

=======

arena: vmem.Arena // Declare the arena variable
vmem.arena_init_growing(&arena, BUFFER_SIZE)
// Create an allocator from the arena
allocator := vmem.arena_allocator(&arena)

StringData :: struct {
    count:  int,            // Number of bytes in the string
    data:   ^u8,            // Pointer to the string data
=======
>>>>>>> Stashed changes
}

InventoryItem :: struct {
    id:           i32,         // Item ID
    quantity:     i32,         // Quantity of the item
    price:        f32,         // Price as float (e.g., $5.99)
    name:         StringData,  // Name of the item
    manufacturer: StringData  // Manufacturer of the item
}

// Global Variables
inventory_items: []InventoryItem
serialized_items: [][]u8

<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
// Function to log operations
log_operation :: proc(operation: string, item: InventoryItem) {
    fmt.println("[LOG]", operation, "Item ID:", item.id)
}

<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
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
=======
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
// Function to serialize an InventoryItem
serialize_item :: proc(item: InventoryItem, allocator: mem.Allocator) -> []u8 {
    // Calculate total size needed: 
    // - 2 * i32 (id + quantity) → 8 bytes
    // - 1 * f32 (price) → 4 bytes
    // - 2 * int (string lengths) → depends on architecture (typically 8-16 bytes)
    // - Actual string bytes (name and manufacturer)
    total_size := 8 + 4 + 8 + item.name.count + item.manufacturer.count
    buffer, err := mem.alloc(allocator, total_size) // Allocate buffer for all data
    if err != nil {
        fmt.println("Error in function Serialize_item.")
    }    
    offset := 0 // Initialize the offset

    // Convert values to byte representation - offset works similar to specifying an index in Python
    // Offset += 4 is telling the script to look 4 bytes past the last 'object' copied, aka one index away
    mem.copy(buffer[offset:offset+4], transmute([4]u8)item.id)
    offset += 4
    mem.copy(buffer[offset:offset+4], transmute([4]u8)item.quantity)
    offset += 4
    mem.copy(buffer[offset:offset+4], transmute([4]u8)item.price)
    offset += 4
    mem.copy(buffer[offset:offset+4], transmute([4]u8)item.name.count)
    offset += 4
    mem.copy(buffer[offset:offset+4], transmute([4]u8)item.manufacturer.count)
    offset += 4

    // Copy string data
    mem.copy(buffer[offset:offset+item.name.count], item.name.data)
    offset += item.name.count
    mem.copy(buffer[offset:offset+item.manufacturer.count], item.manufacturer.data)
    offset += item.manufacturer.count
>>>>>>> Stashed changes

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

<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream

write_item :: proc(file_name: string, item: InventoryItem) -> bool {
    log_operation("Adding item", item)
    
    temp_db: InventoryDatabase
    temp_db.items = append(temp_db.items, item)
    
    buffer := serialize_inventory(temp_db)
    success := os.write_entire_file(file_name, buffer.data, true)
=======
// Function to write an InventoryItem to a binary file
write_item :: proc(file_name: string, item: InventoryItem, allocator: mem.Allocator) -> bool {
    log_operation("Adding item", item)
    serialized_data := serialize_item(item, allocator)
    success := os.write_entire_file(file_name, serialized_data, true)
>>>>>>> Stashed changes
=======
// Function to write an InventoryItem to a binary file
write_item :: proc(file_name: string, item: InventoryItem, allocator: mem.Allocator) -> bool {
    log_operation("Adding item", item)
    serialized_data := serialize_item(item, allocator)
    success := os.write_entire_file(file_name, serialized_data, true)
>>>>>>> Stashed changes
=======
// Function to write an InventoryItem to a binary file
write_item :: proc(file_name: string, item: InventoryItem, allocator: mem.Allocator) -> bool {
    log_operation("Adding item", item)
    serialized_data := serialize_item(item, allocator)
    success := os.write_entire_file(file_name, serialized_data, true)
>>>>>>> Stashed changes
    if !success {
        fmt.println("Error writing to file:", file_name)
        return false
    }
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
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
=======
    return true
}

// Read strings - StringData stores count and the actual text
read_string :: proc(reader: ^bytes.Reader) -> StringData {
    // Create empty StringData struct
    str_data: StringData
    // Check if enough bytes to read count
    if reader.i + size_of(int) > len(reader.s) {
        return str_data
    }
    // Read count
    mem.copy(transmute([]u8)&str_data.count, reader.s[reader.i:reader.i+size_of(int)])
    reader.i += size_of(int)
    // Check if there is enough space for the actual string
    if reader.i + str_data.count > len(reader.s) {
        return str_data
    }
    // Read the actual string (data)
    str_data.data = &reader.s[reader.i]
    reader.i += str_data.count
    return str_data
}


// Function to deserialize an InventoryItem from a bytes.Reader
deserialize_inventory_item :: proc(reader: ^bytes.Reader) -> (InventoryItem, bool) {
    item: InventoryItem    
    // Checks if there is enough bytes left ro read id, quantity, and price
    if reader.i + size_of(i32) * 2 + size_of(f32) > len(reader.s) {
        fmt.println("Not enough bytes available to read item details")
        return item, false
    }
    // Read id, quantity, and price
    mem.copy(transmute([]u8)&item.id, reader.s[reader.i:reader.i+size_of(i32)])
    reader.i += size_of(i32)
    mem.copy(transmute([]u8)&item.quantity, reader.s[reader.i:reader.i+size_of(i32)])
    reader.i += size_of(i32)
    mem.copy(transmute([]u8)&item.price, reader.s[reader.i:reader.i+size_of(f32)])
    reader.i += size_of(f32)
    // Read name
    item.name = read_string(reader)
    // Read manufacturer
    item.manufacturer = read_string(reader)
    return item, true
}


// Function to read inventory items from a file handle
read_inventory_items :: proc(handle: os.Handle) -> ([]InventoryItem, bool) {
    data, success := os.read_entire_file_from_handle(handle)
    if !success {
        fmt.println("Error reading file")
        return nil, false
    }
    reader := bytes.Reader{s = data} // Initialize a reader with the data buffer
    items: []InventoryItem
    for reader.i < len(reader.s) { // Read until we reach the end of the buffer
        item, ok := deserialize_inventory_item(&reader)
        if !ok {
            fmt.println("Error deserializing items.")
            break
        }
        items = append(items, item)
    }
    return items, true
}



// Change this to find item by name.
// Find an inventory item by id.
// REMOVE reference to os.File
/*find_item :: proc(file: os.File, search_id: i32) -> (bool, InventoryItem) {
>>>>>>> Stashed changes
=======
    return true
}

// Read strings - StringData stores count and the actual text
read_string :: proc(reader: ^bytes.Reader) -> StringData {
    // Create empty StringData struct
    str_data: StringData
    // Check if enough bytes to read count
    if reader.i + size_of(int) > len(reader.s) {
        return str_data
    }
    // Read count
    mem.copy(transmute([]u8)&str_data.count, reader.s[reader.i:reader.i+size_of(int)])
    reader.i += size_of(int)
    // Check if there is enough space for the actual string
    if reader.i + str_data.count > len(reader.s) {
        return str_data
    }
    // Read the actual string (data)
    str_data.data = &reader.s[reader.i]
    reader.i += str_data.count
    return str_data
}


// Function to deserialize an InventoryItem from a bytes.Reader
deserialize_inventory_item :: proc(reader: ^bytes.Reader) -> (InventoryItem, bool) {
    item: InventoryItem    
    // Checks if there is enough bytes left ro read id, quantity, and price
    if reader.i + size_of(i32) * 2 + size_of(f32) > len(reader.s) {
        fmt.println("Not enough bytes available to read item details")
        return item, false
    }
    // Read id, quantity, and price
    mem.copy(transmute([]u8)&item.id, reader.s[reader.i:reader.i+size_of(i32)])
    reader.i += size_of(i32)
    mem.copy(transmute([]u8)&item.quantity, reader.s[reader.i:reader.i+size_of(i32)])
    reader.i += size_of(i32)
    mem.copy(transmute([]u8)&item.price, reader.s[reader.i:reader.i+size_of(f32)])
    reader.i += size_of(f32)
    // Read name
    item.name = read_string(reader)
    // Read manufacturer
    item.manufacturer = read_string(reader)
    return item, true
}


// Function to read inventory items from a file handle
read_inventory_items :: proc(handle: os.Handle) -> ([]InventoryItem, bool) {
    data, success := os.read_entire_file_from_handle(handle)
    if !success {
        fmt.println("Error reading file")
        return nil, false
    }
    reader := bytes.Reader{s = data} // Initialize a reader with the data buffer
    items: []InventoryItem
    for reader.i < len(reader.s) { // Read until we reach the end of the buffer
        item, ok := deserialize_inventory_item(&reader)
        if !ok {
            fmt.println("Error deserializing items.")
            break
        }
        items = append(items, item)
    }
    return items, true
}



// Change this to find item by name.
// Find an inventory item by id.
// REMOVE reference to os.File
/*find_item :: proc(file: os.File, search_id: i32) -> (bool, InventoryItem) {
>>>>>>> Stashed changes
=======
    return true
}

// Read strings - StringData stores count and the actual text
read_string :: proc(reader: ^bytes.Reader) -> StringData {
    // Create empty StringData struct
    str_data: StringData
    // Check if enough bytes to read count
    if reader.i + size_of(int) > len(reader.s) {
        return str_data
    }
    // Read count
    mem.copy(transmute([]u8)&str_data.count, reader.s[reader.i:reader.i+size_of(int)])
    reader.i += size_of(int)
    // Check if there is enough space for the actual string
    if reader.i + str_data.count > len(reader.s) {
        return str_data
    }
    // Read the actual string (data)
    str_data.data = &reader.s[reader.i]
    reader.i += str_data.count
    return str_data
}


// Function to deserialize an InventoryItem from a bytes.Reader
deserialize_inventory_item :: proc(reader: ^bytes.Reader) -> (InventoryItem, bool) {
    item: InventoryItem    
    // Checks if there is enough bytes left ro read id, quantity, and price
    if reader.i + size_of(i32) * 2 + size_of(f32) > len(reader.s) {
        fmt.println("Not enough bytes available to read item details")
        return item, false
    }
    // Read id, quantity, and price
    mem.copy(transmute([]u8)&item.id, reader.s[reader.i:reader.i+size_of(i32)])
    reader.i += size_of(i32)
    mem.copy(transmute([]u8)&item.quantity, reader.s[reader.i:reader.i+size_of(i32)])
    reader.i += size_of(i32)
    mem.copy(transmute([]u8)&item.price, reader.s[reader.i:reader.i+size_of(f32)])
    reader.i += size_of(f32)
    // Read name
    item.name = read_string(reader)
    // Read manufacturer
    item.manufacturer = read_string(reader)
    return item, true
}


// Function to read inventory items from a file handle
read_inventory_items :: proc(handle: os.Handle) -> ([]InventoryItem, bool) {
    data, success := os.read_entire_file_from_handle(handle)
    if !success {
        fmt.println("Error reading file")
        return nil, false
    }
    reader := bytes.Reader{s = data} // Initialize a reader with the data buffer
    items: []InventoryItem
    for reader.i < len(reader.s) { // Read until we reach the end of the buffer
        item, ok := deserialize_inventory_item(&reader)
        if !ok {
            fmt.println("Error deserializing items.")
            break
        }
        items = append(items, item)
    }
    return items, true
}



// Change this to find item by name.
// Find an inventory item by id.
// REMOVE reference to os.File
/*find_item :: proc(file: os.File, search_id: i32) -> (bool, InventoryItem) {
>>>>>>> Stashed changes
    os.seek(file, 0, os.SEEK_SET)
    for {
        success, item := read_inventory_items(file)
        if !success { break }
        if item.id == search_id {
            return true, item
        }
    }
    return false, InventoryItem{}
}
*/

// Function to update an inventory item's quantity
update_item_quantity :: proc(handle: os.Handle, search_id: i32, sold_quantity: i32) -> bool {
    os.seek(handle, 0, os.SEEK_SET)
    items, success := read_inventory_items(handle)
    if !success {
        return false
    }
    // Find the matching item in the array.
    for index, item in items {
        if item.id == search_id {
            // Update quantity.
            item.quantity -= sold_quantity
            // Update the item in the array.
            items[index] = item
            return true
        }
    }
    return false
}


// Function to update an inventory item's price
update_item_price :: proc(handle: os.Handle, search_id: i32, new_price: f32) -> bool {
    os.seek(handle, 0, os.SEEK_SET)
    items, success := read_inventory_items(handle)
    if !success {
        return false
    }
    for index, item in items {
        if item.id == search_id {
            item.price = new_price
            items[index] = item
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

<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
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
=======
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
// Function to test the inventory database
test_database :: proc(handle: os.Handle, allocator: mem.Allocator) {
    items := []InventoryItem{
        {id = 1, quantity = 50, price = 0.99, name = StringData{count = 6, data = "Apples".to_bytes()}, manufacturer = StringData{count = 9, data = "FarmFresh".to_bytes()}},
        {id = 2, quantity = 5, price = 299.99, name = StringData{count = 5, data = "Sword".to_bytes()}, manufacturer = StringData{count = 7, data = "Camelot".to_bytes()}},
        {id = 3, quantity = 50, price = 60, name = StringData{count = 10, data = "Skateboard".to_bytes()}, manufacturer = StringData{count = 9, data = "Birdhouse".to_bytes()}}
    }
    for item in items {
        append(&inventory_items, item)
<<<<<<< Updated upstream
<<<<<<< Updated upstream
>>>>>>> Stashed changes
    }
    success := write_item(file, new_item1)
    if success {
<<<<<<< Updated upstream
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
=======
        fmt.println("All three items have been added to inventory.")
>>>>>>> Stashed changes
=======
    }
    success := write_item(file, new_item1)
    if success {
        fmt.println("All three items have been added to inventory.")
>>>>>>> Stashed changes
=======
    }
    success := write_item(file, new_item1)
    if success {
        fmt.println("All three items have been added to inventory.")
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
        id = 1,
        quantity = 10,
        price = 1.00,
        name = "Apple",
        manufacturer = "FarmInc",
=======
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
        id =        1,
        quantity =  10,
        price =     1.00,
        name = StringData{count = 5, data = "Apple".to_bytes()},
        manufacturer = StringData{count = 7, data = "FarmInc".to_bytes()},
>>>>>>> Stashed changes
    }

    success := write_item(handle, item)
    assert(success, "Failed to write item")

    os.seek(handle, 0, os.SEEK_SET)
    success, read_inventory_items := read_inventory_items(handle)
    assert(success, "Failed to read item")
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
    assert(read_item.id == item.id, "Item ID mismatch")
    assert(read_item.name == item.name, "Name mismatch")
=======
    assert(read_inventory_items.id == item.id, "Item ID mismatch")
    assert(read_inventory_items.name.count == item.name.count, "Name count mismatch")
>>>>>>> Stashed changes
=======
    assert(read_inventory_items.id == item.id, "Item ID mismatch")
    assert(read_inventory_items.name.count == item.name.count, "Name count mismatch")
>>>>>>> Stashed changes
=======
    assert(read_inventory_items.id == item.id, "Item ID mismatch")
    assert(read_inventory_items.name.count == item.name.count, "Name count mismatch")
>>>>>>> Stashed changes
}

// Write a test to print all inventory items

main :: proc() {
    file_name := "inventory.dat"

    defer vmem.arena_destroy(&arena)
    


    // Read the file
    contents, err := os.read_entire_file(default_allocator, file_name)
    if err != nil {
        fmt.println("Failed to open file:", err)
        return
    }

    defer default_allocator.free(contents) // Free the allocated memory after use

    fmt.println("File contents:\n", string(contents))

    defer os.close(file_name)

    // Call test_database for testing purposes.
    test_database(handle)
}