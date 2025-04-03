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
    items: []InventoryItem, // Dynamic array of inventory items
}

INITIAL_CAPACITY :: 100 // Configurable initial capacity for dynamic arrays
DEFAULT_ITEM_CAPACITY :: 100 // Configurable initial capacity for dynamic arrays
log_operation :: proc(operation: string, item: InventoryItem) {
    fmt.println("[LOG]", operation, "Item ID:", item.id)
}

Arena :: struct {
    memory: []u8,
    offset: int,
}

arena_init :: proc(size: int) -> Arena {
    return Arena{
        memory = make([]u8, size),
        offset = 0,
    }
}

arena_alloc :: proc(arena: ^Arena, size: int) -> ^u8 {
    if arena.offset + size > len(arena.memory) {
        fmt.println("Error: Arena out of memory.")
        return nil
    }
    ptr := &arena.memory[arena.offset]
    arena.offset += size
    return ptr
}

// Resets the arena's offset to zero, effectively marking all previously allocated memory as reusable.
// Note: This does not deallocate or clear the memory, so any pointers to previously allocated memory
// will become invalid. Use with caution to avoid memory safety issues.
arena_reset :: proc(arena: ^Arena) {
    arena.offset = 0
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
    db.items = append(db.items, new_item); // Append the new item to the dynamic array
    return true // Indicate successful addition of the item
}

serialize_inventory :: proc(database: InventoryDatabase) -> bytes.Buffer {
    estimated_size := 0
    buffer := bytes.Buffer{}
    bytes.buffer_init(&buffer, estimated_size)
    buffer: bytes.Buffer
    bytes.buffer_init(&buffer, estimated_size)
    if err := buffer.write_u32(item_count); err != .None {
        fmt.println("Error: Failed to write item count to buffer. Error:", err)
        return bytes.Buffer{}
    }

    // Serialize each item
    for item in database.items {
        if err := buffer.write_u32(item.id); err != .None {
            fmt.println("Error: Failed to write item ID to buffer. Error:", err)
            return bytes.Buffer{}
        }
        if err := buffer.write_u32(item.quantity); err != .None {
            fmt.println("Error: Failed to write item quantity to buffer. Error:", err)
            return bytes.Buffer{}
        }
        if err := buffer.write_f32(item.price); err != .None {
            fmt.println("Error: Failed to write item price to buffer. Error:", err)
            return bytes.Buffer{}
        }

        // Serialize name
        name_data := []u8(item.name)
        if err := buffer.write_u32(len(name_data)); err != .None {
            fmt.println("Error: Failed to write name length to buffer. Error:", err)
            return bytes.Buffer{}
        }
        if err := buffer.write(name_data); err != .None {
            fmt.println("Error: Failed to write name data to buffer. Error:", err)
            return bytes.Buffer{}
        }

        // Serialize manufacturer
        manufacturer_data := []u8(item.manufacturer)
        if err := buffer.write_u32(len(manufacturer_data)); err != .None {
            fmt.println("Error: Failed to write manufacturer length to buffer. Error:", err)
            return bytes.Buffer{}
        }
        if err := buffer.write(manufacturer_data); err != .None {
            fmt.println("Error: Failed to write manufacturer data to buffer. Error:", err)
            return bytes.Buffer{}
        }
    }

    return buffer
}

deserialize_inventory :: proc(buffer: bytes.Buffer) -> InventoryDatabase {
    db: InventoryDatabase
    reader: bytes.Reader
    bytes.reader_init(&reader, buffer)

    // Read item count
    if bytes.reader_remaining(&reader) < 4 {
        fmt.println("Error: Buffer underflow while reading item count.")
        return InventoryDatabase{}
    }
    item_count := bytes.reader_read_u32(&reader)
    db.items = make([dynamic]InventoryItem, 0, item_count)[:]

    // Read each item
    for _ in 0..<item_count {
        item: InventoryItem

        if bytes.reader_remaining(&reader) < 12 {
            fmt.println("Error: Buffer underflow while reading item attributes.")
            return InventoryDatabase{}
        }
        item.id = bytes.reader_read_u32(&reader)
        item.quantity = bytes.reader_read_u32(&reader)
        item.price = bytes.reader_read_f32(&reader)

        // Read name
        name_length := bytes.reader_read_u32(&reader)
        name_data := make([]u8, name_length)[:]
        bytes.reader_read(&reader, name_data)
        item.name = string(name_data)

        // Read manufacturer
        manufacturer_length := bytes.reader_read_u32(&reader)
        manufacturer_data := make([]u8, manufacturer_length)
        reader.read(manufacturer_data)
        item.manufacturer = string(manufacturer_data)

        db.items = append(db.items, item)
    }

    return db
}

