//! Structs and Types for basic GUI widgets
//! @Zane Youmans

const std = @import("std");
const sdl = @import("../sdl/sdl.zig");
const guiApp = @import("GuiApp.zig");
const fonts = @import("fonts.zig");

//const ttf = @cImport({@cInclude("SDL2/SDL_ttf.h");});

const WidgetErrors = error{
    CreateSurfaceFailed,
    CreateTextureFailed,
    OpenFontFailed,
    ChildrenListNotCreated,
    WidgetArenaNotCreated,
    NoOwningGuiSet,
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

pub const Transform = struct {
    position: Vec2(i32) = .{ .x = 0, .y = 0 }, //x,y
    rotation: f32 = undefined, //degrees
    scale: Vec2(f32) = .{ .x = 1.0, .y = 1.0 }, //x,y
};

pub fn Button(comptime WrapperType: type) type{
    
    return struct {

        pub fn draw(self: *Button(WrapperType), widget: *Widget(WrapperType)) !void {
            _ = self;

            const rect: sdl.c.SDL_Rect = sdl.c.SDL_Rect{
                .x = widget.transform.position.x, //
                .y =widget.transform.position.y,
                .h = widget.size.y,
                .w = widget.size.x,
            };

            var color: sdl.types.RGBAColor = widget.color;

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
            
            //TODO: Open fonts somewhere once and make them accessable to all widgets
            //Perhaps up at the GuiApp level

            if (widget.*.owningGui) |gui|
            {

                _ = sdl.c.SDL_SetRenderDrawColor(gui.*.renderer, color.r, color.g, color.b, color.a);
                _ = sdl.c.SDL_RenderFillRect(gui.*.renderer, &rect);
                const font = sdl.c.TTF_OpenFont("/usr/share/fonts/truetype/ubuntu/Ubuntu-C.ttf", 64);
                defer sdl.c.TTF_CloseFont(font);
                if (font == null)
                {
                    return error.OpenFontFailed;
                } 
            
                const newColor: sdl.c.SDL_Color = .{.r = 0,.g = 0, .b =0,.a = 255};

                const c_string: [*c]const u8 = @ptrCast(widget.*.label);

                const surface = sdl.c.TTF_RenderText_Blended(font, c_string, newColor);
                defer sdl.c.SDL_FreeSurface(surface);
                if (surface == null)
                {
                    return error.CreateSurfaceFailed;
                }

                const texture = sdl.c.SDL_CreateTextureFromSurface(gui.*.renderer, surface);
                defer sdl.c.SDL_DestroyTexture(texture);
                if (texture == null)
                {
                    return error.CreateTextureFailed;
                } 
                _ = sdl.c.SDL_RenderCopy(gui.*.renderer, texture, null, &rect);
            }
            else {
                return error.NoOwningGuiSet;
            }
        }
    };
}

pub fn CheckBox(comptime WrapperType: type) type
{
    return struct {
        checked: bool = false,

        onCheckStateChanged: ?*const fn(outer:*WrapperType, widget: *Widget(WrapperType), newState: bool) void = null,

        pub fn update(self: *CheckBox(WrapperType), widget: *Widget(WrapperType)) !void{
            
            if (widget.*.owningGui) |gui|
            {  
                //if it's hovered and just clicked, flip state
                if (widget.*.hoverState == WidgetHoverStates.JUST_NOW_HOVERED or 
                    widget.*.hoverState == WidgetHoverStates.HOVERED)
                {
                    
                    if (gui.*.environment.mouseLeft == MouseButtonStates.JUST_NOW_PRESSED)
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
                            callback(gui.*.environment.wrapperApp,widget, self.checked);
                        }
                    }
                }
            }
            else {
                return error.NoOwningGuiSet;
            }
        }

        pub fn draw(self: *CheckBox(WrapperType), widget: *Widget(WrapperType)) !void {

            const rect: sdl.c.SDL_Rect = sdl.c.SDL_Rect{
                .x = widget.transform.position.x, //
                .y =widget.transform.position.y,
                .h = widget.size.y,
                .w = widget.size.x,
            };

            var color: sdl.types.RGBAColor = widget.color;

            if (widget.*.hoverState == WidgetHoverStates.HOVERED)
            {
                //lighten the color just a bit
                color.r +|= 30;
                color.g +|= 30;
                color.b +|= 30;
                
            }

            if (widget.*.owningGui) |gui|
            {
            
                _ = sdl.c.SDL_SetRenderDrawColor(gui.*.renderer, color.r, color.g, color.b, color.a);
                _ = sdl.c.SDL_RenderFillRect(gui.*.renderer, &rect);

                //fill in the center green if it's checked
                if (self.checked)
                {
                    _ = sdl.c.SDL_SetRenderDrawColor(gui.*.renderer, 0, 200, 0, 255);
                }
                else 
                {
                    _ = sdl.c.SDL_SetRenderDrawColor(gui.*.renderer, 50, 50, 50, 255);
                }

                const border = 10;

                const checked_rect: sdl.c.SDL_Rect = sdl.c.SDL_Rect{
                .x = widget.transform.position.x + border, //
                .y =widget.transform.position.y + border,
                .h = widget.size.y - (2*border),
                .w = widget.size.x - (2*border),
                };

                _ = sdl.c.SDL_RenderFillRect(gui.*.renderer, &checked_rect);
            }
            else {
                return error.NoOwningGuiSet;
            }
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
        fontIndex: usize,
        value: []const u8 = "",

        pub fn draw(self: *Label(WrapperType), widget: *Widget(WrapperType)) !void
        {
   
            //TODO: Open fonts somewhere once and make them accessable to all widgets
            //Perhaps up at the GuiApp level

            //const font = sdl.c.TTF_OpenFont("/usr/share/fonts/truetype/ubuntu/Ubuntu-C.ttf", 36);
            //defer sdl.c.TTF_CloseFont(font);

            //get the needed font from the list

            if (widget.*.owningGui) |gui|
            {

                const font: ?*fonts.Font = gui.*.fonts.items[self.fontIndex-1];
                if (font) |f|
                {
                    _=f;
                } 
                else 
                {
                    return error.OpenFontFailed;
                }

                //var h: c_int = undefined;
                //var w: c_int = undefined;

                //_ = sdl.c.TTF_SizeText(font, widget.*.label, &w, &h);

                const dims = try font.?.TextSize(widget.*.label);

                const rect: sdl.c.SDL_Rect = sdl.c.SDL_Rect{
                    .x = widget.transform.position.x, //
                    .y =widget.transform.position.y,
                    .h = dims.h,
                    .w = dims.w,
                };

                const newColor: sdl.c.SDL_Color = .{.r = widget.*.color.r,.g = widget.*.color.g, .b = widget.*.color.b,.a = 255};

                const c_string: [*c]const u8 = @ptrCast(widget.*.label);
                const surface = sdl.c.TTF_RenderText_Blended(font.?.font, c_string, newColor);
                defer sdl.c.SDL_FreeSurface(surface);
                if (surface == null)
                {
                    return error.CreateSurfaceFailed;
                }

                const texture = sdl.c.SDL_CreateTextureFromSurface(gui.*.renderer, surface);
                defer sdl.c.SDL_DestroyTexture(texture);
                if (texture == null)
                {
                    return error.CreateTextureFailed;
                } 

                _ = sdl.c.SDL_RenderCopy(gui.*.renderer, texture, null, &rect);
            }
            else {
                return error.NoOwningGuiSet;
            }
        }
    };
}

