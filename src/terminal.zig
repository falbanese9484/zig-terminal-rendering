const std = @import("std");
const posix = std.posix;

pub fn enableRawMode() !posix.termios {
    const stdin_fd = posix.STDIN_FILENO;

    const original = try posix.tcgetattr(stdin_fd);
    var raw = original;

    raw.iflag.BRKINT = false;
    raw.iflag.ICRNL = false;
    raw.iflag.INPCK = false;

    raw.oflag.OPOST = false;

    raw.cflag.CSIZE = .CS8;

    raw.lflag.ECHO = false;
    raw.lflag.ICANON = false;
    raw.lflag.IEXTEN = false;
    raw.lflag.ISIG = false;

    raw.cc[@intFromEnum(posix.V.MIN)] = 1;
    raw.cc[@intFromEnum(posix.V.TIME)] = 0;

    try posix.tcsetattr(stdin_fd, .FLUSH, raw);
    return original;
}

pub fn restoreTerminal(original: posix.termios) void {
    posix.tcsetattr(posix.STDIN_FILENO, .FLUSH, original) catch {};
}
