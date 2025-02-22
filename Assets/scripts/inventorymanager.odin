package main

import "core:fmt"
import "core:sort"

// Create a dynamic array of type "Item"
item_inventory: [dynamic]Item

// Constructor of an "Item" object
NewItem :: proc (name: string, price: float, amount: int, manufacturer: string) -> Item {
    return Item{
        name = name,
        price = price,
        amount = amount,
        manufacturer = manufacturer
    }
}

// Method to add an item to the array
AddItem :: proc (item: Item) {
    item_inventory.append(item)
}

// Method to remove an item from the array
RemoveItem :: proc (itemName: string) {
    ordered_remove(item_inventory, itemName)
}

// Method to search for an item in the array
FindItem :: proc(itemName: string) {
    if sort.find(item_inventory, itemName){
        fmt.println("Item found")
    }
    else{
        fmt.println("Item not found")
    }
}

// Method to update the amount of an item in the array
UpdateAmount :: proc(itemName: string, newAmount: int) {
    item_inventory[itemName].amount = newAmount
}

// Method that adds up the total value of the inventory
GetTotalValue :: proc() -> float {
    total: float
    for i := 0; i < item_inventory.len; i+= 1 {
      total += item_inventory[i].price
    }
}