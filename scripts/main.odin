package main

// port of micro ui c demo to odin, using rlmu as renderer

import "items"
import "tests"

import "rlmu"
import "core:fmt"
import "core:strings"
import rl "vendor:raylib"
import mu "vendor:microui"
// import win "core:sys/windows"



log_sb := strings.builder_make()
log_updated := false
items_selected:= items.InventoryDatabase{
    items = make([dynamic]items.Item), // Initialize as a dynamic array
}

file_name:= "inventory.dat"

log_input_text := make_slice([]u8, 128)
log_input_text_len : int

screen_width:i32 = 800;
screen_height:i32= 800;

// screen_width: = win.GetSystemMetrics(win.SM_CXSCREEN);
// screen_height: = win.GetSystemMetrics(win.SM_CYSCREEN);

window_right_button_divider : i32 = 5

bg : [3]u8 = { 90, 95, 100 }

main :: proc() {

    // fmt.print("Screen Width: ", win.GetSystemMetrics(win.SM_CXSCREEN), "\n")
    // fmt.print("Screen Height: ", win.GetSystemMetrics(win.SM_CYSCREEN), "\n")
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
        items.add_item_by_members(&db, 1, 1.0, "Test Item", "Test Manufacturer")
        items.add_item_by_members(&db, 2, 2.0, "Test Item 2", "Test Manufacturer 2")
        items.add_item_by_members(&db, 3, 3.0, "Test Item 3", "Test Manufacturer 3")
        items.add_item_by_members(&db, 4, 4.0, "Test Item 4", "Test Manufacturer 4")

        defer {
            initialize_window(db)
            // fmt.print(db.items)
        }
        
    }
    
}

initialize_window :: proc(db : items.InventoryDatabase) {
    
    rl.SetWindowState({ .WINDOW_RESIZABLE})
    rl.InitWindow(screen_width, screen_height, "Inventory Managment UI")
    defer rl.CloseWindow()

    ctx := rlmu.init_scope() // same as calling, `rlmu.init(); defer rlmu.destroy()`

    for !rl.WindowShouldClose() {
        defer free_all(context.temp_allocator)

        rl.BeginDrawing(); defer rl.EndDrawing()
        rl.ClearBackground({ bg.r, bg.g, bg.b, 255 })
        
        rlmu.begin_scope()  // same as calling, `rlmu.begin(); defer rlmu.end()`

        button_window(ctx,db) // next parameter is for database reading
        log_window(ctx)
        edit_window(ctx)
    }
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
                my_builder:= strings.builder_make()
                strings.write_string(&my_builder,item.name)
                strings.write_string(&my_builder,"  x  ")
                strings.write_int(&my_builder, cast(int)item.quantity)
                strings.write_string(&my_builder,"       $")
                fmt.sbprintf(&my_builder,"%.2f",item.price)
                strings.write_string(&my_builder," total price: ")
                strings.write_string(&my_builder,"     $")
                fmt.sbprintf(&my_builder, "%.2f", item.price*cast(f32)(item.quantity))
                label:= strings.to_string(my_builder)
                
                button_width:= i32(screen_width/2)-9
                mu.layout_row(ctx, {button_width}, (screen_height/8))
                
        
                if .SUBMIT in mu.button(ctx, label){
                    fetch_item(item)
                    write_log(label)
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
edit_window :: proc (ctx : ^mu.Context) {
    if mu.begin_window(ctx, "Edit window", mu.Rect{ 0, 0, screen_width/2, screen_height/2 },{ .EXPANDED,.NO_CLOSE,.NO_RESIZE}) {
        defer mu.end_window(ctx)
        win := mu.get_current_container(ctx)
        win.rect.w = max(win.rect.w, 0)
        win.rect.w = min(win.rect.w, 0)
        win.rect.h = max(win.rect.h, 0)
        win.rect.h = min(win.rect.h, 0)
        if len(items_selected.items) == 0 {
            label_width:= i32(screen_width/2)-10
            mu.layout_row(ctx, {label_width}, (screen_height/3))
            mu.label(ctx, "No items selected")
 
        }else{
            label_width:= i32(screen_width/2)-10
            mu.layout_row(ctx, {label_width}, (screen_height/3))
            mu.label(ctx, items_selected.items[0].name)

        }

        
    }
}
write_log :: proc(text: string) {
    if strings.builder_len(log_sb) != 0 {
        // Append newline if log isn't empty
        fmt.sbprint(&log_sb, "\n")
    }
    fmt.sbprint(&log_sb, text)
    log_updated = true
}

fetch_item :: proc(item_to_add : items.Item){
    items.add_item_by_struct(&items_selected, item_to_add)
}

