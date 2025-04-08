package items

import "core:fmt"
import "core:testing"
import "core:strings"
import "../items" // Adjust the path to the `items` package

// Test the total_value_of_inventory function
test_total_value_of_inventory :: proc(t: ^testing.T) {
    // Create a mock InventoryDatabase
    db: items.InventoryDatabase = items.InventoryDatabase{
        items = make([dynamic]items.Item, 0), // Initialize as a dynamic array
    }

    // Add test items to the database
    items.add_item_by_members(&db, 10, 5.99, "Apple", "FruitCo") // Total: 10 * 5.99 = 59.90
    items.add_item_by_members(&db, 20, 15.49, "Banana", "TropicalFarms") // Total: 20 * 15.49 = 309.80
    items.add_item_by_members(&db, 5, 3.49, "Carrot", "VeggieWorld") // Total: 5 * 3.49 = 17.45

    // Expected total value
    expected_total := 59.90 + 309.80 + 17.45

    // Call the function and capture the output
    output := items.total_value_of_inventory(&db)

    // Verify the output contains the expected total value
    testing.expect(t, ok=strings.contains(output, fmt.sbprintf(nil, "Total Inventory Value: $%.2f", expected_total)))

    fmt.println("All tests for total_value_of_inventory passed.")
}