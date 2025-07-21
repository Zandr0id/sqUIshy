//! Structs and Types for basic GUI widgets
//! @Zane Youmans

const std = @import("std");
const sdl = @import("../sdl/sdl.zig");
const guiApp = @import("GuiApp.zig");

//const ttf = @cImport({@cInclude("SDL2/SDL_ttf.h");});

const WidgetErrors = error{
    CreateSurfaceFailed,
    CreateTextureFailed,
    OpenFontFailed,
};

pub const WidgetHoverStates = enum(u8){
    UNHOVERED,
    JUST_NOW_UNHOVERED,
    JUST_NOW_HOVERED,
    HOVERED
};

pub const MouseButtonStates = enum(u8)
{
    RELEASED,
    JUST_NOW_RELEASED,
    JUST_NOW_PRESSED,
    PRESSED
};


pub fn Vec2(comptime T: type) type {
    return struct{

        x: T = undefined,
        y: T = undefined,

        pub fn Create(pos_x: T, pos_y: T) @This() {
            return 
            .{
                .x = pos_x,
                .y = pos_y,
            };
        }
    };
}

pub const RGBAColor = struct {
    r: u8 = 0,
    g: u8 = 0,
    b: u8 = 0,
    a: u8 = 0,

    pub fn Create(r: u8, g: u8, b: u8, a: u8) RGBAColor {
        return RGBAColor{
            .r = r, //
            .g = g,
            .b = b,
            .a = a,
        };
    }

    pub fn AsInt32() u32 {
        return (.r << 24) + (.g << 16) + (.b << 8) + .a;
    }
};

pub const Transform = struct {
    position: Vec2(i32) = .{ .x = 0, .y = 0 }, //x,y
    rotation: f32 = undefined, //degrees
    scale: Vec2(f32) = .{ .x = 1.0, .y = 1.0 }, //x,y
};

pub fn Button(comptime WrapperType: type) type{
    
    return struct {
        pub fn update(self: *Button(WrapperType), widget: *Widget(WrapperType)) void
        {
            _ = self;
            _ = widget;

            //Buttons don't really need to update anything unique to them since they don't hold any state

        }

        pub fn draw(self: *Button(WrapperType), widget: *Widget(WrapperType)) !void {
            _ = self;

            const rect: sdl.c.SDL_Rect = sdl.c.SDL_Rect{
                .x = widget.transform.position.x, //
                .y =widget.transform.position.y,
                .h = widget.size.y,
                .w = widget.size.x,
            };

            var color: RGBAColor = widget.color;

            if (widget.*.hoverState == WidgetHoverStates.HOVERED)
            {
                if (widget.*.isMouseDown)
                {
                    color.r = 200;
                    color.g = 100;
                    color.b = 100;
                }
                else
                {
                    //lighten the color just a bit
                    color.r +|= 30;
                    color.g +|= 100;
                    color.b +|= 30;
                }
            }
            
            _ = sdl.c.SDL_SetRenderDrawColor(widget.*.owningGui.*.renderer, color.r, color.g, color.b, color.a);
            _ = sdl.c.SDL_RenderFillRect(widget.*.owningGui.*.renderer, &rect);
            const font = sdl.c.TTF_OpenFont("/usr/share/fonts/truetype/ubuntu/Ubuntu-C.ttf", 64);
            if (font == null)
            {
                return error.OpenFontFailed;
            } 
        
            const newColor: sdl.c.SDL_Color = .{.r = 0,.g = 0, .b =0,.a = 255};
            const surface = sdl.c.TTF_RenderText_Blended(font, widget.*.label, newColor);
            if (surface == null)
            {
                return error.CreateSurfaceFailed;
            }

            const texture = sdl.c.SDL_CreateTextureFromSurface(widget.*.owningGui.*.renderer, surface);
            if (texture == null)
            {
                return error.CreateTextureFailed;
            } 

            sdl.c.SDL_FreeSurface(surface);
            _ = sdl.c.SDL_RenderCopy(widget.*.owningGui.*.renderer, texture, null, &rect);
        }
    };
}

