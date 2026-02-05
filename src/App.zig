const std = @import("std");
const builtin = @import("builtin");
const sdl = @import("sdl/sdl_types.zig");
const gui = @import("gui/GuiApp.zig");
const fonts = @import("gui/fonts.zig");

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

    // Buffer for dynamic label text
    label_buffer: [8]u8 = [_]u8{'\n'} ** 8,

    pub fn OnClick1(self: *App, widget: *AppWidget) void {
        try self.horizontal_slider.?.widgetType.Slider.setValue(widget, 0.0);
    }

    pub fn onSliderChanged(self: *App, widget: *AppWidget, newValue: f32) void {
        _ = widget;
        // Format the value into the buffer
        const formatted = std.fmt.bufPrintZ(&self.label_buffer, "{d:.1}", .{newValue}) catch "Error";
        // Update the green button's label
        if (self.green_button) |button| {
            button.label = formatted;
        }
    }

    pub fn Activate(self: *App, allocator: std.mem.Allocator) !void {
        //allocate a gui
        self.gui = try allocator.create(gui.GuiApp(App));
        defer allocator.destroy(self.gui);

        //make some options
        const appOptions: gui.GuiAppOptions = .{ .allocator = allocator, .appTitle = "Test GUI App", .startingWindowSize = .{ .x = 1000, .y = 800 }, .backgroundColor = .{ .r = 30, .g = 30, .b = 30, .a = 255 } };

        //Init the gui with the options
        try self.gui.*.Init(self, appOptions);

        const rootWidget = self.gui.*.rootContainerWidget;

        //const largeFont = try self.gui.*.AddFont(getSystemFontPath(), 64);
        const smallFont = try self.gui.*.AddFont(getSystemFontPath(), 32);
        _ = smallFont;
        if (rootWidget) |root| {

            const button_template: AppWidget = .{
                .label = "Green Button",
                .widgetType = gui.widgets.WidgetType(App){ .Button = gui.widgets.Button(App){ .fontIndex = 0 } },
                .presentation = .{
                    .shape = .{ .Rect = .{ .size = .{ .x = 300, .y = 100 } } },
                    .color = .{ .r = 0, .g = 200, .b = 0, .a = 255 },
                    .transform = gui.widgets.Transform{ .position = .{ .x = 10, .y = 10 } },
                },
                .onMouseUp = OnClick1,
            };

            self.green_button = root.*.addChildWidget(button_template);

            const circle_button: AppWidget = .{
                .label = "Red Button",
                .widgetType = gui.widgets.WidgetType(App){ .Button = gui.widgets.Button(App){ .fontIndex = 0 } },
                .presentation = .{
                    .shape = .{ .Circle = .{ .radius = 50 } },
                    .color = .{ .r = 200, .g = 0, .b = 0, .a = 255 },
                    .transform = gui.widgets.Transform{ .position = .{ .x = 350, .y = 10 } },
                },
                .onMouseUp = OnClick1,
            };

            self.red_button = root.*.addChildWidget(circle_button);

            const slider_template: AppWidget = .{
                .label = "",
                .widgetType = gui.widgets.WidgetType(App){ .Slider = gui.widgets.Slider(App){
                    .minValue = 0,
                    .maxValue = 100,
                    .currentValue = 25,
                    .orientation = .HORIZONTAL,
                    .onValueChanged = onSliderChanged,
                } },
                .presentation = .{
                    .shape = .{ .Rect = .{ .size = .{ .x = 300, .y = 30 } } },
                    .color = .{ .r = 100, .g = 150, .b = 200, .a = 255 },
                    .transform = gui.widgets.Transform{ .position = .{ .x = 10, .y = 130 } },
                },
            };

            self.horizontal_slider = root.*.addChildWidget(slider_template);

            //run the app until it quits
            try self.gui.*.Run();
        }
    }
};

//TODO: move this to a more appropriate place
pub fn getSystemFontPath() []const u8 {
    switch (builtin.target.os.tag) {
        .macos => {
            return "/System/Library/Fonts/Supplemental/Arial.ttf";
        },
        .windows => {
            return "C:\\Windows\\Fonts\\arial.ttf";
        },
        else => {
            const linux_paths = [_][]const u8{
                "/usr/share/fonts/truetype/ubuntu/Ubuntu-C.ttf",
                "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
                "/usr/share/fonts/TTF/arial.ttf",
                "/usr/share/fonts/liberation/LiberationSans-Regular.ttf",
                "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
            };

            return linux_paths[0];
        },
    }
}
