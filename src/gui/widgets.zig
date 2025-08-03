//! Structs and Types for basic GUI widgets
//! @Zane Youmans

const std = @import("std");
const sdl = @import("../sdl/sdl.zig");
const guiApp = @import("GuiApp.zig");
const fonts = @import("fonts.zig");
const shapes = @import("../shapes/shapes.zig");

//const ttf = @cImport({@cInclude("SDL2/SDL_ttf.h");});

const WidgetErrors = error{
    CreateSurfaceFailed,
    CreateTextureFailed,
    OpenFontFailed,
    ChildrenListNotCreated,
    NoOwningGuiSet,
};

pub const WidgetHoverStates = enum(u8) { UNHOVERED, JUST_NOW_UNHOVERED, JUST_NOW_HOVERED, HOVERED };

pub const MouseButtonStates = enum(u8) { RELEASED, JUST_NOW_RELEASED, JUST_NOW_PRESSED, PRESSED };


pub const Transform = struct {
    position: shapes.Vec2(i32) = .{ .x = 0, .y = 0 }, //x,y
    rotation: f32 = undefined, //degrees
    scale: shapes.Vec2(f32) = .{ .x = 1.0, .y = 1.0 }, //x,y
};

pub fn Button(comptime WrapperType: type) type {
    return struct {
        fontIndex: ?usize = null,
        shape: shapes.Shape=.{.Rect=.{}},

        pub fn draw(self: *Button(WrapperType), widget: *Widget(WrapperType)) !void {
            const transfromedCoords = widget.*.relativeToGlobalCoordinates();
            const rect: sdl.c.SDL_Rect = sdl.c.SDL_Rect{
                .x = transfromedCoords.x, //
                .y = transfromedCoords.y,
                .h = widget.presentation.bounds.y,
                .w = widget.presentation.bounds.x,
            };

            var color: sdl.types.RGBAColor = widget.presentation.color;

            if (widget.*.hoverState == WidgetHoverStates.HOVERED) {
                if (widget.*.isMouseDown) {
                    color.r = 200;
                    color.g = 100;
                    color.b = 100;
                } else {
                    //lighten the color just a bit
                    color.r +|= 30;
                    color.g +|= 100;
                    color.b +|= 30;
                }
            }

            if (widget.*.owningGui) |gui| {
                _ = sdl.c.SDL_SetRenderDrawColor(gui.*.renderer, color.r, color.g, color.b, color.a);
                _ = sdl.c.SDL_RenderFillRect(gui.*.renderer, &rect);

                const fontIndex: usize = self.fontIndex orelse gui.*.fonts.items.len - 1;
                const font: ?*fonts.Font = gui.*.fonts.items[fontIndex];
                if (font) |f| {
                    _ = f;
                } else {
                    return error.OpenFontFailed;
                }

                const newColor: sdl.c.SDL_Color = .{ .r = 0, .g = 0, .b = 0, .a = 255 };
                const c_string: [*c]const u8 = @ptrCast(widget.*.label);

                const surface = sdl.c.TTF_RenderText_Blended(font.?.font, c_string, newColor);
                defer sdl.c.SDL_FreeSurface(surface);
                if (surface == null) {
                    return error.CreateSurfaceFailed;
                }

                const texture = sdl.c.SDL_CreateTextureFromSurface(gui.*.renderer, surface);
                defer sdl.c.SDL_DestroyTexture(texture);
                if (texture == null) {
                    return error.CreateTextureFailed;
                }
                _ = sdl.c.SDL_RenderCopy(gui.*.renderer, texture, null, &rect);
            } else {
                return error.NoOwningGuiSet;
            }
        }
    };
}