pub fn CheckBox(comptime WrapperType: type) type
{
    return struct {
        checked: bool = false,

        onCheckStateChanged: ?*const fn(outer:*WrapperType, widget: *Widget(WrapperType), newState: bool) void = null,

        pub fn update(self: *CheckBox(WrapperType), widget: *Widget(WrapperType)) void{
            
            //if it's hovered and just clicked, flip state
            if (widget.*.hoverState == WidgetHoverStates.JUST_NOW_HOVERED or 
                widget.*.hoverState == WidgetHoverStates.HOVERED)
            {
                
                if (widget.*.owningGui.*.environment.mouseLeft == MouseButtonStates.JUST_NOW_PRESSED)
                {
                    if (self.checked)
                    {
                        self.checked = false;
                    }
                    else
                    {
                        self.checked = true;
                    }
                    
                    if (self.onCheckStateChanged) |callback|
                    {
                        callback(widget.owningGui.*.environment.wrapperApp,widget, self.checked);
                    }
                }
            }
        }

        pub fn draw(self: *CheckBox(WrapperType), widget: *Widget(WrapperType)) !void {

            const rect: sdl.c.SDL_Rect = sdl.c.SDL_Rect{
                .x = widget.transform.position.x, //
                .y =widget.transform.position.y,
                .h = widget.size.y,
                .w = widget.size.x,
            };

            var color: RGBAColor = widget.color;

            if (widget.*.hoverState == WidgetHoverStates.HOVERED)
            {
                //lighten the color just a bit
                color.r +|= 30;
                color.g +|= 30;
                color.b +|= 30;
                
            }

            _ = sdl.c.SDL_SetRenderDrawColor(widget.owningGui.*.renderer, color.r, color.g, color.b, color.a);
            _ = sdl.c.SDL_RenderFillRect(widget.owningGui.*.renderer, &rect);

            //fill in the center green if it's checked
            if (self.checked)
            {
                _ = sdl.c.SDL_SetRenderDrawColor(widget.owningGui.*.renderer, 0, 200, 0, 255);
            }
            else 
            {
                _ = sdl.c.SDL_SetRenderDrawColor(widget.owningGui.*.renderer, 50, 50, 50, 255);
            }
                const border = 10;

                const checked_rect: sdl.c.SDL_Rect = sdl.c.SDL_Rect{
                .x = widget.transform.position.x + border, //
                .y =widget.transform.position.y + border,
                .h = widget.size.y - (2*border),
                .w = widget.size.x - (2*border),
                };

                _ = sdl.c.SDL_RenderFillRect(widget.owningGui.*.renderer, &checked_rect);
        }
    };
}

pub const Slider = struct {
    minValue: u32 = 0,
    maxValue: u32 = 100,
    currentValue: u32 = 0,

    pub fn draw(self: *Slider, widget: *Widget) !void 
    {
        _ = self;
        _ = widget;
    }
};

pub fn Label(comptime WrapperType: type) type
{
    return struct {
        value: []const u8 = "",

        pub fn draw(self: *Label(WrapperType), widget: *Widget(WrapperType)) !void
        {
            _ = self;

            const rect: sdl.c.SDL_Rect = sdl.c.SDL_Rect{
                .x = widget.transform.position.x, //
                .y =widget.transform.position.y,
                .h = widget.size.y,
                .w = widget.size.x,
            };

            const font = sdl.c.TTF_OpenFont("/usr/share/fonts/truetype/ubuntu/Ubuntu-C.ttf", 64);
            if (font == null)
            {
                return error.OpenFontFailed;
            } 
        
            const newColor: sdl.c.SDL_Color = .{.r = widget.*.color.r,.g = widget.*.color.g, .b =widget.*.color.b,.a = 255};
            const surface = sdl.c.TTF_RenderText_Blended(font, widget.*.label, newColor);
            if (surface == null)
            {
                return error.CreateSurfaceFailed;
            }

            const texture = sdl.c.SDL_CreateTextureFromSurface(widget.*.owningGui.*.renderer, surface);
            if (texture == null)
            {
                return error.CreateTextureFailed;
            } 

            sdl.c.SDL_FreeSurface(surface);
            _ = sdl.c.SDL_RenderCopy(widget.*.owningGui.*.renderer, texture, null, &rect);
        }
    };
}

pub fn WidgetType(comptime WrapperType: type) type
{
    return union(enum) {
        const SelfType = @This();

        Button: Button(WrapperType),
        CheckBox: CheckBox(WrapperType),
        Slider: Slider,
        Label: Label(WrapperType),

        pub fn update(self: *SelfType, widget: *Widget(WrapperType)) void
        {
            switch(self.*) {
                .Button => |*button| button.update(widget),
                .CheckBox => |*checkbox| checkbox.update(widget),
                else => {},
            }
        }

        pub fn draw(self: *SelfType, widget: *Widget(WrapperType)) !void {
            switch (self.*) {
                .Button => |*button| try button.draw(widget),
                .CheckBox => |*checkBox| try checkBox.draw(widget),
                .Label => |*label| try label.draw(widget),
                //.Slider => |*slider| slider.draw(self, widget),
                else => {},
            }
        }
    };
}

