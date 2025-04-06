// Binary file format for inventory items.
// Item, in our use, means something that a store would sell. Example: 'Apple' item. 'Sword' item. 'Skateboard' item.

package items

import "core:fmt"
import "core:os"
import "core:bytes"
import "core:bufio"
import "core:io"

// Global Struct Definitions

// Struct for in-memory operations
InventoryItem :: struct {
    id: i32,
    quantity: i32,
    price: f32,
    name: string,
    manufacturer: string,
}

InventoryDatabase :: struct {
    items: [dynamic]InventoryItem, // Use a dynamic array instead of a slice
}

// Function to log operations
log_operation :: proc(operation: string, item: InventoryItem) {
    fmt.println("[LOG]", operation, "Item ID:", item.id)
}

// Find an item in the inventory database by its name
find_item_by_name :: proc(db: ^InventoryDatabase, name: string) -> ^InventoryItem {
    for i in 0..<len(db.items) {
        if db.items[i].name == name {
            return &db.items[i]
        }
    }
    return nil
}

// Adds a new item to the inventory database.
add_item :: proc(db: ^InventoryDatabase, quantity: i32, price: f32, name: string, manufacturer: string) -> bool {
    // Check for duplicate names using find_item_by_name
    if find_item_by_name(db, name) != nil {
        fmt.println("Error: Item with name", name, "already exists.")
        return false
    }

    // Create a new InventoryItem
    new_item := InventoryItem{
        id = cast(i32)(len(db.items) + 1), // Assign a unique ID based on the array length
        quantity = quantity,
        price = price,
        name = name,
        manufacturer = manufacturer,
    }

    // Append the new item to the items array
    append(&db.items, new_item)

    fmt.println("Item successfully added: Name =", name)
    return true
}

// Update the price of an item in the inventory
update_item_price :: proc(db: ^InventoryDatabase, name: string, new_price: f32) -> bool {
    if new_price < 0 {
        fmt.println("Error: New price cannot be negative.")
        return false
    }
    item := find_item_by_name(db, name)
    if item == nil {
        fmt.println("Error: Item with name", name, "not found.")
        return false
    }
    item.price = new_price
    log_operation("Updated Price", item^)
    return true
}

// Removes an item from the inventory database by its name
remove_item :: proc(db: ^InventoryDatabase, name: string) -> bool {
    item := find_item_by_name(db, name)
    if item == nil {
        fmt.println("Error: Item with name", name, "not found.")
        return false
    }

    // Find the index of the item to remove
    for i in 0..<len(db.items) {
        if &db.items[i] == item {
            log_operation("Removed", db.items[i])
            ordered_remove(&db.items, i) // Use ordered_remove to remove the item
            return true
        }
    }

    return false
}

sell_product :: proc(db: ^InventoryDatabase, name: string, quantity: i32) -> bool {
    if quantity <= 0 {
        fmt.println("Error: You can't sell nothing!")
        return false
    }

    item := find_item_by_name(db, name)
    if item == nil {
        fmt.println("Error: Item", name, "doesn't exist.")
        return false
    }

    if item.quantity < quantity {
        fmt.println("Error: Not enough stock for the item", name, "to be sold", "- Requested:", quantity, "Available:", item.quantity)
        return false
    }

    item.quantity -= quantity
    log_operation("Sold", item^)
    fmt.println("Sold", quantity, "unit(s) of", name, "- Remaining stock:", item.quantity)
    return true
}

restock_product :: proc(db: ^InventoryDatabase, name: string, quantity: i32) -> bool {
    if quantity <= 0 {
        fmt.println("Error: Quantity must be > 0.")
        return false
    }

    item := find_item_by_name(db, name)
    if item == nil {
        fmt.println("Error: Item", name, "doesn't exist.")
        return false
    }

    item.quantity += quantity
    log_operation("Restocked", item^)
    fmt.println("Restocked", quantity, "unit(s) of", name, "Previous stock", item.quantity - quantity, "- New stock:", item.quantity)
    return true
}

// Search for an item in the inventory database by its name and print the result
search_item_details :: proc(db: ^InventoryDatabase, name: string) {
    item := find_item_by_name(db, name)
    if item != nil {
        fmt.println("Item found: Name =", item.name, "Quantity =", item.quantity, "Price =", item.price, "Manufacturer =", item.manufacturer)
    } else {
        fmt.println("Item with name", name, "not found.")
    }
}


// Method that calculates and prints the total value of the inventory
total_value_of_inventory :: proc(db: ^InventoryDatabase) {
    total: f32 = 0.0
    for item in db.items {
        total += cast(f32)(item.quantity) * item.price
    }
    fmt.println("Total Inventory Value: $", total)
}


