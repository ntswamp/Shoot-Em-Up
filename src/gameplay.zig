const r = @cImport(@cInclude("raylib.h"));
const gl = @import("global.zig");

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
    isAlive: bool,
};

const Bullet = struct {
    rec: r.Rectangle,
    speed: r.Vector2,
    color: r.Color,
    isAlive: bool,
};

var isGameOver = false;
var isPaused = false;
var isWin = false;
var score: c_int = 0;
var player: Player = undefined;
var enemy: [gl.ENEMIES_CAP]Enemy = undefined;
var bullet: [gl.NUM_SHOOTS]Bullet = undefined;
var wave: EnemyWave = undefined;
var shootRate: c_int = 0;
var alpha: f32 = 0.0;
var aliveEnemies: c_int = 0;
var enemiesKill: c_int = 0;
var isSmooth = false;

var texPlayer: r.Texture2D = undefined;
var texEnemy: r.Texture2D = undefined;

var sdEnemyDie: r.Sound = undefined;
var sdPlayerShoot: r.Sound = undefined;
var sdWin: r.Sound = undefined;

pub fn Init() void {
    shootRate = 0;
    isPaused = false;
    isGameOver = false;
    isWin = false;
    isSmooth = false;
    wave = EnemyWave.FIRST;
    aliveEnemies = gl.WAVE_I;
    enemiesKill = 0;
    score = 0;
    alpha = 0;
    sdWin = r.LoadSound("resources/audio/won.wav");

    // Initialize player
    player.rec.x = 20;
    player.rec.y = 50;
    player.rec.width = 90;
    player.rec.height = 40;
    player.speed.x = 7;
    player.speed.y = 7;
    player.color = r.SKYBLUE;
    sdPlayerShoot = r.LoadSound("resources/audio/player_shoot.wav");
    texPlayer = r.LoadTexture("resources/textures/player.png");

    // Initialize enemies
    for (0..gl.ENEMIES_CAP) |i| {
        enemy[i].rec.width = 20;
        enemy[i].rec.height = 20;
        enemy[i].rec.x = @as(f32, @floatFromInt(r.GetRandomValue(gl.SCR_WIDTH, gl.SCR_WIDTH + 1000)));
        enemy[i].rec.y = @as(f32, @floatFromInt(r.GetRandomValue(0, gl.SCR_HEIGHT - @as(c_int, @intFromFloat(enemy[i].rec.height)))));
        enemy[i].speed.x = 7;
        enemy[i].speed.y = 7;
        enemy[i].isAlive = true;

        var red: c_int = r.GetRandomValue(1, 254);
        var g: c_int = r.GetRandomValue(1, 254);
        var b: c_int = r.GetRandomValue(1, 254);

        enemy[i].color = r.Color{
            .r = @intCast(red),
            .g = @intCast(g),
            .b = @intCast(b),
            .a = 255,
        };
    }
    sdEnemyDie = r.LoadSound("resources/audio/light_off.wav");
    texEnemy = r.LoadTexture("resources/textures/enemy.png");

    // Initialize bullets
    for (0..gl.NUM_SHOOTS) |i| {
        bullet[i].rec.x = player.rec.x;
        bullet[i].rec.y = player.rec.y + player.rec.height / 4;
        bullet[i].rec.width = 15;
        bullet[i].rec.height = 15;
        bullet[i].speed.x = 7;
        bullet[i].speed.y = 0;
        bullet[i].isAlive = false;
        bullet[i].color = r.GOLD;
    }
}

