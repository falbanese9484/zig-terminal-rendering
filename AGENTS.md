# Repository Guidance

## Collaboration

- This is a learning project. Explain Zig and terminal concepts, ask guiding questions, and offer small code fragments rather than complete implementations.
- Do not edit application code unless the user explicitly asks. Prefer reviewing the user's attempt and identifying the next small experiment.

## Toolchain And Commands

- Use Zig 0.16.0 or newer; `build.zig.zon` has no external dependencies.
- Format check: `zig fmt --check src build.zig`.
- Build: `zig build`.
- Run all tests: `zig build test`.
- Run the existing focused test: `zig test src/root.zig --test-filter "basic add functionality"`.
- Run interactively: `zig build run`; it requires a real TTY and exits when `q` is pressed. Do not run it unattended or through a non-TTY executor.

## Architecture

- `src/main.zig` is the executable entrypoint and currently owns input, state updates, buffer construction, and rendering.
- `src/terminal.zig` owns POSIX raw-mode setup/restoration; `src/ansi.zig` owns terminal escape sequences.
- `src/root.zig` is still generated library/test scaffold code, not the terminal application's entrypoint.

## Terminal Constraints

- Raw mode disables `OPOST`, so rendering must emit `\r\n` explicitly rather than relying on newline translation.
- Preserve deferred restoration of terminal attributes, cursor visibility, and the alternate screen on every exit/error path.
- Rendering currently uses a fixed `[3000]u8` cell buffer. Indexing is `y * width + x`, so coordinate guards and `width * height <= buf.len` are required invariants.