// Serialize the inventory database into a binary format
serialize_inventory :: proc(database: InventoryDatabase, buffer: ^bytes.Buffer) -> bool {
    // Serialize the number of items in the array
    item_count := i32(len(database.items))
    n, err := bytes.buffer_write_ptr(buffer, cast(rawptr)&item_count, size_of(item_count))
    if err != .None {
        fmt.println("Error: Failed to write item count to buffer.")
        return false
    }

    // Serialize each item in the array
    for i in 0..<len(database.items) {
        item := database.items[i] // Access each item explicitly

        // Serialize item ID
        n, err = bytes.buffer_write_ptr(buffer, cast(rawptr)&item.id, size_of(item.id))
        if err != .None {
            fmt.println("Error: Failed to write item ID to buffer.")
            return false
        }

        // Serialize item quantity
        n, err = bytes.buffer_write_ptr(buffer, cast(rawptr)&item.quantity, size_of(item.quantity))
        if err != .None {
            fmt.println("Error: Failed to write item quantity to buffer.")
            return false
        }

        // Serialize item price
        n, err = bytes.buffer_write_ptr(buffer, cast(rawptr)&item.price, size_of(item.price))
        if err != .None {
            fmt.println("Error: Failed to write item price to buffer.")
            return false
        }

        // Serialize the name
        name_length := u32(len(item.name))
        n, err = bytes.buffer_write_ptr(buffer, cast(rawptr)&name_length, size_of(name_length))
        if err != .None {
            fmt.println("Error: Failed to write name length to buffer.")
            return false
        }
        n, err = bytes.buffer_write(buffer, transmute([]u8)item.name)
        if err != .None {
            fmt.println("Error: Failed to write name to buffer.")
            return false
        }

        // Serialize the manufacturer
        manufacturer_length := u32(len(item.manufacturer))
        n, err = bytes.buffer_write_ptr(buffer, cast(rawptr)&manufacturer_length, size_of(manufacturer_length))
        if err != .None {
            fmt.println("Error: Failed to write manufacturer length to buffer.")
            return false
        }
        n, err = bytes.buffer_write(buffer, transmute([]u8)item.manufacturer)
        if err != .None {
            fmt.println("Error: Failed to write manufacturer to buffer.")
            return false
        }
    }

    return true
}

// Save the inventory database to a file using bufio.Writer
save_inventory :: proc(file_name: string, database: InventoryDatabase) -> bool {
    file, success := os.open(file_name, .Write | .Create)
    if !success {
        fmt.println("Error: Failed to create file:", file_name)
        return false
    }
    defer os.close(file)

    writer := bufio.Writer{}
    bufio.writer_init(&writer, file)

    buffer := bytes.Buffer{}
    bytes.buffer_init(&buffer, nil)

    if !serialize_inventory(database, &buffer) {
        return false
    }

    bufio.writer_write(&writer, buffer.buf[:])
    bufio.writer_flush(&writer)

    return true
}

// Load the inventory database from a file using bufio.Reader
load_inventory :: proc(file_name: string) -> (bool, InventoryDatabase) {
    file, success := os.open(file_name, .Read)
    if !success {
        fmt.println("Error: Failed to open file:", file_name)
        return false, InventoryDatabase{}
    }
    defer os.close(file)

    buf_reader := bufio.Reader{}
    bufio.reader_init(&buf_reader, file)

    buffer := bytes.Buffer{}
    bytes.buffer_init(&buffer, nil)

    temp := make([]u8, 1024)
    for {
        n, err := bufio.reader_read(&buf_reader, temp)
        if err == .EOF {
            break
        }
        if err != .None {
            fmt.println("Error: Failed to read from file:", file_name)
            return false, InventoryDatabase{}
        }
        append(&buffer.buf, temp[:n])
    }

    // Deserialize the buffer directly
    binary_reader := bytes.Reader{}
    bytes.reader_init(&binary_reader, buffer.buf)

    db: InventoryDatabase
    // Read the number of items in the array
    item_count: u32
    bytes.reader_read(&binary_reader, ^u8(&item_count), size_of(item_count))
    db.items = make([dynamic]InventoryItem, 0)

    // Deserialize each item
    for _ in 0..<item_count {
        item: InventoryItem

        // Deserialize item ID
        bytes.reader_read(&binary_reader, ^u8(&item.id), size_of(item.id))

        // Deserialize item quantity
        bytes.reader_read(&binary_reader, ^u8(&item.quantity), size_of(item.quantity))

        // Deserialize item price
        bytes.reader_read(&binary_reader, ^u8(&item.price), size_of(item.price))

        // Deserialize name
        name_length: u32
        bytes.reader_read(&binary_reader, ^u8(&name_length), size_of(name_length))
        name_data := make([]u8, name_length)
        bytes.reader_read(&binary_reader, name_data, name_length)
        item.name = string(name_data)

        // Deserialize manufacturer
        manufacturer_length: u32
        bytes.reader_read(&binary_reader, ^u8(&manufacturer_length), size_of(manufacturer_length))
        manufacturer_data := make([]u8, manufacturer_length)
        bytes.reader_read(&binary_reader, manufacturer_data, manufacturer_length)
        item.manufacturer = string(manufacturer_data)

        append(&db.items, item)
    }

    return true, db
}

// Test the inventory management system
test_inventory_system :: proc() {
    // Create an empty InventoryDatabase
    db: InventoryDatabase = InventoryDatabase{
        items = make([dynamic]InventoryItem, 0), // Initialize as a dynamic array
    }

    // Add items to the inventory
    add_item(&db, 50, 0.99, "Apples", "FarmFresh")
    add_item(&db, 5, 299.99, "Sword", "Camelot")
    add_item(&db, 20, 60.00, "Skateboard", "Birdhouse")

    // Save the inventory to a file
    save_inventory("inventory.dat", db)

    // Load the inventory from the file
    success, loaded_db := load_inventory("inventory.dat")
    if success {
        fmt.println("Loaded Inventory:")
        for item in loaded_db.items {
            fmt.println("Name:", item.name, "Quantity:", item.quantity, "Price:", item.price, "Manufacturer:", item.manufacturer)
        }
    }

    // Check if an item exists before updating its quantity
    if find_item_by_name(&db, "Apples") != nil {
        update_item_quantity(&db, "Apples", 10)
    } else {
        fmt.println("Item 'Apples' does not exist.")
    }

    // Update the price of an item
    update_item_price(&db, "Sword", 249.99)

    // Remove an item from the inventory
    remove_item(&db, "Skateboard")

    // Save the updated inventory to a new file
    save_inventory("inventory_updated.dat", db)
}

// Main procedure
main :: proc() {
    test_inventory_system()
}
