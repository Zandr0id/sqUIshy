const std = @import("std");
const sdl = @import("../sdl/sdl.zig");
pub const widgets = @import("widgets.zig");
const fonts = @import("fonts.zig");

const GuiAppErrors = error{
    CantAddWidgetsWhileRunning,
    CantAddFontsWhileRunning,
    RootContainerNotCreated,
};

pub const GuiAppOptions = struct{
    startingWindowSize: widgets.Vec2(i32) = .{.x = 0, .y = 0},
    appTitle: []const u8,
    allocator: std.mem.Allocator,
    backgroundColor: sdl.types.RGBAColor = .{.r= 0,.g = 0, .b = 0, .a = 255}
};

pub fn GuiApp(comptime WrapperType: type) type {
    return struct{
        const SelfType = @This();
        const WidgetType = widgets.Widget(WrapperType);

        window: sdl.WindowPtr = undefined,
        renderer: sdl.RendererPtr = undefined,

        //this root widget houses all the other wigets
        rootContainerWidget: ?*widgets.Widget(WrapperType) = null,

        //these are for tracking fonts as they are loaded
        fonts: std.ArrayList(*fonts.Font) = undefined,
        arena: std.heap.ArenaAllocator = undefined,

        //environment info should be accessable to all widgets within the root
        environment: struct {
            wrapperApp: *WrapperType = undefined,
            windowSize: widgets.Vec2(i32) = .{.x = 0, .y=0},
            mouseLocation: widgets.Vec2(i32) = .{.x = 0,.y = 0},
            mouseLeft: widgets.MouseButtonStates = widgets.MouseButtonStates.RELEASED,
            mouseRight: widgets.MouseButtonStates = widgets.MouseButtonStates.RELEASED,
        } = undefined,

        options: GuiAppOptions = undefined,
        running: bool = false,

        pub fn Init(self: *GuiApp(WrapperType), wrapper: *WrapperType, options: GuiAppOptions) !void
        {

            self.options = options;
            self.environment = .{.windowSize = self.options.startingWindowSize, .wrapperApp = wrapper};
            
            self.arena = std.heap.ArenaAllocator.init(self.options.allocator);

            //create the root container widget to house all other widgets
            self.rootContainerWidget = try options.allocator.create(widgets.Widget(WrapperType));
            self.rootContainerWidget.?.* = .{.transform = .{.position = .{ .x = 0, .y = 0 }},
                                            .color = self.options.backgroundColor,
                                            .label = "not set",
                                            .widgetType = widgets.WidgetType(WrapperType){ .Container = .{}},
                                            .size = .{.x = options.startingWindowSize.x, .y = options.startingWindowSize.y}};

            self.rootContainerWidget.?.*.owningGui = self;
            self.rootContainerWidget.?.*.widgetType.Container.init(self.rootContainerWidget.?, self.options.allocator);

            //prep the list to accept fonts
            self.fonts = std.ArrayList(*fonts.Font).init(self.options.allocator);
       
            try sdl.Init();
            errdefer self.CleanUp();
        }

        pub fn CleanUp(self: *GuiApp(WrapperType)) void
        {
            sdl.Quit();

            self.*.arena.deinit();
            //self.*.appWidgets.deinit();

            //tell all child widgets to shutdown
            if (self.rootContainerWidget) |root|
            {
                root.*.widgetType.shutdown();
            }

            //destory the root container
            self.options.allocator.destroy(self.rootContainerWidget.?);

            //clear out all fonts
            self.*.fonts.deinit();
        }

        pub fn AddFont(self: *GuiApp(WrapperType) ,path: []const u8, size: u32) !usize
        {

            errdefer self.CleanUp();

            //TODO just print warning and not crash?
            if (self.running)
            {
                return error.CantAddWidgetsWhileRunning;
            }

            const allocator = self.arena.allocator();
            const newFont = try allocator.create(fonts.Font);

            try newFont.LoadFont(path, size);

            try self.fonts.append(newFont);

            return self.fonts.items.len;
        }

        pub fn AddWidget(self: *GuiApp(WrapperType), widget: widgets.Widget(WrapperType)) !*widgets.Widget(WrapperType)
        {

            errdefer self.CleanUp();

            if (self.running)
            {
                return error.CantAddWidgetsWhileRunning;
            }
            
            if (self.rootContainerWidget) |root|
            {
                return try root.*.widgetType.Container.addChildWidget(root, widget);
            }
            else {
                return error.RootContainerNotCreated;
            }
        }

        pub fn Run(self: *GuiApp(WrapperType)) !void {
        
            defer self.CleanUp();

            self.window = try sdl.Window.createWindow(self.options.appTitle, self.options.startingWindowSize.x,self.options.startingWindowSize.y);
            defer sdl.Window.destroyWindow(self.window);

            self.renderer  = try sdl.Renderer.createRenderer(self.window);
            defer sdl.Renderer.destroyRenderer(self.renderer);

            var event: sdl.Event = undefined;

            self.running = true;
            while (self.running) 
            {
                if (self.renderer) |r|
                {
                    sdl.Renderer.clearScreenToColor(r, self.options.backgroundColor);
                }

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

                //for (self.appWidgets.items) |w|
                if (self.rootContainerWidget) |root|
                {
                    try root.*.update();
                    try root.*.draw();
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