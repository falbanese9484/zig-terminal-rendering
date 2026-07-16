# Roadmap

Current milestone: move one multi-cell ASCII sprite around a fixed logical canvas.

## 1. Clean Up The Rendering Core

- [x] Separate `Position` from the canvas
  - Keep only `x` and `y` on the position type.
  - Move `width`, `height`, and cell storage into the screen abstraction.
  - Preserve the current movement and border behavior.

- [x] Separate frame construction from presentation
  - Clear the frame by filling its cells with spaces.
  - Draw objects into the frame.
  - Present the completed frame and flush once.
  - Keep presentation read-only with respect to the cell buffer.

- [x] Introduce a `Screen` type in `src/screen.zig`
  - Store cells, width, and height.
  - Keep a fixed backing array for now.
  - Enforce `width * height == cells.len`.
  - Guard coordinates before calculating `y * width + x`.
  - Centralize cell placement so callers do not perform flat indexing.

- [x] Clean up input dispatch
  - Read one input.
  - Update player state in one dispatch point.
  - Draw and present once after the update.
  - Let unknown keys leave state unchanged.

- [ ] Tighten terminal presentation
  - Clear the physical terminal once during setup.
  - Return the cursor home before each frame.
  - Emit `\r\n` explicitly because raw mode disables `OPOST`.
  - Avoid advancing beyond the final row if it causes scrolling.
  - Preserve terminal restoration, cursor visibility, and alternate-screen cleanup.

## 2. Render One Sprite

- [ ] Define one hard-coded rectangular ASCII sprite
  - Store width, height, and read-only cells.
  - Enforce `cells.len == width * height`.
  - Use spaces as transparent cells for the first version.

- [ ] Draw the sprite into the screen
  - Iterate through sprite-local coordinates.
  - Translate local coordinates into screen coordinates.
  - Skip transparent cells.
  - Clip cells that fall outside the screen instead of panicking.

- [ ] Make movement account for sprite dimensions
  - Keep the entire sprite inside the logical canvas.
  - Handle a sprite larger than the screen without unsigned underflow.
  - Verify every edge independently.

- [ ] Add focused tests for pure screen logic
  - Set a valid cell.
  - Reject an invalid coordinate.
  - Draw a sprite at the origin.
  - Preserve cells beneath transparent sprite cells.
  - Clip a sprite at each screen edge.

## 3. Add A Timed Event Loop

- [ ] Reshape the loop into explicit phases
  - Poll input with a timeout instead of blocking indefinitely.
  - Handle available input.
  - Update application state.
  - Clear, draw, and present the frame.

- [ ] Add one projectile as application state
  - A shoot input creates or activates the projectile.
  - Advance it once per update rather than running a blocking shoot loop.
  - Deactivate it when it leaves the canvas.
  - Keep the buffer single-threaded; do not introduce a mutex.

- [ ] Support multiple projectiles only after one works
  - Store active projectiles in a bounded collection first.
  - Update and draw each projectile through the same frame loop.

## 4. Explore An Asset Editor

- [ ] Reuse `Screen` as an editable sprite canvas
  - Track an editor cursor and selected ASCII character.
  - Support place, erase, and clear operations.
  - Preview through the same presentation path as the game.

- [ ] Decide on persistence after the in-memory editor works
  - Define a small asset format with dimensions and cell data.
  - Load and save one asset.
  - Defer color and Unicode until the ASCII format is stable.

## Later

- [ ] Detect terminal dimensions and allocate the screen at runtime.
- [ ] Handle terminal resize events and clamp existing positions.
- [ ] Add color by replacing byte cells with a richer cell representation.
- [ ] Evaluate a graphical backend only if terminal constraints obstruct the intended renderer.

## Verification

- Format: `zig fmt --check src build.zig`
- Build: `zig build`
- Test: `zig build test`
- Run interactively: `zig build run` and press `q` to exit.
