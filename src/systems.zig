const std = @import("std");
const rl = @import("raylib");
const print = std.debug.print;

const State = @import("state.zig");
const Entities = @import("entities.zig");
const Components = @import("components.zig");
const Events = @import("events.zig");

const alloc = State.temp_allocator;

fn maybeWrap(x: f32, y: f32) rl.Vector2 {
    return .{
        .x = @mod(x, State.screen_width),
        .y = @mod(y, State.screen_height),
    };
}

const H = struct {
    fn andIDs(s1: []u64, s2: []u64) std.ArrayList(u64) {
        var list = std.ArrayList(u64).init(alloc);

        if (s1.len == 0 or s2.len == 0) {
            return list;
        }

        const small = if (s1.len <= s2.len) s1 else s2;
        const large = if (s1.len > s2.len) s1 else s2;

        var hash_set = std.hash_map.AutoHashMap(u64, void).init(alloc);

        for (small) |value| {
            hash_set.put(value, {}) catch unreachable;
        }

        for (large) |value| {
            if (hash_set.get(value) != null) {
                list.append(value) catch unreachable;
                _ = hash_set.remove(value);
            }
        }

        return list;
    }

    fn subIDs(s1: []u64, s2: []u64) std.ArrayList(u64) {
        var list = std.ArrayList(u64).init(alloc);
        var hash_set = std.hash_map.AutoHashMap(u64, void).init(alloc);

        for (s2) |value| {
            hash_set.put(value, {}) catch unreachable;
        }

        for (s1) |value| {
            if (hash_set.get(value) == null) {
                list.append(value) catch unreachable;
            }
        }

        return list;
    }
};

pub fn updateCamera() void {
    var camera = &State.Rendering.camera;

    if (rl.isKeyDown(rl.KeyboardKey.up)) {
        camera.target.y -= 10;
    }
    if (rl.isKeyDown(rl.KeyboardKey.down)) {
        camera.target.y += 10;
    }
    if (rl.isKeyDown(rl.KeyboardKey.left)) {
        camera.target.x -= 10;
    }
    if (rl.isKeyDown(rl.KeyboardKey.right)) {
        camera.target.x += 10;
    }
    if (rl.isKeyDown(rl.KeyboardKey.o)) {
        camera.rotation -= 0.8;
    }
    if (rl.isKeyDown(rl.KeyboardKey.p)) {
        camera.rotation += 0.8;
    }
    if (rl.isKeyDown(rl.KeyboardKey.k)) {
        camera.zoom += 0.05;
    }
    if (rl.isKeyDown(rl.KeyboardKey.l)) {
        camera.zoom -= 0.05;
    }
}

pub fn spawnRandomEnemies(dt: f32) void {
    const Data = struct {
        var last_time: f32 = 0.0;
    };

    Data.last_time += dt;
    if (Data.last_time < 5.0) {
        return;
    } else {
        Data.last_time -= 5.0;
    }

    Entities.createGenericEnemy(rl.math.vector2Zero());
}

pub fn drawPlayer() void {
    const id1 = Components.list_PlayerTag.keys();
    const id2 = H.andIDs(
        alloc,
        id1,
        Components.list_Position.keys(),
    );

    const ids = id2.items;
    for (ids) |id| {
        const position = Components.list_Position.getPtr(id).?;

        const x: i32 = @intFromFloat(position.x);
        const y: i32 = @intFromFloat(position.y);

        rl.drawCircle(
            x,
            y,
            12,
            rl.Color.white,
        );
        rl.drawCircle(
            x,
            y,
            10,
            rl.Color.black,
        );
    }
}

