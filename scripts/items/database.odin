// Binary file format for inventory items.
// Item, in our use, means something that a store would sell. Example: 'Apple' item. 'Sword' item. 'Skateboard' item.

package items

import "core:fmt"
import "core:os"
import "core:bytes"

// Global Struct Definitions

/*
// Struct for in-memory operations
InventoryItem :: struct {
    id: i32,
    quantity: i32,
    price: f32,
    name: string,
    manufacturer: string,
}
    */

InventoryDatabase :: struct {
    items: []InventoryItem, // Dynamic array of inventory items
    items_map: map[i32]bool // Hash map for quick ID lookup
}

// Function to log operations
log_operation :: proc(operation: string, item: InventoryItem) {
    fmt.println("[LOG]", operation, "Item ID:", item.id)
}

// Adds a new item to the inventory database.
// This function checks for duplicate IDs before adding the item.
// If a duplicate ID is detected, the function will return false and the item will not be added.
// Parameters:
// - db: Pointer to the InventoryDatabase where the item will be added.
// - id: Unique identifier for the item.
// - quantity: Number of items available in stock.
// - price: Price of the item.
// - name: Name of the item.
// - manufacturer: Manufacturer of the item.
// Returns:
// - true if the item was successfully added to the database.
// - false if the item could not be added due to validation errors or duplicate ID.
add_item :: proc(db: ^InventoryDatabase, id: i32, quantity: i32, price: f32, name: string, manufacturer: string) -> bool {
    // Check for duplicate IDs
    if db.items_map[id] {
        fmt.println("Error: Item with ID", id, "already exists.")
        return false
    }

    // Create a new InventoryItem
    new_item := InventoryItem{
        id = id,
        quantity = quantity,
        price = price,
        name = name,
        manufacturer = manufacturer,
    }

    // Append the new item to the items array
    db.items = append(db.items, new_item)

    // Add the ID to the items_map
    db.items_map[id] = true

    fmt.println("Item successfully added: ID =", id, "Name =", name)
    return true
}

// Serialize the inventory database into a binary format
serialize_inventory :: proc(database: InventoryDatabase) -> bytes.Buffer {
    buffer: bytes.Buffer
    bytes.buffer_init(&buffer, nil) // Initialize the buffer

    // Serialize the number of items in the array
    item_count := i32(len(database.items))
    bytes.buffer_write(&buffer, ^u8(&item_count), size_of(item_count)) // Write item count as bytes

    // Serialize each item in the array
    for item in database.items {
        // Serialize item ID
        bytes.buffer_write(&buffer, ^u8(&item.id), size_of(item.id))

        // Serialize item quantity
        bytes.buffer_write(&buffer, ^u8(&item.quantity), size_of(item.quantity))

        // Serialize item price
        bytes.buffer_write(&buffer, ^u8(&item.price), size_of(item.price))

        // Serialize the name
        name_length := u32(len(item.name))
        bytes.buffer_write(&buffer, ^u8(&name_length), size_of(name_length)) // Write name length
        bytes.buffer_write(&buffer, []u8(item.name), name_length)           // Write name data

        // Serialize the manufacturer
        manufacturer_length := u32(len(item.manufacturer))
        bytes.buffer_write(&buffer, ^u8(&manufacturer_length), size_of(manufacturer_length)) // Write manufacturer length
        bytes.buffer_write(&buffer, []u8(item.manufacturer), manufacturer_length)           // Write manufacturer data
    }

    return buffer
}

// Deserialize the inventory database from a binary format
deserialize_inventory_with_arena :: proc(buffer: bytes.Buffer) -> InventoryDatabase {
    db: InventoryDatabase
    reader: bytes.Reader
    bytes.reader_init(&reader, buffer.data)

    // Read the number of items in the array
    item_count := reader.read_u32()
    db.items = make([]InventoryItem, 0, item_count)

    // Deserialize each item
    for _ in 0..<item_count {
        item: InventoryItem

        item.id = reader.read_u32()           // Deserialize item ID
        item.quantity = reader.read_u32()    // Deserialize item quantity
        item.price = reader.read_f32()       // Deserialize item price

        // Deserialize name
        name_length := reader.read_u32()
        name_data := make([]u8, name_length)
        reader.read(name_data)
        item.name = string(name_data)

        // Deserialize manufacturer
        manufacturer_length := reader.read_u32()
        manufacturer_data := make([]u8, manufacturer_length)
        reader.read(manufacturer_data)
        item.manufacturer = string(manufacturer_data)

        db.items = append(db.items, item)
    }

    return db
}

