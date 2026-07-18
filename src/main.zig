const std = @import("std");
const Io = std.Io;

const term = @import("terminal.zig");
const ansi = @import("ansi.zig");
const screen_mod = @import("screen.zig");

fn handleInput(state: *GameState, input: u8, bounds: *const screen_mod.Bounds) !void {
    switch (input) {
        'w' => state.player.move(.up, bounds, &state.player_sprite),
        's' => state.player.move(.down, bounds, &state.player_sprite),
        'a' => state.player.move(.left, bounds, &state.player_sprite),
        'd' => state.player.move(.right, bounds, &state.player_sprite),
        ' ' => try state.triggerProjectile(&state.player),
        'q' => state.running = false,
        else => {},
    }
}

fn setRandomTarget(
    state: *GameState,
    bounds: *const screen_mod.Bounds,
    random: std.Random,
) void {
    // Needs player bounds i.e. the wdth and height of the sprite
    state.target = .{
        .x = random.uintLessThan(usize, bounds.width - 2),
        .y = random.uintLessThan(usize, bounds.height - 4),
        .value = 'X',
    };
}

fn update(state: *GameState, bounds: *const screen_mod.Bounds, random: std.Random) void {
    // I think this makes sense to put here..
    state.setCollisionNull();

    if (state.target == null) {
        setRandomTarget(state, bounds, random);
    }
    if (state.projectiles.items.len > 0) {
        var i: usize = 0;
        while (i < state.projectiles.items.len) : (i += 1) {
            var proj = &state.projectiles.items[i];
            if (proj.y == 0) {
                _ = state.projectiles.swapRemove(i);
                // Do not increment i, as the next projectile has shifted into this index
            } else {
                proj.y -= 1;
            }
            if (state.target) |target| {
                if (target.x == proj.x and target.y == proj.y) {
                    // Collision occured, wipe the projectile and the target and set the action
                    state.setCollision(target.x, target.y, '-');
                    state.target = null;
                    _ = state.projectiles.swapRemove(i);
                }
            }
        }
    }
}

fn drawFrame(screen: *screen_mod.Screen, state: *const GameState) void {
    screen.clear();
    drawPlayer(screen, &state.player, &state.player_sprite);
    if (state.projectiles.items.len > 0) {
        for (state.projectiles.items) |proj| {
            _ = screen.set(proj.x, proj.y, proj.value);
        }
    }
    if (state.target) |target| {
        _ = screen.set(target.x, target.y, target.value);
    }
    if (state.collision) |collision| {
        // We need to check bounds here to make sure we dont overflow
        _ = screen.set(collision.x, collision.y + 1, collision.value);
        _ = screen.set(collision.x, collision.y - 1, collision.value);
    }
}

fn drawPlayer(s: *screen_mod.Screen, player: *const Player, player_sprite: *const Sprite) void {
    // Putting this here for now but will eventually enforece cells.len at a spriteInit level...I think
    if (player_sprite.cells.len != player_sprite.height * player_sprite.width) {
        @panic("Sprite cells length does not match height * width");
    }
    for (0..player_sprite.height) |row| {
        for (0..player_sprite.width) |col| {
            const sprite_index = row * player_sprite.width + col;
            const sprite_char = player_sprite.cells[sprite_index];
            if (sprite_char != ' ') {
                _ = s.set(player.x + col, player.y + row, sprite_char);
            }
        }
    }
}

const Direction = enum {
    up,
    down,
    left,
    right,
};

const Sprite = struct {
    height: usize,
    width: usize,
    cells: []const u8,
};

const Player = struct {
    x: usize,
    y: usize,

    const Self = @This();

    pub fn move(self: *Self, direction: Direction, bounds: *const screen_mod.Bounds, sprite: *const Sprite) void {
        if (sprite.width > bounds.width or sprite.height > bounds.height) {
            return;
        }
        switch (direction) {
            .up => {
                if (self.y > 0) {
                    self.y -= 1;
                }
            },
            .down => {
                if (self.y < bounds.height - sprite.height) {
                    self.y += 1;
                }
            },
            .left => {
                if (self.x > 0) {
                    self.x -= 1;
                }
            },
            .right => {
                if (self.x < bounds.width - sprite.width) {
                    self.x += 1;
                }
            },
        }
    }
};

const Projectile = struct {
    x: usize,
    y: usize,
    value: u8,
};

const Target = struct {
    x: usize,
    y: usize,
    value: u8,
};

const Collision = struct {
    x: usize,
    y: usize,
    value: u8,
};

const GameState = struct {
    player: Player,
    player_sprite: Sprite,
    projectiles: std.ArrayList(Projectile),
    target: ?Target,
    running: bool,
    collision: ?Collision,

    const Self = @This();

    fn triggerProjectile(self: *Self, player: *const Player) !void {
        if (self.projectiles.items.len == self.projectiles.capacity) {
            return;
        }
        const proj = Projectile{
            .x = player.x + 2, // Center of the player sprite
            .y = player.y - 1, // Just above the player
            .value = '|',
        };
        _ = try self.projectiles.appendBounded(proj);
    }

    fn setCollision(self: *Self, x: usize, y: usize, value: u8) void {
        self.collision = .{
            .x = x,
            .y = y,
            .value = value,
        };
    }

    fn setCollisionNull(self: *Self) void {
        self.collision = null;
    }
};

pub fn initPlayer(height: usize) Player {
    return Player{
        .x = 0,
        .y = height,
    };
}

