const std = @import("std");
const sdl = @import("../sdl/sdl.zig");
pub const widgets = @import("widgets.zig");

const GuiAppErrors = error{
    CantAddWidgetsWhileRunning
};

pub const GuiAppOptions = struct{
    startingWindowSize: widgets.Vec2(i32) = .{.x = 0, .y = 0},
    appTitle: []const u8,
    allocator: std.mem.Allocator,
    backgroundColor: widgets.RGBAColor = .{.r= 0,.g = 0, .b = 0, .a = 255}
};

pub fn GuiApp(comptime WrapperType: type) type {
    return struct{
        const SelfType = @This();
        const WidgetType = widgets.Widget(WrapperType);

        window: sdl.WindowPtr = undefined,
        renderer: sdl.RendererPtr = undefined,
        appWidgets: std.ArrayList(*widgets.Widget(WrapperType)) = undefined,
        environment: struct {
            wrapperApp: *WrapperType = undefined,
            windowSize: widgets.Vec2(i32) = .{.x = 0, .y=0},
            mouseLocation: widgets.Vec2(i32) = .{.x = 0,.y = 0},
            mouseLeft: widgets.MouseButtonStates = widgets.MouseButtonStates.RELEASED,
            mouseRight: widgets.MouseButtonStates = widgets.MouseButtonStates.RELEASED,
        } = undefined,

        arena: std.heap.ArenaAllocator = undefined,

        options: GuiAppOptions = undefined,

        running: bool = false,

        pub fn Init(self: *GuiApp, wrapper: *WrapperType, options: GuiAppOptions) !void
        {
            self.options = options;
            self.environment = .{.windowSize = self.options.startingWindowSize, .wrapper = wrapper};

            //create the memory slaps to create widgets on
            self.arena = std.heap.ArenaAllocator.init(self.options.allocator);
            self.appWidgets = std.ArrayList(*widgets.Widget).init(self.options.allocator);
        }

        pub fn AddWidget(self: *GuiApp, widget: widgets.Widget) !*widgets.Widget
        {
            if (self.running)
            {
                return error.CantAddWidgetsWhileRunning;
            }
            
            const allocator = self.arena.allocator();
            const newWidget = try allocator.create(widgets.Widget);
            newWidget.* = widget;
            newWidget.*.owningGui = self;

            try self.appWidgets.append(newWidget);

            return newWidget;
        }

        pub fn Run(self: *GuiApp) !void {
            try sdl.Init();
            defer sdl.Quit();

            self.window = try sdl.Window.createWindow(self.options.appTitle, self.options.startingWindowSize.x,self.options.startingWindowSize.y);
            defer sdl.Window.destroyWindow(self.window);

            self.renderer  = try sdl.Renderer.createRenderer(self.window);
            defer sdl.Renderer.destroyRenderer(self.renderer);

            //set this to clean up at the end
            defer self.appWidgets.deinit();
            defer self.arena.deinit();
            
            var event: sdl.Event = undefined;

            self.running = true;
            while (self.running) 
            {
                //clear the screen
                _ = sdl.c.SDL_SetRenderDrawColor(self.renderer, 
                                                self.options.backgroundColor.r,
                                                self.options.backgroundColor.g, 
                                                self.options.backgroundColor.b,
                                                self.options.backgroundColor.a);
                _ = sdl.c.SDL_RenderClear(self.renderer);

                //check if the mouse states need to transition to their steady states after one frame
                if (self.environment.mouseLeft == widgets.MouseButtonStates.JUST_NOW_PRESSED)
                {
                    self.environment.mouseLeft = widgets.MouseButtonStates.PRESSED;
                }
                else if (self.environment.mouseLeft == widgets.MouseButtonStates.JUST_NOW_RELEASED)
                {
                    self.environment.mouseLeft = widgets.MouseButtonStates.RELEASED;
                }

                //run the event loop
                while (sdl.c.SDL_PollEvent(&event) != 0) {
                    const event_enum: sdl.EventsEnum = @enumFromInt(event.type);
                    switch (event_enum) {
                        sdl.EventsEnum.WINDOW_QUIT => {
                            self.running = false;
                        },

                        //window events are a sub-catagory
                        sdl.EventsEnum.WINDOW_EVENT => {
                            const window_event_enum: sdl.EventsEnum = @enumFromInt(event.window.event);
                            switch (window_event_enum) {
                                sdl.EventsEnum.WINDOW_RESIZED => {
                                    self.environment.windowSize.x = event.window.data1;
                                    self.environment.windowSize.y = event.window.data2;
                                    std.debug.print("Resize to {d}x{d}\n", .{ event.window.data1, event.window.data2 });
                                },
                                else => {},
                            }
                        },
                        sdl.EventsEnum.MOUSE_MOTION =>{
                            self.environment.mouseLocation.x = event.motion.x;
                            self.environment.mouseLocation.y = event.motion.y;
                        },
                        sdl.EventsEnum.MOUSE_BUTTONDOWN =>{
                            self.environment.mouseLeft = widgets.MouseButtonStates.JUST_NOW_PRESSED;
                        },
                        sdl.EventsEnum.MOUSE_BUTTONUP =>{
                            self.environment.mouseLeft = widgets.MouseButtonStates.JUST_NOW_RELEASED;
                        },
                        else => {},
                    }
                }

                for (self.appWidgets.items) |w|
                {
                    w.*.update();
                    try w.*.draw();
                }

                //draw mouse crosshairs
                _ = sdl.c.SDL_SetRenderDrawColor(self.renderer, 255, 100, 0, 255);
                _ = sdl.c.SDL_RenderDrawLine(self.renderer, self.environment.mouseLocation.x, 0, self.environment.mouseLocation.x, self.environment.windowSize.y);
                _ = sdl.c.SDL_RenderDrawLine(self.renderer, 0, self.environment.mouseLocation.y, self.environment.windowSize.x, self.environment.mouseLocation.y);

                sdl.c.SDL_RenderPresent(self.renderer);
                sdl.c.SDL_Delay(16);
            }
        }
    };
}