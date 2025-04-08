package items

import "core:fmt"
import "core:testing"
import "../items" // Adjust the path to the `items` package

// Test the sell_product function
test_sell_product :: proc(t: ^testing.T) {
    // Create a mock InventoryDatabase
    db: items.InventoryDatabase = items.InventoryDatabase{
        items = make([dynamic]items.Item, 0), // Initialize as a dynamic array
    }

    // Add test items to the database
    items.add_item_by_members(&db, 10, 5.99, "Apple", "FruitCo")
    items.add_item_by_members(&db, 20, 15.49, "Banana", "TropicalFarms")

    // Test 1: Sell a valid quantity of an existing item
    success := items.sell_product(&db, "Apple", 5)
    testing.expect(t, ok=success)
    testing.expect(t, ok=db.items[0].quantity == 5) // Ensure the quantity is reduced

    // Test 2: Attempt to sell more than the available stock
    success = items.sell_product(&db, "Apple", 10)
    testing.expect(t, ok=!success)
    testing.expect(t, ok=db.items[0].quantity == 5) // Ensure the quantity is unchanged

    // Test 3: Attempt to sell a non-existent item
    success = items.sell_product(&db, "Orange", 5)
    testing.expect(t, ok=!success)
    testing.expect(t, ok=len(db.items) == 2) // Ensure the inventory is unchanged

    // Test 4: Attempt to sell with a quantity of zero
    success = items.sell_product(&db, "Banana", 0)
    testing.expect(t, ok=!success)
    testing.expect(t, ok=db.items[1].quantity == 20) // Ensure the quantity is unchanged

    // Test 5: Attempt to sell with a negative quantity
    success = items.sell_product(&db, "Banana", -5)
    testing.expect(t, ok=!success)
    testing.expect(t, ok=db.items[1].quantity == 20) // Ensure the quantity is unchanged

    // Test 6: Sell the exact remaining stock of an item
    success = items.sell_product(&db, "Banana", 20)
    testing.expect(t, ok=success)
    testing.expect(t, ok=db.items[1].quantity == 0) // Ensure the quantity is reduced to zero

    fmt.println("All tests for sell_product passed.")
}