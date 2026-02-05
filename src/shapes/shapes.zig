const std = @import("std");

const PI = 3.141592654;

pub fn Vec2(comptime T: type) type {
    return struct {
        x: T,
        y: T,

        //Thanks Pythagoras!
        pub fn length(self: Vec2(T)) f32
        {
            return @sqrt( (self.x * self.x) + (self.y * self.y));
        }

        pub fn add(a: Vec2(T), b: Vec2(T)) Vec2(T){
            return Vec2(T){.x = a.x + b.x, .y = a.y + b.y};
        }

        pub fn subtract(a: Vec2(T), b: Vec2(T)) Vec2(T){
            return Vec2(T){.x = a.x - b.x, .y = a.y - b.y};
        }
    };
}

pub fn Vec3(comptime T: type) type {
    return struct {
        x: T,
        y: T,
        z: T,
    };
}

pub const Circle = struct{
    radius: f32 = 1.0,

    pub fn perimeter(self: *Circle) f32
    {
        return 2 * PI * self.radius;
    }

    pub fn area(self: *Circle) f32
    {
        return PI * self.radius * self.radius;
    }

    pub fn sdf(self: *Circle, center: Vec2(f32), point: Vec2(f32)) f32
    {
        return Vec2(f32).subtract(point, center).length() - self.radius;
    }
};

pub const Rect = struct {
    size: Vec2(f32) = .{.x = 1.0, .y = 1.0},

    pub fn area(self: *Rect) f32
    {
        return (self.size.x) * (self.size.y);
    }

    pub fn perimeter(self: *Rect) f32
    {
        return (self.size.x*2) + (self.size.y*2);
    }

    pub fn sdf(self: *Rect, center: Vec2(f32), point: Vec2(f32)) f32
    {
        const p = Vec2(f32).subtract(point, center);
        const d = Vec2(f32){
            .x = @abs(p.x) - (self.size.x / 2),
            .y = @abs(p.y) - (self.size.y / 2),
        };
        const outside = Vec2(f32){
            .x = @max(d.x, 0),
            .y = @max(d.y, 0),
        };
        const outside_dist = @sqrt(outside.x * outside.x + outside.y * outside.y);
        const inside_dist = @min(@max(d.x, d.y), 0);
        return outside_dist + inside_dist;
    }

};

//TODO: Get this working to make complex shapes out of primatives
const CompositShape = struct {
    center: Vec2(f32),
    shapes: []Shape,
};

//The Shape interface. All the this set of functions should be implemented by other shapes.
pub const Shape = union(enum) {
    Circle: Circle,
    Rect: Rect,

    pub fn area(self: *Shape) f32
    {
        switch(self.*){
            .Circle =>|*circle| {return circle.area();},
            .Rect => |*rect| {return rect.area();},
        }
    }

    pub fn perimeter(self: *Shape) f32
    {
        switch(self.*){
            .Circle =>|*circle| {return circle.perimeter();},
            .Rect => |*rect| {return rect.perimeter();},
        }
    }

    pub fn sdf(self: *Shape, center: Vec2(f32), point: Vec2(f32)) f32
    {
        switch(self.*){
            .Circle => |*circle| {return circle.sdf(center,point);},
            .Rect => |*rect| {return rect.sdf(center,point);},
        }
    }

    pub fn containsPoint(self: *Shape, center: Vec2(f32), point: Vec2(f32)) bool
    {
        return self.sdf(center, point) <= 0;
    }

    pub fn getBounds(self: *Shape) Vec2(f32) {
        switch (self.*) {
            .Circle => |circle| return .{ .x = circle.radius * 2, .y = circle.radius * 2 },
            .Rect => |rect| return rect.size,
        }
    }
};
