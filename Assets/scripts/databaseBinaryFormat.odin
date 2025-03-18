package main

import "core:fmt"
import "core:os"
import "core:mem"

// Generic helper to write a value's bytes to a file.
write_val :: proc(T: type, file: os.File, ptr: ^T) -> int {
    data: []u8 = mem.as_bytes(ptr)
    return os.write(file, data)
}

// Generic helper to read bytes from a file into a value.
read_val :: proc(T: type, file: os.File, ptr: ^T) -> int {
    data: []u8 = mem.as_bytes(ptr)[0:min(size_of(T), len(mem.as_bytes(ptr)))]
    return os.read(file, data)
}

InventoryItem :: struct {
    id: i32,
    name_length: i32,
    name: []u8,
    quantity: i32,
    price: f32,
    manufacturer_length: i32,
    manufacturer: []u8,
    is_deleted: bool,
};

// Write an inventory item to a binary file.
write_inventory_item :: proc(file: os.File, item: InventoryItem) -> bool {
    // Seek to end of file.
    os.seek(file, 0, os.SEEK_END)
    bytes_written := 0

    bytes_written += write_val(i32, file, &item.id)
    bytes_written += write_val(i32, file, &item.name_length)
    bytes_written += os.write(file, item.name)
    bytes_written += write_val(file, &item.manufacturer_length)
    bytes_written += os.write(file, item.manufacturer)
    bytes_written += write_val(file, &item.quantity)
    bytes_written += write_val(file, &item.price)

    is_deleted_int: i32
    if item.is_deleted {
        is_deleted_int = 1
    } else {
        is_deleted_int = 0
    }
    bytes_written += write_val(file, &is_deleted_int)

    expected_size := size_of(item.id) +
                     size_of(item.name_length) +
                     item.name_length +
                     size_of(item.manufacturer_length) +
                     item.manufacturer_length +
                     size_of(item.quantity) +
                     size_of(item.price) +
                     size_of(is_deleted_int)
    return bytes_written == expected_size
}