pub fn drawUI() void {
    const Helpers = struct {
        fn drawHeart(x: i32, y: i32) void {
            const heart = State.Textures.heart;

            const w = heart.width;
            const h = heart.height;
            const scale = 0.05;

            const hsw: f32 = @as(f32, @floatFromInt(w)) * scale * 0.5;
            const hsh: f32 = @as(f32, @floatFromInt(h)) * scale * 0.5;

            rl.drawTextureEx(heart, .{
                .x = @as(f32, @floatFromInt(x)) - hsw,
                .y = @as(f32, @floatFromInt(y)) - hsh,
            }, 0.0, scale, rl.Color.white);
        }
    };
    rl.drawText(
        "Don't get hit!",
        320,
        200,
        20,
        rl.Color.light_gray,
    );

    Helpers.drawHeart(690, 400);
    Helpers.drawHeart(720, 400);
    Helpers.drawHeart(750, 400);
}

pub fn movePlayer(dt: f32) void {
    const id = Components.list_PlayerTag.keys()[0];
    var pos = Components.list_Position.getPtr(id).?;

    const p = rl.isKeyDown;
    const k = rl.KeyboardKey;

    if (p(k.w)) {
        pos.y = @max(0, pos.y - 5 * 60 * dt);
    }
    if (p(k.s)) {
        pos.y = @min(State.Rendering.virtual_height, pos.y + 5 * 60 * dt);
    }
    if (p(k.a)) {
        pos.x = @max(0, pos.x - 5 * 60 * dt);
    }
    if (p(k.d)) {
        pos.x = @min(State.Rendering.virtual_width, pos.x + 5 * 60 * dt);
    }
}

pub fn updateTextureFace() void {
    const id1 = Components.list_GenericEnemyTag.keys();
    const id2 = H.andIDs(
        id1,
        Components.list_Velocity.keys(),
    );
    const id3 = H.andIDs(
        id2.items,
        Components.list_Animation.keys(),
    );

    const ids = id3.items;

    for (ids) |id| {
        var anim = Components.list_Animation.getPtr(id).?;
        const vel = Components.list_Velocity.getPtr(id).?;

        // if the texture by default facing right
        if (vel.x > 0) anim.orientation.x = -1; // then this should be 1
        if (vel.x < 0) anim.orientation.x = 1; // then this should be -1
    }
}

pub fn simpleMoveBounce(dt: f32) void {
    const id1 = Components.list_Velocity.keys();
    const id2 = H.andIDs(
        id1,
        Components.list_Position.keys(),
    );
    const id3 = H.andIDs(
        id2.items,
        Components.list_Animation.keys(),
    );
    const id4 = H.subIDs(
        id3.items,
        Components.list_PlayerTag.keys(),
    );

    const ids = id4.items;

    for (ids) |id| {
        const velocity = Components.list_Velocity.getPtr(id).?;
        const position = Components.list_Position.getPtr(id).?;

        var new_position = position.*.add(velocity.*.scale(dt));

        if (new_position.x < 0) {
            new_position.x = 0;
            velocity.x *= -1;
        }
        if (new_position.x > State.Rendering.virtual_width) {
            new_position.x = State.Rendering.virtual_width;
            velocity.x *= -1;
        }
        if (new_position.y < 0) {
            new_position.y = 0;
            velocity.y *= -1;
        }
        if (new_position.y > State.Rendering.virtual_height) {
            new_position.y = State.Rendering.virtual_height;
            velocity.y *= -1;
        }

        position.* = new_position;
    }
}

pub fn checkCollision() void {
    const leeway = 5.0;

    const player_id = Components.list_PlayerTag.keys()[0];
    const player_pos = Components.list_Position.get(player_id).?;
    const player_shape = Components.list_Shape.get(player_id).?;

    const id1 = Components.list_Position.keys();
    const id2 = H.andIDs(
        id1,
        Components.list_Animation.keys(),
    );
    const id3 = H.andIDs(
        id2.items,
        Components.list_Shape.keys(),
    );

    const ids = id3.items;
    for (ids) |id| {
        if (id == player_id) continue;
        const pos = Components.list_Position.get(id).?;
        const shp = Components.list_Shape.get(id).?;

        const r1 = @max(1, player_shape.width() / 2 - leeway);
        const r2 = @max(1, shp.width() / 2 - leeway);

        if (!rl.checkCollisionCircles(
            player_pos,
            r1,
            pos,
            r2,
        )) {
            continue;
        }

        print("IDS {} and {} collided\n", .{ player_id, id });

        if (Components.list_GenericEnemyTag.get(id) != null) {
            enemyCollision(id);
        }

        if (Components.list_Health.get(id) != null) {
            heartCollision(id);
        }
    }
}

