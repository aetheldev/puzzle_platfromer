# B04 — Sokoban In Sauce, Puzzle-Game Foundation

Goal: rebuild Sokoban inside `sauce/` as foundation for your co-op puzzle game.

This is more relevant than Snake/Tetris if final game is puzzle/co-op.

## Why Sokoban

Sokoban teaches production puzzle architecture:

- tile grid truth
- player entity
- crates as entities or grid objects
- pressure plates
- doors
- level reset
- undo stack
- readable puzzle feedback

## Recommended Data Split

Game_State arrays:

```odin
Tile :: enum u8 { floor, wall, goal, plate, door_closed, door_open }
tiles: [ROWS][COLS]Tile
```

Entities:

- player
- crates
- particles
- floating UI hints

Why crates as entities: they move, need animation, maybe handles, maybe effects.

## Milestones

1. Load ASCII level into `Game_State.tiles`.
2. Spawn player/crate entities from markers.
3. Player grid movement with input intent.
4. Push crate if target tile free.
5. Plate opens door.
6. Win when all crates on goals or players reach exits.
7. Add move tweening, dust, push shake.
8. Add plate glow, door open particles, success jingle hook.
9. Add undo stack.

## Visual Direction

Pick one close to final co-op mood:

- Rusty Lake room puzzle
- magical diorama
- split-tech/nature prototype
- toybox/board-game tactile look

## Why This Matters For Co-op

Your final game likely has:

- shared grid truth
- player entities
- interactable objects
- doors/switches/plates
- state changes with strong feedback

Sokoban in sauce is training for that exact architecture.
