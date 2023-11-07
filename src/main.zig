const r = @cImport(@cInclude("raylib.h"));
const gl = @import("global.zig");
const title = @import("title.zig");
const gameplay = @import("gameplay.zig");

pub fn main() !void {
    r.InitWindow(gl.SCR_WIDTH, gl.SCR_HEIGHT, "Shoot 'em up!");
    r.InitAudioDevice();

    // const image: r.Image = r.LoadImage("resources/lights_map.png");
    // gl.LightsMap = r.LoadImageColors(image);
    // gl.LightsMapWidth = image.width;
    // gl.LightsMapHeight = image.height;
    // r.UnloadImage(image);

    gl.Font = r.LoadFont("resources/font_arcadian.png");
    //doors = LoadTexture("resources/textures/doors.png");
    //sndDoor = LoadSound("resources/audio/door.ogg");

    // Setup and Init first screen
    gl.CurrentScreen = gl.GameScreen.TITLE;
    r.SetTargetFPS(gl.TARGET_FPS);

    title.Init();
    while (!r.WindowShouldClose()) {
        UpdateMain();
    }
}

fn UpdateMain() void {
    // Update
    //----------------------------------------------------------------------------------
    if (!gl.OnTransition) {
        switch (gl.CurrentScreen) {
            gl.GameScreen.TITLE => {
                title.Update();

                if (title.End() == true) {
                    r.StopMusicStream(gl.Music);
                    gl.TransitionToScreen(@intFromEnum(gl.GameScreen.GAMEPLAY));
                }
            },
            gl.GameScreen.GAMEPLAY => {
                gameplay.Update();

                if (gameplay.End()) gl.ChangeToScreen(@intFromEnum(gl.GameScreen.TITLE)); //else if (gameplay.End() == 2) gl.TransitionToScreen(@intFromEnum(gl.GameScreen.TITLE));
            },
        }
    } else {
        // Update transition (fade-in, fade-out)
        gl.UpdateTransition();
    }

    if (gl.CurrentScreen != gl.GameScreen.GAMEPLAY) r.UpdateMusicStream(gl.Music);
    //----------------------------------------------------------------------------------

    // Draw
    //----------------------------------------------------------------------------------
    r.BeginDrawing();

    r.ClearBackground(r.RAYWHITE);

    switch (gl.CurrentScreen) {
        gl.GameScreen.TITLE => title.Draw(),
        gl.GameScreen.GAMEPLAY => gameplay.Draw(),
    }

    //if (onTransition) DrawTransition();

    r.EndDrawing();
}
