const r = @cImport(@cInclude("raylib.h"));
const gl = @import("global.zig");

//----------------------------------------------------------------------------------
// Types and Structures Definition
//----------------------------------------------------------------------------------
const EnemyWave = enum(c_int) {
    FIRST = 0,
    SECOND = 1,
    THIRD = 2,
};

const Player = struct {
    rec: r.Rectangle,
    speed: r.Vector2,
    color: r.Color,
};

const Enemy = struct {
    rec: r.Rectangle,
    speed: r.Vector2,
    color: r.Color,
    active: bool,
};

const Shoot = struct {
    rec: r.Rectangle,
    speed: r.Vector2,
    color: r.Color,
    active: bool,
};

//------------------------------------------------------------------------------------
// Global Variables Declaration
//------------------------------------------------------------------------------------
var gameOver = false;
var pause = false;
var score: c_int = 0;
var win = false;
var player: Player = undefined;
var enemy: [gl.ENEMIES_CAP]Enemy = undefined;
var shoot: [gl.NUM_SHOOTS]Shoot = undefined;
var wave: EnemyWave = undefined;
var shootRate: c_int = 0;
var alpha: f32 = 0.0;
var activeEnemies: c_int = 0;
var enemiesKill: c_int = 0;
var smooth = false;

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
//int main(void)
// {
//     // Initialization (Note windowTitle is unused on Android)
//     //---------------------------------------------------------
//     InitWindow(gl.SCR_WIDTH, gl.SCR_HEIGHT, "classic game: space invaders");

//     InitGame();

// #if defined(PLATFORM_WEB)
//     emscripten_set_main_loop(UpdateDrawFrame, 60, 1);
// #else
//     SetTargetFPS(60);
//     //--------------------------------------------------------------------------------------

//     // Main game loop
//     while (!WindowShouldClose())    // Detect window close button or ESC key
//     {
//         // Update and Draw
//         //----------------------------------------------------------------------------------
//         UpdateDrawFrame();
//         //----------------------------------------------------------------------------------
//     }
// #endif
//     // De-Initialization
//     //--------------------------------------------------------------------------------------
//     UnloadGame();         // Unload loaded data (textures, sounds, models...)

//     CloseWindow();        // Close window and OpenGL context
//     //--------------------------------------------------------------------------------------

//     return 0;
// }

//------------------------------------------------------------------------------------
// Module Functions Definitions (local)
//------------------------------------------------------------------------------------

// Initialize game variables
pub fn Init() void {
    // Initialize game variables
    shootRate = 0;
    pause = false;
    gameOver = false;
    win = false;
    smooth = false;
    wave = EnemyWave.FIRST;
    activeEnemies = gl.WAVE_I;
    enemiesKill = 0;
    score = 0;
    alpha = 0;

    // Initialize player
    player.rec.x = 20;
    player.rec.y = 50;
    player.rec.width = 20;
    player.rec.height = 20;
    player.speed.x = 5;
    player.speed.y = 5;
    player.color = r.BLACK;

    // Initialize enemies
    for (0..gl.ENEMIES_CAP) |i| {
        enemy[i].rec.width = 10;
        enemy[i].rec.height = 10;
        enemy[i].rec.x = @as(f32, @floatFromInt(r.GetRandomValue(gl.SCR_WIDTH, gl.SCR_WIDTH + 1000)));
        enemy[i].rec.y = @as(f32, @floatFromInt(r.GetRandomValue(0, gl.SCR_HEIGHT - @as(c_int, @intFromFloat(enemy[i].rec.height)))));
        enemy[i].speed.x = 5;
        enemy[i].speed.y = 5;
        enemy[i].active = true;
        enemy[i].color = r.GRAY;
    }

    // Initialize shoots
    for (0..gl.NUM_SHOOTS) |i| {
        shoot[i].rec.x = player.rec.x;
        shoot[i].rec.y = player.rec.y + player.rec.height / 4;
        shoot[i].rec.width = 10;
        shoot[i].rec.height = 5;
        shoot[i].speed.x = 7;
        shoot[i].speed.y = 0;
        shoot[i].active = false;
        shoot[i].color = r.MAROON;
    }
}

