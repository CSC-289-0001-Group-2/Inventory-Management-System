package items

import "core:fmt"
import "core:testing"
import "core:strings"

// Test the search_item_details function
test_search_item_details :: proc(t: ^testing.T) {
    // Create a mock InventoryDatabase
    db: InventoryDatabase = InventoryDatabase{
        items = make([dynamic]Item, 0), // Initialize as a dynamic array
    }

    // Add test items to the database
    add_item_by_members(&db, 10, 5.99, "Apple", "FruitCo")
    add_item_by_members(&db, 20, 15.49, "Banana", "TropicalFarms")

    // Test 1: Search for an existing item
    output := search_item_details(&db, "Apple")
    testing.expect(t, ok=strings.contains(output, "Item found: Name = Apple"))
    testing.expect(t, ok=strings.contains(output, "Quantity = 10"))
    testing.expect(t, ok=strings.contains(output, "Price = 5.99"))
    testing.expect(t, ok=strings.contains(output, "Manufacturer = FruitCo"))

    // Test 2: Search for a non-existent item
    output = search_item_details(&db, "Orange")
    testing.expect(t, ok=strings.contains(output, "Item with name Orange not found."))

    fmt.println("All tests for search_item_details passed.")
}