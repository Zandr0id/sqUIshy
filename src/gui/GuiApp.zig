const std = @import("std");
const sdl = @import("../sdl/sdl.zig");
const widgets = @import("widgets.zig");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

const GuiAppErrors = error{

};

pub const GuiAppOptions = struct{
    startingWindowSize: widgets.Vec2(i32) = .{.x = 0, .y = 0},
    appTitle: []const u8,
    allocator: std.mem.Allocator,
};

pub const GuiApp = struct{
    window: sdl.WindowPtr = undefined,
    renderer: sdl.RendererPtr = undefined,
    appWidgets: std.ArrayList(widgets.Widget) = undefined,
    context: widgets.UIContext = undefined,

    options: GuiAppOptions = undefined,

    running: bool = false,

    pub fn Init(self: *GuiApp, options: GuiAppOptions) void
    {
        self.options = options;
        self.context.windowSize = options.startingWindowSize;

        self.appWidgets = std.ArrayList(widgets.Widget).init(self.options.allocator);
    }

    pub fn AddWidget(self: *GuiApp, widget: *const widgets.Widget) !void
    {
        if (self.running)
        {
            return;
        }
        
        //we need an editable version
        var newWidget = widget.*;

        //set the context on it and add it to the list
        newWidget.context = &self.context;
        try self.appWidgets.append(newWidget);
    }

    pub fn Run(self: *GuiApp) !void {
        try sdl.Init();
        defer sdl.Quit();

        self.window = try sdl.Window.createWindow(self.options.appTitle, self.options.startingWindowSize.x,self.options.startingWindowSize.y);
        defer sdl.Window.destroyWindow(self.window);

        self.renderer  = try sdl.Renderer.createRenderer(self.window);
        self.context.renderer = self.renderer;
        defer sdl.Renderer.destroyRenderer(self.renderer);

        //set this to clean up at the end
        defer self.appWidgets.deinit();

        var event: sdl.types.Event = undefined;

        self.running = true;
        while (self.running) 
        {
            //clear the screen
            _ = c.SDL_SetRenderDrawColor(self.renderer, 0, 0, 0, 255);
            _ = c.SDL_RenderClear(self.renderer);

            //check if the mouse states need to transition to their steady states after one frame
            if (self.context.mouseLeft == widgets.MouseButtonStates.JUST_NOW_PRESSED)
            {
                self.context.mouseLeft = widgets.MouseButtonStates.PRESSED;
            }
            else if (self.context.mouseLeft == widgets.MouseButtonStates.JUST_NOW_RELEASED)
            {
                self.context.mouseLeft = widgets.MouseButtonStates.RELEASED;
            }

            //run the event loop
            while (c.SDL_PollEvent(&event) != 0) {
                const event_enum: sdl.types.EventsEnum = @enumFromInt(event.type);
                switch (event_enum) {
                    sdl.types.EventsEnum.WINDOW_QUIT => {
                        self.running = false;
                    },

                    //window events are a sub-catagory
                    sdl.types.EventsEnum.WINDOW_EVENT => {
                        const window_event_enum: sdl.types.EventsEnum = @enumFromInt(event.window.event);
                        switch (window_event_enum) {
                            sdl.types.EventsEnum.WINDOW_RESIZED => {
                                self.context.windowSize.x = event.window.data1;
                                self.context.windowSize.y = event.window.data2;
                                std.debug.print("Resize to {d}x{d}\n", .{ event.window.data1, event.window.data2 });
                            },
                            else => {},
                        }
                    },
                    sdl.types.EventsEnum.MOUSE_MOTION =>{
                        self.context.mouseLocation.x = event.motion.x;
                        self.context.mouseLocation.y = event.motion.y;
                    },
                    sdl.types.EventsEnum.MOUSE_BUTTONDOWN =>{
                        self.context.mouseLeft = widgets.MouseButtonStates.JUST_NOW_PRESSED;
                    },
                    sdl.types.EventsEnum.MOUSE_BUTTONUP =>{
                        self.context.mouseLeft = widgets.MouseButtonStates.JUST_NOW_RELEASED;
                    },
                    else => {},
                }
            }

            for (self.appWidgets.items) |*w|
            {
                w.update();
                w.draw();
            }

            //draw mouse crosshairs
            _ = c.SDL_SetRenderDrawColor(self.renderer, 255, 100, 0, 255);
            _ = c.SDL_RenderDrawLine(self.renderer, self.context.mouseLocation.x, 0, self.context.mouseLocation.x, self.context.windowSize.y);
            _ = c.SDL_RenderDrawLine(self.renderer, 0, self.context.mouseLocation.y, self.context.windowSize.x, self.context.mouseLocation.y);

            c.SDL_RenderPresent(self.renderer);
            c.SDL_Delay(16);
        }
    }
};