package main

import "core:fmt"
import "core:os"
import "core:encoding/json"

// Define a structure to represent an inventory item.
InventoryItem :: struct {
    id: i32,
    name: string,
    quantity: i32,
    price: f32,
    manufacturer: string,
    is_deleted: bool,
}

main :: proc() {
    // Create a slice (dynamic array) of inventory items.
    items := []InventoryItem{
        InventoryItem{ id = 1, name = "Apples", quantity = 50, price = 0.99, manufacturer = "FarmFresh", is_deleted = false },
        InventoryItem{ id = 2, name = "Swords", quantity = 5, price = 299.99, manufacturer = "Camelot", is_deleted = false },
    }

    // Marshal (serialize) the items slice into JSON format.
    data, marshal_err := json.marshal(items)
    if marshal_err != nil {
        fmt.println("JSON marshal error:", marshal_err)
        return
    }

    // Open (or create) the inventory file with read-write permissions.
    f, open_err := os.open("inventory.json", os.O_RDWR | os.O_CREATE)
    if open_err != nil {
        fmt.println("Failed to open file:", open_err)
        return
    }
    defer os.close(f) // Ensure the file is closed when the function exits.

    // Write the JSON data to the file.
    n, write_err := os.write(f, data)
    if write_err != nil {
        fmt.println("Failed to write data:", write_err)
        return
    }
    if n != len(data) {
        fmt.println("Failed to write all data")
        return
    }

    // Rewind the file to the beginning.
    os.seek(f, 0, os.SEEK_SET)

    // Retrieve file information to determine its size.
    info, stat_err := os.stat("inventory.json")
    if stat_err != nil {
        fmt.println("Error retrieving file information:", stat_err)
        return
    }
    size := info.size

    // Create a buffer to hold the file's contents.
    buffer := make([]u8, int(size))

    // Read the full content of the file into the buffer.
    bytesRead, read_err := os.read_full(f, buffer) // Using a new variable 'bytesRead'
    if read_err != nil {
        fmt.println("Error reading file:", read_err)
        return
    }
    if bytesRead != int(size) {
        fmt.println("Failed to read full data")
        return
    }

    // Unmarshal (deserialize) the JSON data back into a slice of InventoryItem.
    items2 := []InventoryItem{}
    unmarshal_err := json.unmarshal(buffer, &items2)
    if unmarshal_err != nil {
        fmt.println("JSON unmarshal error:", unmarshal_err)
        return
    }

    // Print the current inventory to the console.
    fmt.println("Current inventory:", items2)
}
package main

import "core:fmt"
import "core:os"
import "core:mem"

// item structure accounting for future items with long names
InventoryItem :: struct {
    id:         i32,
    name_length: i32, // Length of the name string
    name:       []u8, // Dynamic byte slice to hold the name
    quantity:   i32,
    price:      f32,
    is_deleted: bool,
}

write_inventory_item :: proc(file: ^os.File, item: InventoryItem) -> bool {
    // Seek to the end of the file to append the new item
    file.seek(0, os.Seek_End); 

    // Write the length of the name
    bytes_written := file.write(mem.as_raw_bytes(&item.name_length));

    // Write the name itself
    bytes_written += file.write(item.name);

    // Write other item details
    bytes_written += file.write(mem.as_raw_bytes(&item.quantity));
    bytes_written += file.write(mem.as_raw_bytes(&item.price));
    bytes_written += file.write(mem.as_raw_bytes(&item.is_deleted));

    // Check if we wrote everything successfully
    return bytes_written == (mem.size_of(i32) + item.name_length + mem.size_of(i32) + mem.size_of(f32) + mem.size_of(bool));
}

// Function to read an individual inventory item from a binary file
read_inventory_item :: proc(file: ^os.File) -> InventoryItem {
    item: InventoryItem;

    // Read the length of the name first
    bytes_read := file.read(mem.as_raw_bytes(&item.name_length));

    if bytes_read != mem.size_of(i32) {
        fmt.println("Error reading name length.");
        return item; // Return empty item on error
    }

    // Allocate memory for the name based on the length
    item.name = mem.alloc(item.name_length);

    // Now read the name itself
    bytes_read = file.read(item.name);
    if bytes_read != item.name_length {
        fmt.println("Error reading item name.");
        return item; // Return empty item on error
    }

    // Read the other item details
    bytes_read += file.read(mem.as_raw_bytes(&item.quantity));
    if bytes_read != mem.size_of(i32) + item.name_length {
        fmt.println("Error reading item quantity.");
        return item;
    }

    bytes_read += file.read(mem.as_raw_bytes(&item.price));
    if bytes_read != mem.size_of(i32) + item.name_length + mem.size_of(i32) {
        fmt.println("Error reading item price.");
        return item;
    }

    bytes_read += file.read(mem.as_raw_bytes(&item.is_deleted));
    if bytes_read != mem.size_of(i32) + item.name_length + mem.size_of(i32) + mem.size_of(f32) {
        fmt.println("Error reading item deletion status.");
        return item;
    }

    return item;
}

