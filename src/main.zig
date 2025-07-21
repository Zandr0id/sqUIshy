//!Main program entry and loop
//! @Zane Youmans

const std = @import("std");
const sdl = @import("sdl/sdl.zig");
const gui = @import("gui/widgets.zig");

const guiApp = @import("gui/GuiApp.zig");

const Allocator = std.mem.Allocator;

const Operations = enum{
    ADD,
    SUB,
    MULT,
    DIV
};

var numberBuffer: std.ArrayList(f32) = undefined;

var op1: ?f32 = null;
var op2: ?f32 = null;

var editingOp1 = true;

var operation: ?Operations = null;

//reset everything
fn Clear(widget: *gui.Widget) void
{
    _ = widget;
    op1 = null;
    op2 = null;
    operation = null;
    editingOp1 = true;

}

fn AddToBuffer(widget: *gui.Widget) void
{

        const ptr: []const u8 = std.mem.span(widget.*.label);
        const toAdd: f32 = value: {
            if(std.mem.eql(u8,ptr,"0"))
            {
                break: value 0;
            }
            else if(std.mem.eql(u8,ptr,"1"))
            {
                break: value 1;
            }
            else if(std.mem.eql(u8,ptr,"2"))
            {
                break: value 2;
            }
            else if(std.mem.eql(u8,ptr,"3"))
            {
                break: value 3;
            }
            else if(std.mem.eql(u8,ptr,"4"))
            {
                break: value 4;
            }
            else if(std.mem.eql(u8,ptr,"5"))
            {
                break: value 5;
            }
            else if(std.mem.eql(u8,ptr,"6"))
            {
                break: value 6;
            }
            else if(std.mem.eql(u8,ptr,"7"))
            {
                break: value 7;
            }
            else if(std.mem.eql(u8,ptr,"8"))
            {
                break: value 8;
            }
            else if(std.mem.eql(u8,ptr,"9"))
            {
                break: value 9;
            }
            break: value 0;
        };
        numberBuffer.append(toAdd) catch {
            
            std.debug.print("out of memory",.{});
        };
        printScreen();
    
}

fn pickOperation(widget: *gui.Widget) void
{
        const ptr: []const u8 = std.mem.span(widget.*.label);
        operation = value: {
            if(std.mem.eql(u8,ptr," + "))
            {
                break: value Operations.ADD ;
            }
            else if(std.mem.eql(u8,ptr," - "))
            {
                break: value Operations.SUB;
            }
            else if(std.mem.eql(u8,ptr," * "))
            {
                break: value Operations.MULT;
            }
            else if(std.mem.eql(u8,ptr," / "))
            {
                break: value Operations.DIV;
            }
            else { break: value null;}
        };
        op1 = bufferToInt();
        numberBuffer.clearRetainingCapacity();
        printScreen();
}

fn printScreen() void
{
    var opSymbol = " ";
    if (operation) |op|
    {
        opSymbol = switch(op)
        {
            Operations.ADD => "+",
            Operations.SUB => "-",
            Operations.MULT => "*",
            Operations.DIV => "/",
        };
    }

    if(op1) |op|
    {
        std.debug.print("{d}",.{op});
    }

    if(operation) |op|
    {
        _ = op;
        std.debug.print("{s}",.{opSymbol});
    }

    for (numberBuffer.items[0..]) |num|
    {
        std.debug.print("{d}",.{num});
    }

    std.debug.print("\n",.{});

}

fn bufferToInt() f32
{
    var ret: f32 = 0;
    for (numberBuffer.items[0..], 1..) |value, place|
    {
        const place_f32: f32 = @floatFromInt(place);
        const multiplier: f32 = place_f32 * 10.0;
        ret +=  value * multiplier;
    }
    return ret;
}

pub fn main() !void {

    var GPA = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = GPA.allocator();

    numberBuffer = std.ArrayList(f32).init(allocator);
    defer numberBuffer.clearAndFree();

    const margin = 20;
    const button_side = 100;

    //set the options
    const appOptions: guiApp.GuiAppOptions = .{.allocator = allocator,
                                                .appTitle = "Button Test",
                                                .startingWindowSize = .{.x = 1000, .y = 800},
                                                .backgroundColor = .{.r = 30, .g = 30, .b = 30, .a=255}};

    //create the app and initialize it with the options
    var app: guiApp.GuiApp = .{};
    app.Init(appOptions);

    //let's make some widgets!
    //TODO: Make functions for each type of widget
    var button: gui.Widget = .{
        .label = "Green Button",
        .widgetType = gui.WidgetType{ .Button = gui.Button{} }, //
        .size = .{ .x = button_side, .y = button_side},
        .color = gui.RGBAColor.Create(0, 200, 0, 255),
        .transform = gui.Transform{ .position = .{ .x = 0, .y = 0 } },
        //.onHovered = HandleHover,
        //.onUnhovered = HandleUnhover,
        //.onMouseDown = Increment,
    };

    //Make a grid of buttons

    var number_index:u8 = 0;
    for (0..4) |x|
    {
        for (0..4) |y|
        {
            if(y == 3 and (x == 0 or x == 2))
            {
                button.color = .{.r = 50,.g = 0, .b = 210,.a = 255};
                switch(x)
                {
                    0 => button.label = " AC ",
                    2 => button.label = " < ",
                    else=>{}
                }
            }
            else if (x == 3)
            {
                button.color = .{.r = 200,.g = 50, .b = 50,.a = 255};
                //button.onMouseUp = pickOperation;
                switch(y)
                {
                    0 => button.label = " + ",
                    1 => button.label = " - ",
                    2 => button.label = " * ",
                    3 => button.label = " / ",
                    else => {}
                }
            }
            else 
            {
                button.color = .{.r = 0,.g = 200, .b = 0,.a = 255};
                //button.onMouseUp = AddToBuffer;
                button.label = switch(number_index)
                {
                    0 => "1",
                    1 => "4",
                    2 => "7",
                    3 => "2",
                    4 => "5",
                    5 => "8",
                    6 => "0",
                    7 => "3",
                    8 => "6",
                    9 => "9",
                    else => break
                };
                number_index += 1;
            }

            const intx: i32 = @intCast(x);
            const inty: i32 = @intCast(y);
            button.transform.position.x = ((margin + button_side) * intx) + margin;
            button.transform.position.y = ((margin + button_side) * inty) + margin;

            try app.AddWidget(&button);
        }
    }

    var checkbox: gui.Widget = .{
        .label = "Check Box",
        .widgetType = gui.WidgetType{ .CheckBox = gui.CheckBox{.checked = false} }, //
        .size = .{ .x = 50, .y = 50},
        .color = gui.RGBAColor.Create(75, 75, 75, 255),
        .transform = gui.Transform{ .position = .{ .x = 600, .y = 600 } }};

    try app.AddWidget(&checkbox);

    var label: gui.Widget = .{
        .label = "Test Text",
        .widgetType = gui.WidgetType{ .Label = gui.Label{} }, //
        .size = .{ .x = 200, .y = 50},
        .color = gui.RGBAColor.Create(200, 200, 200, 255),
        .transform = gui.Transform{ .position = .{ .x = 670, .y = 600 } }};
    
    try app.AddWidget(&label);
    //this runs the event loop
    try app.Run();

    std.debug.print("Shutting Down\n",.{});

}
