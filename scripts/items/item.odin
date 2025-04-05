#ITEM CLASS

package items

import "core:fmt"

//Item STRUCT
Item :: struct {
    name        string
    price       f32
    amount      int
    manufacturer string
}

//Constructor for Item
new_item :: proc(name: string, price: f32, amount: int, manufacturer: string) -> Item {
    return Item{
        name = name,
        price = price,
        amount = amount,
        manufacturer = manufacturer, 
    }
}
//To-String Method
item_to_string :: proc(i: Item) -> string {
    return fmt.Sprintf("Item Name: %s, Price: %.2f, Amount: %d, Manufacturer: %s", i.name, i.price, i.amount, i.manufacturer)
}

//Empty Constructor
empty_item :: proc() -> Item {
    return Item{
        name = "",
        price = 0.0,
        amount = 0,
        manufacturer = "",
    }
}