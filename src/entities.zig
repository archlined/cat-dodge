const std = @import("std");
const rl = @import("raylib");

const Components = @import("components.zig");
const State = @import("state.zig");

pub var next_id: u64 = 0;

pub fn getIncNextID() u64 {
    const res = std.math.add(u64, next_id, 1) catch {
        @panic("Entities can no longer have unique IDs {}");
    };
    next_id = res;
    return res;
}

pub fn createPlayer() void {
    const id = getIncNextID();
    const anim = Components.Animation{
        .split_interval = 32,
        .should_loop = true,
        .split_time = 0.2,
        .texture = State.Textures.cat_idle,
        .offset_from_position = .{
            .x = 20,
            .y = -5,
        },
    };
    const pos = State.Rendering.virtual_midpoint;
    const shape = Components.Shape{ .circle = 30 };

    Components.list_Position.put(id, pos) catch unreachable;
    Components.list_PlayerTag.put(id, Components.PlayerTag{}) catch unreachable;
    Components.list_Animation.put(id, anim) catch unreachable;
    Components.list_Shape.put(id, shape) catch unreachable;
}

pub fn createGenericEnemy(position: rl.Vector2) void {
    _ = position;
    const id = getIncNextID();

    const anim = Components.Animation{
        .texture = State.Textures.cat_box,
        .split_interval = 32,
        .split_time = 0.2,
        .should_loop = true,
    };

    const rp = rl.Vector2{
        .x = @as(f32, @floatFromInt(rl.getRandomValue(0, State.Rendering.virtual_width))),
        .y = @as(f32, @floatFromInt(rl.getRandomValue(0, State.Rendering.virtual_height))),
    };

    const rv = rl.Vector2{
        .x = @as(f32, @floatFromInt(rl.getRandomValue(1, 5 * 60))),
        .y = @as(f32, @floatFromInt(rl.getRandomValue(1, 5 * 60))),
    };

    const shape: Components.Shape = .{ .circle = 30 };

    const tag = Components.GenericEnemyTag{};

    Components.list_Animation.put(id, anim) catch unreachable;
    Components.list_Position.put(id, rp) catch unreachable;
    Components.list_Velocity.put(id, rv) catch unreachable;
    Components.list_Shape.put(id, shape) catch unreachable;
    Components.list_GenericEnemyTag.put(id, tag) catch unreachable;
}

pub fn removeGenericEnemy(id: u64) void {
    _ = Components.list_Animation.swapRemove(id);
    _ = Components.list_Position.swapRemove(id) catch unreachable;
    _ = Components.list_Velocity.swapRemove(id) catch unreachable;
    _ = Components.list_Shape.swapRemove(id) catch unreachable;
    _ = Components.list_GenericEnemyTag.swapRemove(id) catch unreachable;
}

pub fn createGenericCat() void {
    const id = getIncNextID();

    const cat = Components.Animation{
        .split_interval = 32,
        .should_loop = true,
        .split_time = 0.2,
        .texture = State.Textures.cat_idle,
    };

    Components.list_Animation.put(id, cat) catch unreachable;
    Components.list_Position.put(id, .{
        .x = 300,
        .y = 225,
    }) catch unreachable;
    Components.list_Velocity.put(id, .{
        .x = 0,
        .y = 0,
    }) catch unreachable;
}

pub fn createHealth(position: rl.Vector2) void {
    const id = getIncNextID();

    Components.list_Position.put(id, position) catch unreachable;
    Components.list_Shape.put(id, Components.Shape{ .circle = 15 }) catch unreachable;
    Components.list_Animation.put(id, Components.Animation.fromTexture(State.Textures.heart)) catch unreachable;
    Components.list_Health.put(id, .{}) catch unreachable;
    // Figure out how to handle animation / sprites.
}

pub fn removeHealth(id: u64) void {
    _ = Components.list_Position.swapRemove(id);
    _ = Components.list_Shape.swapRemove(id);
    _ = Components.list_Animation.swapRemove(id);
    _ = Components.list_Health.swapRemove(id);
}
