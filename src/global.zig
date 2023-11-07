const r = @cImport(@cInclude("raylib.h"));
const title = @import("title.zig");
const gameplay = @import("gameplay.zig");

pub const SCR_WIDTH: c_int = 1280;
pub const SCR_HEIGHT: c_int = 720;
pub const TARGET_FPS = 60;

pub const GameScreen = enum(c_int) {
    TITLE = 1,
    GAMEPLAY = 2,
};

//----------------------------------------------------------------------------------
// GAMEPLAY
//----------------------------------------------------------------------------------
pub const NUM_SHOOTS = 50;
pub const ENEMIES_CAP = 50;
pub const WAVE_I = 10;
pub const WAVE_II = 20;
pub const WAVE_III = 50;
//----------------------------------------------------------------------------------
// Shared Variables Definition (global)
//----------------------------------------------------------------------------------
pub var LightsMapWidth: c_int = 0;
pub var LightsMapHeight: c_int = 0;
pub var LightsMap: [*]r.Color = undefined;

pub var Font: r.Font = undefined;
pub var Music: r.Music = undefined;

// Screen
pub var CurrentScreen = GameScreen.TITLE;
pub var OnTransition = false;
var transAlpha: f32 = 0;
var transFadeOut = false;
var transFromScreen: c_int = -1;
var transToScreen: c_int = -1;

// Request transition to next screen
pub fn TransitionToScreen(screen: c_int) void {
    OnTransition = true;
    transFromScreen = @intFromEnum(CurrentScreen);
    transToScreen = screen;
}

pub fn ChangeToScreen(screen: c_int) void {
    switch (CurrentScreen) {
        GameScreen.TITLE => title.Unload(),
        GameScreen.GAMEPLAY => gameplay.Unload(),
    }

    switch (screen) {
        @intFromEnum(GameScreen.TITLE) => title.Init(),
        @intFromEnum(GameScreen.GAMEPLAY) => gameplay.Init(),
        else => {
            unreachable;
        },
    }

    CurrentScreen = @enumFromInt(screen);
}

pub fn UpdateTransition() void {
    if (!transFadeOut) {
        transAlpha += 0.05;

        if (transAlpha >= 1.0) {
            transAlpha = 1.0;

            switch (transFromScreen) {
                @intFromEnum(GameScreen.TITLE) => {
                    title.Unload();
                },
                @intFromEnum(GameScreen.GAMEPLAY) => {
                    //UnloadGameplayScreen();
                },
                else => {
                    unreachable;
                },
            }

            switch (transToScreen) {
                @intFromEnum(GameScreen.TITLE) => {
                    title.Init();
                    CurrentScreen = GameScreen.TITLE;
                },
                @intFromEnum(GameScreen.GAMEPLAY) => {
                    gameplay.Init();
                    CurrentScreen = GameScreen.GAMEPLAY;
                },
                else => {
                    unreachable;
                },
            }

            transFadeOut = true;
        }
    } else // Transition fade out logic
    {
        transAlpha -= 0.05;

        if (transAlpha <= 0) {
            transAlpha = 0;
            transFadeOut = false;
            OnTransition = false;
            transFromScreen = -1;
            transToScreen = -1;
        }
    }
}
