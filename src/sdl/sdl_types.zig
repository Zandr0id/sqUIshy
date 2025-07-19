const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
});

pub const Event = sdl.SDL_Event;

pub const EventsEnum = enum(u32) {
    WINDOW_EVENT = sdl.SDL_WINDOWEVENT, //
    WINDOW_QUIT = sdl.SDL_QUIT,
    WINDOW_RESIZED = sdl.SDL_WINDOWEVENT_RESIZED,
    MOUSE_MOTION = sdl.SDL_MOUSEMOTION,
    MOUSE_BUTTONUP = sdl.SDL_MOUSEBUTTONUP,
    MOUSE_BUTTONDOWN = sdl.SDL_MOUSEBUTTONDOWN,
    _,
};
