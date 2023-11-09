const r = @cImport(@cInclude("raylib.h"));
const gl = @import("global.zig");
const title = @import("title.zig");
const gameplay = @import("gameplay.zig");

pub fn main() !void {
    r.InitWindow(gl.SCR_WIDTH, gl.SCR_HEIGHT, "Shoot 'em up!");
    r.InitAudioDevice();
    gl.Font = r.LoadFont("resources/font_arcadian.png");
    gl.CurrentScene = gl.Scene.TITLE;
    r.SetTargetFPS(gl.TARGET_FPS);
    title.Init();

    while (!r.WindowShouldClose()) {
        Update();
    }
}

fn Update() void {
    if (!gl.IsOnTransition) {
        switch (gl.CurrentScene) {
            gl.Scene.TITLE => {
                title.Update();
                if (title.End() == true) {
                    r.StopMusicStream(gl.Music);
                    gl.TransitionToScene(@intFromEnum(gl.Scene.GAMEPLAY));
                }
            },
            gl.Scene.GAMEPLAY => {
                gameplay.Update();
                if (gameplay.End()) gl.ChangeToScene(@intFromEnum(gl.Scene.TITLE)); //else if (gameplay.End() == 2) gl.TransitionToScene(@intFromEnum(gl.Scene.TITLE));
            },
        }
    } else {
        gl.UpdateTransition();
    }

    if (gl.CurrentScene != gl.Scene.GAMEPLAY) r.UpdateMusicStream(gl.Music);

    r.BeginDrawing();
    r.ClearBackground(r.RAYWHITE);

    switch (gl.CurrentScene) {
        gl.Scene.TITLE => title.Draw(),
        gl.Scene.GAMEPLAY => gameplay.Draw(),
    }

    r.EndDrawing();
}
