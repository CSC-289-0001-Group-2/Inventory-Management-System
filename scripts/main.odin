package main

// Port of micro UI C demo to Odin, using rlmu as the renderer

// Import necessary modules
import "items"
import "tests"
import "rlmu"
import "core:fmt"
import "core:strings"
import rl "vendor:raylib"
import mu "vendor:microui"
import win "core:sys/windows"
import virtual "core:mem/virtual"
import "core:strconv"
import "base:runtime"

// Global variables
log_sb := strings.builder_make()
edit_sb := strings.builder_make()
log_updated := false
items_selected: [dynamic]items.Item
file_name := "inventory.dat"

// Buffers for text input in the GUI
log_input_text := make_slice([]u8, 128)
log_input_text_len: int
editor_input_text := make_slice([]u8, 128)
editor_input_text_len: int
editor_input_text_2 := make_slice([]u8, 128)
editor_input_text_len_2: int

editor_input_text_3 := make_slice([]u8, 128)
editor_input_text_len_3: int

editor_input_text_4 := make_slice([]u8, 128)
editor_input_text_len_4: int

editor_input_num: f32
editor_input_text_rect: mu.Rect


screen_width := win.GetSystemMetrics(win.SM_CXSCREEN) - 50
screen_height := win.GetSystemMetrics(win.SM_CYSCREEN) - 100

window_right_button_divider: i32 = 5

header_width := cast(i32)(((cast(f32)screen_width * 0.5) - 10) * 1.0)
label_width := cast(i32)(((cast(f32)screen_width * 0.5) - 10) * 0.20)
interface_width := cast(i32)(((cast(f32)screen_width * 0.5) - 10) * 0.45)
button_width := cast(i32)(((cast(f32)screen_width * 0.35) - 10) * 1.0)
edit_button_width := cast(i32)(((cast(f32)screen_width * 0.45) - 10) * 1.0)
save_button_width := cast(i32)(((cast(f32)screen_width * 0.5) - 10) * 1.0)
checkbox_width := cast(i32)(((cast(f32)screen_width * 0.5) - 10) * 0.075)
delete_width := cast(i32)(((cast(f32)screen_width * 0.5) - 10) * 0.2)

bg: [3]u8 = {90, 95, 100}

// Global variables for Item Quantity (present here to avoid re-initializing the buffer every time)
quantity_buffer := make_slice([]u8, 32)
quantity_str_len: int = 0
quantity_initialized: bool = false

// Increase during testing. Current is 20,000 items.
checks: [20000]bool = false 

// Main entry point
main :: proc() {
    // tests.run_all_tests()
    initialize_database()
    // Initialize the window and start the main loop
}

// Initializes the inventory database
initialize_database :: proc() {
    db, success := items.load_inventory(file_name)
    if !success {
        fmt.println("Error loading inventory from file:", file_name)
        db := items.InventoryDatabase{
            items = make([dynamic]items.Item), // Initialize as a dynamic array
        }
        items.addBenchmark(&db, 10000) // Pass the address of `db`

        defer {
            initialize_window(&db) // Pass the address of `db`
        }
    } else {
        fmt.println("Loaded inventory from file:", file_name)
        initialize_window(&db) // Pass the address of `db`
    }
}

initialize_window :: proc(db: ^items.InventoryDatabase) {
    rl.SetWindowState({.WINDOW_RESIZABLE})
    rl.InitWindow(screen_width, screen_height, "Inventory Management UI")

    ctx := rlmu.init_scope() // same as calling, `rlmu.init(); defer rlmu.destroy()`
    //context.allocator = context.temp_allocator
    for !rl.WindowShouldClose() {
    //    runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

        rl.BeginDrawing()
        defer rl.EndDrawing()
        rl.ClearBackground({bg.r, bg.g, bg.b, 255})

        rlmu.begin_scope() // same as calling, `rlmu.begin(); defer rlmu.end()`

        initialize_sub_windows(ctx, db)
    }

    if rl.WindowShouldClose(){
        save_data(db)
    }
}

