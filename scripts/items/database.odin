package items

import "core:fmt"
import "core:os"
import "core:bytes"

StringData :: struct {
    count: int,    // Number of bytes in the string
    data: []u8,    // String content (no mem.alloc!)
}

InventoryItem :: struct {
    id: i32,
    quantity: i32,
    price: f32,
    name: StringData,
    manufacturer: StringData
}

read_inventory :: proc(file_name: string) -> []InventoryItem {
    // Read entire file into memory
    file_data, success := os.read_entire_file(file_name)
    if !success {
        fmt.println("Error: Unable to read file:", file_name)
        return nil
    }

    // Create a bytes.Reader
    reader: bytes.Reader
    bytes.reader_init(&reader, file_data)

    // Read item count
    count: i32
    count_bytes: [4]u8 = transmute([4]u8) count
    n, _ := bytes.reader_read(&reader, count_bytes[:])
        if n != 4 {
        fmt.println("Error: Failed to read item count.")
        return nil
    }

    items: []InventoryItem = make([]InventoryItem, count)

    // Read each inventory item
    for i in 0..<count {
        item: InventoryItem

        // Read fixed-size fields
        id_bytes: [4]u8 = transmute([4]u8) item.id
        n, _ = bytes.reader_read(&reader, id_bytes[:]) // ✅ Convert fixed array to slice
        if n != 4 { fmt.println("Error: Failed to read item ID."); return nil }

        price_bytes := transmute([4]u8) item.price
        n, _ = bytes.reader_read(&reader, price_bytes[:])
        if n != 4 { fmt.println("Error: Failed to read item price."); return nil }
        
        quantity_bytes := transmute([4]u8) item.quantity
        n, _ = bytes.reader_read(&reader, quantity_bytes[:])
        if n != 4 { fmt.println("Error: Failed to read item quantity."); return nil }

        // Read name data
        count_name_bytes := transmute([4]u8) (i32(item.name.count)) 
        n, _ = bytes.reader_read(&reader, count_name_bytes[:])
        if n != 4 { fmt.println("Error: Failed to read name count."); return nil }
                
        current_name_offset := 0
        name_bytes: []u8 = file_data[current_name_offset : current_name_offset + item.name.count]
        current_name_offset += item.name.count // Update manually after each read
        
        // Read manufacturer count data
        count_manufacturer_bytes := transmute([4]u8) (i32(item.manufacturer.count))
        n, _ = bytes.reader_read(&reader, count_manufacturer_bytes[:])
        if n != 4 {
            fmt.println("Error: Failed to read manufacturer count.")
            return nil
        }

        current_manufacturer_offset := 0
        manufacturer_bytes: []u8 = file_data[current_manufacturer_offset : current_manufacturer_offset + item.manufacturer.count]
        current_manufacturer_offset += item.manufacturer.count // Update manually after each read
        
        // Store item in the array
        items[i] = item
    }

    return items
}

// Test function to load and print inventory
main :: proc() {
    inventory := read_inventory("inventory.dat")
    if inventory == nil {
        fmt.println("Failed to load inventory.")
        return
    }

    fmt.println("Loaded Inventory:")
    for item in inventory {
        fmt.println("ID:", item.id, "Qty:", item.quantity, "Price:", item.price)
        fmt.println("Name:", string(item.name.data))
        fmt.println("Manufacturer:", string(item.manufacturer.data))
    }
}