pub fn CheckBox(comptime WrapperType: type) type {
    return struct {
        checked: bool = false,

        onCheckStateChanged: ?*const fn (outer: *WrapperType, widget: *Widget(WrapperType), newState: bool) void = null,

        pub fn update(self: *CheckBox(WrapperType), widget: *Widget(WrapperType)) !void {
            if (widget.*.owningGui) |gui| {
                //if it's hovered and just clicked, flip state
                if (widget.*.hoverState == WidgetHoverStates.JUST_NOW_HOVERED or
                    widget.*.hoverState == WidgetHoverStates.HOVERED)
                {
                    if (gui.*.environment.mouseLeft == MouseButtonStates.JUST_NOW_PRESSED) {
                        if (self.checked) {
                            self.checked = false;
                        } else {
                            self.checked = true;
                        }

                        if (self.onCheckStateChanged) |callback| {
                            callback(gui.*.environment.wrapperApp, widget, self.checked);
                        }
                    }
                }
            } else {
                return error.NoOwningGuiSet;
            }
        }

        pub fn draw(self: *CheckBox(WrapperType), widget: *Widget(WrapperType)) !void {
            const transformedCoords = widget.*.relativeToGlobalCoordinates();
            const rect: sdl.c.SDL_Rect = sdl.c.SDL_Rect{
                .x = transformedCoords.x,
                .y = transformedCoords.y,
                .h = widget.presentation.bounds.y,
                .w = widget.presentation.bounds.x,
            };

            var color: sdl.types.RGBAColor = widget.presentation.color;

            if (widget.*.hoverState == WidgetHoverStates.HOVERED) {
                //lighten the color just a bit
                color.r +|= 30;
                color.g +|= 30;
                color.b +|= 30;
            }

            if (widget.*.owningGui) |gui| {
                _ = sdl.c.SDL_SetRenderDrawColor(gui.*.renderer, color.r, color.g, color.b, color.a);
                _ = sdl.c.SDL_RenderFillRect(gui.*.renderer, &rect);

                //fill in the center green if it's checked
                if (self.checked) {
                    _ = sdl.c.SDL_SetRenderDrawColor(gui.*.renderer, 0, 200, 0, 255);
                } else {
                    _ = sdl.c.SDL_SetRenderDrawColor(gui.*.renderer, 50, 50, 50, 255);
                }

                const border = 10;

                const checked_rect: sdl.c.SDL_Rect = sdl.c.SDL_Rect{
                    .x = transformedCoords.x + border, //
                    .y = transformedCoords.y + border,
                    .h = widget.presentation.bounds.y - (2 * border),
                    .w = widget.presentation.bounds.x - (2 * border),
                };

                _ = sdl.c.SDL_RenderFillRect(gui.*.renderer, &checked_rect);
            } else {
                return error.NoOwningGuiSet;
            }
        }
    };
}

pub fn Slider(comptime WrapperType: type) type 
{
    return struct {
        minValue: f32 = 0,
        maxValue: f32 = 100,
        currentValue: f32 = 50,
        orientation: enum(u2) {VERTICAL, HORIZONTAL} = .HORIZONTAL,

        //function pointer for updates
        onValueChanged: ?*fn(outer:*WrapperType, widget: *Widget(WrapperType), newState: bool) void = null,

        pub fn update(self: *Slider(WrapperType), widget: *Widget(WrapperType)) !void
        {
            _ = self;
            _ = widget;
        }

        pub fn draw(self: *Slider(WrapperType), widget: *Widget(WrapperType)) !void 
        {
            const transformedCoords = widget.*.relativeToGlobalCoordinates();
            var rect: sdl.c.SDL_Rect = sdl.c.SDL_Rect{
                .x = transformedCoords.x,
                .y = transformedCoords.y,
                .h = widget.presentation.bounds.y,
                .w = widget.presentation.bounds.x,
            };

            // Calculate ratio as floating point first, then convert to position
  
            const ratio = self.currentValue / self.maxValue;
            _ = ratio;
            // Calculate thumb position (leave some space for the thumb width)
          //  const thumb_width: f32 = 30;
           // const available_width: f32 = @as(f32,widget.bounds.x) - thumb_width;
           // const thumbPos: f32 = ratio * available_width;
            
            var thumbRect: sdl.c.SDL_Rect = sdl.c.SDL_Rect{
                .x = transformedCoords.x ,//+ thumbPos,
                .y = transformedCoords.y,
                .h = widget.presentation.bounds.y,
                .w = 30,
            };

            switch(self.orientation)
            {
                //swap the orientation
                .VERTICAL => {
                    var temp = rect.h;
                    rect.h = rect.w;
                    rect.w = temp;

                    temp = thumbRect.w;
                    thumbRect.w = thumbRect.h;
                    thumbRect.h = temp;
                },
                else =>{}
            }

            if (widget.*.owningGui) |gui|
            {
                //draw a background
                _ = sdl.c.SDL_SetRenderDrawColor(gui.*.renderer, 130, 130, 130, 255);
                _ = sdl.c.SDL_RenderFillRect(gui.*.renderer, &rect);

                //give it a border
                _ = sdl.c.SDL_SetRenderDrawColor(gui.*.renderer, 0, 0, 0, 255);
                _ = sdl.c.SDL_RenderDrawRect(gui.*.renderer, &rect);

                //make the draggable part
                _ = sdl.c.SDL_SetRenderDrawColor(gui.*.renderer,
                                                widget.*.presentation.color.r,
                                                widget.*.presentation.color.g,
                                                widget.*.presentation.color.b,
                                                255);
                _ = sdl.c.SDL_RenderFillRect(gui.*.renderer, &thumbRect);
            }
        }
    };
} 

