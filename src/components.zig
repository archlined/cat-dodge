const std = @import("std");
const rl = @import("raylib");
const State = @import("state.zig");

pub var list_Position = std.AutoArrayHashMap(u64, Position).init(State.allocator);
pub var list_Shape = std.AutoArrayHashMap(u64, Shape).init(State.allocator);
pub var list_Velocity = std.AutoArrayHashMap(u64, Velocity).init(State.allocator);
pub var list_Animation = std.AutoArrayHashMap(u64, Animation).init(State.allocator);
pub var list_PlayerTag = std.AutoArrayHashMap(u64, PlayerTag).init(State.allocator);
pub var list_GenericEnemyTag = std.AutoArrayHashMap(u64, GenericEnemyTag).init(State.allocator);
pub var list_Health = std.AutoArrayHashMap(u64, Health).init(State.allocator);

pub const Position = rl.Vector2;
pub const Shape = union(enum) {
    /// x is width, y is height
    rectangle: rl.Vector2,
    /// radius
    circle: f32,

    _,

    pub fn width(self: Shape) f32 {
        switch (self) {
            .rectangle => |x| return x.x,
            .circle => |x| return x * 2,
            else => @panic("Unknown shape"),
        }
    }

    pub fn height(self: Shape) f32 {
        switch (self) {
            .rectangle => |x| return x.y,
            .circle => |x| return x * 2,
            else => @panic("Unknown shape"),
        }
    }
};
pub const Velocity = rl.Vector2;
pub const Animation = struct {
    texture: rl.Texture,
    split_interval: i32,
    split_time: f32,
    should_loop: bool,
    current_time: f64 = 0.0,
    current_frame: i32 = 0,
    offset_from_position: rl.Vector2 = .{ .x = 0, .y = 0 },
    // for horizontal or vertical flipping
    orientation: rl.Vector2 = .{ .x = 1, .y = 1 },

    pub fn get(self: *Animation, dt: f64) rl.Rectangle {
        self.current_time += dt;
        const frame_n = @divFloor(@as(i32, @intCast(self.texture.width)), self.split_interval);

        if (self.current_time >= self.split_time) {
            self.current_time = 0.0;
            if (self.current_frame + 1 >= frame_n) {
                if (self.should_loop) {
                    self.current_frame = 0;
                }
            } else {
                self.current_frame += 1;
            }
        }

        const height = @as(f32, @floatFromInt(self.texture.height)) * self.orientation.y;
        const width = @as(f32, @floatFromInt(self.split_interval)) * self.orientation.x;
        return rl.Rectangle{
            .y = 0,
            .x = @as(f32, @floatFromInt(self.current_frame * self.split_interval)),
            .height = height,
            .width = width,
        };
    }

    pub fn flipHorizontal(self: *Animation) void {
        self.orientation.x *= -1;
    }

    pub fn flipVertical(self: *Animation) void {
        self.orientation.y *= -1;
    }

    pub fn fromTexture(txt: rl.Texture) Animation {
        return Animation{
            .texture = txt,
            .split_interval = txt.width,
            .split_time = 1.0,
            .should_loop = false,
        };
    }
};

pub const PlayerTag = struct {};
pub const GenericEnemyTag = struct {};
pub const Health = struct {};

pub fn resetAll() void {
    list_Position.clearRetainingCapacity();
    list_Shape.clearRetainingCapacity();
    list_Velocity.clearRetainingCapacity();
    list_Animation.clearRetainingCapacity();
    list_PlayerTag.clearRetainingCapacity();
    list_GenericEnemyTag.clearRetainingCapacity();
    list_Health.clearRetainingCapacity();
}

pub fn deinit() void {
    list_Position.deinit();
    list_Shape.deinit();
    list_Velocity.deinit();
    list_Animation.deinit();
    list_PlayerTag.deinit();
    list_GenericEnemyTag.deinit();
    list_Health.deinit();
}
