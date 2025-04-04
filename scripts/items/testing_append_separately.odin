package items

import "core:fmt"

// Define TestInventoryItem type
TestInventoryItem :: struct {
    id: int,
    name: string,
}

// Define a global array to hold all inventory items
inventory_items: []TestInventoryItem = make([]TestInventoryItem, 0) // Initialize as an empty slice

// Define a global counter for auto-incrementing IDs
next_id: int = 1 // Start the ID counter at 1

// Function to add a new item to the inventory
test_add_item :: proc(name: string) {
    // Create a new TestInventoryItem with the next available ID
    new_item := TestInventoryItem{id = next_id, name = name}

    // Append the new item to the inventory array
    inventory_items = append(^inventory_items, new_item) // Use the built-in append function

    // Increment the ID counter
    next_id += 1

    fmt.println("Item successfully added: ID =", new_item.id, "Name =", name)
}

main :: proc() {
    // Add items to the inventory
    test_add_item("Item A")
    test_add_item("Item B")

    // Print the inventory
    fmt.println("Current Inventory:")
    for item in inventory_items {
        fmt.println("ID:", item.id, "Name:", item.name)
    }
}