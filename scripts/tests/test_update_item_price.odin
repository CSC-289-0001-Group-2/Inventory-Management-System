package items

import "core:fmt"
import "core:testing"
import "../items" // Adjust the path to the `items` package

// Test the update_item_price function
test_update_item_price :: proc(t: ^testing.T) {
    // Create a mock InventoryDatabase
    db: items.InventoryDatabase = items.InventoryDatabase{
        items = make([dynamic]items.Item, 0), // Initialize as a dynamic array
    }

    // Add test items to the database
    items.add_item_by_members(&db, 10, 5.99, "Apple", "FruitCo")
    items.add_item_by_members(&db, 20, 15.49, "Banana", "TropicalFarms")

    // Test 1: Update the price of an existing item
    success := items.update_item_price(&db, "Apple", 6.99)
    testing.expect(t, ok=success)
    testing.expect(t, ok=db.items[0].price == 6.99)

    // Test 2: Attempt to update the price of a non-existent item
    success = items.update_item_price(&db, "Orange", 4.99)
    testing.expect(t, ok=!success)

    // Test 3: Attempt to update the price with a negative value
    success = items.update_item_price(&db, "Banana", -1.00)
    testing.expect(t, ok=!success)
    testing.expect(t, ok=db.items[1].price == 15.49)

    fmt.println("All tests for update_item_price passed.")
}