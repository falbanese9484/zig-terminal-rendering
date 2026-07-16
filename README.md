# Zig Buffer Thing

A small, dependency-free Zig project for learning terminal rendering and
buffer-based screen updates. The current application draws a movable `@` on a
fixed logical canvas while handling POSIX raw mode and ANSI terminal cleanup.

## Requirements

- Zig 0.16.0 or newer
- A POSIX-compatible terminal with ANSI escape sequence support

## Run

```sh
zig build run
```

The program is interactive and must be run in a real terminal.

### Controls

| Key | Action |
| --- | --- |
| `w` | Move up |
| `a` | Move left |
| `s` | Move down |
| `d` | Move right |
| `q` | Quit |

Movement is constrained to the logical canvas.

## Development

Build the executable:

```sh
zig build
```

Run all tests:

```sh
zig build test
```

Run the generated library test directly:

```sh
zig test src/root.zig --test-filter "basic add functionality"
```

Check formatting:

```sh
zig fmt --check src build.zig
```

## Project Structure

```text
src/
├── main.zig      # Application state, input loop, drawing, and presentation
├── screen.zig    # Fixed-size cell buffer and coordinate-safe cell placement
├── terminal.zig  # POSIX raw-mode setup and restoration
├── ansi.zig      # ANSI escape sequences
└── root.zig      # Generated library and test scaffold
```

`Screen` currently owns a fixed 3,000-byte backing array. With the configured
width of 50 cells, this produces a 50×60 logical canvas. Each frame is cleared,
the player is drawn into the cell buffer, and the completed frame is written to
the terminal in one presentation phase.

## Current Scope

This is a learning project rather than a finished game. The next milestone is
to replace the single-cell player with a movable, multi-cell ASCII sprite. The
longer-term roadmap in [`todo.md`](todo.md) covers sprite clipping, focused
screen tests, a timed event loop, projectiles, and an ASCII asset editor.

## Terminal Behavior

At startup, the application:

- enables raw input mode;
- enters the terminal's alternate screen;
- hides the cursor; and
- clears the display.

Deferred cleanup restores the original terminal attributes, shows the cursor,
and leaves the alternate screen when the application exits normally or returns
an error.