// Update game (one frame)
pub fn Update() void {
    if (!gameOver) {
        if (r.IsKeyPressed('P')) pause = !pause;

        if (!pause) {
            switch (wave) {
                EnemyWave.FIRST => {
                    if (!smooth) {
                        alpha = alpha + 0.02;

                        if (alpha >= 1.0) smooth = true;
                    }

                    if (smooth) alpha -= 0.02;

                    if (enemiesKill == activeEnemies) {
                        enemiesKill = 0;

                        for (0..@as(usize, @intCast(activeEnemies))) |i| {
                            if (!enemy[i].active) enemy[i].active = true;
                        }

                        activeEnemies = gl.WAVE_II;
                        wave = EnemyWave.SECOND;
                        smooth = false;
                        alpha = 0.0;
                    }
                },
                EnemyWave.SECOND => {
                    if (!smooth) {
                        alpha = alpha + 0.02;

                        if (alpha >= 1.0) smooth = true;
                    }

                    if (smooth) alpha -= 0.02;

                    if (enemiesKill == activeEnemies) {
                        enemiesKill = 0;

                        for (0..@as(usize, @intCast(activeEnemies))) |i| {
                            if (!enemy[i].active) enemy[i].active = true;
                        }

                        activeEnemies = gl.WAVE_III;
                        wave = EnemyWave.THIRD;
                        smooth = false;
                        alpha = 0.0;
                    }
                },
                EnemyWave.THIRD => {
                    if (!smooth) {
                        alpha = alpha + 0.02;

                        if (alpha >= 1.0) smooth = true;
                    }

                    if (smooth) alpha -= 0.02;

                    if (enemiesKill == activeEnemies) win = true;
                },
            }

            // Player movement
            if (r.IsKeyDown(r.KEY_RIGHT)) player.rec.x += player.speed.x;
            if (r.IsKeyDown(r.KEY_LEFT)) player.rec.x -= player.speed.x;
            if (r.IsKeyDown(r.KEY_UP)) player.rec.y -= player.speed.y;
            if (r.IsKeyDown(r.KEY_DOWN)) player.rec.y += player.speed.y;

            // Player collision with enemy

            for (0..@as(usize, @intCast(activeEnemies))) |i| {
                if (r.CheckCollisionRecs(player.rec, enemy[i].rec)) gameOver = true;
            }

            // Enemy behaviour
            for (0..@as(usize, @intCast(activeEnemies))) |i| {
                if (enemy[i].active) {
                    enemy[i].rec.x -= enemy[i].speed.x;

                    if (enemy[i].rec.x < 0) {
                        enemy[i].rec.x = @as(f32, @floatFromInt(r.GetRandomValue(gl.SCR_WIDTH, gl.SCR_WIDTH + 1000)));
                        enemy[i].rec.y = @as(f32, @floatFromInt(r.GetRandomValue(0, gl.SCR_HEIGHT - @as(c_int, @intFromFloat(enemy[i].rec.height)))));
                    }
                }
            }

            // Wall behaviour
            if (player.rec.x <= 0) player.rec.x = 0;
            if (player.rec.x + player.rec.width >= gl.SCR_WIDTH) player.rec.x = gl.SCR_WIDTH - player.rec.width;
            if (player.rec.y <= 0) player.rec.y = 0;
            if (player.rec.y + player.rec.height >= gl.SCR_HEIGHT) player.rec.y = gl.SCR_HEIGHT - player.rec.height;

            // Shoot initialization
            if (r.IsKeyDown(r.KEY_SPACE)) {
                shootRate += 5;

                for (0..gl.NUM_SHOOTS) |i| {
                    if (!shoot[i].active and @mod(shootRate, 20) == 0) {
                        shoot[i].rec.x = player.rec.x;
                        shoot[i].rec.y = player.rec.y + player.rec.height / 4;
                        shoot[i].active = true;
                        break;
                    }
                }
            }

            // Shoot logic
            for (0..gl.NUM_SHOOTS) |i| {
                if (shoot[i].active) {
                    // Movement
                    shoot[i].rec.x += shoot[i].speed.x;

                    // Collision with enemy
                    for (0..@as(usize, @intCast(activeEnemies))) |j| {
                        if (enemy[j].active) {
                            if (r.CheckCollisionRecs(shoot[i].rec, enemy[j].rec)) {
                                shoot[i].active = false;
                                enemy[j].rec.x = @as(f32, @floatFromInt(r.GetRandomValue(gl.SCR_WIDTH, gl.SCR_WIDTH + 1000)));
                                enemy[j].rec.y = @as(f32, @floatFromInt(r.GetRandomValue(0, gl.SCR_HEIGHT - @as(c_int, @intFromFloat(enemy[j].rec.height)))));
                                shootRate = 0;
                                enemiesKill += 1;
                                score += 100;
                            }

                            if (shoot[i].rec.x + shoot[i].rec.width >= gl.SCR_WIDTH) {
                                shoot[i].active = false;
                                shootRate = 0;
                            }
                        }
                    }
                }
            }
        }
    } else {
        if (r.IsKeyPressed(r.KEY_ENTER)) {
            Init();
            gameOver = false;
        }
    }
}