fn enemyCollision(id: u64) void {
    _ = id;
    if (State.GlobalData.collision_cooldown <= 0.0) {
        Events.event_queue.append(Events.Event{ .health_change = -1 }) catch unreachable;
        State.GlobalData.health -= 1;
        State.GlobalData.collision_cooldown = 1;

        // This should either be an event or handled somewhere else I feel
        rl.playSound(State.Sounds.oof);
    }
}

fn heartCollision(id: u64) void {
    if (State.GlobalData.health <= 2) {
        Events.event_queue.append(Events.Event{ .health_change = 1 }) catch unreachable;
        State.GlobalData.health += 1;

        Entities.removeHealth(id);

        // Should maybe emit an event instead
        rl.playSound(State.Sounds.beep);
    }
}

pub fn drawShapes() void {
    const id1 = Components.list_Shape.keys();
    const id2 = H.andIDs(
        id1,
        Components.list_Position.keys(),
    );

    const ids = id2.items;
    for (ids) |id| {
        const shape = Components.list_Shape.getPtr(id).?.*;
        const position = Components.list_Position.getPtr(id).?.*;

        const clr = rl.Color.fade(rl.Color.green, 0.3);

        const sc = getNewScreenScale();
        const x_scale = sc.x;
        const y_scale = sc.y;

        switch (shape) {
            .circle => |r| {
                rl.drawEllipse(
                    @as(i32, @intFromFloat(position.x * x_scale)),
                    @as(i32, @intFromFloat(position.y * y_scale)),
                    r * x_scale,
                    r * y_scale,
                    clr,
                );
            },
            .rectangle => |rect| {
                rl.drawRectangleV(position, .{
                    .x = rect.x * x_scale,
                    .y = rect.y * y_scale,
                }, clr);
            },
            else => @panic("Unknown shape"),
        }
    }
}

fn getNewScreenScale() rl.Vector2 {
    const x_scale: f32 = @as(f32, @floatFromInt(rl.getScreenWidth())) / @as(f32, @floatFromInt(State.real_camera_width));
    const y_scale: f32 = @as(f32, @floatFromInt(rl.getScreenHeight())) / @as(f32, @floatFromInt(State.real_camera_height));

    return .{
        .x = x_scale,
        .y = y_scale,
    };
}

pub fn clockCollisionTimer(dt: f32) void {
    const cd = &State.GlobalData.collision_cooldown;

    if (cd.* != 0) {
        print("Collision immunity: {d:.2}s left\n", .{cd.*});
    }

    if (cd.* > 0) {
        cd.* -= dt;
        cd.* = @max(0, cd.*);
    }
}

pub fn spawnHealth(dt: f32) void {
    const Data = struct {
        var last_spawn: f32 = 0.0;
    };

    Data.last_spawn += dt;

    if (Data.last_spawn >= 15.0) {
        Data.last_spawn -= 15.0;
        const rx: f32 = @floatFromInt(
            rl.getRandomValue(0, State.Rendering.virtual_width),
        );
        const ry: f32 = @floatFromInt(
            rl.getRandomValue(0, State.Rendering.virtual_height),
        );

        Entities.createHealth(.{ .x = rx, .y = ry });
    }
}

pub fn updateTimeSurvived(dt: f32) void {
    State.GlobalData.time_survived += dt;
}

pub fn resetGame() void {
    Components.resetAll();
    State.GlobalData.health = 3;
    State.GlobalData.time_survived = 0;
}

