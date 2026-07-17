# Repository Guidance

## Collaboration

- This is a learning project. Explain Zig and terminal concepts, ask guiding questions, and offer small code fragments rather than complete implementations.
- Do not edit application code unless the user explicitly asks. Prefer reviewing the user's attempt and identifying the next small experiment.

## Toolchain And Verification

- The minimum toolchain is Zig 0.16.0; the code uses its `std.Io` APIs and has no external dependencies.
- Format check: `zig fmt --check src build.zig`.
- Build: `zig build`.
- Full tests: `zig build test`; this runs both the generated `src/root.zig` module tests and the executable tests in `src/main.zig` plus imported files.
- Focus application tests with `zig test src/main.zig --test-filter "player movement"`; focus screen tests with `zig test src/screen.zig --test-filter "set rejects"`.
- Run interactively: `zig build run`; it requires a real TTY and exits when `q` is pressed. Do not run it unattended or through a non-TTY executor.

## Architecture

- `src/main.zig` is the real application entrypoint. It owns `GameState`, a timed POSIX polling loop, input/update/draw phases, one optional projectile, and inline application tests.
- `src/screen.zig` owns the fixed cell buffer, coordinate-safe writes, presentation, and inline screen tests. `src/root.zig` remains generated library scaffold, not the terminal app.
- `src/terminal.zig` owns POSIX raw-mode setup/restoration; `src/ansi.zig` owns terminal escape sequences.
- The README's single-cell `@` and “next milestone” text lags the executable; use `src/main.zig` and `todo.md` for current behavior and scope.

## Terminal And Loop Constraints

- Raw mode disables `OPOST`, so rendering must emit `\r\n` explicitly rather than relying on newline translation.
- Do not emit `\r\n` after the final frame row; advancing past it can scroll the terminal.
- Preserve deferred restoration of terminal attributes, cursor visibility, and the alternate screen on every exit/error path.
- Rendering uses a fixed `[3000]u8` buffer with `width * height == screen_buffer.len`. Guard coordinates before calculating `y * width + x`.
- Input readiness is checked with `std.posix.poll`; `std.Io.Reader.takeByte()` itself blocks. Keep the stdin reader buffer at one byte unless the loop also checks already-buffered reader data.
- The poll timeout is only a maximum wait: queued input returns immediately and currently causes extra updates. Use elapsed-time/deadline tracking before claiming a fixed simulation rate.
