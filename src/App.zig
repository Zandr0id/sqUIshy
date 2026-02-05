const std = @import("std");
const builtin = @import("builtin");
const sdl = @import("sdl/sdl_types.zig");
const gui = @import("gui/GuiApp.zig");
const fonts = @import("gui/fonts.zig");

pub const App = struct {
    const AppWidget = gui.widgets.Widget(App);

    gui: *gui.GuiApp(App) = undefined,

    // Calculator display
    display: ?*AppWidget = null,

    // Calculator state
    display_buffer: [32]u8 = [_]u8{0} ** 32,
    current_value: f64 = 0,
    pending_value: f64 = 0,
    pending_op: ?u8 = null,
    clear_on_next: bool = true,

    pub fn onButtonPress(self: *App, widget: *AppWidget) void {
        const label = widget.label;
        if (label.len == 0) return;

        const char = label[0];

        switch (char) {
            '0'...'9' => self.inputDigit(char),
            '+', '-', '*', '/' => self.inputOperator(char),
            '=' => self.calculate(),
            'C' => self.clear(),
            else => {},
        }

        self.updateDisplay();
    }

    fn inputDigit(self: *App, digit: u8) void {
        if (self.clear_on_next) {
            self.current_value = 0;
            self.clear_on_next = false;
        }

        // Append digit to current value
        if (self.current_value >= 0) {
            self.current_value = self.current_value * 10 + @as(f64, @floatFromInt(digit - '0'));
        } else {
            self.current_value = self.current_value * 10 - @as(f64, @floatFromInt(digit - '0'));
        }
    }

    fn inputOperator(self: *App, op: u8) void {
        if (self.pending_op != null) {
            self.calculate();
        }
        self.pending_value = self.current_value;
        self.pending_op = op;
        self.clear_on_next = true;
    }

    fn calculate(self: *App) void {
        if (self.pending_op) |op| {
            self.current_value = switch (op) {
                '+' => self.pending_value + self.current_value,
                '-' => self.pending_value - self.current_value,
                '*' => self.pending_value * self.current_value,
                '/' => if (self.current_value != 0) self.pending_value / self.current_value else 0,
                else => self.current_value,
            };
            self.pending_op = null;
        }
        self.clear_on_next = true;
    }

    fn clear(self: *App) void {
        self.current_value = 0;
        self.pending_value = 0;
        self.pending_op = null;
        self.clear_on_next = true;
    }

    fn updateDisplay(self: *App) void {
        _ = std.fmt.bufPrintZ(&self.display_buffer, "{d:.6}", .{self.current_value}) catch {
            if (self.display) |disp| {
                disp.label = "Error";
            }
            return;
        };

        // Trim trailing zeros after decimal point
        var end: usize = 0;
        while (end < self.display_buffer.len and self.display_buffer[end] != 0) : (end += 1) {}

        if (std.mem.indexOf(u8, self.display_buffer[0..end], ".")) |dot_idx| {
            while (end > dot_idx + 1 and self.display_buffer[end - 1] == '0') {
                end -= 1;
            }
            if (end == dot_idx + 1) {
                end = dot_idx; // Remove the decimal point too if no decimals
            }
        }

        // Null-terminate at the new end
        self.display_buffer[end] = 0;

        if (self.display) |disp| {
            disp.label = self.display_buffer[0..end :0];
        }
    }

    pub fn Activate(self: *App, allocator: std.mem.Allocator) !void {
        // Initialize calculator state
        self.current_value = 0;
        self.pending_value = 0;
        self.pending_op = null;
        self.clear_on_next = true;
        self.display_buffer = [_]u8{0} ** 32;
        self.display = null;

        self.gui = try allocator.create(gui.GuiApp(App));
        defer allocator.destroy(self.gui);

        const appOptions: gui.GuiAppOptions = .{
            .allocator = allocator,
            .appTitle = "Calculator",
            .startingWindowSize = .{ .x = 340, .y = 500 },
            .backgroundColor = .{ .r = 40, .g = 40, .b = 40, .a = 255 },
        };

        try self.gui.*.Init(self, appOptions);

        const rootWidget = self.gui.*.rootContainerWidget;
        _ = try self.gui.*.AddFont(getSystemFontPath(), 32);

        if (rootWidget) |root| {
            // Display container (background)
            const display_container: AppWidget = .{
                .label = "",
                .widgetType = gui.widgets.WidgetType(App){ .Container = .{} },
                .presentation = .{
                    .shape = .{ .Rect = .{ .size = .{ .x = 300, .y = 60 } } },
                    .color = .{ .r = 60, .g = 60, .b = 60, .a = 255 },
                    .transform = gui.widgets.Transform{ .position = .{ .x = 20, .y = 20 } },
                },
            };
            const display_box = root.*.addChildWidget(display_container);

            // Display label (inside container)
            if (display_box) |box| {
                const display_label: AppWidget = .{
                    .label = "0",
                    .widgetType = gui.widgets.WidgetType(App){ .Label = gui.widgets.Label(App){ .fontIndex = 1 } },
                    .presentation = .{
                        .shape = .{ .Rect = .{ .size = .{ .x = 280, .y = 40 } } },
                        .color = .{ .r = 255, .g = 255, .b = 255, .a = 255 },
                        .transform = gui.widgets.Transform{ .position = .{ .x = 10, .y = 10 } },
                    },
                };
                self.display = box.*.addChildWidget(display_label);
            }

            // Button layout constants
            const btn_size: f32 = 70;
            const btn_gap: i32 = 5;
            const start_x: i32 = 20;
            const start_y: i32 = 100;

            // Button labels in grid order (4 columns x 5 rows)
            const buttons = [_][]const u8{
                "C", " ", " ", "/",
                "7", "8", "9", "*",
                "4", "5", "6", "-",
                "1", "2", "3", "+",
                "0", " ", "=", "",
            };

            const colors = [_]sdl.RGBAColor{
                .{ .r = 200, .g = 100, .b = 100, .a = 255 }, // C - red
                .{ .r = 100, .g = 100, .b = 100, .a = 255 }, // ( - gray
                .{ .r = 100, .g = 100, .b = 100, .a = 255 }, // ) - gray
                .{ .r = 255, .g = 160, .b = 0, .a = 255 },   // / - orange
                .{ .r = 80, .g = 80, .b = 80, .a = 255 },    // 7
                .{ .r = 80, .g = 80, .b = 80, .a = 255 },    // 8
                .{ .r = 80, .g = 80, .b = 80, .a = 255 },    // 9
                .{ .r = 255, .g = 160, .b = 0, .a = 255 },   // *
                .{ .r = 80, .g = 80, .b = 80, .a = 255 },    // 4
                .{ .r = 80, .g = 80, .b = 80, .a = 255 },    // 5
                .{ .r = 80, .g = 80, .b = 80, .a = 255 },    // 6
                .{ .r = 255, .g = 160, .b = 0, .a = 255 },   // -
                .{ .r = 80, .g = 80, .b = 80, .a = 255 },    // 1
                .{ .r = 80, .g = 80, .b = 80, .a = 255 },    // 2
                .{ .r = 80, .g = 80, .b = 80, .a = 255 },    // 3
                .{ .r = 255, .g = 160, .b = 0, .a = 255 },   // +
                .{ .r = 80, .g = 80, .b = 80, .a = 255 },    // 0
                .{ .r = 80, .g = 80, .b = 80, .a = 255 },    // .
                .{ .r = 100, .g = 180, .b = 100, .a = 255 }, // = - green
                .{ .r = 40, .g = 40, .b = 40, .a = 255 },    // empty
            };

            // Create buttons
            for (buttons, 0..) |label, i| {
                if (label.len == 0) continue;

                const col: i32 = @intCast(i % 4);
                const row: i32 = @intCast(i / 4);
                const x = start_x + col * (@as(i32, @intFromFloat(btn_size)) + btn_gap);
                const y = start_y + row * (@as(i32, @intFromFloat(btn_size)) + btn_gap);

                const btn: AppWidget = .{
                    .label = label,
                    .widgetType = gui.widgets.WidgetType(App){ .Button = gui.widgets.Button(App){ .fontIndex = 0 } },
                    .presentation = .{
                        .shape = .{ .Rect = .{ .size = .{ .x = btn_size, .y = btn_size } } },
                        .color = colors[i],
                        .transform = gui.widgets.Transform{ .position = .{ .x = x, .y = y } },
                    },
                    .onMouseUp = onButtonPress,
                };
                _ = root.*.addChildWidget(btn);
            }

            try self.gui.*.Run();
        }
    }
};

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
