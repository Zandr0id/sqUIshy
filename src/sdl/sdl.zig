//! This file is for putting wrappers around SDL functions called from C, so
//! we can keep the rest of the project clean and only deal with Zig functions
//! @Zane Youmans
const std = @import("std");
pub const types = @import("sdl_types.zig");
const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
});

pub const WindowPtr = ?*sdl.SDL_Window;
pub const RendererPtr = ?*sdl.struct_SDL_Renderer;

pub fn Init() !void {
    if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO) != 0) {
        std.debug.print("SDL_Init Error: {s}\n", .{sdl.SDL_GetError()});
        return error.SDLInitFailed;
    }
}

pub fn Quit() void {
    sdl.SDL_Quit();
}

pub const Window = struct {
    pub fn createWindow(title: []const u8, width: i32, height: i32) !WindowPtr {

        //we need to do some shenanigans to make the title string work correctly
        const allocator = std.heap.page_allocator;
        const dst = try allocator.alloc(u8, title.len);
        std.mem.copyForwards(u8, dst, title);
        defer allocator.free(dst);

        const window = sdl.SDL_CreateWindow(
            dst.ptr,
            sdl.SDL_WINDOWPOS_CENTERED,
            sdl.SDL_WINDOWPOS_CENTERED,
            width,
            height,
            sdl.SDL_WINDOW_SHOWN | sdl.SDL_WINDOW_RESIZABLE,
        );

        if (window == null) {
            std.debug.print("SDL_CreateWindow Error: {s}\n", .{sdl.SDL_GetError()});
            return error.SDLWindowCreationFailed;
        }

        return window;
    }

    pub fn destroyWindow(window: WindowPtr) void {
        if (window) |w| {
            sdl.SDL_DestroyWindow(w);
        }
    }
};

pub const Renderer = struct {
    pub fn createRenderer(window: WindowPtr) !RendererPtr {
        const renderer = sdl.SDL_CreateRenderer(window, -1, sdl.SDL_RENDERER_ACCELERATED);
        if (renderer == null) {
            std.debug.print("SDL_CreateRenderer Error: {s}\n", .{sdl.SDL_GetError()});
            return error.SDLRendererCreationFailed;
        }
        return renderer;
    }

    pub fn destroyRenderer(renderer: RendererPtr) void {
        sdl.SDL_DestroyRenderer(renderer);
    }
};