// Initializes all sub-windows
initialize_sub_windows :: proc(ctx: ^mu.Context, db: ^items.InventoryDatabase) {
    button_window(ctx, db)
    edit_window(ctx, db)
    log_window(ctx)
}

button_window :: proc(ctx: ^mu.Context, db: ^items.InventoryDatabase) {

    if mu.begin_window(ctx, "Inventory List", mu.Rect{screen_width / 2, 0, screen_width / 2, screen_height}, {.EXPANDED, .NO_CLOSE, .NO_RESIZE}) {
        defer mu.end_window(ctx)

        for &item , i in db.items {
            if item.name != "" {
                mu.layout_row(ctx, {checkbox_width, button_width,delete_width}, (screen_height / 15))
                button_label := items.initialize_label(item)

                // Ensure item.id is within the valid range of the `checks` array
                if item.id >= 0 && item.id < len(checks) {
                    if .CHANGE in mu.checkbox(ctx, "", &checks[item.id]){
                        if checks[item.id] {
                            if !is_item_selected(item){
                                append(&items_selected,item)
                                write_log("Item selected:", item.name)
                            }

                        } else{
                            if is_item_selected(item){
                                for selected_item, i in items_selected{
                                    if item.id == selected_item.id{
                                        if i < len(items_selected){
                                            ordered_remove(&items_selected,i)
                                            write_log("Item deselected:", item.name)
                                        }
                                    }
                                }
                            }
                        }
                   }
                } else {
                    fmt.println("Warning: item.id is out of range:", item.id)
                }
                
                if .SUBMIT in mu.button(ctx, button_label) {
                    clear_selected_items()
                    fetch_item(item)
                    write_log(button_label)
                }
                // mu.layout_row(ctx, {checkbox_width, button_width, delete_width}, (screen_height / 15))
                delete_label := strings.builder_make()
                defer strings.builder_destroy(&delete_label) // Ensure the builder is destroyed to prevent memory leaks
                strings.write_string(&delete_label, "Delete Item:  ")
                strings.write_int(&delete_label, (i+1))
                if .SUBMIT in mu.button(ctx, strings.to_string(delete_label)) {
                    delete_individual_item(&item, db)
                }
            }
        }
    }
}

log_window :: proc(ctx: ^mu.Context) {
    if mu.begin_window(ctx, "Log Window", mu.Rect{0, screen_height / 2, screen_width / 2, screen_height / 2}, {.EXPANDED, .NO_CLOSE, .NO_RESIZE}) {
        defer mu.end_window(ctx)

        win := mu.get_current_container(ctx)
        win.rect.w = max(win.rect.w, 0)
        win.rect.w = min(win.rect.w, 0)
        win.rect.h = max(win.rect.h, 0)
        win.rect.h = min(win.rect.h, 0)

        /* output text panel */
        mu.layout_row(ctx, {-1}, -25)
        mu.begin_panel(ctx, "Log Output")
        panel := mu.get_current_container(ctx)
        mu.layout_row(ctx, {-1}, -1)
        mu.text(ctx, strings.to_string(log_sb))
        mu.end_panel(ctx)
        if log_updated {
            panel.scroll.y = panel.content_size.y
            log_updated = false
        }
    }
}



// Renders the edit window
edit_window :: proc(ctx: ^mu.Context, db: ^items.InventoryDatabase) {
    if mu.begin_window(ctx, "Edit window", mu.Rect{0, 0, screen_width / 2, screen_height / 2}, {.EXPANDED, .NO_CLOSE, .NO_RESIZE}) {
        defer mu.end_window(ctx)
        @static edit_button_toggle:= "Edit item"  
        @static is_adding_new_item: bool = true

        // Add a button to create a new item
        mu.layout_row(ctx, {edit_button_width}, (screen_height / 25))
        if .SUBMIT in mu.button(ctx, edit_button_toggle) {
            if is_adding_new_item == true{
                is_adding_new_item = false
                edit_button_toggle = "Add New Item"
                
            }else{
                is_adding_new_item = true
                edit_button_toggle = "Edit item"  
            }
            
            clear_selected_items()
        }
        render_ui(ctx,db,is_adding_new_item)
    }
}

