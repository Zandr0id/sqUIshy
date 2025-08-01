const std = @import("std");
const sdl = @import("sdl/sdl_types.zig");
const gui = @import("gui/GuiApp.zig");

pub const App = struct {

    const AppWidget = gui.widgets.Widget(App);

    gui: *gui.GuiApp(App) = undefined,

    left_panel: ?*AppWidget = null,
    right_panel: ?*AppWidget = null,
    small_panel: ?*AppWidget = null,

    vertical_slider: ?*AppWidget = null,
    horizontal_slider: ?*AppWidget = null,

    green_button: ?*AppWidget = null,
    red_button: ?*AppWidget = null,
    label_1: ?*AppWidget = null,

    checkbox: ?*AppWidget = null,
    label_2: ?*AppWidget = null,

    pub fn OnClick1(self: *App, widget: *AppWidget) void
    {
        _ = widget;
        ChangeText1(self);
    }

    pub fn OnClick2(self: *App, widget: *AppWidget) void
    {
        _ = widget;
        ChangeText2(self);
    }

    pub fn ChangeText1(self: *App) void
    {
        self.label_1.?.*.label = "Green Pressed";
        self.label_1.?.color.r = 0;
        self.label_1.?.color.g = 200;
    }

    pub fn ChangeText2(self: *App) void
    {
        self.label_1.?.label = "Red Pressed";
        self.label_1.?.color.r = 200;
        self.label_1.?.color.g = 0;
    }

    pub fn OnCheckToggle(self: *App, widget: *AppWidget, newState: bool) void
    {
        _ = widget;
        if(newState)
        {
            self.label_2.?.*.label = "Checked!";
        }
        else {
            self.label_2.?.*.label = "Not checked";
        }
    }   

    pub fn Activate(self: *App, allocator: std.mem.Allocator) !void
    {
        //allocate a gui
        self.gui = try allocator.create(gui.GuiApp(App));
        defer allocator.destroy(self.gui);

        //make some options 
        const appOptions: gui.GuiAppOptions = .{.allocator = allocator,
                                                .appTitle = "Test GUI App",
                                                .startingWindowSize = .{.x = 1000, .y = 800},
                                                .backgroundColor = .{.r = 30, .g = 30, .b = 30, .a=255}};

        //Init the gui with the options
        try self.gui.*.Init(self,appOptions);

        const rootWidget = self.gui.*.rootContainerWidget;

        const largeFont = try self.gui.*.AddFont("/usr/share/fonts/truetype/ubuntu/Ubuntu-C.ttf", 64);
        const smallFont = try self.gui.*.AddFont("/usr/share/fonts/truetype/ubuntu/Ubuntu-C.ttf", 32);

        if (rootWidget) |root|
        {

            var container_template: AppWidget = .{
                .label = "LeftPanel",
                .widgetType = gui.widgets.WidgetType(App){.Container = .{.allocator = allocator}},
                .size = .{.x = 480,.y = 780},
                .color = .{.r = 50, .g = 100, .b=100, .a = 255},
                .transform = .{.position = .{.x = 10, .y = 10}}
            };

            self.left_panel = root.*.addChildWidget(container_template);

            container_template = .{
                .label = "RightPanel",
                .widgetType = gui.widgets.WidgetType(App){.Container = .{.allocator = allocator}},
                .size = .{.x = 480,.y = 780},
                .color = .{.r = 100, .g = 50, .b=100, .a = 255},
                .transform = .{.position = .{.x = 510, .y = 10}}
            };

            self.right_panel = root.*.addChildWidget(container_template);

            container_template = .{
                .label = "SmallPanel",
                .widgetType = gui.widgets.WidgetType(App){.Container = .{.allocator = allocator}},
                .size = .{.x = 460,.y = 340},
                .color = .{.r = 150, .g = 150, .b=100, .a = 255},
                .transform = .{.position = .{.x = 10, .y = 350}}
            };

            self.small_panel = self.right_panel.?.*.addChildWidget(container_template);

            var button_template: AppWidget = .{
                .label = "Green Button",
                .widgetType = gui.widgets.WidgetType(App){ .Button = gui.widgets.Button(App){} }, //
                .size = .{ .x = 200, .y = 100},
                .color = .{.r = 0, .g = 200, .b = 0, .a = 255},
                .transform = gui.widgets.Transform{ .position = .{ .x = 10, .y = 10 } },
                .onMouseUp = OnClick1
            };

            //self.green_button = try root.*.widgetType.Container.addChildWidget(self.left_panel,button_template);
            //self.green_button = self.left_panel.?.*.addChildWidget(button_template);
            self.green_button = self.left_panel.?.*.addChildWidget(button_template);
            _ = self.small_panel.?.*.addChildWidget(button_template);

            button_template = .{
                .label = "Red Button",
                .widgetType = gui.widgets.WidgetType(App){ .Button = gui.widgets.Button(App){} }, //
                .size = .{ .x = 200, .y = 100},
                .color = .{.r = 200, .g = 0, .b = 0, .a = 255},
                .transform = gui.widgets.Transform{ .position = .{ .x = 10, .y = 10 } },
                .onMouseUp = OnClick2
            };

            self.red_button = self.right_panel.?.*.addChildWidget(button_template);

            var label_template: AppWidget = .{
                .label = "not set",
                .widgetType = gui.widgets.WidgetType(App){ .Label = gui.widgets.Label(App){.fontIndex = largeFont}},
                .size = .{.x = 300, .y = 75},
                .color = .{.r = 100, .g = 100, .b = 0, .a = 255},
                .transform = gui.widgets.Transform{ .position = .{ .x = 0, .y = 200 } },
            };        

            self.label_1 = self.left_panel.?.*.addChildWidget(label_template);

            label_template = .{
                .label = "Not checked",
                .widgetType = gui.widgets.WidgetType(App){ .Label = gui.widgets.Label(App){.fontIndex = smallFont}},
                .size = .{.x = 200, .y = 50},
                .color = .{.r = 200, .g = 200, .b = 200, .a = 255},
                .transform = gui.widgets.Transform{ .position = .{ .x = 0, .y = 200 } },
            };        

            self.label_2 =  self.right_panel.?.*.addChildWidget(label_template);

            const checkbox_template: AppWidget = .{
                .label = "check",
                .widgetType = gui.widgets.WidgetType(App){ 
                        .CheckBox = 
                        gui.widgets.CheckBox(App){.onCheckStateChanged = OnCheckToggle}
                        },
                .size = .{.x = 50, .y = 50},
                .color = .{.r = 200, .g = 200, .b = 200, .a = 255},
                .transform = gui.widgets.Transform{ .position = .{ .x = 10, .y = 120 } },
            
            };

            self.checkbox = self.left_panel.?.*.addChildWidget(checkbox_template);

            const slider_template: AppWidget = .{
                .label = "Slider1",
                .widgetType = gui.widgets.WidgetType(App){.Slider = .{.orientation = .HORIZONTAL, .minValue = 0, .maxValue = 100, .currentValue = 50}},
                .size = .{.x = 300, .y = 50},
                .color = .{.r = 30, .g = 0, .b = 200, .a = 255},
                .transform = .{.position = .{.x = 10, .y = 200}},
            };

            self.horizontal_slider = self.small_panel.?.*.addChildWidget(slider_template);

            //run the app until it quits
            try self.gui.*.Run();
        }
    }

};