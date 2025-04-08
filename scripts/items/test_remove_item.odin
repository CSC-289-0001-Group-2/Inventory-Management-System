package items

import "core:fmt"
import "core:testing"

// Test the remove_item function
test_remove_item :: proc(t: ^testing.T) {
    // Create a mock InventoryDatabase
    db: InventoryDatabase = InventoryDatabase{
        items = make([dynamic]Item, 0), // Initialize as a dynamic array
    }

    // Add test items to the database
    add_item_by_members(&db, 10, 5.99, "Apple", "FruitCo")
    add_item_by_members(&db, 20, 15.49, "Banana", "TropicalFarms")
    add_item_by_members(&db, 15, 3.49, "Carrot", "VeggieWorld")

    // Test 1: Remove an existing item
    success := remove_item(&db, "Banana")
    testing.expect(t, ok=success)
    testing.expect(t, ok=len(db.items) == 2) // Ensure the item count is reduced
    testing.expect(t, ok=db.items[0].name == "Apple") // Ensure the remaining items are correct
    testing.expect(t, ok=db.items[1].name == "Carrot")

    // Test 2: Attempt to remove a non-existent item
    success = remove_item(&db, "Orange")
    testing.expect(t, ok=!success)
    testing.expect(t, ok=len(db.items) == 2) // Ensure the item count is unchanged

    // Test 3: Remove the first item in the list
    success = remove_item(&db, "Apple")
    testing.expect(t, ok=success)
    testing.expect(t, ok=len(db.items) == 1) // Ensure the item count is reduced
    testing.expect(t, ok=db.items[0].name == "Carrot") // Ensure the remaining item is correct

    // Test 4: Remove the last remaining item
    success = remove_item(&db, "Carrot")
    testing.expect(t, ok=success)
    testing.expect(t, ok=len(db.items) == 0) // Ensure the inventory is empty

    fmt.println("All tests for remove_item passed.")
}