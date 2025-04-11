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

// screen_width:i32 = 800;
// screen_height:i32= 800;

screen_width: = win.GetSystemMetrics(win.SM_CXSCREEN)-50;
screen_height: = win.GetSystemMetrics(win.SM_CYSCREEN)-100;

window_right_button_divider : i32 = 5

bg : [3]u8 = { 90, 95, 100 }

main :: proc() {

    // fmt.print("Screen Width: ", win.GetSystemMetrics(win.SM_CXSCREEN), "\n")
    // fmt.print("Screen Height: ", win.GetSystemMetrics(win.SM_CYSCREEN), "\n")
    tests.run_all_tests()
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
        items.add10mil(&db)

        defer {
            initialize_window(db)
            // fmt.print(db.items)
        }  
    } 
}

initialize_window :: proc(db : items.InventoryDatabase) {
    
    rl.SetWindowState({ .WINDOW_RESIZABLE})
    rl.InitWindow(screen_width, screen_height, "Inventory Managment UI")

    ctx := rlmu.init_scope() // same as calling, `rlmu.init(); defer rlmu.destroy()`

    allocator: virtual.Arena 
    _= virtual.arena_init_growing(&allocator)// Set the allocator for the database

    context.allocator = virtual.arena_allocator(&allocator) 

    for !rl.WindowShouldClose() {
        begin := virtual.arena_temp_begin(&allocator)
        defer virtual.arena_temp_end(begin)

        rl.BeginDrawing(); defer rl.EndDrawing()
        rl.ClearBackground({ bg.r, bg.g, bg.b, 255 })
        
        rlmu.begin_scope() // same as calling, `rlmu.begin(); defer rlmu.end()`

        initialize_sub_windows(ctx, db)
    }
}

initialize_sub_windows :: proc(ctx : ^mu.Context, db : items.InventoryDatabase){
    button_window(ctx,db)
    edit_window(ctx)
    log_window(ctx)  
}

// number_i32 :: proc(ctx: ^Context, value: ^i32, step: Real, fmt_string: string = SLIDER_FMT, opt: Options = {.ALIGN_CENTER}) -> (res: Result_Set) {
//     id := get_id(ctx, uintptr(value))
//     base := layout_next(ctx)
//     last := value^

//     /* handle text input mode */
//     if number_textbox(ctx, value, base, id, fmt_string) {
//         return
//     }

//     /* handle normal mode */
//     update_control(ctx, id, base, opt)

//     /* handle input */
//     if ctx.focus_id == id && ctx.mouse_down_bits == {.LEFT} {
//         value^ += i32(ctx.mouse_delta.x) * step
//     }
//     /* set flag if value changed */
//     if value^ != last {
//         res += {.CHANGE}
//     }

//     /* draw base */
//     draw_control_frame(ctx, id, base, .BASE, opt)
//     /* draw text  */
//     text_buf: [4096]byte
//     draw_control_text(ctx, fmt.bprintf(text_buf[:], fmt_string, value^), base, .TEXT, opt)

//     return
// }
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
                button_width:= i32(screen_width/2)-9
                mu.layout_row(ctx, {button_width}, (screen_height/8))
                // // displayed: name x quantity, single price, total price
                // mu.label(ctx,item.name)
                // mu.label(ctx, " x ")
                // mu.number(ctx, &item.quantity)
                // mu.label(ctx, "       $")
                // mu.number(ctx, &item.price,0.01)
        
                if .SUBMIT in mu.button(ctx, item.label){
                    fetch_item(item)
                    write_log(item.label)
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
        if len(items_selected) == 0 {
            label_width:= i32(screen_width/2)-10
            mu.layout_row(ctx, {label_width}, (screen_height/3))
            mu.label(ctx, "No items selected")
 
        }else{
            label_width:= i32(screen_width/2)-10
            mu.layout_row(ctx, {label_width}, (screen_height/3))
            mu.label(ctx, items_selected[0].name)

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

fetch_item :: proc(items_to_edit: ..items.Item){
    clear(&items_selected)
    for item in items_to_edit do append(&items_selected, item)
}

