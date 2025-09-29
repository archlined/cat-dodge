const std = @import("std");
const rl = @import("raylib");
const cast = std.math.lossyCast;

pub var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const allocator = gpa.allocator();
pub var arena = std.heap.ArenaAllocator.init(allocator);
pub const temp_allocator = arena.allocator();
var seed: i64 = undefined;

pub fn init() void {
    rl.setConfigFlags(rl.ConfigFlags{
        .window_resizable = true,
        .msaa_4x_hint = true,
    });

    rl.initWindow(
        1280,
        720,
        "Survive the fire",
    );
    rl.setTargetFPS(60);
    rl.initAudioDevice();

    seed = std.time.milliTimestamp();
    rl.setRandomSeed(@truncate(@as(u64, @bitCast(seed))));

    Textures.loadTextures();
    Sounds.loadSounds();
    Rendering.initTargetRenderTexture();
}

pub fn deinit() void {
    rl.closeAudioDevice();
    Textures.unloadTextures();
    Sounds.unloadSounds();
    Rendering.deinitTargetRenderTexture();
    rl.closeWindow();
    arena.deinit();
}

pub const Rendering = struct {
    pub const virtual_width = 1280;
    pub const virtual_height = 720;
    pub const virtual_midpoint = rl.Vector2{
        .x = virtual_width / 2,
        .y = virtual_height / 2,
    };

    pub var camera = rl.Camera2D{
        .target = .{
            .x = virtual_midpoint.x,
            .y = virtual_midpoint.y,
        },
        .offset = .{
            .x = virtual_width / 2,
            .y = virtual_height / 2,
        },
        .rotation = 0.0,
        .zoom = 0.8,
    };

    pub var target: rl.RenderTexture2D = undefined;

    pub fn initTargetRenderTexture() void {
        Rendering.target = rl.loadRenderTexture(
            Rendering.virtual_width,
            Rendering.virtual_height,
        ) catch @panic("Couldn't load render target texture");
    }

    pub fn deinitTargetRenderTexture() void {
        rl.unloadRenderTexture(Rendering.target);
    }

    pub fn screenRectangle() rl.Rectangle {
        return rl.Rectangle{
            .x = 0,
            .y = 0,
            .width = @as(f32, @floatFromInt(rl.getScreenWidth())),
            .height = @as(f32, @floatFromInt(rl.getScreenHeight())),
        };
    }
};

pub const Textures = struct {
    pub var heart: rl.Texture = undefined;
    pub var cat_idle: rl.Texture = undefined;
    pub var cat_box: rl.Texture = undefined;

    pub fn loadTextures() void {
        Textures.heart = rl.loadTexture("src/resources/heart.png") //
        catch @panic("Failed to load heart texture");
        Textures.cat_idle = rl.loadTexture("src/resources/Idle.png") //
        catch @panic("Failed to load cat texture");
        Textures.cat_box = rl.loadTexture("src/resources/Box3.png") //
        catch @panic("Failed to load cat box texture");
    }

    pub fn unloadTextures() void {
        rl.unloadTexture(Textures.heart);
        rl.unloadTexture(Textures.cat_idle);
        rl.unloadTexture(Textures.cat_box);
    }
};

pub const Sounds = struct {
    pub var background_music: rl.Music = undefined;
    pub var oof: rl.Sound = undefined;
    pub var sad_meow: rl.Sound = undefined;
    pub var chill_guy: rl.Sound = undefined;
    pub var beep: rl.Sound = undefined;
    pub var clap: rl.Sound = undefined;

    pub fn loadSounds() void {
        background_music = rl.loadMusicStream("src/resources/kevin-macleod-hall-of-the-mountain-king.mp3") //
        catch @panic("Failed to load music");
        oof = loadClipAudio("src/resources/oof.mp3", 0.5, null, null) //
        catch @panic("Failed to oof audio");
        sad_meow = loadClipAudio("src/resources/sad-meow-song.mp3", null, 9, 0.25) //
        catch @panic("Failed to sad meow audio");
        chill_guy = rl.loadSound("src/resources/chill-guy.mp3") //
        catch @panic("Failed to load chill guy audio");
        beep = rl.loadSound("src/resources/beep-out.mp3") //
        catch @panic("Failed to load beep audio");
        clap = rl.loadSound("src/resources/clap.mp3") //
        catch @panic("Failed to load clap audio");
    }

    pub fn unloadSounds() void {
        rl.unloadMusicStream(background_music);
        rl.unloadSound(oof);
        rl.unloadSound(sad_meow);
        rl.unloadSound(chill_guy);
        rl.unloadSound(beep);
        rl.unloadSound(clap);
    }

    fn loadClipAudio(path: [:0]const u8, start: ?f32, end: ?f32, volume: ?f32) !rl.Sound {
        var audio = try rl.loadWave(path);
        defer rl.unloadWave(audio);

        const start_frame = if (start != null)
            cast(i32, start.? * cast(f32, audio.sampleRate))
        else
            0;
        const end_frame = if (end != null)
            cast(i32, end.? * cast(f32, audio.sampleRate))
        else
            cast(i32, audio.frameCount);

        rl.waveCrop(&audio, start_frame, end_frame);
        const audio_sound = rl.loadSoundFromWave(audio);

        rl.setSoundVolume(audio_sound, volume orelse 1.0);

        return audio_sound;
    }
};

pub const GlobalData = struct {
    pub var health: i32 = 3;
    pub var collision_cooldown: f32 = 0.0;
    pub var time_survived: f32 = 0.0;
};

pub const UI_elements = struct {
    pub const HealthBar = struct {
        pub fn draw() void {
            const heart_txt = Textures.heart;
            const sw: f32 = @floatFromInt(rl.getScreenWidth());
            const sh: f32 = @floatFromInt(rl.getScreenHeight());

            const hp: usize = @intCast(GlobalData.health);
            if (hp <= 0) return;

            for (0..hp) |i| {
                const if32: f32 = @floatFromInt(i);

                rl.drawTextureEx(
                    heart_txt,
                    .{
                        .x = sw * 0.89 + sw * if32 * 0.1 / 3,
                        .y = sh * 0.93,
                    },
                    0.0,
                    0.08,
                    rl.Color.white,
                );
            }
        }
    };

    pub const Timer = struct {
        pub fn draw() void {
            const str: [:0]u8 = std.fmt.allocPrintZ(
                temp_allocator,
                "Time: {d:.2}",
                .{GlobalData.time_survived},
            ) catch @panic("Can't parse shit");

            const sw: f32 = @floatFromInt(Rendering.virtual_width);
            const sh: f32 = @floatFromInt(Rendering.virtual_height);

            rl.drawText(
                str,
                @as(i32, @intFromFloat(sw * 0.90)),
                @as(i32, @intFromFloat(sh * 0.02)),
                20,
                rl.Color.white,
            );
        }
    };
};
