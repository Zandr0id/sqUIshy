//!Main program entry and loop
//! @Zane Youmans

const std = @import("std");
const sdl = @import("sdl/sdl.zig");
const gui = @import("gui/widgets.zig");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

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
    try sdl.Init();
    defer sdl.Quit();

    const WINDOW_SIZE: gui.Vec2(i32) = .{ .x = 980, .y=140 }; 

    var GPA = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = GPA.allocator();
    var Widgets = std.ArrayList(gui.Widget).init(allocator);
    defer Widgets.deinit();

    const window: sdl.WindowPtr = try sdl.Window.createWindow("Test window", WINDOW_SIZE.x, WINDOW_SIZE.y);
    defer sdl.Window.destroyWindow(window);

    const renderer: sdl.RendererPtr = try sdl.Renderer.createRenderer(window);
    defer sdl.Renderer.destroyRenderer(renderer);

    var running = true;
    var event: sdl.types.Event = undefined;

    var context: gui.UIContext = .{ .renderer = renderer,
                                    .windowSize = .{.x = WINDOW_SIZE.x, .y = WINDOW_SIZE.y} };

    //test button widget
    const b1: gui.Widget = .{
        .label = "Green Button",
        .widgetType = gui.WidgetType{ .Button = gui.Button{} }, //
        .size = .{ .x = 300, .y = 100 },
        .color = gui.RGBAColor.Create(0, 200, 0, 255),
        .context = &context,
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
        .context = &context,
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
        .context = &context,
        .transform = gui.Transform{ .position = .{ .x = 660, .y = 20 } },
        //.onHovered = HandleHover,
        //.onUnhovered = HandleUnhover,
        .onMouseDown = HandleClick,
        //.onMouseUp = HandleRelease,
        };

    try Widgets.append(b1);
    try Widgets.append(b2);
    try Widgets.append(b3);

    while (running) {

        //clear the screen
        _ = c.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        _ = c.SDL_RenderClear(renderer);


        //check if the mouse states need to transition to their steady states after one frame
        if (context.mouseLeft == gui.MouseButtonStates.JUST_NOW_PRESSED)
        {
            context.mouseLeft = gui.MouseButtonStates.PRESSED;
        }
        else if (context.mouseLeft == gui.MouseButtonStates.JUST_NOW_RELEASED)
        {
            context.mouseLeft = gui.MouseButtonStates.RELEASED;
        }

        //run the event loop
        while (c.SDL_PollEvent(&event) != 0) {
            const event_enum: sdl.types.EventsEnum = @enumFromInt(event.type);
            switch (event_enum) {
                sdl.types.EventsEnum.WINDOW_QUIT => {
                    running = false;
                },

                //window events are a sub-catagory
                sdl.types.EventsEnum.WINDOW_EVENT => {
                    const window_event_enum: sdl.types.EventsEnum = @enumFromInt(event.window.event);
                    switch (window_event_enum) {
                        sdl.types.EventsEnum.WINDOW_RESIZED => {
                            context.windowSize.x = event.window.data1;
                            context.windowSize.y = event.window.data2;
                            std.debug.print("Resize to {d}x{d}\n", .{ event.window.data1, event.window.data2 });
                        },
                        else => {},
                    }
                },
                sdl.types.EventsEnum.MOUSE_MOTION =>{
                    context.mouseLocation.x = event.motion.x;
                    context.mouseLocation.y = event.motion.y;
                },
                sdl.types.EventsEnum.MOUSE_BUTTONDOWN =>{
                    context.mouseLeft = gui.MouseButtonStates.JUST_NOW_PRESSED;
                },
                sdl.types.EventsEnum.MOUSE_BUTTONUP =>{
                    context.mouseLeft = gui.MouseButtonStates.JUST_NOW_RELEASED;
                },
                else => {},
            }
        }

        for (Widgets.items) |*w|
        {
            w.update();
            w.draw();
        }

        //draw mouse crosshairs
        _ = c.SDL_SetRenderDrawColor(renderer, 255, 100, 0, 255);
        _ = c.SDL_RenderDrawLine(renderer, context.mouseLocation.x, 0, context.mouseLocation.x, context.windowSize.y);
        _ = c.SDL_RenderDrawLine(renderer, 0, context.mouseLocation.y, context.windowSize.x, context.mouseLocation.y);

        c.SDL_RenderPresent(renderer);
        c.SDL_Delay(16);
    }
}
