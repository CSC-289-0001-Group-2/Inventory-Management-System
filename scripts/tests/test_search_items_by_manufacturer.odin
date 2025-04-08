package items

import "core:fmt"
import "core:testing"
import "../items" // Import the items package

// Test the search_items_by_manufacturer function
test_search_items_by_manufacturer :: proc(t: ^testing.T) {
    // Create a mock InventoryDatabase
    db: items.InventoryDatabase = items.InventoryDatabase{
        items = make([dynamic]items.Item, 0), // Initialize as a dynamic array
    }

    // Add test items to the database
    items.add_item_by_members(&db, 10, 5.99, "Apple", "FruitCo")
    items.add_item_by_members(&db, 20, 15.49, "Banana", "TropicalFarms")
    items.add_item_by_members(&db, 5, 3.49, "Carrot", "FruitCo")
    items.add_item_by_members(&db, 8, 4.99, "Orange", "CitrusWorld")

    // Test 1: Search for items by a manufacturer that exists
    results := items.search_items_by_manufacturer(&db, "FruitCo")
    testing.expect(t=t, ok=len(results) == 2)
    testing.expect(t=t, ok=results[0].name == "Apple")
    testing.expect(t=t, ok=results[1].name == "Carrot")

    // Test 2: Search for items by a manufacturer with no matches
    results = items.search_items_by_manufacturer(&db, "NonExistentCo")
    testing.expect(t=t, ok=len(results) == 0)

    // Test 3: Search for items by another manufacturer
    results = items.search_items_by_manufacturer(&db, "TropicalFarms")
    testing.expect(t=t, ok=len(results) == 1)
    testing.expect(t=t, ok=results[0].name == "Banana")

    // Test 4: Search for items by a manufacturer with a single match
    results = items.search_items_by_manufacturer(&db, "CitrusWorld")
    testing.expect(t=t, ok=len(results) == 1)
    testing.expect(t=t, ok=results[0].name == "Orange")

    fmt.println("All tests for search_items_by_manufacturer passed.")
}