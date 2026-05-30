# Production Tickets

Use these as real roadmap for building game with `sauce/`.

## Phase 1 - Sauce Reading

1. Read `sauce/core_main.odin`
verify: explain frame flow in your own words

2. Read `sauce/game.odin`
verify: locate `Game_State`, `app_frame`, `game_update`, `game_draw`

3. Read `sauce/entity.odin`
verify: explain create/destroy/free-list flow

4. Read `sauce/core_render.odin`
verify: explain where quads are batched and submitted

## Phase 2 - Sauce Sokoban

1. Add `Game_Mode.sokoban`
verify: game boots and enters sokoban mode

2. Add Sokoban level file parsing under game layer
verify: map loads from text file

3. Add Sokoban player entity and box entity
verify: entities spawn from file markers

4. Add discrete push movement rules
verify: player can push one box and cannot walk through walls

5. Add win detection and reset
verify: all goals covered -> level complete

6. Add move counter + UI
verify: visible and increments correctly

7. Add undo
verify: step back one move including pushed box

## Phase 3 - Sauce Co-op

1. Add second player entity and second input map
verify: both can move locally at same time

2. Add asymmetric bridge collision
verify: red and blue see different traversable routes

3. Add shared pressure plate door
verify: both needed to open progression

4. Add shared camera midpoint
verify: both remain visible in one room

5. Add first full co-op test room
verify: room requires communication, not parallel repetition

## Phase 4 - Production Polish

1. Add sound events
verify: move, push, door, win all have feedback

2. Add particles and camera feedback
verify: actions feel punchier

3. Add save/load progression
verify: game resumes on last unlocked level

4. Add menu flow
verify: title -> select -> play -> win -> next level

5. Add editor/export pipeline
verify: level made in tool loads in production game