pub fn Label(comptime WrapperType: type) type {
    return struct {
        fontIndex: usize,
        value: []const u8 = "",

        pub fn draw(self: *Label(WrapperType), widget: *Widget(WrapperType)) !void
        {

            //get the needed font from the list

            if (widget.*.owningGui) |gui| {
                const font: ?*fonts.Font = gui.*.fonts.items[self.fontIndex - 1];
                if (font) |f| {
                    _ = f;
                } else {
                    return error.OpenFontFailed;
                }


                const dims = try font.?.TextSize(widget.*.label);

                const transformedCoords = widget.*.relativeToGlobalCoordinates();

                const rect: sdl.c.SDL_Rect = sdl.c.SDL_Rect{
                    .x = transformedCoords.x, //
                    .y = transformedCoords.y,
                    .h = dims.h,
                    .w = dims.w,
                };

                const newColor: sdl.c.SDL_Color = .{ .r = widget.*.presentation.color.r,
                                                     .g = widget.*.presentation.color.g, 
                                                     .b = widget.*.presentation.color.b, 
                                                     .a = 255 };

                const c_string: [*c]const u8 = @ptrCast(widget.*.label);
                const surface = sdl.c.TTF_RenderText_Blended(font.?.font, c_string, newColor);
                defer sdl.c.SDL_FreeSurface(surface);
                if (surface == null) {
                    return error.CreateSurfaceFailed;
                }

                const texture = sdl.c.SDL_CreateTextureFromSurface(gui.*.renderer, surface);
                defer sdl.c.SDL_DestroyTexture(texture);
                if (texture == null) {
                    return error.CreateTextureFailed;
                }

                _ = sdl.c.SDL_RenderCopy(gui.*.renderer, texture, null, &rect);
            } else {
                return error.NoOwningGuiSet;
            }
        }
    };
}

pub fn Container(comptime WrapperType: type) type {
    return struct {
        allocator: ?std.mem.Allocator = null,
        childWidgets: ?std.ArrayList(*Widget(WrapperType)) = null,
        showBorder: bool = false,

        pub fn init(self: *Container(WrapperType), widget: *Widget(WrapperType), allocator: std.mem.Allocator) void {
            _ = widget;
            self.allocator = allocator;
            self.childWidgets = std.ArrayList(*Widget(WrapperType)).init(allocator);
        }

        //We're intentionally copying the newWidget by value here
        pub fn addChildWidget(self: *Container(WrapperType), parentWidget: ?*Widget(WrapperType), newWidget: Widget(WrapperType)) !*Widget(WrapperType) {
            //if children widgets have been initialized, add a new
            if (self.childWidgets) |*children|
            {
                const addedWidget = try self.*.allocator.?.create(Widget(WrapperType));
                addedWidget.* = newWidget;

                if (parentWidget) |widget| {
                    addedWidget.*.parent = widget;
                    if (widget.*.owningGui) |gui| {
                        addedWidget.*.owningGui = gui;
                    }
                }

                if (self.allocator) |a| {
                    addedWidget.init(a);
                }
                try children.append(addedWidget);
                return addedWidget;
            }

            return WidgetErrors.ChildrenListNotCreated;
        }

        pub fn update(self: *Container(WrapperType), widget: *Widget(WrapperType)) !void {
            _ = widget;
            if (self.childWidgets) |children| {
                for (children.items) |child| {
                    try child.update();
                }
            } else {
                return error.ChildrenListNotCreated;
            }
        }

        pub fn draw(self: *Container(WrapperType), widget: *Widget(WrapperType)) !void {
            if (widget.*.owningGui) |gui| {
                var rect: sdl.c.SDL_Rect = .{};
                const transformedCoords = widget.*.relativeToGlobalCoordinates();
                
                rect = .{.x = @intCast(transformedCoords.x), 
                        .y = @intCast(transformedCoords.y) ,
                        .h = widget.presentation.bounds.y,
                        .w = widget.presentation.bounds.x,
                        };
       
                _ = sdl.c.SDL_SetRenderDrawColor(gui.*.renderer, 
                                                widget.*.presentation.color.r,
                                                widget.*.presentation.color.g,
                                                widget.*.presentation.color.b,
                                                255);
                _ = sdl.c.SDL_RenderFillRect(gui.*.renderer, &rect);
            }

            if (self.childWidgets) |children| {
                for (children.items) |child| {
                    try child.draw();
                }
            } else {
                return error.ChildrenListNotCreated;
            }
        }

        pub fn shutdown(self: *Container(WrapperType)) void {
            if (self.childWidgets) |children| {
                for (children.items) |child| {
                    child.shutdown();
                    self.allocator.?.destroy(child);
                }
            }

            if (self.childWidgets) |array|
            {
                array.deinit();
            }


        }
    };
}

