// Binary file format for inventory items.
// Item, in our use, means something that a store would sell. Example: 'Apple' item. 'Sword' item. 'Skateboard' item.

package items

import "core:fmt"
import "core:os"
import "core:bytes"
import "core:bufio"
import "base:runtime"
import "core:mem"
import "core:strings"
import "core:time"
import "core:testing"

// Global Struct Definitions

// Struct for in-memory operations
// Item :: struct {
//     id: i32,
//     quantity: i32,
//     price: f32,
//     name: string,
//     manufacturer: string,
// }

// InventoryDatabase :: struct {
//     items: [dynamic]Item, // Use a dynamic array instead of a slice
// }

// Function to log operations
log_operation :: proc(operation: string, item: Item) {
    fmt.println("[LOG]", operation, "Item ID:", item.id)
}

// Find an item in the inventory database by its name
find_item_by_name :: proc(db: ^InventoryDatabase, name: string) -> ^Item {
    for i in 0..<len(db.items) {
        if db.items[i].name == name {
            return &db.items[i]
        }
    }
    return nil
}

// Adds a new item to the inventory database.
add_item_by_members :: proc(db: ^InventoryDatabase, quantity: i32, price: f32, name: string, manufacturer: string) -> bool {
    // Check for duplicate names using find_item_by_name
    // if find_item_by_name(db, name) != nil {
    //     fmt.println("Error: Item with name", name, "already exists.")
    //     return false
    // }

    // Create a new Item
    new_item := Item{
        id = cast(i32)(len(db.items) + 1), // Assign a unique ID based on the array length
        quantity = quantity,
        price = price,
        name = name,
        manufacturer = manufacturer,
    }

    // Append the new item to the items array
    append(&db.items, new_item)

    // fmt.println("Item successfully added: Name =", name)
    return true
}

add_item_by_struct :: proc(db: ^InventoryDatabase, item : Item) -> bool {
    // Check for duplicate names using find_item_by_name
    if find_item_by_name(db, item.name) != nil {
        fmt.println("Error: Item with name", item.name, "already exists.")
        return false
    }

    // Create a new Item

    // Append the new item to the items array
    append(&db.items, item)

    // fmt.println("Item successfully added: Name =", item.name)
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
search_item_details :: proc(db: ^InventoryDatabase, name: string) -> string {
    builder := strings.Builder{}
    strings.builder_init(&builder, context.allocator) // Initialize the builder with the default allocator

    item := find_item_by_name(db, name)
    if item != nil {
        fmt.sbprintf(&builder, "Item found: Name = %s, Quantity = %d, Price = %.2f, Manufacturer = %s",
            item.name, item.quantity, item.price, item.manufacturer)
    } else {
        fmt.sbprintf(&builder, "Item with name %s not found.", name)
    }

    return strings.to_string(builder) // Convert the builder's contents to a string
}


// Method that calculates and prints the total value of the inventory
total_value_of_inventory :: proc(db: ^InventoryDatabase) -> string {
    total: f32 = 0.0
    for item in db.items {
        total += cast(f32)(item.quantity) * item.price
    }
    return fmt.sbprintf(nil, "Total Inventory Value: $%.2f", total)
}



// You can add other serialize_* procs here, and then call any of them with just `serialize`


// Save the inventory database to a file using bufio.Writer
save_inventory :: proc(file_name: string, database: InventoryDatabase) -> bool {
    file, success := os.open(file_name, os.O_WRONLY | os.O_CREATE)
    if success != 0 {
        fmt.println("Error: Failed to create file:", file_name)
        return false
    }
    defer os.close(file)

    writer := bufio.Writer{}
    bufio.writer_init(&writer, os.stream_from_handle(file))

    buffer := bytes.Buffer{}
    bytes.buffer_init(&buffer, nil)

    serialize_inventory(&buffer,database)

    bufio.writer_write(&writer, buffer.buf[:])
    bufio.writer_flush(&writer)

    return true
}

// Load the inventory database from a file using bufio.Reader
load_inventory :: proc(file_name: string) -> (InventoryDatabase, bool) {
    data, success := os.read_entire_file_from_filename(file_name)

    // Check if the file could not be opened or read
    // If the operation fails, print an error message and return an empty database with a failure status.
    if !success {
        // The file could not be opened or read. This might happen if:
        // - The file does not exist.
        // - The program does not have the necessary permissions to access the file.
        // - There is an issue with the file system (e.g., the file is locked or corrupted).
        fmt.println("Error: Failed to open file:", file_name)
        return InventoryDatabase{}, false
    }
    
    if len(data) == 0 {
        fmt.println("Error: File is empty:", file_name)
        return InventoryDatabase{}, false
    }

    return deserialize_inventory(data)
}
