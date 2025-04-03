# Project Class Outline

## Item Class

Holds individual item information such as:

- **Name**: String - The name of the item.
- **Description**: - The description of the item.
- **Price**: Float - The price of the item.
- **Amount**: Int - Quantity available in stock.
- **Manufacturer**: String - The name of the manufacturer.

### Basic Methods:

- **Constructor**: Initializes an item with the required values. (There should be an empty constructor that takes no values and a constructor that takes four parameters)
- **Setters/Getters**: Setters and getters for each value
- **ToString()**: Returns a string representation of the item.

---

## InventoryManager Class

Handles a collection of `Item` objects and provides various operations.

### Attributes:

- **items**: Dynamic array of `Item` objects.

### Basic Methods:

- **Constructor**: Initializes an item with the required values. (One empty method and one method that takes an array/ SQLoader object when that's implemented)
- **AddItem(item: Item)**: Adds a new item to the inventory.
- **RemoveItem(itemName: string)**: Removes an item from inventory.
- **FindItem(itemName: string) -> Item?**: Searches for an item by name.
- **UpdateAmount(itemName: string, newAmount: int)**: Modifies stock levels.
- **GetTotalValue() -> float**: Calculates total inventory value.


---
## Future Extensions:

- **SQLoader object**: Handles sql database related functions (save/load).
- **Graphical Interface / CLI dedicated object**: Provides a frontend for interaction.

