package items

import "core:fmt"
import "core:testing"
import "core:strings"

// Test the total_value_of_inventory function
test_total_value_of_inventory :: proc(t: ^testing.T) {
    // Create a mock InventoryDatabase
    db: InventoryDatabase = InventoryDatabase{
        items = make([dynamic]Item, 0), // Initialize as a dynamic array
    }

    // Add test items to the database
    add_item_by_members(&db, 10, 5.99, "Apple", "FruitCo") // Total: 10 * 5.99 = 59.90
    add_item_by_members(&db, 20, 15.49, "Banana", "TropicalFarms") // Total: 20 * 15.49 = 309.80
    add_item_by_members(&db, 5, 3.49, "Carrot", "VeggieWorld") // Total: 5 * 3.49 = 17.45

    // Expected total value
    expected_total := 59.90 + 309.80 + 17.45

    // Redirect output to a strings.Builder
    output_builder := strings.Builder{}
    strings.builder_init(&output_builder, context.allocator)
    fmt.set_output_stream(strings.stream_from_builder(&output_builder))

    // Call the function
    total_value_of_inventory(&db)

    // Capture the output
    output := strings.to_string(&output_builder)

    // Verify the output contains the expected total value
    testing.expect(t, ok=strings.contains(output, fmt.sprintf("Total Inventory Value: $%.2f", expected_total)))

    fmt.println("All tests for total_value_of_inventory passed.")
}