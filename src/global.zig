const r = @cImport(@cInclude("raylib.h"));
const title = @import("title.zig");
const gameplay = @import("gameplay.zig");

pub const SCR_WIDTH: c_int = 1280;
pub const SCR_HEIGHT: c_int = 720;
pub const TARGET_FPS = 60;
pub const Scene = enum(c_int) {
    TITLE = 1,
    GAMEPLAY = 2,
};
pub const NUM_SHOOTS = 50;
pub const ENEMIES_CAP = 50;
pub const WAVE_I = 10;
pub const WAVE_II = 20;
pub const WAVE_III = 50;

pub var LightsMapWidth: c_int = 0;
pub var LightsMapHeight: c_int = 0;
pub var LightsMap: [*]r.Color = undefined;
pub var Font: r.Font = undefined;
pub var Music: r.Music = undefined;
pub var CurrentScene = Scene.TITLE;
pub var IsOnTransition = false;

var transAlpha: f32 = 0;
var isTransFadeOut = false;
var transFromScene: c_int = -1;
var transToScene: c_int = -1;

// Request transition to next scene
pub fn TransitionToScene(scene: c_int) void {
    IsOnTransition = true;
    transFromScene = @intFromEnum(CurrentScene);
    transToScene = scene;
}

pub fn ChangeToScene(scene: c_int) void {
    switch (CurrentScene) {
        Scene.TITLE => title.Unload(),
        Scene.GAMEPLAY => gameplay.Unload(),
    }

    switch (scene) {
        @intFromEnum(Scene.TITLE) => title.Init(),
        @intFromEnum(Scene.GAMEPLAY) => gameplay.Init(),
        else => {
            unreachable;
        },
    }

    CurrentScene = @enumFromInt(scene);
}

pub fn UpdateTransition() void {
    if (!isTransFadeOut) {
        transAlpha += 0.05;

        if (transAlpha >= 1.0) {
            transAlpha = 1.0;
            switch (transFromScene) {
                @intFromEnum(Scene.TITLE) => {
                    title.Unload();
                },
                @intFromEnum(Scene.GAMEPLAY) => {
                    gameplay.Unload();
                },
                else => {
                    unreachable;
                },
            }

            switch (transToScene) {
                @intFromEnum(Scene.TITLE) => {
                    title.Init();
                    CurrentScene = Scene.TITLE;
                },
                @intFromEnum(Scene.GAMEPLAY) => {
                    gameplay.Init();
                    CurrentScene = Scene.GAMEPLAY;
                },
                else => {
                    unreachable;
                },
            }
            isTransFadeOut = true;
        }
    } else // Transition fade out logic
    {
        transAlpha -= 0.05;

        if (transAlpha <= 0) {
            transAlpha = 0;
            isTransFadeOut = false;
            IsOnTransition = false;
            transFromScene = -1;
            transToScene = -1;
        }
    }
}