// Draw game (one frame)
pub fn Draw() void {
    //r.BeginDrawing();

    //r.ClearBackground(r.RAYWHITE);

    if (!gameOver) {
        r.DrawRectangleRec(player.rec, player.color);

        if (wave == EnemyWave.FIRST) {
            r.DrawText("FIRST WAVE", gl.SCR_WIDTH / 2 - @divExact(r.MeasureText("FIRST WAVE", 40), 2), gl.SCR_HEIGHT / 2 - 40, 40, r.Fade(r.BLACK, alpha));
        } else if (wave == EnemyWave.SECOND) {
            r.DrawText("SECOND WAVE", gl.SCR_WIDTH / 2 - @divExact(r.MeasureText("SECOND WAVE", 40), 2), gl.SCR_HEIGHT / 2 - 40, 40, r.Fade(r.BLACK, alpha));
        } else if (wave == EnemyWave.THIRD) r.DrawText("THIRD WAVE", gl.SCR_WIDTH / 2 - @divExact(r.MeasureText("THIRD WAVE", 40), 2), gl.SCR_HEIGHT / 2 - 40, 40, r.Fade(r.BLACK, alpha));

        for (0..@as(usize, @intCast(activeEnemies))) |i| {
            if (enemy[i].active) r.DrawRectangleRec(enemy[i].rec, enemy[i].color);
        }

        for (0..gl.NUM_SHOOTS) |i| {
            if (shoot[i].active) r.DrawRectangleRec(shoot[i].rec, shoot[i].color);
        }

        r.DrawText(r.TextFormat("%04i", score), 20, 20, 40, r.GRAY);

        if (win) r.DrawText("YOU WIN", gl.SCR_WIDTH / 2 - @divExact(r.MeasureText("YOU WIN", 40), 2), gl.SCR_HEIGHT / 2 - 40, 40, r.BLACK);

        if (pause) r.DrawText("GAME PAUSED", gl.SCR_WIDTH / 2 - @divExact(r.MeasureText("GAME PAUSED", 40), 2), gl.SCR_HEIGHT / 2 - 40, 40, r.GRAY);
    } else r.DrawText("PRESS [ENTER] TO PLAY AGAIN", @divExact(r.GetScreenWidth(), 2) - @divExact(r.MeasureText("PRESS [ENTER] TO PLAY AGAIN", 20), 2), @divExact(r.GetScreenHeight(), 2) - 50, 20, r.GRAY);

    //r.EndDrawing();
}

// Unload game variables
pub fn Unload() void {
    // TODO: Unload all dynamic loaded data (textures, sounds, models...)
}

pub fn End() bool {
    return gameOver;
}
