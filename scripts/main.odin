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

// Global variables
log_sb := strings.builder_make()
log_updated := false
items_selected: [dynamic]items.Item
file_name := "inventory.dat"

// Buffers for text input in the GUI
log_input_text := make_slice([]u8, 128)
log_input_text_len: int
editor_input_text := make_slice([]u8, 128)
editor_input_text_len: int
editor_input_text_2 := make_slice([]u8, 128)
editor_input_text_len_2 : int

editor_input_num : f32
editor_input_text_rect : mu.Rect


screen_width: = win.GetSystemMetrics(win.SM_CXSCREEN)-50;
screen_height: = win.GetSystemMetrics(win.SM_CYSCREEN)-100;

window_right_button_divider : i32 = 5



header_width:= cast(i32)(((cast(f32)screen_width*0.5)-10)*1.0)
label_width:= cast(i32)(((cast(f32)screen_width*0.5)-10)*0.20)
interface_width:= cast(i32)(((cast(f32)screen_width*0.5)-10)*0.45)
button_width:= i32(screen_width/2)-9

bg : [3]u8 = { 90, 95, 100 }

// Global variables for Item Quantity (present here to avoid re-initializing the buffer every time)
quantity_buffer := make_slice([]u8, 32)
quantity_str_len: int = 0
quantity_initialized: bool = false

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
        items.addBenchmark(&db, 10000) // Add 10,000 items to the database for testing


        defer{
            initialize_window(db)
            // fmt.print(db.items)
        }  
    }else {
        fmt.println("Loaded inventory from file:", file_name)
        // fmt.print(db.items)
        initialize_window(db)
    }
}

initialize_window :: proc(db : items.InventoryDatabase) {
    
    rl.SetWindowState({ .WINDOW_RESIZABLE})
    rl.InitWindow(screen_width, screen_height, "Inventory Managment UI")

    ctx := rlmu.init_scope() // same as calling, `rlmu.init(); defer rlmu.destroy()`

    // allocator: virtual.Arena 
    // _= virtual.arena_init_growing(&allocator)// Set the allocator for the database

    // context.allocator = virtual.arena_allocator(&allocator) 

    for !rl.WindowShouldClose() {
        // begin := virtual.arena_temp_begin(&allocator)
        // defer virtual.arena_temp_end(begin)

        rl.BeginDrawing(); defer rl.EndDrawing()
        rl.ClearBackground({ bg.r, bg.g, bg.b, 255 })
        
        rlmu.begin_scope() // same as calling, `rlmu.begin(); defer rlmu.end()`

        initialize_sub_windows(ctx, db)
    }
}

// Initializes all sub-windows
initialize_sub_windows :: proc(ctx: ^mu.Context, db: items.InventoryDatabase) {
    button_window(ctx, db)
    edit_window(ctx, db)
    log_window(ctx)  
}

button_window :: proc(ctx : ^mu.Context, db : items.InventoryDatabase){ //, items: [dynamic]Item
    if mu.begin_window(ctx, "Inventory List", mu.Rect{ screen_width/2, 0, screen_width/2, screen_height },{ .EXPANDED,.NO_CLOSE,.NO_RESIZE}) {
        win := mu.get_current_container(ctx)
        win.rect.w = max(win.rect.w, 0)
        win.rect.w = min(win.rect.w, 0)
        win.rect.h = max(win.rect.h, 0)
        win.rect.h = min(win.rect.h, 0)
           
        defer mu.end_window(ctx)
        // fmt.print("database length: ", len(db.items), "\n")
        for item in db.items {
            if item.name != "" {
                                mu.layout_row(ctx, {button_width}, (screen_height / 8))
                button_label := items.initialize_label(item)
                                if .SUBMIT in mu.button(ctx, button_label) { 
                    fetch_item(item)
                    write_log(button_label)   
                }
            }
        } 
    }
}

