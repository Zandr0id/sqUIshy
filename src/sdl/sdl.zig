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

    pub fn setDrawColor(renderer: RendererPtr, color: types.RGBAColor) void
    {
        if (renderer) |r|
        {
            _ = c.SDL_SetRenderDrawColor(r, color.r, color.g, color.b, color.a);
        }
    }

    pub fn clearScreenToColor(renderer: RendererPtr, color: types.RGBAColor) void
    {
        if (renderer) |r|
        {
            var oldColor: types.RGBAColor = .{};

            _ = c.SDL_GetRenderDrawColor(r, &(oldColor.r), &(oldColor.g), &(oldColor.b), &(oldColor.a));
            setDrawColor(r, color);
            _ = c.SDL_RenderClear(r);
            setDrawColor(r, oldColor);
        }
    }

    /// Draw a filled circle using horizontal scanlines
    pub fn fillCircle(renderer: RendererPtr, centerX: i32, centerY: i32, radius: i32) void {
        if (renderer) |r| {
            var y: i32 = -radius;
            while (y <= radius) : (y += 1) {
                // Calculate x extent at this y using circle equation: x^2 + y^2 = r^2
                const y_f: f32 = @floatFromInt(y);
                const r_f: f32 = @floatFromInt(radius);
                const x_extent: i32 = @intFromFloat(@sqrt(r_f * r_f - y_f * y_f));

                _ = c.SDL_RenderDrawLine(r, centerX - x_extent, centerY + y, centerX + x_extent, centerY + y);
            }
        }
    }

    /// Draw a filled rectangle
    pub fn fillRect(renderer: RendererPtr, x: i32, y: i32, w: i32, h: i32) void {
        if (renderer) |r| {
            const rect: c.SDL_Rect = .{ .x = x, .y = y, .w = w, .h = h };
            _ = c.SDL_RenderFillRect(r, &rect);
        }
    }
};
