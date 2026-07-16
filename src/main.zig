const std = @import("std");
const Io = std.Io;

const term = @import("terminal.zig");
const ansi = @import("ansi.zig");
const screen_mod = @import("screen.zig");

fn drawPlayer(s: *screen_mod.Screen, player: *const Player) void {
    _ = s.set(player.x, player.y, '@');
}

const Direction = enum {
    up,
    down,
    left,
    right,
};

const Player = struct {
    x: usize,
    y: usize,

    const Self = @This();

    pub fn move(self: *Self, direction: Direction, bounds: *const screen_mod.Bounds) void {
        switch (direction) {
            .up => {
                if (self.y > 0) {
                    self.y -= 1;
                }
            },
            .down => {
                if (self.y < bounds.height - 1) {
                    self.y += 1;
                }
            },
            .left => {
                if (self.x > 0) {
                    self.x -= 1;
                }
            },
            .right => {
                if (self.x < bounds.width - 1) {
                    self.x += 1;
                }
            },
        }
    }
};

pub fn initPlayer() Player {
    return Player{
        .x = 0,
        .y = 0,
    };
}

pub fn main(init: std.process.Init) !void {
    var out_buf: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(init.io, &out_buf);
    const stdout = &stdout_writer.interface;

    var in_buf: [128]u8 = undefined;
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

    var player = initPlayer();
    var screen = screen_mod.initScreen(50);

    screen.clear();
    drawPlayer(&screen, &player);
    try screen.present(stdout);

    while (true) {
        const byte = try stdin.takeByte();
        if (byte == 'q') break;
        const direction: ?Direction = switch (byte) {
            'w' => .up,
            's' => .down,
            'a' => .left,
            'd' => .right,
            else => null,
        };

        if (direction) |value| {
            player.move(value, &screen.bounds);
        }

        screen.clear();
        drawPlayer(&screen, &player);
        try screen.present(stdout);
    }
}
