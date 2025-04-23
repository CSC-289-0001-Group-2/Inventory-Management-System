package items

import "core:fmt"
import "core:bytes"
import "core:encoding/endian"
import "core:mem"
import "core:strings"
import virtual "core:mem/virtual"

// Struct Definitions
InventoryDatabase :: struct {
    items: [dynamic]Item,
    allocator: virtual.Arena,
}

Item :: struct {
    id: i32,
    quantity: i32,
    price: f32,
    name: string,
    manufacturer: string,
    label: string,
}
#assert(size_of(Item) == 8 + 4 + 4 + 16 + 16 + 16)

// Serialize the inventory database
serialize_inventory :: proc(buf: ^bytes.Buffer, database: InventoryDatabase) {
    // Serialize the number of items in the array (Little Endian encoding)
    bytes.buffer_write(buf, mem.any_to_bytes(i64le(len(database.items))))

    for item in database.items {
        // Serialize item fields
        bytes.buffer_write(buf, mem.any_to_bytes(i32le(item.id)))
        bytes.buffer_write(buf, mem.any_to_bytes(i32le(item.quantity)))
        bytes.buffer_write(buf, mem.any_to_bytes(f32le(item.price)))

        // Serialize the name
        bytes.buffer_write(buf, mem.any_to_bytes(i64le(len(item.name))))
        bytes.buffer_write_string(buf, item.name)

        // Serialize the manufacturer
        bytes.buffer_write(buf, mem.any_to_bytes(i64le(len(item.manufacturer))))
        bytes.buffer_write_string(buf, item.manufacturer)
    }
}

// Deserialize the inventory database
deserialize_inventory :: proc(data: []u8) -> (database: InventoryDatabase, ok: bool) {
    // Shadow data to allow advancing through the slice
    data := data

    // Get the number of items in the database
    num_items: i64
    deserialize(&data, &num_items) or_return

    // Reserve space for items to avoid resizing during appends
    reserve(&database.items, num_items)

    item: Item
    for _ in 0..<num_items {
        deserialize(&data, &item.id)           or_return
        deserialize(&data, &item.quantity)     or_return
        deserialize(&data, &item.price)        or_return
        deserialize(&data, &item.name)         or_return
        deserialize(&data, &item.manufacturer) or_return
        item.label = initialize_label(item) // Initialize the label for the item

        append(&database.items, item)
    }

    return database, true
}

// Deserialize helper functions
deserialize_i32 :: proc(data: ^[]u8, val: ^i32) -> (ok: bool) {
    val^  = endian.get_i32(data^, .Little) or_return
    data^ = data[4:]
    return true
}

deserialize_i64 :: proc(data: ^[]u8, val: ^i64) -> (ok: bool) {
    val^  = endian.get_i64(data^, .Little) or_return
    data^ = data[8:]
    return true
}

deserialize_u32 :: proc(data: ^[]u8, val: ^u32) -> (ok: bool) {
    val^  = endian.get_u32(data^, .Little) or_return
    data^ = data[4:]
    return true
}

deserialize_f32 :: proc(data: ^[]u8, val: ^f32) -> (ok: bool) {
    val^  = endian.get_f32(data^, .Little) or_return
    data^ = data[4:]
    return true
}

deserialize_string :: proc(data: ^[]u8, val: ^string) -> (ok: bool) {
    str_len: i64

    deserialize(data, &str_len) or_return
    if len(data) >= int(str_len) {
        val^  = strings.clone(string(data[:str_len]))
        data^ = data[str_len:]
        return true
    } else {
        return false
    }
}

// Serialize and deserialize function groups
serialize :: proc{serialize_inventory}

deserialize :: proc{
    deserialize_inventory,
    deserialize_f32,
    deserialize_u32,
    deserialize_i32,
    deserialize_string,
    deserialize_i64,
}