pub fn main(init: std.process.Init) !void {
    var seed: u64 = undefined;
    init.io.random(std.mem.asBytes(&seed));

    var prng = std.Random.DefaultPrng.init(seed);
    const random = prng.random();
    var out_buf: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(init.io, &out_buf);
    const stdout = &stdout_writer.interface;

    var in_buf: [1]u8 = undefined;
    var stdin_reader = std.Io.File.stdin().reader(init.io, &in_buf);

    const stdin = &stdin_reader.interface;

    const original = try term.enableRawMode();
    defer term.restoreTerminal(original);

    try stdout.print("{s}{s}{s}", .{ ansi.enter_alt_screen, ansi.hide_cursor, ansi.clear_screen });
    try stdout.flush();

    defer {
        stdout.print("{s}{s}", .{ ansi.show_cursor, ansi.leave_alt_screen }) catch {};
        stdout.flush() catch {};
    }

    const player_sprite = Sprite{
        .width = 5,
        .height = 3,
        .cells = " /^\\ " ++
            "<@@@>" ++
            " / \\ ",
    };
    var screen = screen_mod.initScreen(100);
    var player = initPlayer(screen.bounds.height - player_sprite.height);

    screen.clear();
    drawPlayer(&screen, &player, &player_sprite);
    try screen.present(stdout);

    var projectiles: [8]Projectile = undefined;
    const projs = std.ArrayList(Projectile).initBuffer(&projectiles);

    var state = GameState{
        .player = player,
        .projectiles = projs,
        .running = true,
        .player_sprite = player_sprite,
        .target = null,
        .collision = null,
    };

    setRandomTarget(&state, &screen.bounds, random);

    var poll_fds = [_]std.posix.pollfd{.{
        .fd = std.posix.STDIN_FILENO,
        .events = std.posix.POLL.IN,
        .revents = 0,
    }};

    while (true) {
        const ready = try std.posix.poll(&poll_fds, 50);
        if (ready > 0 and
            poll_fds[0].revents & std.posix.POLL.IN == std.posix.POLL.IN)
        {
            const input = try stdin.takeByte();
            try handleInput(&state, input, &screen.bounds);
        }
        if (!state.running) {
            break;
        }
        update(&state, &screen.bounds, random);
        drawFrame(&screen, &state);
        try screen.present(stdout);
    }
}

test "drawPlayer draws at the origin and preserves transparent cells" {
    const sprite = Sprite{
        .width = 3,
        .height = 2,
        .cells = " A " ++
            "BCD",
    };
    const player = Player{ .x = 0, .y = 0 };
    var screen = screen_mod.initScreen(50);
    screen.clear();
    _ = screen.set(0, 0, '#');

    drawPlayer(&screen, &player, &sprite);

    try std.testing.expectEqual(@as(u8, '#'), screen.screen_buffer[0]);
    try std.testing.expectEqual(@as(u8, 'A'), screen.screen_buffer[1]);
    try std.testing.expectEqualSlices(u8, "BCD", screen.screen_buffer[50..53]);
}

test "drawPlayer clips cells beyond the right and bottom edges" {
    const sprite = Sprite{
        .width = 2,
        .height = 2,
        .cells = "AB" ++
            "CD",
    };
    var screen = screen_mod.initScreen(50);
    screen.clear();
    const player = Player{
        .x = screen.bounds.width - 1,
        .y = screen.bounds.height - 1,
    };

    drawPlayer(&screen, &player, &sprite);

    try std.testing.expectEqual(@as(u8, 'A'), screen.screen_buffer[screen.screen_buffer.len - 1]);
}

test "player movement reaches and stops at every screen edge" {
    const sprite = Sprite{
        .width = 3,
        .height = 2,
        .cells = "ABC" ++
            "DEF",
    };
    const bounds = screen_mod.Bounds{ .width = 10, .height = 8 };
    var player = Player{ .x = 6, .y = 5 };

    player.move(.right, &bounds, &sprite);
    player.move(.down, &bounds, &sprite);
    try std.testing.expectEqual(@as(usize, 7), player.x);
    try std.testing.expectEqual(@as(usize, 6), player.y);

    player.move(.right, &bounds, &sprite);
    player.move(.down, &bounds, &sprite);
    try std.testing.expectEqual(@as(usize, 7), player.x);
    try std.testing.expectEqual(@as(usize, 6), player.y);

    player.x = 0;
    player.y = 0;
    player.move(.left, &bounds, &sprite);
    player.move(.up, &bounds, &sprite);
    try std.testing.expectEqual(@as(usize, 0), player.x);
    try std.testing.expectEqual(@as(usize, 0), player.y);
}

test "player movement handles exact-fit and oversized sprites" {
    const bounds = screen_mod.Bounds{ .width = 5, .height = 3 };
    const exact_fit = Sprite{
        .width = 5,
        .height = 3,
        .cells = "12345" ++
            "67890" ++
            "abcde",
    };
    const oversized = Sprite{
        .width = 6,
        .height = 3,
        .cells = "123456" ++
            "7890ab" ++
            "cdefgh",
    };
    var player = Player{ .x = 0, .y = 0 };

    player.move(.right, &bounds, &exact_fit);
    player.move(.down, &bounds, &exact_fit);
    try std.testing.expectEqual(@as(usize, 0), player.x);
    try std.testing.expectEqual(@as(usize, 0), player.y);

    player.move(.right, &bounds, &oversized);
    player.move(.down, &bounds, &oversized);
    try std.testing.expectEqual(@as(usize, 0), player.x);
    try std.testing.expectEqual(@as(usize, 0), player.y);
}
