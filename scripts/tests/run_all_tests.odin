package tests

import "core:fmt"
import "core:testing"
import "../items"
import "core:time"

run_all_tests :: proc() {
    start_time := time.now()
    fmt.println("Running tests at:", time.clock_from_time(start_time))
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
    finish_time := time.now()
    duration := time.diff(start_time, finish_time)
    fmt.println("\nAll tests completed at:", time.clock_from_time(start_time)," Total Duration:",time.duration_milliseconds(duration))
}