render_ui :: proc(ctx: ^mu.Context, db: ^items.InventoryDatabase, is_adding_new_item: bool ){
    submitted := false
    submitted2 := false
    submitted3 := false
    submitted4:= false
    submitted5:= false
    new_name := ""
    new_manufacturer := ""
    new_quantity: i32= 0
    new_price: f32= 0.0

    if !is_adding_new_item { //TODO: add toggle bits here
        if (len(items_selected) > 0 ){
            single_item := len(items_selected) == 1
            mu.layout_row(ctx, {header_width}, (screen_height / 25))
            
            my_builder := strings.builder_make()
            defer strings.builder_destroy(&my_builder)
            
            strings.write_string(&my_builder, "Edit Item/s: ")
            for item in items_selected {
                strings.write_string(&my_builder, " ")
                strings.write_string(&my_builder, item.name)
            }
            mu.label(ctx, strings.to_string(my_builder))

            // Item Name
            mu.layout_row(ctx, {label_width, interface_width}, (screen_height / 25))
            mu.label(ctx, "Item Name:")
            if .SUBMIT in mu.textbox(ctx, editor_input_text, &editor_input_text_len) {
                mu.set_focus(ctx, ctx.last_id)
                if single_item {
                    items_selected[0].name = string(editor_input_text[:editor_input_text_len])
                }
            }

            // Item Manufacturer
            mu.layout_row(ctx, {label_width, interface_width}, (screen_height / 25))
            mu.label(ctx, "Item Manufacturer:")
            if .SUBMIT in mu.textbox(ctx, editor_input_text_2, &editor_input_text_len_2) {
                mu.set_focus(ctx, ctx.last_id)
                if single_item {
                    items_selected[0].manufacturer = string(editor_input_text_2[:editor_input_text_len_2])
                }
            }

            // Item Quantity
            mu.layout_row(ctx, {label_width, interface_width}, (screen_height / 25))
            mu.label(ctx, "Item Quantity:")
            if .SUBMIT in mu.textbox(ctx, editor_input_text_3, &editor_input_text_len_3) {
                mu.set_focus(ctx, ctx.last_id)
                if single_item {
                    items_selected[0].quantity = cast(i32)(strconv.atoi(string(editor_input_text_3[:editor_input_text_len_3])))
                }
            }

            // Item Price
            mu.layout_row(ctx, {label_width, interface_width}, (screen_height / 25))
            mu.label(ctx, "Item Price:")
            if .SUBMIT in mu.textbox(ctx, editor_input_text_4, &editor_input_text_len_4) {
                mu.set_focus(ctx, ctx.last_id)
                if single_item {
                    value, check := strconv.parse_f32(string(editor_input_text_4[:editor_input_text_len_4]))
                    if check == false {
                        write_log("Error: Invalid price input.")
                    } else {
                        items_selected[0].price = value
                    }
                }
            }



            mu.layout_row(ctx, {edit_button_width}, (screen_height/25))
            if .SUBMIT in mu.button(ctx, "Confirm Edits") {
                // fmt.println("editor 1 len: ", editor_input_text_len,"\neditor2 len: ", editor_input_text_len_2)
                submitted2 = (editor_input_text_len_2 > 0)
                submitted = (editor_input_text_len > 0 )
                submitted3 = (editor_input_text_len_3 > 0)
                submitted4 = (editor_input_text_len_4 > 0)
                submitted5 = (editor_input_text_len <= 0 && editor_input_text_len_2 <= 0 && editor_input_text_len_3 <= 0 && editor_input_text_len_4 <= 0)
            }
            mu.layout_row(ctx, {edit_button_width}, screen_height / 25)
            if.SUBMIT in mu.button(ctx, "Delete Selected Items"){
                delete_bulk_items(&items_selected, db)
            }
            if submitted == true {
                new_name = string(editor_input_text[:editor_input_text_len])
                write_log("Name Changed To:")
                write_log(new_name)
                editor_input_text_len = 0
                for &item in db.items{
                    if is_item_selected(item){
                        item.name = new_name
                        clear_name_input()
                    }
                }
            }
            if submitted2 == true {
                new_manufacturer = string(editor_input_text_2[:editor_input_text_len_2])
                write_log("Manufacturer Changed To:")
                write_log(new_manufacturer)
                editor_input_text_len_2 = 0
                for &item in db.items{
                    if is_item_selected(item){
                        item.manufacturer = new_manufacturer
                        clear_manufacturer_input()
                    }
                }
            }

            if submitted3 == true {
                new_quantity = cast(i32)(strconv.atoi(string(editor_input_text_3[:editor_input_text_len_3])))
                write_log("Quantity Changed To:")
                write_log(string(editor_input_text_3[:editor_input_text_len_3]))
                editor_input_text_len_3 = 0
                for &item in db.items{
                    if is_item_selected(item){
                        fmt.println("Item quantity: ", item.quantity)
                        fmt.println("New quantity: ", new_quantity)
                        item.quantity = new_quantity
                        clear_quantity_input()
                    }
                }
            }

            if submitted4 == true {
                new_price = cast(f32)(strconv.atoi(string(editor_input_text_4[:editor_input_text_len_4])))
                write_log("Price Changed To:")
                write_log(string(editor_input_text_4[:editor_input_text_len_4]))
                editor_input_text_len_4 = 0
                for &item in db.items{
                    if is_item_selected(item){
                        fmt.println("Item price: ", item.price)
                        fmt.println("New price: ", new_price)
                        item.price = new_price
                        clear_price_input()
                    }
                }
            }

            if submitted == true || submitted2 == true || submitted3 == true || submitted4 == true {
                for &item in db.items{
                    if is_item_selected(item){
                        delete(item.label)
                        item.label = items.initialize_label(item) // Reinitialize the label for the item
                        write_log("Changes saved")
                    }
                }
            }
            
            
            if submitted5 == true {
            write_log("Error: No inputs found")
            clear(&items_selected)
            }
                defer if submitted == true || submitted2 == true || submitted3 == true || submitted4 == true {
                save_data(db)
            }
            }else{

            mu.layout_row(ctx, {label_width}, (screen_height / 3))
            mu.label(ctx, "No items selected")
        }

    }else{
        mu.layout_row(ctx, {label_width, interface_width}, (screen_height / 25))
        mu.label(ctx, "Item Name:")
        mu.textbox(ctx, editor_input_text, &editor_input_text_len)

        mu.layout_row(ctx, {label_width, interface_width}, (screen_height / 25))
        mu.label(ctx, "Manufacturer:")
        mu.textbox(ctx, editor_input_text_2, &editor_input_text_len_2)

        mu.layout_row(ctx, {label_width, interface_width}, (screen_height / 25))
        mu.label(ctx, "Quantity:")
        mu.textbox(ctx, editor_input_text_3, &editor_input_text_len_3)

        mu.label(ctx, "Price:")
        mu.textbox(ctx, editor_input_text_4, &editor_input_text_len_4)

        mu.layout_row(ctx, {edit_button_width}, (screen_height / 25))
        if .SUBMIT in mu.button(ctx, "Confirm") {
            new_item_name := string(editor_input_text[:editor_input_text_len])
            new_item_manufacturer := string(editor_input_text_2[:editor_input_text_len_2])
            new_item_quantity := cast(i32)(strconv.atoi(string(editor_input_text_3[:editor_input_text_len_3])))
            new_item_price : f32 = 0.0
            value, check := strconv.parse_f32(string(editor_input_text_4[:editor_input_text_len_4]))
            if check == false {
                write_log("Error: Invalid price input.")
            } else {
                new_item_price = value
            }


            if new_item_name == "" {
                write_log("Error: Item name cannot be empty.")
            } else if new_item_quantity <= 0 {
                write_log("Error: Quantity must be greater than zero.")
            } else if new_item_price <= -1 {
                write_log("Error: Price must be greater than -1.")
            } else {
                success := items.add_item_by_members(db, new_item_quantity,new_item_price, new_item_name, new_item_manufacturer)
                if success {
                    my_builder := strings.builder_make()
                    defer strings.builder_destroy(&my_builder)

                    strings.write_string(&my_builder, "Added new item: ")
                    strings.write_string(&my_builder, new_item_name)
                    write_log(strings.to_string(my_builder))
                    save_data(db)
                    clear_text_inputs()

                } else {
                    my_builder := strings.builder_make()
                    defer strings.builder_destroy(&my_builder)

                    strings.write_string(&my_builder, "Error: Item with this name already exists: ")
                    strings.write_string(&my_builder, new_item_name)
                    write_log(strings.to_string(my_builder))
                }
            }
        }

    }

}

