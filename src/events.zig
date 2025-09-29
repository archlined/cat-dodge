const std = @import("std");
const State = @import("state.zig");

pub const Event = union(enum) {
    health_change: i32,
};

pub var event_queue = std.ArrayList(Event).init(State.allocator);

pub fn deinit() void {
    event_queue.deinit();
}
