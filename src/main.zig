//!Main program entry and loop
//! @Zane Youmans

const std = @import("std");
//const gui = @import("gui/widgets.zig");

const app = @import("App.zig");



pub fn main() !void {

    var GPA = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = GPA.deinit();

    const allocator = GPA.allocator();

    const MyApp = try allocator.create(app.App);
    defer allocator.destroy(MyApp);

    try MyApp.*.Activate(allocator);

//    numberBuffer = std.ArrayList(f32).init(allocator);
//    defer numberBuffer.clearAndFree();
//
//    const margin = 20;
//    const button_side = 100;
//
//    //set the options
//    const appOptions: guiApp.GuiAppOptions = .{.allocator = allocator,
//                                                .appTitle = "Button Test",
//                                                .startingWindowSize = .{.x = 1000, .y = 800},
//                                                .backgroundColor = .{.r = 30, .g = 30, .b = 30, .a=255}};
//
//    //create the app and initialize it with the options
//    var app: guiApp.GuiApp = .{};
//    app.Init(appOptions);
//
//    //let's make some widgets!
//    //TODO: Make functions for each type of widget
//    var button: gui.Widget = .{
//        .label = "Green Button",
//        .widgetType = gui.WidgetType{ .Button = gui.Button{} }, //
//        .size = .{ .x = button_side, .y = button_side},
//        .color = gui.RGBAColor.Create(0, 200, 0, 255),
//        .transform = gui.Transform{ .position = .{ .x = 0, .y = 0 } },
//        //.onHovered = HandleHover,
//        //.onUnhovered = HandleUnhover,
//        //.onMouseDown = Increment,
//    };
//
//    //Make a grid of buttons
//
//    var number_index:u8 = 0;
//    for (0..4) |x|
//    {
//        for (0..4) |y|
//        {
//            if(y == 3 and (x == 0 or x == 2))
//            {
//                button.color = .{.r = 50,.g = 0, .b = 210,.a = 255};
//                switch(x)
//                {
//                    0 => button.label = " AC ",
//                    2 => button.label = " < ",
//                    else=>{}
//                }
//            }
//            else if (x == 3)
//            {
//                button.color = .{.r = 200,.g = 50, .b = 50,.a = 255};
//                //button.onMouseUp = pickOperation;
//                switch(y)
//                {
//                    0 => button.label = " + ",
//                    1 => button.label = " - ",
//                    2 => button.label = " * ",
//                    3 => button.label = " / ",
//                    else => {}
//                }
//            }
//            else 
//            {
//                button.color = .{.r = 0,.g = 200, .b = 0,.a = 255};
//                //button.onMouseUp = AddToBuffer;
//                button.label = switch(number_index)
//                {
//                    0 => "1",
//                    1 => "4",
//                    2 => "7",
//                    3 => "2",
//                    4 => "5",
//                    5 => "8",
//                    6 => "0",
//                    7 => "3",
//                    8 => "6",
//                    9 => "9",
//                    else => break
//                };
//                number_index += 1;
//            }
//
//            const intx: i32 = @intCast(x);
//            const inty: i32 = @intCast(y);
//            button.transform.position.x = ((margin + button_side) * intx) + margin;
//            button.transform.position.y = ((margin + button_side) * inty) + margin;
//
//            try app.AddWidget(&button);
//        }
//    }
//
//    var checkbox: gui.Widget = .{
//        .label = "Check Box",
//        .widgetType = gui.WidgetType{ .CheckBox = gui.CheckBox{.checked = false} }, //
//        .size = .{ .x = 50, .y = 50},
//        .color = gui.RGBAColor.Create(75, 75, 75, 255),
//        .transform = gui.Transform{ .position = .{ .x = 600, .y = 600 } }};
//
//    try app.AddWidget(&checkbox);
//
//    var label: gui.Widget = .{
//        .label = "Test Text",
//        .widgetType = gui.WidgetType{ .Label = gui.Label{} }, //
//        .size = .{ .x = 200, .y = 50},
//        .color = gui.RGBAColor.Create(200, 200, 200, 255),
//        .transform = gui.Transform{ .position = .{ .x = 670, .y = 600 } }};
//    
//    try app.AddWidget(&label);
//    //this runs the event loop
//    //try app.Run();
//
//
}
