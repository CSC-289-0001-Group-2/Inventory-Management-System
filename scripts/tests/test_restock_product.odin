package items

import "core:fmt"
import "core:testing"
import "../items" // Adjust the path to the `items` package

// Test the restock_product function
test_restock_product :: proc(t: ^testing.T) {
    // Create a mock InventoryDatabase
    db: items.InventoryDatabase = items.InventoryDatabase{
        items = make([dynamic]items.Item, 0), // Initialize as a dynamic array
    }

    // Add test items to the database
    items.add_item_by_members(&db, 10, 5.99, "Apple", "FruitCo")
    items.add_item_by_members(&db, 20, 15.49, "Banana", "TropicalFarms")

    // Test 1: Restock an existing item
    success := items.restock_product(&db, "Apple", 5)
    testing.expect(t, ok=success)
    testing.expect(t, ok=db.items[0].quantity == 15) // Ensure the quantity is increased

    // Test 2: Attempt to restock a non-existent item
    success = items.restock_product(&db, "Orange", 10)
    testing.expect(t, ok=!success)
    testing.expect(t, ok=len(db.items) == 2) // Ensure the inventory is unchanged

    // Test 3: Attempt to restock with a quantity of zero
    success = items.restock_product(&db, "Banana", 0)
    testing.expect(t, ok=!success)
    testing.expect(t, ok=db.items[1].quantity == 20) // Ensure the quantity is unchanged

    // Test 4: Attempt to restock with a negative quantity
    success = items.restock_product(&db, "Banana", -5)
    testing.expect(t, ok=!success)
    testing.expect(t, ok=db.items[1].quantity == 20) // Ensure the quantity is unchanged

    // Test 5: Restock with a large quantity
    success = items.restock_product(&db, "Banana", 100)
    testing.expect(t, ok=success)
    testing.expect(t, ok=db.items[1].quantity == 120) // Ensure the quantity is increased correctly

    fmt.println("All tests for restock_product passed.")
}