// Funtion to read ALL in-stock inventory items from binary file
read_inventory_items :: proc(file: ^os.File) -> []InventoryItem {
    file.seek(0, os.Seek_Absolute);

    // Error handling
    // Prevent infinite loop if no inventory
    if file.size() == 0 {
        fmt.println("No items in inventory.");
        return []InventoryItem{};
    }
    
    items: []InventoryItem;
    item: InventoryItem;
    
    for file.read(mem.as_raw_bytes(&item.name_length)) == mem.size_of(i32) {
        // Allocate memory for the name based on the length
        item.name = mem.alloc(item.name_length);
        
        // Read the actual name
        file.read(item.name);

        // Read the rest of the item data
        file.read(mem.as_raw_bytes(&item.quantity));
        file.read(mem.as_raw_bytes(&item.price));
        file.read(mem.as_raw_bytes(&item.is_deleted));
        
        if !item.is_deleted { // Only return non-deleted items
            items = append(items, item);
        }
    }
    
    return items;
}

// Funtion to find an item by ID
find_inventory_item :: proc(file: ^os.File, search_id: i32) -> (bool, InventoryItem) {
    file.seek(0, os.Seek_Absolute);
    
    item: InventoryItem;
    
    for file.read(mem.as_raw_bytes(&item)) == mem.size_of(InventoryItem) {
        if item.id == search_id && !item.is_deleted {
            return (true, item); // Item found
        }
    }
    
    return (false, InventoryItem{}); // Return false and an empty item if not found
}

// Funtion to update inventory quantity (Item sold)
update_inventory_quantity :: proc(file: ^os.File, search_id: i32, sold_quantity: i32) -> bool {
    file.seek(0, os.Seek_Absolute);
    
    item: InventoryItem;
    pos := 0;
    
    for file.read(mem.as_raw_bytes(&item)) == mem.size_of(InventoryItem) {
        if item.id == search_id && !item.is_deleted {
            item.quantity -= sold_quantity; // Reduce quantity once customer purchase is made
            
            file.seek(pos, os.Seek_Absolute); // Move back to start of item
            file.write(mem.as_raw_bytes(&item)); // Overwrites old quantity with new value
            
            return true; // Success
        }
        pos += mem.size_of(InventoryItem);
    }
    
    return false; // Item not found
}

// Marking an item as deleted (aka Sold Out but still in inventory)
delete_inventory_item :: proc(file: ^os.File, search_id: i32) -> bool {
    file.seek(0, os.Seek_Absolute);
    
    item: InventoryItem;
    pos := 0;
    
    for file.read(mem.as_raw_bytes(&item)) == mem.size_of(InventoryItem) {
        if item.id == search_id && !item.is_deleted {
            item.is_deleted = true; // Mark as deleted
            
            file.seek(pos, os.Seek_Absolute);
            file.write(mem.as_raw_bytes(&item));
            
            return true;
        }
        pos += mem.size_of(InventoryItem);
    }
    
    return false;
}


main :: proc() {
    file, err := os.open("inventory.dat", os.File_Open_Mode{write=true, read=true, create=true});
    if err != nil {
        fmt.println("Failed to open file");
        return;
    }

    // Adding apples to inventory
    new_item := InventoryItem{id=1, name="Apples", quantity=50, price=0.99, is_deleted=false};
    success := write_inventory_item(&file, new_item);
    if success {
        fmt.println("Item added to inventory.");
    } else {
        fmt.println("Failed to add item.");
    }

    // Adding cool swords to inventory
    new_item := InventoryItem{id=2, name="Cool Sword", quantity=5, price=1500.50, is_deleted=false};
    success := write_inventory_item(&file, new_item);
    if success {
        fmt.println("Item added to inventory.");
    } else {
        fmt.println("Failed to add item.");
    }

    // Selling 10 apples
    update_inventory_quantity(&file, 1, 10); // Targets ID 1, which in our example, is apples

    // Mark item as sold out
    delete_inventory_item(&file, 1);

    // Read inventory (only if file is not empty)
    if file.size() > 0 {
        items := read_inventory_items(&file);
        fmt.println("Current inventory:", items);
    } else {
        fmt.println("Inventory file is empty. Add items to inventory.");
    }

    file.seek(0, os.Seek_Absolute); // Reset file pointer to start (prevents errors from functions only applying midway through file instead of from the beginning)

    file.close(); // Close file after all operations
}
