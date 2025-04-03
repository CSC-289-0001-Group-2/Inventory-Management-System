// Binary file format for inventory items.
// Item, in our use, means something that a store would sell. Example: 'Apple' item. 'Sword' item. 'Skateboard' item.

package items

import "core:fmt"
import "core:os"
import "core:mem"
import "core:bytes"
import vmem "core:mem/virtual"



// Global Struct Definitions
// Struct for binary serialization
StringData :: struct {
    count: int,    // Number of bytes in the string
    data: []u8    // String content as a byte array
}

// Struct for in-memory operations
InventoryItem :: struct {
    id: i32,
    quantity: i32,
    price: f32,
    name: StringData,
    manufacturer: StringData
}

InventoryDatabase :: struct {
    items: []InventoryItem // Dynamic array of inventory items
}


// Function to log operations
log_operation :: proc(operation: string, item: InventoryItem) {
    fmt.println("[LOG]", operation, "Item ID:", item.id)
}

arena: vmem.Arena // Declare the global arena variable

// Initialize the arena before using it
init_arena :: proc() {
    BUFFER_SIZE :: 1_000_000 // Initial size of 1 MB
    vmem.arena_init_growing(&arena, BUFFER_SIZE)
}

// Reset the arena to reuse memory
reset_arena :: proc() {
    vmem.arena_reset(&arena)
}

// Adds a new item to the inventory database.
// This function checks for duplicate IDs before adding the item.
// If an item with the same ID already exists, it logs a message and does not add the item.
// If `db.items` is uninitialized (nil), it initializes the dynamic array with a default capacity.
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
    // Validate that name and manufacturer are non-empty
    if len(name) == 0 {
        fmt.println("Error: Name cannot be empty.")
        // No reinitialization of db.items is needed here
        return false
    }
    if len(manufacturer) == 0 {
        fmt.println("Error: Manufacturer cannot be empty.")
        return false
    }
    // Initialize the dynamic array if it hasn't been initialized
    if db.items == nil {
        db.items = make([dynamic]InventoryItem, 0, INITIAL_CAPACITY)[:];
        }

    // Check for duplicate IDs
    for item in db.items {
        if item.id == id {
            fmt.println("Error: Item with ID", id, "and Name", string(item.name.data), "already exists.")
            return false
        }
    }

    // Create a new InventoryItem
    new_item: InventoryItem = InventoryItem{
        id = id,
        quantity = quantity,
        price = price,
        name = StringData{
            count = len(name),
            data = []u8(name),
        },
        manufacturer = StringData{
            count = len(manufacturer),
            data = manufacturer[:],
        },
    };

    // Append the new item to the database
    db.items = append(db.items, new_item); // Append the new item to the dynamic array
    fmt.println("Item successfully added to database:", new_item.id);
}

// Serialize the inventory database into a binary format
serialize_inventory :: proc(database: InventoryDatabase) -> bytes.Buffer {
    buffer: bytes.Buffer
    bytes.buffer_init(&buffer, nil) // Initialize the buffer

    // Serialize the number of items in the array
    item_count := i32(len(database.items))
    buffer.write_u32(item_count)

    // Serialize each item in the array
    for item in database.items {
        buffer.write_u32(item.id)           // Serialize item ID
        buffer.write_u32(item.quantity)    // Serialize item quantity
        buffer.write_f32(item.price)       // Serialize item price

        // Serialize the name
        buffer.write_u32(item.name.count)  // Serialize name length
        buffer.write(item.name.data)       // Serialize name data

        // Serialize the manufacturer
        buffer.write_u32(item.manufacturer.count) // Serialize manufacturer length
        buffer.write(item.manufacturer.data)      // Serialize manufacturer data
    }

    return buffer
}

deserialize_inventory_with_arena :: proc(buffer: bytes.Buffer, arena: ^Arena) -> InventoryDatabase {
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
        name_data := arena_alloc(arena, name_length)
        reader.read(name_data[:name_length])
        item.name = StringData{
            count = name_length,
            data = name_data[:name_length],
        }

        // Deserialize manufacturer
        manufacturer_length := reader.read_u32()
        manufacturer_data := arena_alloc(arena, manufacturer_length)
        reader.read(manufacturer_data[:manufacturer_length])
        item.manufacturer = StringData{
            count = manufacturer_length,
            data = manufacturer_data[:manufacturer_length],
        }

        db.items = append(db.items, item)
    }

    return db
}

save_inventory :: proc(file_name: string, database: InventoryDatabase) -> bool {
    buffer := serialize_inventory(database)
    success := os.write_entire_file(file_name, buffer.data, true)
    if !success {
        fmt.println("Error: Failed to save inventory to file:", file_name)
        return false
    }
    return true
}

load_inventory :: proc(file_name: string) -> (bool, InventoryDatabase) {
    file_data, success := os.read_entire_file(file_name)
    if !success {
        fmt.println("Error: Failed to load inventory from file:", file_name)
        return false, InventoryDatabase{}
    }

    buffer := bytes.Buffer{data = file_data}
    db := deserialize_inventory_with_arena(buffer, &arena)
    return true, db
}

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

// Removes an item from the inventory database by its ID.
// Parameters:
// - db: Pointer to the InventoryDatabase from which the item will be removed.
// - id: Unique identifier of the item to be removed.
// Returns:
// - true if the item was successfully removed, false if the item was not found.
remove_item :: proc(db: ^InventoryDatabase, id: i32) -> bool {
    for i in 0..<len(db.items) {
        if db.items[i].id == id {
            log_operation("Removed", db.items[i])
            // Replace the item to be removed with the last item in the array.
            // Note: This operation does not preserve the order of items in the array.
            db.items[i] = db.items[len(db.items) - 1]
            db.items = db.items[:len(db.items) - 1]
            return true
        }
    }
    fmt.println("Error: Item with ID", id, "not found.")
    return false
}

// This procedure tests the functionality of the inventory management system.
// It validates adding, saving, loading, updating, and removing items from the inventory.
test_inventory_system :: proc() {
    db := InventoryDatabase{}

    // Add items
    add_item(&db, 1, 50, 0.99, "Apples", "FarmFresh")
    add_item(&db, 2, 5, 299.99, "Sword", "Camelot")
    add_item(&db, 3, 20, 60.00, "Skateboard", "Birdhouse")

    // Save to file
    save_inventory("inventory.dat", db)

    // Load from file
    success, loaded_db := load_inventory("inventory.dat")
    if success {
        fmt.println("Loaded Inventory:")
        for item in loaded_db.items {
            fmt.println(item)
        }
    }

    // Update and remove items
    update_item_quantity(&db, 1, 10)
    update_item_price(&db, 2, 249.99)
    remove_item(&db, 3)

    // Save updated inventory
    save_inventory("inventory_updated.dat", db)
}

// The main procedure serves as the entry point for the program.
// It calls the test_inventory_system function to demonstrate the inventory system functionality.
main :: proc() {
    test_inventory_system()
}
