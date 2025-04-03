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


// Writer

StringData :: struct {
    count: int,    // Number of bytes in the string
    data: []u8,    // String content (no mem.alloc!)
}

InventoryItem :: struct {
    id: i32,
    quantity: i32,
    price: f32,
    name: StringData,
    manufacturer: StringData
}

BUFFER_SIZE :: 1024

log_operation :: proc(operation: string, item: InventoryItem) {
    fmt.println("[LOG]", operation, "Item ID:", item.id)
}

InventoryDatabase :: struct {
    items: []InventoryItem,
}

add_item :: proc(db: ^InventoryDatabase, item: InventoryItem) {
    db.items = append(db.items, item)
}

serialize_inventory :: proc(database: InventoryDatabase) -> bytes.Buffer {
    buffer := bytes.Buffer{}
    
    item_count := len(database.items)
    buffer.write_bytes(item_count)
    
    for item in database.items {
        buffer.write_bytes(item.id)
        buffer.write_bytes(item.quantity)
        buffer.write_bytes(item.price)
        
        buffer.write_bytes(item.name.count)
        buffer.write(item.name.data[:item.name.count])
        
        buffer.write_bytes(item.manufacturer.count)
        buffer.write(item.manufacturer.data[:item.manufacturer.count])
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
        count_name_bytes := transmute([4]u8) (i32(item.name.count)) 
        n, _ = bytes.reader_read(&reader, count_name_bytes[:])
        if n != 4 { fmt.println("Error: Failed to read name count."); return nil }
                
        current_name_offset := 0
        name_bytes: []u8 = file_data[current_name_offset : current_name_offset + item.name.count]
        current_name_offset += item.name.count // Update manually after each read
        
        // Read manufacturer count data
        count_manufacturer_bytes := transmute([4]u8) (i32(item.manufacturer.count))
        n, _ = bytes.reader_read(&reader, count_manufacturer_bytes[:])
        if n != 4 {
            fmt.println("Error: Failed to read manufacturer count.")
            return nil
        }

        current_manufacturer_offset := 0
        manufacturer_bytes: []u8 = file_data[current_manufacturer_offset : current_manufacturer_offset + item.manufacturer.count]
        current_manufacturer_offset += item.manufacturer.count // Update manually after each read
        
        // Store item in the array
        items[i] = item
    }

    return items
}


// Functions

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

// Write a test for the read_full_inventory function.

// Write a test to print all inventory items

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