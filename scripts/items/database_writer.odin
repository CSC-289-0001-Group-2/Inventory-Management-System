package items

import "core:fmt"
import "core:os"
import "core:bytes"

StringData :: struct {
    count: int,
    data: ^u8,
}

InventoryItem :: struct {
    id: i32,
    quantity: i32,
    price: f32,
    name: StringData,
    manufacturer: StringData,
}

BUFFER_SIZE :: 1024

log_operation :: proc(operation: string, item: InventoryItem) {
    fmt.println("[LOG]", operation, "Item ID:", item.id)
}

InventoryDatabase :: struct {
    items: []InventoryItem,
}

add_item :: proc(db: ^InventoryDatabase, item: InventoryItem) {
    db.items = append(db.items, item)
}

serialize_inventory :: proc(database: InventoryDatabase) -> bytes.Buffer {
    buffer := bytes.Buffer{}
    
    item_count := len(database.items)
    buffer.write_bytes(item_count)
    
    for item in database.items {
        buffer.write_bytes(item.id),
        buffer.write_bytes(item.quantity),
        buffer.write_bytes(item.price),
        
        buffer.write_bytes(item.name.count),
        buffer.write(item.name.data[:item.name.count]),
        
        buffer.write_bytes(item.manufacturer.count),
        buffer.write(item.manufacturer.data[:item.manufacturer.count]),
    }
    
    return buffer
}

write_item :: proc(file_name: string, item: InventoryItem) -> bool {
    log_operation("Adding item", item)
    
    temp_db: InventoryDatabase
    temp_db.items = append(temp_db.items, item)
    
    buffer := serialize_inventory(temp_db)
    success := os.write_entire_file(file_name, buffer.data, true)
    if !success {
        fmt.println("Error writing to file:", file_name)
        return false
    }
    return true
}

save_inventory :: proc(file_name: string, database: InventoryDatabase) -> bool {
    buffer := serialize_inventory(database)
    success := os.write_entire_file(file_name, buffer.data, true)
    if !success {
        fmt.println("Error writing inventory to file:", file_name)
        return false
    }
    return true
}
