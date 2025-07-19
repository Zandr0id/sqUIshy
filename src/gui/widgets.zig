//! Structs and Types for basic GUI widgets
//! @Zane Youmans

const std = @import("std");
const sdl = @import("../sdl/sdl.zig");

//TODO: get this out of here and wrap all the drawing function in the sdl.zig file
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

//Any global UI data can go here
pub const UIContext = struct {
    renderer: sdl.RendererPtr,
    windowSize: Vec2(i32) = .{.x = 0, .y=0},
    mouseLocation: Vec2(i32) = .{.x = 0,.y = 0},
    mouseLeft: MouseButtonStates = MouseButtonStates.RELEASED,
    mouseRight: MouseButtonStates = MouseButtonStates.RELEASED,
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

pub const Button = struct {

    pub fn update(self: *Button, widgetType: *WidgetType, widget: *Widget) void
    {
        _ = widgetType;
        _ = self;
        const mousePos = widget.*.context.*.mouseLocation;
        const widgetLocation = widget.*.transform.position;

        //are we currently hovered?
        const latestHoverState = (mousePos.x >= widgetLocation.x) and
                            (mousePos.x <= widgetLocation.x + widget.*.size.x) and
                            (mousePos.y >= widgetLocation.y) and
                            (mousePos.y <= widgetLocation.y + widget.*.size.y);



        hoverStateCheck: switch(widget.*.hoverState)
        {
            WidgetHoverStates.UNHOVERED=>
            {
                
                if (true == latestHoverState) //we were unhovered, and we just stared
                {
                    widget.*.hoverState = WidgetHoverStates.HOVERED;
                    continue: hoverStateCheck WidgetHoverStates.JUST_NOW_HOVERED;
                }
                else 
                {
                    //TODO do something while remaining unhovered?
                }
            },
            WidgetHoverStates.JUST_NOW_HOVERED=>
            {
                if (widget.*.onHovered) |callback|
                {
                    callback(widget);
                }
                continue: hoverStateCheck WidgetHoverStates.HOVERED;
            },
            WidgetHoverStates.HOVERED=>
            {
                if (false == latestHoverState) //we were hovered, now we're not
                {
                    widget.*.hoverState = WidgetHoverStates.UNHOVERED;
                    continue: hoverStateCheck WidgetHoverStates.JUST_NOW_UNHOVERED;
                }
                else 
                {
                    //TODO do something while remaining hovered
                }
            },
            WidgetHoverStates.JUST_NOW_UNHOVERED=>
            {
                if (widget.*.onUnhovered) |callback|
                {
                    callback(widget);
                }
                continue: hoverStateCheck WidgetHoverStates.UNHOVERED;
            }
        }

        //don't even try to run onClick if you're not hovered. Makes no sense.
        if (true == latestHoverState)  
        {
            mouseStateCheck: switch(widget.context.mouseLeft)
            {
                MouseButtonStates.JUST_NOW_PRESSED=>
                {
                    if (widget.*.onMouseDown) |callback|
                    {
                        callback(widget);
                    }
                    widget.*.isMouseDown = true;
                    continue :mouseStateCheck MouseButtonStates.PRESSED;
                },
                MouseButtonStates.PRESSED=>
                {
                    //TODO mouse being held
                },
                MouseButtonStates.JUST_NOW_RELEASED=>
                {
                    if (widget.*.onMouseUp) |callback|
                    {
                        callback(widget);
                    }
                    widget.*.isMouseDown = false;
                    continue :mouseStateCheck MouseButtonStates.RELEASED;
                },
                MouseButtonStates.RELEASED=>
                {
                    //TODO while mouse not pressed.
                    //probably do nothing here
                }
            }
        }
    }

    pub fn draw(self: *Button, widgetType: *WidgetType, widget: *Widget) void {
        _ = self;
        _ = widgetType;

        const rect: c.SDL_Rect = c.SDL_Rect{
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
        
        _ = c.SDL_SetRenderDrawColor(widget.context.*.renderer, color.r, color.g, color.b, color.a);
        _ = c.SDL_RenderFillRect(widget.context.*.renderer, &rect);
    }
};

pub const CheckBox = struct {
    checked: bool = false,

    pub fn draw(self: *Button, widgetType: *WidgetType, widget: *Widget) void {
        _ = self;
        _ = widget;
        _ = widgetType;
    }
};

pub const Slider = struct {
    minValue: u32 = 0,
    maxValue: u32 = 100,
    currentValue: u32 = 0,

    pub fn draw(self: *Button, widgetType: *WidgetType, widget: *Widget) void {
        _ = self;
        _ = widget;
        _ = widgetType;
    }
};

pub const WidgetType = union(enum) {
    Button: Button,
    CheckBox: CheckBox,
    Slider: Slider,

    pub fn update(self: *WidgetType, widget: *Widget) void
    {
        switch(self.*) {
            .Button => |*button| button.update(self,widget),
            else => {},
        }
    }

    pub fn draw(self: *WidgetType, widget: *Widget) void {
        switch (self.*) {
            .Button => |*button| button.draw(self, widget),
            //.CheckBox => |*checkBox| checkBox.draw(self, widget),
            //.Slider => |*slider| slider.draw(self, widget),
            else => {},
        }
    }
};

pub const Widget = struct {
    //state data
    label: []const u8 = "",
    transform: Transform, //
    size: Vec2(i32), //length,width
    color: RGBAColor,
    parent: *Widget = undefined,
    context: *const UIContext,
    hoverState: WidgetHoverStates = WidgetHoverStates.UNHOVERED,
    isMouseDown: bool = false,

    onHovered: ?*const fn(widget: *Widget) void = null,
    onUnhovered: ?*const fn(widget: *Widget) void = null,
    onMouseDown: ?*const fn(widget: *Widget) void = null,
    onMouseUp: ?*const fn(widget: *Widget) void = null,

    widgetType: WidgetType,

    pub fn update(self: *Widget) void {
        self.widgetType.update(self);
    }

    pub fn draw(self: *Widget) void {
        self.widgetType.draw(self);
    }
};
