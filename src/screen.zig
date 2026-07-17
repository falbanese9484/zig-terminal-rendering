const std = @import("std");

const ansi = @import("ansi.zig");

pub const Bounds = struct {
    height: usize,
    width: usize,
};

pub const Screen = struct {
    bounds: Bounds,
    screen_buffer: [3000]u8,

    const Self = @This();

    pub fn set(self: *Self, x: usize, y: usize, value: u8) bool {
        if (x >= self.bounds.width or y >= self.bounds.height) return false;

        self.screen_buffer[y * self.bounds.width + x] = value;
        return true;
    }

    pub fn clear(self: *Self) void {
        for (&self.screen_buffer) |*c| {
            c.* = ' ';
        }
    }

    pub fn present(self: *const Self, stdout: *std.Io.Writer) !void {
        try stdout.writeAll(ansi.cursor_home);
        for (0..self.bounds.height) |t| {
            const start = t * self.bounds.width;
            const end = start + self.bounds.width;

            const row = self.screen_buffer[start..end];
            try stdout.writeAll(row);
            if (t < self.bounds.height - 1) {
                try stdout.writeAll("\r\n");
            }
        }
        try stdout.flush();
    }
};

pub fn initScreen(width: usize) Screen {
    if (width == 0) {
        @panic("Width must be greater than 0");
    }

    const fixed_size_array: [3000]u8 = undefined;

    if (fixed_size_array.len % width != 0) {
        @panic("Width must be a divisor of the fixed size array length");
    }

    const height = fixed_size_array.len / width;
    if (height == 0) {
        @panic("Width is too large for the fixed size array");
    }

    return Screen{
        .bounds = Bounds{ .height = height, .width = width },
        .screen_buffer = fixed_size_array,
    };
}

test "set writes a cell at valid coordinates" {
    var screen = initScreen(50);
    screen.clear();

    try std.testing.expect(screen.set(2, 3, 'X'));
    try std.testing.expectEqual(@as(u8, 'X'), screen.screen_buffer[3 * screen.bounds.width + 2]);
}

test "set rejects coordinates outside the screen" {
    var screen = initScreen(50);
    screen.clear();

    try std.testing.expect(!screen.set(screen.bounds.width, 0, 'X'));
    try std.testing.expect(!screen.set(0, screen.bounds.height, 'X'));
}
