//!Main program entry and loop
//! @Zane Youmans

const std = @import("std");
const app = @import("App.zig");

pub fn main() !void {

    var GPA = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = GPA.deinit();

    const allocator = GPA.allocator();

    const MyApp = try allocator.create(app.App);
    defer allocator.destroy(MyApp);

    try MyApp.*.Activate(allocator);

}