pub fn WidgetType(comptime WrapperType: type) type {
    return union(enum) {
        const SelfType = @This();

        Button: Button(WrapperType),
        CheckBox: CheckBox(WrapperType),
        Slider: Slider(WrapperType),
        Label: Label(WrapperType),
        Container: Container(WrapperType),

        //run these functions only on widget types that need them

        pub fn init(self: *SelfType, widget: *Widget(WrapperType), allocator: std.mem.Allocator) void {
            switch (self.*) {
                .Container => |*container| container.init(widget, allocator),
                else => {},
            }
        }

        pub fn update(self: *SelfType, widget: *Widget(WrapperType)) !void {
            switch (self.*) {
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
                .Slider => |*slider| try slider.draw( widget),
                //else => {},
            }
        }

        pub fn shutdown(self: *SelfType) void {
            switch (self.*) {
                .Container => |*container| container.shutdown(),
                else => {},
            }
        }

        pub fn addChildWidget(self: *SelfType, widget: *Widget(WrapperType), newWidget: Widget(WrapperType)) ?*Widget(WrapperType) {
            switch (self.*) { //TODO Do something smarter with the possible error here
                .Container => |*container| return container.addChildWidget(widget, newWidget) catch {
                    return null;
                },
                else => {
                    return null;
                },
            }
        }
    };
}