// Read one inventory item from the file. Returns (success, item).
read_inventory_item :: proc(file: os.File) -> (bool, InventoryItem) {
    var item: InventoryItem
    var bytes_read: int

    bytes_read = read_val(file, &item.id)
    if bytes_read != size_of(item.id) { return false, item }

    bytes_read = read_val(file, &item.name_length)
    if bytes_read != size_of(item.name_length) { return false, item }

    item.name = mem.alloc(item.name_length)
    bytes_read = os.read(file, item.name)
    if bytes_read != item.name_length {
        mem.free(item.name)
        return false, item
    }

    bytes_read = read_val(file, &item.manufacturer_length)
    if bytes_read != size_of(item.manufacturer_length) { return false, item }
    if bytes_read != item.manufacturer_length {
        mem.free(item.name)
        mem.free(item.manufacturer)
    if bytes_read != size_of(item.quantity) {
        mem.free(item.name)
        mem.free(item.manufacturer)
    if bytes_read != size_of(item.price) {
        mem.free(item.name)
        mem.free(item.manufacturer)
        return false, item
    if bytes_read != size_of(is_deleted_int) {
        mem.free(item.name)
        mem.free(item.manufacturer)
        return false, item
    }
    }
    }
    item.manufacturer = mem.alloc(item.manufacturer_length)
    bytes_read = os.read(file, item.manufacturer)
    if bytes_read != item.manufacturer_length { return false, item }

    bytes_read = read_val(file, &item.quantity)
    if bytes_read != size_of(item.quantity) { return false, item }

    bytes_read = read_val(file, &item.price)
    if bytes_read != size_of(item.price) { return false, item }

    var is_deleted_int: i32
    bytes_read = read_val(file, &is_deleted_int)
    if bytes_read != size_of(is_deleted_int) { return false, item }
    item.is_deleted = is_deleted_int != 0

    return true, item
}

// Read all non-deleted inventory items.
read_inventory_items :: proc(file: os.File) -> []InventoryItem {
    os.seek(file, 0, os.SEEK_SET)
    items: []InventoryItem = nil
    for {
        success, item := read_inventory_item(file)
        if !success { break }
        if !item.is_deleted {
            items = append(items, item)
        }
    }
    return items
}

// Find an inventory item by id.
find_inventory_item :: proc(file: os.File, search_id: i32) -> (bool, InventoryItem) {
    os.seek(file, 0, os.SEEK_SET)
    for {
        success, item := read_inventory_item(file)
        if !success { break }
        if item.id == search_id && !item.is_deleted {
            return true, item
        }
    }
    return false, InventoryItem{}
}

// Update an inventory item's quantity.
// Reads the item, updates the quantity, then seeks back to the quantity field.
update_inventory_quantity :: proc(file: os.File, search_id: i32, sold_quantity: i32) -> bool {
    os.seek(file, 0, os.SEEK_SET)
    for {
        start_pos := os.tell(file)
        success, item := read_inventory_item(file)
        if !success { break }
        if item.id == search_id && !item.is_deleted {
            item.quantity -= sold_quantity
            offset := size_of(item.id) +
                      size_of(item.name_length) + item.name_length +
                      size_of(item.manufacturer_length) + item.manufacturer_length
            os.seek(file, start_pos + offset, os.SEEK_SET)
            data: []u8 = cast([*]u8, &item.quantity)[0..size_of(item.quantity)]
            os.write(file, data)
            return true
        }
    }
    return false
}

// Mark an inventory item as deleted.
delete_inventory_item :: proc(file: os.File, search_id: i32) -> bool {
    os.seek(file, 0, os.SEEK_SET)
    for {
        start_pos := os.tell(file)
        success, item := read_inventory_item(file)
        if !success { break }
        if item.id == search_id && !item.is_deleted {
            item.is_deleted = true
            offset := size_of(item.id) +
                      size_of(item.name_length) + item.name_length +
                      size_of(item.manufacturer_length) + item.manufacturer_length +
                      size_of(item.quantity) + size_of(item.price)
            os.seek(file, start_pos + offset, os.SEEK_SET)
            var is_deleted_int: i32
            if item.is_deleted { is_deleted_int = 1 } else { is_deleted_int = 0 }
            data: []u8 = cast([*]u8, &is_deleted_int)[0..size_of(is_deleted_int)]
            os.write(file, data)
            return true
        }
    }
    return false
}

main :: proc() {
    file, err := os.open("inventory.dat", os.O_RDWR | os.O_CREATE, 0666)
    if err != nil {
        fmt.println("Failed to open file")
        return
    }
    defer os.close(file)

    new_item: InventoryItem = InventoryItem{
        id = 1,
        name_length = 6,                  // "Apples" has 6 bytes
        name = "Apples".to_bytes(),
        manufacturer_length = 9,          // "FarmFresh"
        manufacturer = "FarmFresh".to_bytes(),
        quantity = 50,
        price = 0.99,
        is_deleted = false,
    }
    success := write_inventory_item(file, new_item)
    if success {
        fmt.println("Item added to inventory.")
    } else {
        fmt.println("Failed to add item.")
    }

    new_item = InventoryItem{
        id = 2,
        name_length = 6,                  // "Swords" has 6 bytes
        name = "Swords".to_bytes(),
        manufacturer_length = 7,          // "Camelot"
        manufacturer = "Camelot".to_bytes(),
        quantity = 5,
        price = 299.99,
        is_deleted = false,
    }
    success = write_inventory_item(file, new_item)
    if success {
        fmt.println("Item added to inventory.")
    } else {
        fmt.println("Failed to add item.")
    }

    update_inventory_quantity(file, 1, 10)
    delete_inventory_item(file, 1)

    items := read_inventory_items(file)
    fmt.println("Current inventory:", items)

    for item in items {
        mem.free(item.name)
        mem.free(item.manufacturer)
    }
}
