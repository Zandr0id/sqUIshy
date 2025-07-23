const sdl = @import("../sdl/sdl.zig");
const std = @import("std");

const FontErrors = error
{
    FailedToOpenFont,
    FailedToGetTextRect,
    FontAlreadyLoaded
};

pub const Font = struct 
{
    font: ?*sdl.c.struct__TTF_Font = null,
    size: usize = undefined,

    pub fn LoadFont(self: *Font, path: []const u8, size: usize) FontErrors!void
    {
       // if (self.font) |f|
       // {
       //     _ = f;
       //     return FontErrors.FontAlreadyLoaded;
       // }
        const c_string: [*c]const u8 = @ptrCast(path.ptr);
        const c_size:c_int = @intCast(size);

        self.font = sdl.c.TTF_OpenFont(c_string, c_size);

        if (self.font) |f|
        {
            _ = f;
            self.size = size;
        }
        else 
        {
            const err = sdl.c.TTF_GetError();
            std.debug.print("Failed to open font: {s}\n", .{err});
            return FontErrors.FailedToOpenFont;
        }
    }

    pub fn TextSize(self: *Font, text: []const u8) !struct {w: c_int, h: c_int}
    {
        var w: c_int = undefined;
        var h: c_int = undefined;
       
        if (self.font) |f|
        {
            const c_string: [*c]const u8 = @ptrCast(text);
            const worked = sdl.c.TTF_SizeText(f, c_string, &w, &h);

            if (worked == -1)
            {
                return FontErrors.FailedToGetTextRect;
            }
        }
        else {
            return FontErrors.FailedToGetTextRect;
        }

        return .{.w = w, .h = h};
    }

};