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
        InventoryItem{ id = 3, name = "Metallica T-Shirts", quantity = 30, price = 20.00, manufacturer = "Metallica", is_deleted = false },
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