// Logs a message to the log window
write_log :: proc(text: ..string) {
    new_builder := strings.builder_make()
    defer strings.builder_destroy(&new_builder)
    for segment in text do strings.write_string(&new_builder, segment)
    comp_text := strings.to_string(new_builder)
    if strings.builder_len(log_sb) != 0 {
        // Append newline if log isn't empty
        fmt.sbprint(&log_sb, "\n")
    }
    fmt.sbprint(&log_sb, comp_text)
    log_updated = true
}
fetch_item ::proc{ fetch_item_ind,fetch_items_by_array}
// Fetches an item and adds it to the selected items list
fetch_item_ind :: proc(items_to_edit: ..items.Item) {
    clear(&items_selected)
    for item in items_to_edit do append(&items_selected, item)
}

fetch_items_by_array :: proc(items_to_edit: [dynamic]items.Item) {
    clear(&items_selected)
    for item in items_to_edit {
        append(&items_selected, item)
        fmt.println("Item added to selected items:", item.name)
    }
}
// Checks if an item is selected
is_item_selected :: proc(item: items.Item) -> bool {
    for selected_item in items_selected {
        if item.id == selected_item.id {
            return true
        }
    }
    return false
}

delete_bulk_items :: proc(items_to_delete: ^[dynamic]items.Item, db: ^items.InventoryDatabase){
    if len(items_to_delete) <= 0{
        return
    } else{
        for &item, i in items_to_delete{
            if is_item_selected(item){
                if i < len(items_selected){
                    item_index:= items.find_item_index(db, item)
                    if item_index != -1{
                        write_log("Removed items :", item.name)
                        free_item(&item)
                        ordered_remove(items_to_delete, i)
                        ordered_remove(&db.items, item_index)
                    }
                    break 
                }
            }
        }
        delete_bulk_items(items_to_delete,db)
    }
}

