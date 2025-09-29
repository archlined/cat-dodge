const rl = @import("raylib");
const std = @import("std");
const print = std.debug.print;

const State = @import("state.zig");
const Components = @import("components.zig");
const Entities = @import("entities.zig");
const Systems = @import("systems.zig");
const Timer = @import("timer.zig").Timer;

pub var next_scene: *const fn (f32) void = main_game;

// Scenes should have all the main loop logic

fn main_menu(dt: f32) void {
    _ = dt;
    @panic("Not implemented!");
}

fn pause(dt: f32) void {
    _ = dt;

    rl.beginTextureMode(State.Rendering.target);
    rl.clearBackground(rl.Color.black);
    Systems.Draw.drawTextCentered(
        "Game is paused, press Q to unpause",
        0,
        0,
        20,
        rl.Color.white,
    );
    rl.endTextureMode();

    rl.beginDrawing();
    rl.clearBackground(rl.Color.black);
    Systems.Draw.drawStretchToScreen(State.Rendering.target.texture);
    rl.endDrawing();

    if (rl.isKeyPressed(rl.KeyboardKey.q)) {
        next_scene = main_game;
    }
}

fn main_game(dt: f32) void {
    const Data = struct {
        var intro = true;
        var timer = Timer{
            .interval = 1.0 / 60.0,
            .once = false,
        };
    };

    if (Data.intro) {
        rl.playMusicStream(State.Sounds.background_music);
        Entities.createPlayer();
        Data.intro = false;
    }

    // Physics updates
    for (0..@intCast(Data.timer.update(dt))) |_| {
        const fixed_dt = Data.timer.interval;
        Systems.updateCamera();
        Systems.spawnRandomEnemies(fixed_dt);
        Systems.spawnHealth(fixed_dt);
        Systems.movePlayer(fixed_dt);
        Systems.simpleMoveBounce(fixed_dt);
        Systems.updateTextureFace();
        Systems.clockCollisionTimer(fixed_dt);
        Systems.checkCollision();
    }

    // Continue systems dependant on frame time (non-physics)
    rl.updateMusicStream(State.Sounds.background_music);
    Systems.updateTimeSurvived(dt);

    // Main rendering
    rl.beginTextureMode(State.Rendering.target);
    rl.beginMode2D(State.Rendering.camera);
    rl.clearBackground(rl.Color.black);
    Systems.Draw.drawVirtualCanvasRectangle();
    Systems.Draw.drawTextCentered(
        "Don't get hit!",
        0,
        0,
        40,
        rl.Color.white,
    );
    Systems.Draw.drawAnimations();
    rl.endMode2D();
    rl.endTextureMode();

    // Scale to actual screen size
    rl.beginDrawing();
    rl.clearBackground(rl.Color.black);
    Systems.Draw.drawStretchToScreen(State.Rendering.target.texture);

    // Draw UI (that is relative to the actual screen)
    State.UI_elements.HealthBar.draw();
    State.UI_elements.Timer.draw();
    rl.endDrawing();

    // If some conditions are met, we change the next scene
    if (State.GlobalData.time_survived >= 145.0) {
        Data.intro = true;
        rl.stopMusicStream(State.Sounds.background_music);
        next_scene = victory;
    }

    if (State.GlobalData.health <= 0) {
        Data.intro = true;
        rl.stopMusicStream(State.Sounds.background_music);
        next_scene = game_over;
    }

    if (rl.isKeyPressed(rl.KeyboardKey.q)) {
        next_scene = pause;
    }
}

fn game_over(dt: f32) void {
    const Data = struct {
        var intro = true;
    };
    _ = dt;

    if (Data.intro) {
        Data.intro = false;
        rl.playSound(State.Sounds.sad_meow);
    }

    rl.beginDrawing();
    rl.clearBackground(rl.Color.black);
    Systems.Draw.drawTextCentered(
        "Game over bucko",
        0,
        -20,
        30,
        rl.Color.white,
    );
    const str = std.fmt.allocPrintZ(
        State.temp_allocator,
        "You survived: {d:.2}s",
        .{State.GlobalData.time_survived},
    ) catch @panic("Can't parse");
    Systems.Draw.drawTextCentered(
        str,
        0,
        20,
        30,
        rl.Color.white,
    );
    Systems.Draw.drawTextCentered(
        "Press R to try again",
        0,
        50,
        30,
        rl.Color.white,
    );

    rl.endDrawing();

    if (rl.isKeyPressed(rl.KeyboardKey.r)) {
        Systems.resetGame();
        rl.stopSound(State.Sounds.sad_meow);
        next_scene = main_game;
    }
}

fn victory(dt: f32) void {
    const Data = struct {
        var intro = true;
    };

    _ = dt;

    if (Data.intro) {
        Data.intro = false;
        rl.playSound(State.Sounds.clap);
    }

    rl.beginTextureMode(State.Rendering.target);
    rl.clearBackground(rl.Color.black);
    Systems.Draw.drawTextCentered(
        "You win!!!",
        0,
        0,
        30,
        rl.Color.white,
    );
    Systems.Draw.drawTextCentered(
        "Press R to play again",
        0,
        50,
        30,
        rl.Color.white,
    );
    rl.endTextureMode();

    rl.beginDrawing();
    rl.clearBackground(rl.Color.black);
    Systems.Draw.drawStretchToScreen(State.Rendering.target.texture);
    rl.endDrawing();

    if (rl.isKeyPressed(rl.KeyboardKey.r)) {
        Systems.resetGame();
        rl.stopSound(State.Sounds.clap);
        Data.intro = true;
        next_scene = main_game;
    }
}