pub fn Widget(comptime WrapperType: type) type
{
    return struct {
        //state data
        const SelfType = @This();

        label: [*c]const u8 = "", //TODO: Make this not have to be a *c array. It's needed for SDL_ttf for now.
        transform: Transform, 
        size: Vec2(i32),
        color: RGBAColor,
        parent: *Widget(WrapperType) = undefined,
        owningGui: *guiApp.GuiApp(WrapperType) = undefined,
        hoverState: WidgetHoverStates = WidgetHoverStates.UNHOVERED,
        isMouseDown: bool = false,

        onHovered: ?*const fn(outer:*WrapperType, widget: *Widget(WrapperType)) void = null,
        onUnhovered: ?*const fn(outer:*WrapperType, widget: *Widget(WrapperType)) void = null,
        onMouseDown: ?*const fn(outer:*WrapperType, widget: *Widget(WrapperType)) void = null,
        onMouseUp: ?*const fn(outer:*WrapperType, widget: *Widget(WrapperType)) void = null,

        widgetType: WidgetType(WrapperType),

        pub fn update(self: *Widget(WrapperType)) void {
            const mousePos = self.owningGui.*.environment.mouseLocation;
            const widgetLocation = self.transform.position;

            //are we currently hovered?
            const latestHoverState = (mousePos.x >= widgetLocation.x) and
                                (mousePos.x <= widgetLocation.x + self.size.x) and
                                (mousePos.y >= widgetLocation.y) and
                                (mousePos.y <= widgetLocation.y + self.size.y);

            hoverStateCheck: switch(self.hoverState)
            {
                WidgetHoverStates.UNHOVERED=>
                {
                    
                    if (true == latestHoverState) //we were unhovered, and we just stared
                    {
                        self.hoverState = WidgetHoverStates.HOVERED;
                        continue: hoverStateCheck WidgetHoverStates.JUST_NOW_HOVERED;
                    }
                    else 
                    {
                        //TODO do something while remaining unhovered?
                    }
                },
                WidgetHoverStates.JUST_NOW_HOVERED=>
                {
                    if (self.onHovered) |callback|
                    {
                        callback(self.owningGui.*.environment.wrapperApp,self);
                    }
                    continue: hoverStateCheck WidgetHoverStates.HOVERED;
                },
                WidgetHoverStates.HOVERED=>
                {
                    if (false == latestHoverState) //we were hovered, now we're not
                    {
                        self.hoverState = WidgetHoverStates.UNHOVERED;
                        continue: hoverStateCheck WidgetHoverStates.JUST_NOW_UNHOVERED;
                    }
                    else 
                    {
                        //TODO do something while remaining hovered
                    }
                },
                WidgetHoverStates.JUST_NOW_UNHOVERED=>
                {
                    if (self.onUnhovered) |callback|
                    {
                        callback(self.owningGui.*.environment.wrapperApp,self);
                    }
                    continue: hoverStateCheck WidgetHoverStates.UNHOVERED;
                }
            }

            //don't even try to run onClick if you're not hovered. Makes no sense.
            if (true == latestHoverState)  
            {
                mouseStateCheck: switch(self.owningGui.*.environment.mouseLeft)
                {
                    MouseButtonStates.JUST_NOW_PRESSED=>
                    {
                        if (self.onMouseDown) |callback|
                        {
                            callback(self.owningGui.*.environment.wrapperApp,self);
                        }
                        self.isMouseDown = true;
                        continue :mouseStateCheck MouseButtonStates.PRESSED;
                    },
                    MouseButtonStates.PRESSED=>
                    {
                        //TODO mouse being held
                    },
                    MouseButtonStates.JUST_NOW_RELEASED=>
                    {
                        if (self.onMouseUp) |callback|
                        {
                            callback(self.owningGui.*.environment.wrapperApp,self);
                        }
                        self.isMouseDown = false;
                        continue :mouseStateCheck MouseButtonStates.RELEASED;
                    },
                    MouseButtonStates.RELEASED=>
                    {
                        //TODO while mouse not pressed.
                        //probably do nothing here
                    }
                }
            }

            self.widgetType.update(self);
        }

        pub fn draw(self: *Widget(WrapperType)) !void {
            try self.widgetType.draw(self);
        }
    };
}
