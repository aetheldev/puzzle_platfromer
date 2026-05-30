# Sokoban In Sauce

Goal: if you want production-style Sokoban in this repo, do it inside `sauce/game.odin`, not separate minimal project.

## Smallest Correct Production Plan

1. Add Sokoban-specific level data to `Game_State`
2. Add Sokoban entity kinds
3. Spawn player + boxes from level file
4. Update puzzle rules in `game_update`
5. Draw via existing sprite/quad pipeline
6. Add UI via existing text/quad drawing

## Recommended Data

Add to `Game_State`:
- current level index
- level grid
- goals grid or tile metadata
- box handles list
- move count
- win state
- mode/state enum if needed

Example shape:

```odin
Level_Cell :: enum u8 { empty, wall, goal }

Game_Mode :: enum { menu, sokoban, editor, coop_test }

Game_State :: struct {
    ...
    mode: Game_Mode,
    current_level: int,
    level_cells: [ROWS][COLS]Level_Cell,
    goal_cells: [ROWS][COLS]bool,
    box_handles: [dynamic]Entity_Handle,
    move_count: int,
    level_won: bool,
}
```

## Recommended Entity Kinds

Extend `Entity_Kind` with:
- `player_sokoban`
- `box`
- maybe `goal_marker` if visual-only entity wanted

But keep walls/goals as tile data, not entities.

Good split:
- static map = tile data
- moving things = entities

## Level Load Flow

1. read text file from `res/levels/sokoban_01.txt`
2. fill tile arrays
3. create player entity where `P` found
4. create box entities where `B` found
5. camera center on board

## Update Flow

Each frame in Sokoban mode:
1. accept discrete movement input, not analog hold movement
2. convert input into grid direction
3. inspect next tile and maybe next-next tile
4. if push legal, move box entity
5. move player entity
6. increment move count
7. check all goals covered

## Rendering Flow

Use existing renderer for:
- wall quads/sprites
- goal marker sprites
- box sprites
- player sprite
- move counter text

Do not start with renderer rewrite.

## Good Production Enhancements

1. undo stack
2. level transitions
3. save progress
4. sound events for push/win/reset
5. juice: shake, glow, particles, hit flash
6. editor mode using same level format

## Exact Sauce Ticket Order

1. Add `Game_Mode.sokoban`
2. Add Sokoban level structs to `Game_State`
3. Add level loader proc
4. Add player + box entity kinds
5. Add Sokoban update proc
6. Add Sokoban draw proc
7. Add reset / next-level flow
8. Add undo
9. Add level file folder under `res/levels`

## Important Choice

For production Sokoban in this repo, do not use fundamentals code directly.
Use fundamentals only as reference.

Actual implementation should look native to `sauce/`.
