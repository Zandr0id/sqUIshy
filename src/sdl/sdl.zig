//! This file is for putting wrappers around SDL functions called from C, so
//! we can keep the rest of the project clean and only deal with Zig functions
//! @Zane Youmans
const std = @import("std");
pub const types = @import("sdl_types.zig");
pub const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_ttf.h");
});

pub const WindowPtr = ?*c.SDL_Window;
pub const RendererPtr = ?*c.struct_SDL_Renderer;


pub const Event = c.SDL_Event;

pub const EventsEnum = enum(u32) {
    WINDOW_EVENT = c.SDL_WINDOWEVENT, //
    WINDOW_QUIT = c.SDL_QUIT,
    WINDOW_RESIZED = c.SDL_WINDOWEVENT_RESIZED,
    MOUSE_MOTION = c.SDL_MOUSEMOTION,
    MOUSE_BUTTONUP = c.SDL_MOUSEBUTTONUP,
    MOUSE_BUTTONDOWN = c.SDL_MOUSEBUTTONDOWN,
    _,
};



pub fn Init() !void {
    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        std.debug.print("SDL_Init Error: {s}\n", .{c.SDL_GetError()});
        return error.SDLInitFailed;
    }

    if (c.TTF_Init() != 0) {
    std.debug.print("TTF_Init failed: {s}\n", .{c.TTF_GetError()});
    return error.TTFInitFailed;
}
}

pub fn Quit() void {
    c.SDL_Quit();
}

pub const Window = struct {
    pub fn createWindow(title: []const u8, width: i32, height: i32) !WindowPtr {

        //we need to do some shenanigans to make the title string work correctly
        const allocator = std.heap.page_allocator;
        const dst = try allocator.alloc(u8, title.len);
        std.mem.copyForwards(u8, dst, title);
        defer allocator.free(dst);

        const window = c.SDL_CreateWindow(
            dst.ptr,
            c.SDL_WINDOWPOS_CENTERED,
            c.SDL_WINDOWPOS_CENTERED,
            width,
            height,
            c.SDL_WINDOW_SHOWN | c.SDL_WINDOW_RESIZABLE,
        );

        if (window == null) {
            std.debug.print("SDL_CreateWindow Error: {s}\n", .{c.SDL_GetError()});
            return error.SDLWindowCreationFailed;
        }

        return window;
    }

    pub fn destroyWindow(window: WindowPtr) void {
        if (window) |w| {
            c.SDL_DestroyWindow(w);
        }
    }
};

pub const Renderer = struct {
    pub fn createRenderer(window: WindowPtr) !RendererPtr {
        const renderer = c.SDL_CreateRenderer(window, -1, c.SDL_RENDERER_ACCELERATED);
        if (renderer == null) {
            std.debug.print("SDL_CreateRenderer Error: {s}\n", .{c.SDL_GetError()});
            return error.SDLRendererCreationFailed;
        }
        return renderer;
    }

    pub fn destroyRenderer(renderer: RendererPtr) void {
        c.SDL_DestroyRenderer(renderer);
    }
};