delete_individual_item :: proc(item_to_delete: ^items.Item, db: ^items.InventoryDatabase){
    item_index:= items.find_item_index(db, item_to_delete^)
    if item_index != -1{
        write_log("Removed item :", item_to_delete.name)
        free_item(item_to_delete)
        ordered_remove(&db.items, item_index)
    }   
}

free_item :: proc(item_to_delete: ^items.Item){
    delete(item_to_delete.name)
    delete(item_to_delete.manufacturer)
    delete(item_to_delete.label)
}

save_data :: proc(db: ^items.InventoryDatabase){
    items.save_inventory(file_name, db^) // Save the inventory to the file
    write_log("data saved to file: ", file_name)// Pass the address of `db`
}

clear_selected_items :: proc(){
    clear(&items_selected)
    for &check in checks{
        check = false
    }
}

clear_text_inputs :: proc(){
    clear_name_input()
    clear_manufacturer_input()
    clear_quantity_input()
    clear_price_input()
}
clear_name_input :: proc(){
    editor_input_text = make_slice([]u8, 128)
    editor_input_text_len = 0
}
clear_manufacturer_input :: proc(){
    editor_input_text_2 = make_slice([]u8, 128)
    editor_input_text_len_2 = 0
}
clear_quantity_input :: proc(){
    editor_input_text_3 = make_slice([]u8, 128)
    editor_input_text_len_3 = 0
}
clear_price_input :: proc(){
    editor_input_text_4 = make_slice([]u8, 128)
    editor_input_text_len_4 = 0
}

