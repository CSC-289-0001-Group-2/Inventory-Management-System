package items

import "core:fmt"
import "core:testing"
import "core:os"
import "core:bytes"

// Test the save_inventory function
test_save_inventory :: proc(t: ^testing.T) {
    // Create a mock InventoryDatabase
    db: InventoryDatabase = InventoryDatabase{
        items = make([dynamic]Item, 0), // Initialize as a dynamic array
    }

    // Add test items to the database
    add_item_by_members(&db, 10, 5.99, "Apple", "FruitCo")
    add_item_by_members(&db, 20, 15.49, "Banana", "TropicalFarms")

    // Define the file name for saving the inventory
    file_name := "test_inventory.dat"

    // Call the save_inventory function
    success := save_inventory(file_name, db)
    testing.expect(t=t, ok=success)

    // Verify that the file was created
    file_info, file_exists := os.stat(file_name)
    testing.expect(t=t, ok=file_exists == nil)
    testing.expect(t=t, ok=file_info.size > 0)

    // Read the file contents to verify the serialized data
    data, read_success := os.read_entire_file_from_filename(file_name)
    testing.expect(t=t, ok=read_success)

    // Deserialize the data and verify the contents
    loaded_db, deserialize_success := deserialize_inventory(data)
    testing.expect(t=t, ok=deserialize_success)
    testing.expect(t=t, ok=len(loaded_db.items) == len(db.items))

    // Verify the contents of the deserialized inventory
    for i in 0..<len(db.items) {
        original_item := db.items[i]
        loaded_item := loaded_db.items[i]
        testing.expect(t=t, ok=original_item.name == loaded_item.name)
        testing.expect(t=t, ok=original_item.quantity == loaded_item.quantity)
        testing.expect(t=t, ok=original_item.price == loaded_item.price)
        testing.expect(t=t, ok=original_item.manufacturer == loaded_item.manufacturer)
    }

    // Clean up: Delete the test file
    os.remove(file_name)

    fmt.println("All tests for save_inventory passed.")
}