pub fn Update() void {
    if (!isGameOver) {
        if (r.IsKeyPressed('P')) isPaused = !isPaused;

        if (!isPaused) {
            switch (wave) {
                EnemyWave.FIRST => {
                    if (!isSmooth) {
                        alpha = alpha + 0.02;
                        if (alpha >= 1.0) isSmooth = true;
                    }

                    if (isSmooth) alpha -= 0.02;
                    if (enemiesKill == aliveEnemies) {
                        enemiesKill = 0;

                        for (0..@as(usize, @intCast(aliveEnemies))) |i| {
                            if (!enemy[i].isAlive) enemy[i].isAlive = true;
                        }

                        aliveEnemies = gl.WAVE_II;
                        wave = EnemyWave.SECOND;
                        isSmooth = false;
                        alpha = 0.0;
                    }
                },
                EnemyWave.SECOND => {
                    if (!isSmooth) {
                        alpha = alpha + 0.02;
                        if (alpha >= 1.0) isSmooth = true;
                    }

                    if (isSmooth) alpha -= 0.02;
                    if (enemiesKill == aliveEnemies) {
                        enemiesKill = 0;

                        for (0..@as(usize, @intCast(aliveEnemies))) |i| {
                            if (!enemy[i].isAlive) enemy[i].isAlive = true;
                        }

                        aliveEnemies = gl.WAVE_III;
                        wave = EnemyWave.THIRD;
                        isSmooth = false;
                        alpha = 0.0;
                    }
                },
                EnemyWave.THIRD => {
                    if (!isSmooth) {
                        alpha = alpha + 0.02;

                        if (alpha >= 1.0) isSmooth = true;
                    }

                    if (isSmooth) alpha -= 0.02;
                    if (enemiesKill == aliveEnemies) isWin = true;
                    r.PlaySound(sdWin);
                },
            }

            // Player movement
            if (r.IsKeyDown(r.KEY_RIGHT)) player.rec.x += player.speed.x;
            if (r.IsKeyDown(r.KEY_LEFT)) player.rec.x -= player.speed.x;
            if (r.IsKeyDown(r.KEY_UP)) player.rec.y -= player.speed.y;
            if (r.IsKeyDown(r.KEY_DOWN)) player.rec.y += player.speed.y;

            // Player collision with enemy

            for (0..@as(usize, @intCast(aliveEnemies))) |i| {
                if (r.CheckCollisionRecs(player.rec, enemy[i].rec)) isGameOver = true;
            }

            // Enemy behaviour
            for (0..@as(usize, @intCast(aliveEnemies))) |i| {
                if (enemy[i].isAlive) {
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
            //if (r.IsKeyDown(r.KEY_SPACE)) {   //autoshoot
            shootRate += 2;

            for (0..gl.NUM_SHOOTS) |i| {
                if (!bullet[i].isAlive and @mod(shootRate, 20) == 0) {
                    r.PlaySound(sdPlayerShoot);
                    bullet[i].rec.x = player.rec.x;
                    bullet[i].rec.y = player.rec.y + player.rec.height / 4;
                    bullet[i].isAlive = true;
                    break;
                }
            }
            //}

            // Shoot logic
            for (0..gl.NUM_SHOOTS) |i| {
                if (bullet[i].isAlive) {
                    // Movement
                    bullet[i].rec.x += bullet[i].speed.x;

                    // Collision with enemy
                    for (0..@as(usize, @intCast(aliveEnemies))) |j| {
                        if (enemy[j].isAlive) {
                            if (r.CheckCollisionRecs(bullet[i].rec, enemy[j].rec)) {
                                r.PlaySound(sdEnemyDie);
                                bullet[i].isAlive = false;
                                enemy[j].rec.x = @as(f32, @floatFromInt(r.GetRandomValue(gl.SCR_WIDTH, gl.SCR_WIDTH + 1000)));
                                enemy[j].rec.y = @as(f32, @floatFromInt(r.GetRandomValue(0, gl.SCR_HEIGHT - @as(c_int, @intFromFloat(enemy[j].rec.height)))));
                                shootRate = 0;
                                enemiesKill += 1;
                                score += 100;
                            }

                            if (bullet[i].rec.x + bullet[i].rec.width >= gl.SCR_WIDTH) {
                                bullet[i].isAlive = false;
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
            isGameOver = false;
        }
    }
}

pub fn Draw() void {
    if (!isGameOver) {
        //r.DrawRectangleRec(player.rec, player.color);
        r.DrawTexture(texPlayer, @as(c_int, @intFromFloat(player.rec.x)) - 90, @as(c_int, @intFromFloat(player.rec.y)) - 20, player.color);

        if (wave == EnemyWave.FIRST) {
            r.DrawText("FIRST WAVE", gl.SCR_WIDTH / 2 - @divExact(r.MeasureText("FIRST WAVE", 40), 2), gl.SCR_HEIGHT / 2 - 40, 40, r.Fade(r.BLACK, alpha));
        } else if (wave == EnemyWave.SECOND) {
            r.DrawText("SECOND WAVE", gl.SCR_WIDTH / 2 - @divExact(r.MeasureText("SECOND WAVE", 40), 2), gl.SCR_HEIGHT / 2 - 40, 40, r.Fade(r.BLACK, alpha));
        } else if (wave == EnemyWave.THIRD) r.DrawText("THIRD WAVE", gl.SCR_WIDTH / 2 - @divExact(r.MeasureText("THIRD WAVE", 40), 2), gl.SCR_HEIGHT / 2 - 40, 40, r.Fade(r.BLACK, alpha));

        for (0..@as(usize, @intCast(aliveEnemies))) |i| {
            if (enemy[i].isAlive) {
                //r.DrawRectangleRec(enemy[i].rec, enemy[i].color);
                r.DrawTexture(texEnemy, @as(c_int, @intFromFloat(enemy[i].rec.x)) - 32, @as(c_int, @intFromFloat(enemy[i].rec.y)) - 20, enemy[i].color);
            }
        }

        for (0..gl.NUM_SHOOTS) |i| {
            if (bullet[i].isAlive) r.DrawRectangleRec(bullet[i].rec, bullet[i].color);
        }

        r.DrawText(r.TextFormat("%04i", score), 20, 20, 40, r.MAROON);

        if (isWin) r.DrawText("YOU WIN", gl.SCR_WIDTH / 2 - @divExact(r.MeasureText("YOU WIN", 40), 2), gl.SCR_HEIGHT / 2 - 40, 40, r.BLACK);

        if (isPaused) r.DrawText("GAME PAUSED", gl.SCR_WIDTH / 2 - @divExact(r.MeasureText("GAME PAUSED", 40), 2), gl.SCR_HEIGHT / 2 - 40, 40, r.GRAY);
    } else r.DrawText("PRESS [ENTER] TO PLAY AGAIN", @divExact(r.GetScreenWidth(), 2) - @divExact(r.MeasureText("PRESS [ENTER] TO PLAY AGAIN", 20), 2), @divExact(r.GetScreenHeight(), 2) - 50, 20, r.GRAY);
}

pub fn Unload() void {
    // Unload dynamic loaded resources (textures, sounds, models...)
    r.UnloadSound(sdEnemyDie);
    r.UnloadSound(sdPlayerShoot);
    r.UnloadSound(sdWin);

    r.UnloadTexture(texPlayer);
    r.UnloadTexture(texEnemy);
}

pub fn End() bool {
    return isGameOver;
}
