// Binary file format for inventory items.
// Item, in our use, means something that a store would sell. Example: 'Apple' item, 'Sword' item, 'Skateboard' item.

package items

import "core:fmt"
import "core:os"
import "core:bytes"
import "core:bufio"
import "base:runtime"
import "core:mem"
import virtual "core:mem/virtual"
import "core:strings"
import "core:time"
import "core:testing"

// Global Struct Definitions

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

// Adds a new item to the inventory database
add_item_by_members :: proc(db: ^InventoryDatabase, quantity: i32, price: f32, name: string, manufacturer: string) -> bool {
    if find_item_by_name(db, name) != nil {
        fmt.println("Error: Item with name", name, "already exists.")
        return false
    }
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

// Adds a new item to the inventory database using a struct
add_item_by_struct :: proc(db: ^InventoryDatabase, item: Item) -> bool {
    if find_item_by_name(db, item.name) != nil {
        fmt.println("Error: Item with name", item.name, "already exists.")
        return false
    }

    append(&db.items, item)
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

    for i in 0..<len(db.items) {
        if &db.items[i] == item {
            log_operation("Removed", db.items[i])
            ordered_remove(&db.items, i)
            return true
        }
    }

    return false
}

// Sell a product from the inventory
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

// Restock a product in the inventory
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

// Find the index of an item in the inventory
find_item_index :: proc(db: ^InventoryDatabase, item: Item) -> int {
    for db_item, i in db.items {
        if db_item.id == item.id {
            return i
        }
    }
    return -1
}

// Search for an item in the inventory database by its name and return details
search_item_details :: proc(db: ^InventoryDatabase, name: string) -> string {
    builder := strings.Builder{}
    strings.builder_init(&builder, context.allocator)

    item := find_item_by_name(db, name)
    if item != nil {
        fmt.sbprintf(&builder, "Item found: Name = %s, Quantity = %d, Price = %.2f, Manufacturer = %s",
            item.name, item.quantity, item.price, item.manufacturer)
    } else {
        fmt.sbprintf(&builder, "Item with name %s not found.", name)
    }

    return strings.to_string(builder)
}

// Calculate and return the total value of the inventory
total_value_of_inventory :: proc(db: ^InventoryDatabase) -> string {
    new_builder := strings.Builder{}
    strings.builder_init(&new_builder, context.allocator)
    total: f32 = 0.0

    for item in db.items {
        total += cast(f32)(item.quantity) * item.price
    }

    strings.write_string(&new_builder, "Total Inventory Value: $")
    fmt.sbprintf(&new_builder, "%.2f", total)

    return strings.to_string(new_builder)
}

// Save the inventory database to a file
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

    serialize_inventory(&buffer, database)

    bufio.writer_write(&writer, buffer.buf[:])
    bufio.writer_flush(&writer)

    return true
}

// Load the inventory database from a file
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

// Search for all items in the inventory database by manufacturer
search_items_by_manufacturer :: proc(db: ^InventoryDatabase, manufacturer: string) -> []Item {
    results := make([dynamic]Item, 0)

    for item in db.items {
        if item.manufacturer == manufacturer {
            append(&results, item)
        }
    }

    return results[:]
}

// Add benchmark items to the inventory database
addBenchmark :: proc(db: ^InventoryDatabase, amount: int) {
    for i := 0; i < amount; i += 1 {
        my_builder := strings.builder_make()
        strings.write_string(&my_builder, "Item - number: ")
        strings.write_int(&my_builder, i)

        item := Item{
            id = cast(i32)i,
            quantity = 1,
            price = 1.0,
            name = strings.to_string(my_builder),
            manufacturer = "Manufacturer",
        }

        add_item_by_struct(db, item)
    }
}

// Initialize a label for an item
initialize_label :: proc(item: Item) -> string {
    my_builder := strings.builder_make()
    strings.write_string(&my_builder, item.name)
    strings.write_string(&my_builder, "  |  Quantity: ")
    strings.write_int(&my_builder, cast(int)item.quantity)
    strings.write_string(&my_builder, " |  Price:  $")
    fmt.sbprintf(&my_builder, "%.2f", item.price)
    strings.write_string(&my_builder, " |  Total Value:  $")
    fmt.sbprintf(&my_builder, "%.2f", item.price * cast(f32)(item.quantity))
    strings.write_string(&my_builder, " |  Manufacturer: ")
    strings.write_string(&my_builder, item.manufacturer)
    return strings.to_string(my_builder)
}