pub const Draw = struct {
    pub fn drawAnimations() void {
        const ids1 = Components.list_Animation.keys();
        const ids2 = H.andIDs(
            ids1,
            Components.list_Position.keys(),
        );

        const ids = ids2.items;
        for (ids) |id| {
            const shape = Components.list_Shape.getPtr(id);
            const postion = Components.list_Position.getPtr(id).?;
            const animation = Components.list_Animation.getPtr(id).?;
            const anim_rect = animation.get(rl.getFrameTime());

            var dest_x = postion.x - anim_rect.x / 2;
            var dest_y = postion.y - anim_rect.y / 2;
            var dest_width = anim_rect.width;
            var dest_height = anim_rect.height;

            // if the entity has a shape, scale the animation to the shape
            if (shape != null) {
                dest_x = postion.x - shape.?.width() / 2;
                dest_y = postion.y - shape.?.height() / 2;
                dest_width = shape.?.width();
                dest_height = shape.?.height();
            }

            dest_x += animation.offset_from_position.x;
            dest_y += animation.offset_from_position.y;

            rl.drawTexturePro(
                animation.texture,
                anim_rect,
                rl.Rectangle{
                    .x = dest_x,
                    .y = dest_y,
                    .width = dest_width,
                    .height = dest_height,
                },
                rl.math.vector2Zero(),
                0.0,
                rl.Color.white,
            );
        }
    }

    pub fn drawStretchToScreen(texture: rl.Texture) void {
        rl.drawTexturePro(
            texture,
            .{
                .x = 0,
                .y = 0,
                .width = State.Rendering.virtual_width,
                .height = -State.Rendering.virtual_height,
            },
            State.Rendering.screenRectangle(),
            rl.math.vector2Zero(),
            0.0,
            rl.Color.white,
        );
    }

    pub fn drawHealthbar() void {
        const sw: f32 = @floatFromInt(rl.getScreenWidth());
        const sh: f32 = @floatFromInt(rl.getScreenHeight());

        // const txt_w = sw * 0.3;
        // const txt_h = sh * 0.1;
        if (State.GlobalData.health <= 0) return;
        for (0..@intCast(State.GlobalData.health)) |i| {
            const ii = @as(f32, @floatFromInt(i));
            rl.drawTextureEx(
                State.Textures.heart,
                .{
                    .x = sw * 0.8 + 0.05 * ii * sw,
                    .y = sh * 0.9,
                },
                0.0,
                0.1,
                rl.Color.white,
            );
        }
    }

    pub fn drawVirtualCanvasRectangle() void {
        rl.drawLine(0, 0, State.Rendering.virtual_width, 0, rl.Color.white);
        rl.drawLine(State.Rendering.virtual_width, 0, State.Rendering.virtual_width, State.Rendering.virtual_height, rl.Color.white);
        rl.drawLine(State.Rendering.virtual_width, State.Rendering.virtual_height, 0, State.Rendering.virtual_height, rl.Color.white);
        rl.drawLine(0, State.Rendering.virtual_height, 0, 0, rl.Color.white);
    }

    pub fn drawTimer() void {
        const str: [:0]u8 = std.fmt.allocPrintZ(
            alloc,
            "Time: {d:.2}",
            .{rl.getTime()},
        ) catch @panic("Can't parse shit");
        // defer alloc.free(str);

        const sw: f32 = @floatFromInt(State.Rendering.virtual_width);
        const sh: f32 = @floatFromInt(State.Rendering.virtual_height);

        rl.drawText(
            str,
            @as(i32, @intFromFloat(sw * 0.90)),
            @as(i32, @intFromFloat(sh * 0.02)),
            20,
            rl.Color.white,
        );
    }

    pub fn drawTextCentered(text: [:0]const u8, offset_x: i32, offset_y: i32, font_size: i32, color: rl.Color) void {
        const text_dim = rl.measureTextEx(
            rl.getFontDefault() catch unreachable,
            text,
            @floatFromInt(font_size),
            1,
        );

        rl.drawText(
            text,
            @as(i32, @intFromFloat(State.Rendering.virtual_midpoint.x)) - @as(i32, @intFromFloat(text_dim.x * 0.5)) + offset_x,
            @as(i32, @intFromFloat(State.Rendering.virtual_midpoint.y)) - @as(i32, @intFromFloat(text_dim.y * 0.5)) + offset_y,
            font_size,
            color,
        );
    }
};