deserialize_inventory_with_arena :: proc(buffer: bytes.Buffer, arena: ^Arena) -> InventoryDatabase {
    db: InventoryDatabase
    reader: bytes.Reader
    bytes.reader_init(&reader, buffer.memory)

    // Read item count
    if bytes.reader_remaining(&reader) < 4 {
    db.items = make([]InventoryItem, 0)
        return InventoryDatabase{}
    }
    item_count := reader.read_u32()
    if item_count < 0 || item_count > 1_000_000 { // Arbitrary upper limit for validation
        fmt.println("Error: Invalid item count value:", item_count)
        return InventoryDatabase{}
    }
    db.items = make([]InventoryItem, 0, item_count)

    // Read each item
    for _ in 0..<item_count {
        item := ^InventoryItem(arena_alloc(arena, size_of(InventoryItem)))
        if item == nil {
            fmt.println("Error: Failed to allocate memory for InventoryItem.")
            return InventoryDatabase{}
        }
        item.name = StringData{}
        item.manufacturer = StringData{}
        if item == nil {
            fmt.println("Error: Failed to allocate memory for InventoryItem.")
            return InventoryDatabase{}
        }

        name_data_ptr := arena_alloc(arena, name_length)
        if name_data_ptr == nil {
            fmt.println("Error: Failed to allocate memory for name.")
            if !utf8.is_valid(name_data[:name_length]) {
                fmt.println("Error: Invalid UTF-8 data for name.")
                return InventoryDatabase{}
            }
            item.name = string(name_data[:name_length])
            return InventoryDatabase{}
        }
        name_data := name_data_ptr[:name_length]
        name_data := arena_alloc(arena, name_length)
        name_slice := name_data[:name_length]
        reader.read(name_slice)
        item.name = string(name_slice)

        // Read manufacturer
        manufacturer_length := reader.read_u32()
        manufacturer_data := arena_alloc(arena, manufacturer_length)
        manufacturer_slice := manufacturer_data[:manufacturer_length]
        reader.read(manufacturer_slice)
        item.manufacturer = string(manufacturer_slice)
        // Read manufacturer
        manufacturer_length := reader.read_u32()
        manufacturer_data := arena_alloc(arena, manufacturer_length)
        reader.read(manufacturer_data[:manufacturer_length])
        if !utf8.is_valid(manufacturer_data[:manufacturer_length]) {
            fmt.println("Error: Invalid UTF-8 data for manufacturer.")
            return InventoryDatabase{}
        }
        item.manufacturer = string(manufacturer_data[:manufacturer_length])

        // Create a copy of the item to avoid referencing arena memory
        copied_item := InventoryItem{
            id = item.id,
            quantity = item.quantity,
            price = item.price,
            name = StringData{
                count = item.name.count,
                data = item.name.data[:],
            },
            manufacturer = StringData{
                count = item.manufacturer.count,
                data = item.manufacturer.data[:],
            },
        }
        db.items = append(db.items, copied_item)
    return db

    return db
}

save_inventory :: proc(file_name: string, database: InventoryDatabase) -> bool {
    buffer := serialize_inventory(database)
    success := os.write_entire_file(file_name, buffer.data, true)
    if !success {
        fmt.println("Error: Failed to save inventory to file:", file_name)
        return false
    }
}

load_inventory :: proc(file_name: string) -> (bool, InventoryDatabase) {
    file_data, success := os.read_entire_file(file_name)
    if !success {
        fmt.println("Error: Failed to load inventory from file:", file_name)
        return false, InventoryDatabase{}
    }

    buffer := bytes.Buffer{data = file_data}
    db := deserialize_inventory(buffer)

    // Validate deserialized data
    for item in db.items {
        if len(item.name) == 0 || len(item.manufacturer) == 0 || item.quantity < 0 || item.price < 0 {
            fmt.println("Error: Corrupted or invalid data in inventory file:", file_name)
            return false, InventoryDatabase{}
        }
    }

    return true, db
}

update_inventory_quantity :: proc(db: ^InventoryDatabase, id: i32, sold_quantity: i32) -> bool {
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

update_inventory_price :: proc(db: ^InventoryDatabase, id: i32, new_price: f32) -> bool {
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
    update_inventory_quantity(&db, 1, 10)
    update_inventory_price(&db, 2, 249.99)
    remove_item(&db, 3)

    // Save updated inventory
    save_inventory("inventory_updated.dat", db)
}

// The main procedure serves as the entry point for the program.
// It calls the test_inventory_system function to demonstrate the inventory system functionality.
main :: proc() {
    test_inventory_system()
}
