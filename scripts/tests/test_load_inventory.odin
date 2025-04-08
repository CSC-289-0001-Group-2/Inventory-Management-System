package tests

import "core:fmt"
import "core:testing"
import "core:os"
import "../items" // Adjust the path to the `items` package

// Test the load_inventory function
test_load_inventory :: proc(t: ^testing.T) {
    // Create a mock InventoryDatabase
    db: items.InventoryDatabase = items.InventoryDatabase{
        items = make([dynamic]items.Item, 0), // Initialize as a dynamic array
    }

    // Add test items to the database
    items.add_item_by_members(&db, 10, 5.99, "Apple", "FruitCo")
    items.add_item_by_members(&db, 20, 15.49, "Banana", "TropicalFarms")

    // Define the file name for saving and loading the inventory
    file_name := "test_inventory.dat"

    // Save the inventory to a file
    save_success := items.save_inventory(file_name, db)
    testing.expect(t=t, ok=save_success)

    // Load the inventory from the file
    loaded_db, load_success := items.load_inventory(file_name)
    testing.expect(t=t, ok=load_success)

    // Verify the loaded inventory matches the original database
    testing.expect(t=t, ok=len(loaded_db.items) == len(db.items))

    for i in 0..<len(db.items) {
        original_item := db.items[i]
        loaded_item := loaded_db.items[i]
        testing.expect(t=t, ok=original_item.name == loaded_item.name)
        testing.expect(t=t, ok=original_item.quantity == loaded_item.quantity)
        testing.expect(t=t, ok=original_item.price == loaded_item.price)
        testing.expect(t=t, ok=original_item.manufacturer == loaded_item.manufacturer)
    }

    // Clean up: Delete the test file
    os.remove(file_name)

    fmt.println("All tests for load_inventory passed.")
}