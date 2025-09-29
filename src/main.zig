const rl = @import("raylib");
const std = @import("std");
const print = std.debug.print;

const State = @import("state.zig");
const Components = @import("components.zig");
const Entities = @import("entities.zig");
const Systems = @import("systems.zig");
const Scene = @import("scene.zig");
const Events = @import("events.zig");

pub fn main() anyerror!void {
    State.init();

    while (!rl.windowShouldClose()) {
        Scene.next_scene(rl.getFrameTime());
        _ = State.arena.reset(.retain_capacity);
    }

    State.deinit();
    Components.deinit();
    Events.deinit();

    if (State.gpa.deinit() == .leak) {
        print("We are leaking memory\n", .{});
    } else {
        print("Memory ok!", .{});
    }
}
