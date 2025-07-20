//!Main program entry and loop
//! @Zane Youmans

const std = @import("std");
const sdl = @import("sdl/sdl.zig");
const gui = @import("gui/widgets.zig");

const guiApp = @import("gui/GuiApp.zig");

const Allocator = std.mem.Allocator;

fn HandleHover(widget: *gui.Widget) void
{
    std.debug.print("{s} Hovered!!!\n",.{widget.*.label});
}

fn HandleUnhover(widget: *gui.Widget) void
{
    std.debug.print("{s} Unhovered!!!\n",.{widget.*.label});
}

fn HandleClick(widget: *gui.Widget) void
{
    std.debug.print("{s} clicked!!!\n",.{widget.*.label});
}

fn HandleRelease(widget: *gui.Widget) void
{
    std.debug.print("{s} released!!!\n",.{widget.*.label});
}

pub fn main() !void {

    var GPA = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = GPA.allocator();
    
    //set the options
    const appOptions: guiApp.GuiAppOptions = .{.allocator = allocator,
                                                .appTitle = "Button Test",
                                                .startingWindowSize = .{.x = 1000, .y = 800}};

    //create the app and initialize it with the options
    var app: guiApp.GuiApp = .{};
    app.Init(appOptions);

    //let's make some widgets!
    //TODO: Make functions for each type of widget
    const b1: gui.Widget = .{
        .label = "Green Button",
        .widgetType = gui.WidgetType{ .Button = gui.Button{} }, //
        .size = .{ .x = 300, .y = 100 },
        .color = gui.RGBAColor.Create(0, 200, 0, 255),
        .transform = gui.Transform{ .position = .{ .x = 20, .y = 20 } },
        //.onHovered = HandleHover,
        //.onUnhovered = HandleUnhover,
        .onMouseDown = HandleClick,
    };

    const b2: gui.Widget = .{
        .label = "Blue Button",
        .widgetType = gui.WidgetType{ .Button = gui.Button{} }, //
        .size = .{ .x = 300, .y = 100 },
        .color = gui.RGBAColor.Create(50, 100, 100, 255),
        .transform = gui.Transform{ .position = .{ .x = 340, .y = 20 } },
        //.onHovered = HandleHover,
        //.onUnhovered = HandleUnhover,
        .onMouseDown = HandleClick,
        };

    const b3: gui.Widget = .{
        .label = "Yellow Button",
        .widgetType = gui.WidgetType{ .Button = gui.Button{} }, //
        .size = .{ .x = 300, .y = 100 },
        .color = gui.RGBAColor.Create(200, 200, 0, 255),
        .transform = gui.Transform{ .position = .{ .x = 660, .y = 20 } },
        //.onHovered = HandleHover,
        //.onUnhovered = HandleUnhover,
        .onMouseDown = HandleClick,
        //.onMouseUp = HandleRelease,
        };

    //add the widgets to the app
    try app.AddWidget(&b1);
    try app.AddWidget(&b2);
    try app.AddWidget(&b3);

    //this runs the event loop
    try app.Run();

    std.debug.print("Shutting Down\n",.{});

}
