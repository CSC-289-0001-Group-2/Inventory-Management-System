package main

// port of micro ui c demo to odin, using rlmu as renderer

import "items"
import "tests"

import "rlmu"
import "core:fmt"
import "core:strings"
import rl "vendor:raylib"
import mu "vendor:microui"
import win "core:sys/windows"
import virtual "core:mem/virtual"



log_sb := strings.builder_make()
log_updated := false
items_selected: [dynamic]items.Item

file_name:= "inventory.dat"

log_input_text := make_slice([]u8, 128)
log_input_text_len : int

editor_input_text := make_slice([]u8, 128)
editor_input_text_len : int

editor_input_text_2 := make_slice([]u8, 128)
editor_input_text_len_2 : int

editor_input_text_3 := make_slice([]u8, 128)
editor_input_text_len_3 : int

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

main :: proc() {

    // tests.run_all_tests()
    initialize_database()
     // Initialize the window and start the main loop

}

initialize_database :: proc(){
    db, success := items.load_inventory(file_name)
    if !success {
        fmt.println("Error loading inventory from file:", file_name)
        db := items.InventoryDatabase{
            items = make([dynamic]items.Item), // Initialize as a dynamic array
        }
        items.addBenchmark(&db, 10000) // Add 1000 items to the database for testing


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

initialize_sub_windows :: proc(ctx : ^mu.Context, db : items.InventoryDatabase){
    button_window(ctx,db)
    edit_window(ctx,db)
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
                
                mu.layout_row(ctx, {button_width}, (screen_height/8))
                button_label := items.initialize_label(item)
                
                if .SUBMIT in mu.button(ctx, button_label){ 
                    fetch_item(item)
                    write_log("Item Selected:     ", button_label)   
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

edit_window :: proc (ctx : ^mu.Context, db : items.InventoryDatabase) {
    if mu.begin_window(ctx, "Edit window", mu.Rect{ 0, 0, screen_width/2, screen_height/2 },{ .EXPANDED,.NO_CLOSE,.NO_RESIZE}) {
        defer mu.end_window(ctx)
        win := mu.get_current_container(ctx)
        win.rect.w = max(win.rect.w, 0)
        win.rect.w = min(win.rect.w, 0)
        win.rect.h = max(win.rect.h, 0)
        win.rect.h = min(win.rect.h, 0)
        if len(items_selected) == 0 {
            label_width:= i32(screen_width/2)-10
            mu.layout_row(ctx, {label_width}, (screen_height/3))
            mu.label(ctx, "No items selected")

 
        }else
        { //TODO: add edit functionality
            header_width:= cast(i32)(((cast(f32)screen_width*0.5)-10)*1.0)
            label_width:= cast(i32)(((cast(f32)screen_width*0.5)-10)*0.20)
            interface_width:= cast(i32)(((cast(f32)screen_width*0.5)-10)*0.45)
            single_item := len(items_selected) == 1

            mu.layout_row(ctx, {header_width}, (screen_height/25))
            my_builder:= strings.builder_make()
            strings.write_string(&my_builder, "Edit Item/s: ")
            
            for item in items_selected{
                strings.write_string(&my_builder, " ")
                strings.write_string(&my_builder, item.name)
            }

            mu.label(ctx, strings.to_string(my_builder))

            new_name := ""
            new_manufacturer := ""
            new_quantity := ""

            submitted := false
            submitted2 := false

            mu.label(ctx, "Item Name:")
            mu.layout_row(ctx, {label_width/-1, interface_width/5}, (screen_height/25))
            // if single_item{
            //     editor_input_text = strings.to
            // }
             

            if .SUBMIT in mu.textbox(ctx, editor_input_text, &editor_input_text_len) {
                mu.set_focus(ctx, ctx.last_id)
                submitted = true
            }

            mu.layout_row(ctx, {label_width/-1, interface_width/5}, (screen_height/25))
            mu.label(ctx, "Item Manufacturer:")
            mu.layout_row(ctx, {label_width/-1}, (screen_height/25))
            if .SUBMIT in mu.textbox(ctx, editor_input_text_2, &editor_input_text_len_2) {
                mu.set_focus(ctx, ctx.last_id)
                submitted2 = true
            }
            if editor_input_text_len_2 <= 0 {
                submitted2 = false
            }
            if submitted2 == true {
                new_manufacturer = string(editor_input_text_2[:editor_input_text_len_2])
                write_log("Manufacturer Changed To:")
                write_log(new_manufacturer)
                editor_input_text_len_2 = 0
                for &item in db.items{
                    if is_item_selected(item){
                        item.manufacturer = new_manufacturer
                    }
                }
            }

            mu.label(ctx, "Item Quantity:")
            mu.layout_row(ctx, {label_width/-1, interface_width/5}, (screen_height/25))
            if .SUBMIT in mu.textbox(ctx, editor_input_text_3, &editor_input_text_len_3) {
                mu.set_focus(ctx, ctx.last_id)
            }

            mu.layout_row(ctx, {label_width/-1, interface_width/5}, (screen_height/25))
            if .SUBMIT in mu.button(ctx, "Confirm Edits") {
                // fmt.println("editor 1 len: ", editor_input_text_len,"\neditor2 len: ", editor_input_text_len_2)
                submitted2 = (editor_input_text_len_2 > 0)
                submitted = (editor_input_text_len > 0 )
            }
            if submitted == true {
                new_name = string(editor_input_text[:editor_input_text_len])
                write_log("Name Changed To:")
                write_log(new_name)
                editor_input_text_len = 0
                for &item in db.items{
                    if is_item_selected(item){
                        item.name = new_name
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
                    }
                }
            }

            editor_input_text_rect := mu.Rect{32, 32, 320, 320}
            if mu.number_textbox(ctx, &editor_input_num, editor_input_text_rect, ctx.last_id, "%.2f") {
                // the text box has been edited, and the value has been updated
                // you can now use the updated value
            }
            
            

        }  
    }
}
write_log :: proc(text: ..string) {
    compiled_text := ""
    new_builder:= strings.builder_make()
    for item in text do strings.write_string(&new_builder, item) 
    compiled_text = strings.to_string(new_builder)

    if strings.builder_len(log_sb) != 0 {
        // Append newline if log isn't empty
        fmt.sbprint(&log_sb, "\n")
    }
    fmt.sbprint(&log_sb, compiled_text)
    log_updated = true
}

fetch_item :: proc(items_to_edit: ..items.Item){
    clear(&items_selected)
    for item in items_to_edit do append(&items_selected, item)
}

is_item_selected :: proc(item: items.Item) -> bool {
    for selected_item in items_selected {
        if item.id == selected_item.id {
            return true
        }
    }
    return false
}

