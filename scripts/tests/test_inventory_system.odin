package tests

import "core:fmt"
import "core:testing"
import "../items" // Import the items package

// Test the inventory management system
test_inventory_system :: proc() {
    db_test := testing.T{}
    test_find_item_by_name(&db_test)
    test_search_item_details(&db_test)
    test_save_inventory(&db_test)
    test_load_inventory(&db_test)
    test_remove_item(&db_test)
    test_sell_product(&db_test)
    test_restock_product(&db_test)
    test_update_item_price(&db_test)
    test_total_value_of_inventory(&db_test)

    fmt.println("All tests for the inventory management system passed.")
}