pub fn Container(comptime WrapperType: type) type
{
    return struct {
        allocator: ?std.mem.Allocator = null,
        childWidgets: ?std.ArrayList(*Widget(WrapperType)) = null,
        arena: ?std.heap.ArenaAllocator = null,
        showBorder: bool = false,

        pub fn init(self: *Container(WrapperType), widget: *Widget(WrapperType), allocator: std.mem.Allocator) void
        {
            _ = widget;
            self.allocator = allocator;
            self.arena = std.heap.ArenaAllocator.init(allocator);
            self.childWidgets = std.ArrayList(*Widget(WrapperType)).init(allocator);
        }

        //We're intentionally copying the newWidget by value here
        pub fn addChildWidget(self: *Container(WrapperType), widget: *Widget(WrapperType), newWidget: Widget(WrapperType)) !*Widget(WrapperType)
        {
            //if children widgets have been initialized, add a new
            if (self.childWidgets) |*children|
            {
                const allocator = self.arena.?.allocator();
                const addedWidget = try allocator.create(Widget(WrapperType));
                addedWidget.* = newWidget;
                addedWidget.*.parent = widget;

                if (widget.*.owningGui) |gui|
                {
                    addedWidget.*.owningGui = gui;
                }

                try children.append(addedWidget);
                return addedWidget;
            }

            return WidgetErrors.ChildrenListNotCreated;
        }

        pub fn update(self: *Container(WrapperType), widget: *Widget(WrapperType)) !void
        {
            _ = widget;
            if (self.childWidgets) |children|
            {
                for(children.items) |child|
                {
                    try child.update();
                }
            }
            else 
            {
                return error.ChildrenListNotCreated;
            }
        }

        pub fn draw(self: *Container(WrapperType), widget: *Widget(WrapperType)) !void 
        {
            _ = widget;
            if (self.childWidgets) |children|
            {
                for(children.items) |child|
                {
                    try child.draw();
                }
            }
            else 
            {
                return error.ChildrenListNotCreated;
            }
        }

        pub fn shutdown(self: *Container(WrapperType)) void 
        {
            if (self.childWidgets) |children|
            {
                for(children.items) |child|
                {
                    child.shutdown();
                }
            }

            if (self.arena) |arena|
            {
                arena.deinit();
            }

            if (self.childWidgets) |array|
            {
                array.deinit();
            }
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
        Container: Container(WrapperType),

        //run these functions only on widget types that need them

        pub fn init(self: *SelfType, widget: *Widget(WrapperType), allocator: std.mem.Allocator) void
        {
            switch(self.*){
                .Container => |*container| container.init(widget, allocator),
                else => {},
            }
        }

        pub fn update(self: *SelfType, widget: *Widget(WrapperType)) !void
        {
            switch(self.*) {
                //.Button => |*button| try button.update(widget),
                .CheckBox => |*checkbox| try checkbox.update(widget),
                .Container => |*container| try container.update(widget),
                else => {},
            }
        }

        pub fn draw(self: *SelfType, widget: *Widget(WrapperType)) !void {
            switch (self.*) {
                .Button => |*button| try button.draw(widget),
                .CheckBox => |*checkBox| try checkBox.draw(widget),
                .Label => |*label| try label.draw(widget),
                .Container => |*container| try container.draw(widget),
                //.Slider => |*slider| slider.draw(self, widget),
                else => {},
            }
        }

        pub fn shutdown(self: *SelfType) void {
            switch (self.*) {
                .Container => |*container| container.shutdown(),
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

        label: []const u8 = "", //TODO: Make this not have to be a *c array. It's needed for SDL_ttf for now.
        transform: Transform, 
        size: Vec2(i32),
        color: sdl.types.RGBAColor,
        parent: *Widget(WrapperType) = undefined,
        owningGui: ?*guiApp.GuiApp(WrapperType) = null,
        hoverState: WidgetHoverStates = WidgetHoverStates.UNHOVERED,
        isMouseDown: bool = false,

        onHovered: ?*const fn(outer:*WrapperType, widget: *Widget(WrapperType)) void = null,
        onUnhovered: ?*const fn(outer:*WrapperType, widget: *Widget(WrapperType)) void = null,
        onMouseDown: ?*const fn(outer:*WrapperType, widget: *Widget(WrapperType)) void = null,
        onMouseUp: ?*const fn(outer:*WrapperType, widget: *Widget(WrapperType)) void = null,

        widgetType: WidgetType(WrapperType),

        pub fn init(self: *Widget(WrapperType), allocator: std.mem.Allocator) void
        {
            self.widgetType.init(self, allocator);
        }

        pub fn update(self: *Widget(WrapperType)) anyerror!void {

            if (self.owningGui) |gui|
            {

                const mousePos = gui.*.environment.mouseLocation;
                const widgetLocation = self.transform.position;

                //are we currently hovered?
                const latestHoverState = (mousePos.x >= widgetLocation.x) and
                                    (mousePos.x <= widgetLocation.x +| self.size.x) and
                                    (mousePos.y >= widgetLocation.y) and
                                    (mousePos.y <= widgetLocation.y +| self.size.y);

                //std.debug.print("{}\n",.{self.hoverState});

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
                            callback(gui.*.environment.wrapperApp,self);
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
                            callback(gui.*.environment.wrapperApp,self);
                        }
                        continue: hoverStateCheck WidgetHoverStates.UNHOVERED;
                    }
                }

                //don't even try to run onClick if you're not hovered. Makes no sense.
                if (true == latestHoverState)  
                {
                    mouseStateCheck: switch(gui.*.environment.mouseLeft)
                    {
                        MouseButtonStates.JUST_NOW_PRESSED=>
                        {
                            if (self.onMouseDown) |callback|
                            {
                                callback(gui.*.environment.wrapperApp,self);
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
                                callback(gui.*.environment.wrapperApp,self);
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

                try self.widgetType.update(self);
            }
            else {
                return error.NoOwningGuiSet;
            }
        }

        pub fn draw(self: *Widget(WrapperType)) anyerror!void {
            try self.widgetType.draw(self);
        }

        pub fn shutdown(self: *Widget(WrapperType)) void {
            self.widgetType.shutdown();
        }
    };
}