log_window :: proc (ctx : ^mu.Context) {
    if mu.begin_window(ctx, "Log Window", mu.Rect{ 0, screen_height/2, screen_width/2, screen_height/2 },{ .EXPANDED,.NO_CLOSE,.NO_RESIZE}) {
        defer mu.end_window(ctx)

        win := mu.get_current_container(ctx)
        win.rect.w = max(win.rect.w, 0)
        win.rect.w = min(win.rect.w, 0)
        win.rect.h = max(win.rect.h, 0)
        win.rect.h = min(win.rect.h, 0)

        /* output text panel */
        mu.layout_row(ctx, { -1 }, -25)
        mu.begin_panel(ctx, "Log Output")
        panel := mu.get_current_container(ctx)
        mu.layout_row(ctx, { -1 }, -1)
        mu.text(ctx, strings.to_string(log_sb))
        mu.end_panel(ctx)
        if log_updated {
            panel.scroll.y = panel.content_size.y
            log_updated = false
        }
    }
}

// Renders the edit window
edit_window :: proc(ctx: ^mu.Context, db: items.InventoryDatabase) {
    if mu.begin_window(ctx, "Edit window", mu.Rect{0, 0, screen_width / 2, screen_height / 2}, {.EXPANDED, .NO_CLOSE, .NO_RESIZE}) {
        defer mu.end_window(ctx)
        if len(items_selected) > 0 {
            // Item Name
            mu.layout_row(ctx, {label_width, interface_width}, (screen_height / 25))
            mu.label(ctx, "Item Name:")
            if .SUBMIT in mu.textbox(ctx, editor_input_text, &editor_input_text_len) {
                mu.set_focus(ctx, ctx.last_id)
                items_selected[0].name = string(editor_input_text[:editor_input_text_len])
                fmt.println("Updated name:", items_selected[0].name)
            }

            // Item Manufacturer
            mu.layout_row(ctx, {label_width, interface_width}, (screen_height / 25))
            mu.label(ctx, "Item Manufacturer:")
            if .SUBMIT in mu.textbox(ctx, editor_input_text_2, &editor_input_text_len_2) {
                mu.set_focus(ctx, ctx.last_id)
                items_selected[0].manufacturer = string(editor_input_text_2[:editor_input_text_len_2])
                fmt.println("Updated manufacturer:", items_selected[0].manufacturer)
            }

            // Item Quantity
            mu.layout_row(ctx, {label_width, interface_width}, (screen_height / 25))
            mu.label(ctx, "Item Quantity:")

            // Initialize the buffer only once when the window is first opened
            if !quantity_initialized {
                quantity_str := strconv.itoa(quantity_buffer, cast(int)(items_selected[0].quantity))
                quantity_str_len = len(quantity_str)
                quantity_initialized = true
            }


            // Use textbox for input
            if .SUBMIT in mu.textbox(ctx, quantity_buffer, &quantity_str_len) {
                mu.set_focus(ctx, ctx.last_id)

                // Convert buffer back to string and parse it as an integer
                input_str := string(quantity_buffer[:quantity_str_len])
                new_quantity := strconv.atoi(input_str)



                // Update the quantity if the input is valid
                if new_quantity != 0 { // Assuming invalid input results in `0`
                    items_selected[0].quantity = cast(i32)(new_quantity)
                    fmt.println("Updated quantity:", items_selected[0].quantity)
                } else {
                    fmt.println("Invalid input for quantity:", input_str)
                }
            }
        } else {
            mu.label(ctx, "No items selected")
        }
    }
}

// Logs a message to the log window
write_log :: proc(text: string) {
    if strings.builder_len(log_sb) != 0 {
        // Append newline if log isn't empty
        fmt.sbprint(&log_sb, "\n")
    }
    fmt.sbprint(&log_sb, text)
    log_updated = true
}

// Fetches an item and adds it to the selected items list
fetch_item :: proc(items_to_edit: ..items.Item) {
    clear(&items_selected)
    for item in items_to_edit do append(&items_selected, item)
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

