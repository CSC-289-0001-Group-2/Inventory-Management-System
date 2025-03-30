// Method to remove an item from the array
RemoveItem :: proc (itemName: string) {
    ordered_remove(item_inventory, itemName) // not declared anywhere
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

// Method that adds up the total value of the inventory
GetTotalValue :: proc() -> float {
    total: float
    for i := 0; i < item_inventory.len; i+= 1 {
      total += item_inventory[i].price
    }
}