pub fn Widget(comptime WrapperType: type) type {
    return struct {
        //state data
        const SelfType = @This();

        label: []const u8 = "",
        presentation: struct{
            transform: Transform,
            bounds: shapes.Vec2(i32),
            shape: shapes.Shape,
            color: sdl.types.RGBAColor,
        },
        parent: ?*Widget(WrapperType) = null,
        owningGui: ?*guiApp.GuiApp(WrapperType) = null,
        hoverState: WidgetHoverStates = WidgetHoverStates.UNHOVERED,
        isMouseDown: bool = false,

        onHovered: ?*const fn (outer: *WrapperType, widget: *Widget(WrapperType)) void = null,
        onUnhovered: ?*const fn (outer: *WrapperType, widget: *Widget(WrapperType)) void = null,
        onMouseDown: ?*const fn (outer: *WrapperType, widget: *Widget(WrapperType)) void = null,
        onMouseUp: ?*const fn (outer: *WrapperType, widget: *Widget(WrapperType)) void = null,

        widgetType: WidgetType(WrapperType),

        pub fn init(self: *Widget(WrapperType), allocator: std.mem.Allocator) void {
            self.widgetType.init(self, allocator);
        }

        pub fn update(self: *Widget(WrapperType)) anyerror!void {
            if (self.owningGui) |gui| {
                const mousePos = gui.*.environment.mouseLocation;

                const widgetLocation = relativeToGlobalCoordinates(self);

                //are we currently hovered?
                //const latestHoverState = (mousePos.x >= widgetLocation.x) and
                //    (mousePos.x <= widgetLocation.x +| self.bounds.x) and
                //    (mousePos.y >= widgetLocation.y) and
                //    (mousePos.y <= widgetLocation.y +| self.bounds.y);

                const float_location = shapes.Vec2(f32){.x = @floatFromInt(widgetLocation.x + (@divTrunc(self.presentation.bounds.x, 2))), .y = @floatFromInt(widgetLocation.y + (@divTrunc(self.presentation.bounds.y, 2)))};
                const float_mouse_location =shapes.Vec2(f32){.x = @floatFromInt(mousePos.x), .y=@floatFromInt(mousePos.y)};

                const latestHoverState = self.presentation.shape.containsPoint(float_location,float_mouse_location);

                //std.debug.print("{}\n",.{self.hoverState});

                hoverStateCheck: switch (self.hoverState) {
                    WidgetHoverStates.UNHOVERED => {
                        if (true == latestHoverState) //we were unhovered, and we just stared
                        {
                            self.hoverState = WidgetHoverStates.HOVERED;
                            continue :hoverStateCheck WidgetHoverStates.JUST_NOW_HOVERED;
                        } else {
                            //TODO do something while remaining unhovered?
                        }
                    },
                    WidgetHoverStates.JUST_NOW_HOVERED => {
                        if (self.onHovered) |callback| {
                            callback(gui.*.environment.wrapperApp, self);
                        }
                        continue :hoverStateCheck WidgetHoverStates.HOVERED;
                    },
                    WidgetHoverStates.HOVERED => {
                        if (false == latestHoverState) //we were hovered, now we're not
                        {
                            self.hoverState = WidgetHoverStates.UNHOVERED;
                            continue :hoverStateCheck WidgetHoverStates.JUST_NOW_UNHOVERED;
                        } else {
                            //TODO do something while remaining hovered
                        }
                    },
                    WidgetHoverStates.JUST_NOW_UNHOVERED => {
                        if (self.onUnhovered) |callback| {
                            callback(gui.*.environment.wrapperApp, self);
                        }
                        continue :hoverStateCheck WidgetHoverStates.UNHOVERED;
                    },
                }

                //don't even try to run onClick if you're not hovered. Makes no sense.
                if (true == latestHoverState) {
                    mouseStateCheck: switch (gui.*.environment.mouseLeft) {
                        MouseButtonStates.JUST_NOW_PRESSED => {
                            if (self.onMouseDown) |callback| {
                                callback(gui.*.environment.wrapperApp, self);
                            }
                            self.isMouseDown = true;
                            continue :mouseStateCheck MouseButtonStates.PRESSED;
                        },
                        MouseButtonStates.PRESSED => {
                            //TODO mouse being held
                        },
                        MouseButtonStates.JUST_NOW_RELEASED => {
                            if (self.onMouseUp) |callback| {
                                callback(gui.*.environment.wrapperApp, self);
                            }
                            self.isMouseDown = false;
                            continue :mouseStateCheck MouseButtonStates.RELEASED;
                        },
                        MouseButtonStates.RELEASED => {
                            //TODO while mouse not pressed.
                            //probably do nothing here
                        },
                    }
                }

                try self.widgetType.update(self);
            } else {
                return error.NoOwningGuiSet;
            }
        }

        pub fn draw(self: *Widget(WrapperType)) anyerror!void {
            try self.widgetType.draw(self);
        }

        pub fn shutdown(self: *Widget(WrapperType)) void {
            self.widgetType.shutdown();
        }

        pub fn addChildWidget(self: *Widget(WrapperType), newWidget: Widget(WrapperType)) ?*Widget(WrapperType) {
            return self.widgetType.addChildWidget(self, newWidget);
        }

        //work up the parent widget chain, summing all cordinates to get to a global cordinates on the whole window
        //top left being 0,0
        pub fn relativeToGlobalCoordinates(self: *Widget(WrapperType)) shapes.Vec2(i32) {
            var ret: shapes.Vec2(i32) = .{ .x = self.presentation.transform.position.x, .y = self.presentation.transform.position.y };
            var parent = self.parent;

            while (parent) |p| : (parent = p.parent) {
                //ret = .{.x =  +| p.transform.position.x, .y = .y +| p.transform.position.y};
                ret.x +|= p.presentation.transform.position.x;
                ret.y +|= p.presentation.transform.position.y;
            }

            return ret;
        }
    };
}
