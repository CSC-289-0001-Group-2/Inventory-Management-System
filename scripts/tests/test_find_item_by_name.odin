package tests

import "core:fmt"
import "core:testing"
import "../items" // Adjust the path to the `items` package

// Test the find_item_by_name function
test_find_item_by_name :: proc(t: ^testing.T) {
    // Create a mock InventoryDatabase
    db: items.InventoryDatabase = items.InventoryDatabase{
        items = make([dynamic]items.Item, 0), // Initialize as a dynamic array
    }

    // Add test items to the database
    items.add_item_by_members(&db, 10, 5.99, "Apple", "FruitCo")
    items.add_item_by_members(&db, 20, 15.49, "Banana", "TropicalFarms")
    items.add_item_by_members(&db, 5, 3.49, "Carrot", "VeggieWorld")

    // Test 1: Find an existing item
    item := items.find_item_by_name(&db, "Apple")
    testing.expect(t=t, ok=item != nil)
    testing.expect(t=t, ok=item.name == "Apple")
    testing.expect(t=t, ok=item.quantity == 10)
    testing.expect(t=t, ok=item.price == 5.99)
    testing.expect(t=t, ok=item.manufacturer == "FruitCo")

    // Test 2: Find another existing item
    item = items.find_item_by_name(&db, "Banana")
    testing.expect(t=t, ok=item != nil)
    testing.expect(t=t, ok=item.name == "Banana")
    testing.expect(t=t, ok=item.quantity == 20)
    testing.expect(t=t, ok=item.price == 15.49)
    testing.expect(t=t, ok=item.manufacturer == "TropicalFarms")

    // Test 3: Attempt to find a non-existent item
    item = items.find_item_by_name(&db, "Orange")
    testing.expect(t=t, ok=item == nil)

    fmt.println("All tests for find_item_by_name passed.")
}