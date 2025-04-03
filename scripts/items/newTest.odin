package items

import "core:fmt"
import "core:os"
import "core:mem"
import "core:bytes"

// Struct to store string data
StringData :: struct {
    count:  int,   // Number of bytes in the string
    data:   ^u8,   // Pointer to the string data
}

// Struct representing an inventory item
InventoryItem :: struct {
    id:           i32,         // Item ID
    quantity:     i32,         // Quantity of the item
    price:        f32,         // Price as float (e.g., $5.99)
    name:         StringData,  // Name of the item
    manufacturer: StringData   // Manufacturer of the item
}

// Function to log operations
log_operation :: proc(operation: string, item: InventoryItem) {
    fmt.println("[LOG]", operation, "Item ID:", item.id)
}

// Function to serialize an InventoryItem
serialize_item :: proc(item: InventoryItem, allocator: mem.Allocator) -> []u8 {
    total_size := 8 + 4 + 8 + item.name.count + item.manufacturer.count
    buffer, err := mem.alloc(allocator, total_size)
    if err != nil {
        fmt.println("Error in function serialize_item.")
    }    
    offset := 0

    // Convert values to byte representation
    mem.copy(buffer[offset:offset+4], transmute([4]u8)item.id)
    offset += 4
    mem.copy(buffer[offset:offset+4], transmute([4]u8)item.quantity)
    offset += 4
    mem.copy(buffer[offset:offset+4], transmute([4]u8)item.price)
    offset += 4
    mem.copy(buffer[offset:offset+4], transmute([4]u8)item.name.count)
    offset += 4
    mem.copy(buffer[offset:offset+4], transmute([4]u8)item.manufacturer.count)
    offset += 4

    // Copy string data
    mem.copy(buffer[offset:offset+item.name.count], item.name.data)
    offset += item.name.count
    mem.copy(buffer[offset:offset+item.manufacturer.count], item.manufacturer.data)
    offset += item.manufacturer.count

    return buffer
}

// Function to write an InventoryItem to a binary file
write_item :: proc(file_name: string, item: InventoryItem, allocator: mem.Allocator) -> bool {
    log_operation("Adding item", item)
    serialized_data := serialize_item(item, allocator)
    success := os.write_entire_file(file_name, serialized_data, true)
    if !success {
        fmt.println("Error writing to file:", file_name)
        return false
    }
    return true
}

// Function to read a string from a binary file
read_string :: proc(reader: ^bytes.Reader) -> StringData {
    str_data: StringData
    if reader.i + size_of(int) > len(reader.s) {
        return str_data
    }

    // Read count
    mem.copy(transmute([]u8)&str_data.count, reader.s[reader.i:reader.i+size_of(int)])
    reader.i += size_of(int)

    if reader.i + str_data.count > len(reader.s) {
        return str_data
    }

    // Read string data
    str_data.data = &reader.s[reader.i]
    reader.i += str_data.count

    return str_data
}

// Function to deserialize an InventoryItem
deserialize_inventory_item :: proc(reader: ^bytes.Reader) -> (InventoryItem, bool) {
    item: InventoryItem    
    if reader.i + size_of(i32) * 2 + size_of(f32) > len(reader.s) {
        fmt.println("Not enough bytes available to read item details")
        return item, false
    }

    // Read id, quantity, and price
    mem.copy(transmute([]u8)&item.id, reader.s[reader.i:reader.i+size_of(i32)])
    reader.i += size_of(i32)
    mem.copy(transmute([]u8)&item.quantity, reader.s[reader.i:reader.i+size_of(i32)])
    reader.i += size_of(i32)
    mem.copy(transmute([]u8)&item.price, reader.s[reader.i:reader.i+size_of(f32)])
    reader.i += size_of(f32)

    // Read name and manufacturer
    item.name = read_string(reader)
    item.manufacturer = read_string(reader)

    return item, true
}

// Function to read inventory items from a binary file
read_inventory_items :: proc(file_name: string) -> ([]InventoryItem, bool) {
    data, success := os.read_entire_file(file_name)
    if !success {
        fmt.println("Error reading file")
        return nil, false
    }

    reader := bytes.Reader{s = data}
    items: []InventoryItem
    for reader.i < len(reader.s) {
        item, ok := deserialize_inventory_item(&reader)
        if !ok {
            fmt.println("Error deserializing item.")
            break
        }
        items = append(items, item)
    }
    return items, true
}

// Main function to test reading/writing
main :: proc() {
    allocator := mem.default_allocator()

    item := InventoryItem{
        id = 1,
        quantity = 10,
        price = 19.99,
        name = StringData{
            count = 6,
            data = transmute(^u8)"Guitar"
        },
        manufacturer = StringData{
            count = 8,
            data = transmute(^u8)"Fender"
        }
    }

    file_name := "inventory.dat"

    // Write item to file
    if write_item(file_name, item, allocator) {
        fmt.println("Item written successfully.")
    } else {
        fmt.println("Failed to write item.")
    }

    // Read items from file
    items, success := read_inventory_items(file_name)
    if success {
        for itm in items {
            fmt.println("Read Item:", itm.id, itm.quantity, itm.price, itm.name.data, itm.manufacturer.data)
        }
    }
}