// Save the inventory database to a file
save_inventory :: proc(file_name: string, database: InventoryDatabase) -> bool {
    buffer := serialize_inventory(database)
    success := os.write_entire_file(file_name, buffer.data, true)
    if !success {
        fmt.println("Error: Failed to save inventory to file:", file_name)
        return false
    }
    return true
}

// Load the inventory database from a file
load_inventory :: proc(file_name: string) -> (bool, InventoryDatabase) {
    file_data, success := os.read_entire_file(file_name)
    if !success {
        fmt.println("Error: Failed to load inventory from file:", file_name)
        return false, InventoryDatabase{}
    }

    buffer := bytes.Buffer{data = file_data}
    db := deserialize_inventory_with_arena(buffer)
    return true, db
}

// Update the quantity of an item in the inventory
update_item_quantity :: proc(db: ^InventoryDatabase, id: i32, sold_quantity: i32) -> bool {
    for i in 0..<len(db.items) {
        if db.items[i].id == id {
            if sold_quantity > db.items[i].quantity {
                fmt.println("Error: Sold quantity exceeds available stock for Item ID", id)
                return false
            }
            db.items[i].quantity -= sold_quantity
            log_operation("Updated Quantity", db.items[i])
            return true
        }
    }
    fmt.println("Error: Item with ID", id, "not found.")
    return false
}

// Update the price of an item in the inventory
update_item_price :: proc(db: ^InventoryDatabase, id: i32, new_price: f32) -> bool {
    if new_price < 0 {
        fmt.println("Error: New price cannot be negative.")
        return false
    }
    for i in 0..<len(db.items) {
        if db.items[i].id == id {
            db.items[i].price = new_price
            log_operation("Updated Price", db.items[i])
            return true
        }
    }
    fmt.println("Error: Item with ID", id, "not found.")
    return false
}

// Removes an item from the inventory database by its ID
remove_item :: proc(db: ^InventoryDatabase, id: i32) -> bool {
    for i in 0..<len(db.items) {
        if db.items[i].id == id {
            log_operation("Removed", db.items[i])
            // Replace the item to be removed with the last item in the array
            db.items[i] = db.items[len(db.items) - 1]
            db.items = db.items[:len(db.items) - 1]
            return true
        }
    }
    fmt.println("Error: Item with ID", id, "not found.")
    return false
}

// Test the inventory management system
test_inventory_system :: proc() {
    // Create an empty InventoryDatabase
    db: InventoryDatabase = InventoryDatabase{
        items = make([]InventoryItem, 0), // Initialize as an empty slice
        items_map = make(map[i32]bool),  // Initialize as an empty map
    }

    // Add items to the inventory
    add_item(&db, 1, 50, 0.99, "Apples", "FarmFresh")
    add_item(&db, 2, 5, 299.99, "Sword", "Camelot")
    add_item(&db, 3, 20, 60.00, "Skateboard", "Birdhouse")

    // Save the inventory to a file
    save_inventory("inventory.dat", db)

    // Load the inventory from the file
    success, loaded_db := load_inventory("inventory.dat")
    if success {
        fmt.println("Loaded Inventory:")
        for item in loaded_db.items {
            fmt.println("ID:", item.id, "Name:", item.name, "Quantity:", item.quantity, "Price:", item.price, "Manufacturer:", item.manufacturer)
        }
    }

    // Update the quantity of an item
    update_item_quantity(&db, 1, 10)

    // Update the price of an item
    update_item_price(&db, 2, 249.99)

    // Remove an item from the inventory
    remove_item(&db, 3)

    // Save the updated inventory to a new file
    save_inventory("inventory_updated.dat", db)
}

// Main procedure
main :: proc() {
    test_inventory_system()
}
