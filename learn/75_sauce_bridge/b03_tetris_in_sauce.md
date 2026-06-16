# B03 — Tetris In Sauce, With Feel

Goal: make Tetris inside `sauce/` with real game feel: lock flash, line clear
particles, ghost piece, UI, palette, shader mood.

## Why Tetris

Tetris teaches grid truth + animated presentation split.

Truth:

- board cells
- active piece
- rotation
- collision
- line clear

Presentation:

- falling piece interpolation
- ghost piece opacity
- line clear flash
- particles per cleared block
- score/combo UI

## Sauce Structure

Add to `Game_State`:

```odin
Tetris_Cell :: enum u8 { empty, i, o, t, s, z, j, l }
Tetromino :: struct { kind: Tetris_Cell, x, y: int, rot: int }
Tetris_Mode :: enum { title, playing, line_clear, game_over }

tetris_board: [20][10]Tetris_Cell
tetris_piece: Tetromino
tetris_next: Tetromino
tetris_drop_timer: f32
tetris_lock_timer: f32
tetris_score: int
tetris_mode: Tetris_Mode
```

Entities:

- particles from cleared rows
- floating score text
- optional block debris entities

No entity per fixed board block unless doing fancy physics explosion.

## Milestones

1. Draw board + active piece.
2. Move/rotate/drop with input.
3. Collision + lock piece into board.
4. Line clear state with 0.15s flash.
5. Spawn particles from cleared cells.
6. Add ghost piece.
7. Add score/combo UI.
8. Add visual theme: CRT, glass blocks, magic runes, or factory crates.

## Feel Checklist

- hard drop shake small
- lock flash short
- line clear hitstop tiny
- combo text punch scale
- ghost piece translucent
- next piece panel readable

## Important Lesson

Tetris teaches animation state separate from board truth. Board changes instantly;
presentation can flash, fade, shake, and particles can spawn after.
