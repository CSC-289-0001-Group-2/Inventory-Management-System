#ITEM CLASS


class Item:

    #EMPTY CONSTRUCTOR
    def __init__(self):
        self.name = ""
        self.price = 0.0
        self.amount = 0
        self.manufacturer - ""

    #GET/SET for "name"
    def get_name(self):
        return self.name
    def set_name(self, name):
        self.name = name

    #GET/SET for "price"
    def get_price(self):
        return self.price
    def set_price(self, price):
        self.price = price
            
    #GET/SET for "amount"
    def get_amount(self):
        return self.amount
    def set_amount(self,amount):
        self.amount = amount

    #GET/SET for "manufacturer"
    def get_manufacturer(self):
        return self.manufacturer
    def set_manufacturer(self,manufacturer):
        self.manufacturer = manufacturer


    def __str__(self):
        return f"Item Name: {self.name}, Price: {self.price}, Amount: {self.amount}, Manufacturer: {self.manufacturer}"    


    