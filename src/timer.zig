const std = @import("std");
const cast = std.math.lossyCast;

pub const Timer = struct {
    time: f32 = 0,
    time_started: f32 = 0,
    interval: f32,
    once: bool,

    pub fn update(self: *Timer, dt: f32) i32 {
        std.debug.assert(cast(i32, 0.99) == 0);

        self.time += dt;
        self.time_started += dt;

        if (self.once and
            self.time_started >= self.interval)
            return 1;

        const ret: i32 = cast(i32, self.time / self.interval);
        self.time -= cast(f32, ret) * self.interval;

        return ret;
    }
};
