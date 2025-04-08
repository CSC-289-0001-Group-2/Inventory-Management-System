package main

// port of micro ui c demo to odin, using rlmu as renderer

import "items"
import "tests"

import "rlmu"
import "core:fmt"
import "core:strings"
import rl "vendor:raylib"
import mu "vendor:microui"


log_sb := strings.builder_make()
log_updated := false

log_input_text := make_slice([]u8, 128)
log_input_text_len : int


screen_width : i32= 800
screen_height : i32= 800



window_right_button_divider : i32 = 5

bg : [3]u8 = { 90, 95, 100 }

main :: proc() {
    // db,success := items.load_inventory("inventory.txt")
    // if !success {
    //     fmt.println("Failed to load inventory.")
    //     db = items.InventoryDatabase{
    //         items = make([dynamic]items.Item, 10000000), // Initialize as a dynamic array
    //     }
    // }
    tests.run_all_tests()

    // rl.InitWindow(screen_width, screen_height, "Inventory Managment UI")
    // defer rl.CloseWindow()

    // ctx := rlmu.init_scope() // same as calling, `rlmu.init(); defer rlmu.destroy()`

    // for !rl.WindowShouldClose() {
    //     defer free_all(context.temp_allocator)

    //     rl.BeginDrawing(); defer rl.EndDrawing()
    //     rl.ClearBackground({ bg.r, bg.g, bg.b, 255 })
        
    //     rlmu.begin_scope()  // same as calling, `rlmu.begin(); defer rlmu.end()`


    //     button_window(ctx,db) // next parameter is for database reading
    // } 
}

button_window :: proc(ctx : ^mu.Context, db : items.InventoryDatabase){ //, items: [dynamic]Item
    if mu.begin_window(ctx, "Inventory List", mu.Rect{ screen_width/2, 0, screen_width/2, screen_height },{ .EXPANDED}) {
        // for i in 0..<len(db.items) {
            
            defer mu.end_window(ctx)
            button_width: i32 = i32(screen_width/2)
            button_num: i32 =20
            initial : string = "Apple x 20"
            price : string = "$30.34"
            
            my_builder:= strings.builder_make()
            strings.write_string(&my_builder,initial)
            mu.layout_row(ctx, {button_width}, (screen_height/8))
            for i : i32 = 0; i < (button_width-i32(len(initial))-i32(len(price)))/4; i+=1{
                strings.write_string(&my_builder," ")
            }
    
            
            strings.write_string(&my_builder,price)
            label:= strings.to_string(my_builder)
    
            mu.button(ctx, label)
        // }
        // mu.begin_panel(ctx, "Inventory List")
        // mu.end_panel(ctx)
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

u8_slider :: proc(ctx: ^mu.Context, value: ^u8, low, high: int) -> mu.Result_Set {
    mu.push_id_uintptr(ctx, transmute(uintptr)value)
    defer mu.pop_id(ctx)


    @(static) tmp: f32
    tmp = f32(value^)
    res := mu.slider(ctx, &tmp, f32(low), f32(high), 0, "%.f", { .ALIGN_CENTER })
    value ^= u8(tmp)
    return res
}