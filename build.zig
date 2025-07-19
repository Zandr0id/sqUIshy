const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "sdl2_zig",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = mode,
    });

    exe.linkSystemLibrary("SDL2");
    exe.linkLibC();
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    b.step("run", "Run the SDL2 app").dependOn(&run_cmd.step);
}
