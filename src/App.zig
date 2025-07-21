const std = @import("std");
const gui = @import("gui/GuiApp.zig");

pub const App = struct {

    const AppWidget = gui.widgets.Widget(App);

    gui: *gui.GuiApp(App) = undefined,

    button_1: *AppWidget = undefined,
    button_2: *AppWidget = undefined,
    label_1: *AppWidget = undefined,
    label_2: *AppWidget = undefined,
    checkbox: *AppWidget = undefined,

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
        self.label_1.label = "Green Pressed";
        self.label_1.color.r = 0;
        self.label_1.color.g = 200;
    }

    pub fn ChangeText2(self: *App) void
    {
        self.label_1.label = "Red Pressed";
        self.label_1.color.r = 200;
        self.label_1.color.g = 0;
    }

    pub fn Activate(self: *App, allocator: std.mem.Allocator) !void
    {
        //allocate a gui
        self.gui = try allocator.create(gui.GuiApp);
        defer allocator.destroy(self.gui);

        //make some options 
        const appOptions: gui.GuiAppOptions = .{.allocator = allocator,
                                                .appTitle = "Test GUI App",
                                                .startingWindowSize = .{.x = 1000, .y = 800},
                                                .backgroundColor = .{.r = 30, .g = 30, .b = 30, .a=255}};

        //Init the gui with the options
        try self.gui.*.Init(appOptions,@This());

        var button_template: AppWidget = .{
            .label = "Green Button",
            .widgetType = gui.widgets.WidgetType(App){ .Button = gui.widgets.Button{} }, //
            .size = .{ .x = 200, .y = 100},
            .color = gui.widgets.RGBAColor.Create(0, 200, 0, 255),
            .transform = gui.widgets.Transform{ .position = .{ .x = 0, .y = 0 } },
            .onMouseUp = OnClick1
        };

        const button_1 = try self.gui.*.AddWidget(button_template);
        _ = button_1;

        button_template = .{
            .label = "Red Button",
            .widgetType = gui.widgets.WidgetType(App){ .Button = gui.widgets.Button{} }, //
            .size = .{ .x = 200, .y = 100},
            .color = gui.widgets.RGBAColor.Create(200, 0, 0, 255),
            .transform = gui.widgets.Transform{ .position = .{ .x = 220, .y = 0 } },
            .onMouseUp = OnClick2
        };

        const button_2 = try self.gui.*.AddWidget(button_template);
        _ = button_2;

        const label_template: AppWidget = .{
            .label = "not set",
            .widgetType = gui.widgets.WidgetType(App){ .Label = gui.widgets.Label{}},
            .size = .{.x = 300, .y = 75},
            .color = gui.widgets.RGBAColor.Create(0, 0, 0, 255),
            .transform = gui.widgets.Transform{ .position = .{ .x = 0, .y = 200 } },
        };        

        const label_1 = try self.gui.*.AddWidget(label_template);
        _ = label_1;

        //run the app until it quits
        try self.gui.*.Run();
    }

};