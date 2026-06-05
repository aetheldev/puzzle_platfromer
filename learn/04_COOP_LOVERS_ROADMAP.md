# Co-op Lovers Roadmap

Goal: learn enough Odin/Sokol/game design to build a small asymmetric co-op puzzle game you can play with your wife.

Target feeling: BOKURA's shared world with different truths, We Were Here's communication puzzles, Rusty Lake's symbols and mystery, Escape Simulator's readable object logic.

This roadmap is personal. It sits on top of the existing `learn/` path. Use `learn/02_MASTER_TICKET_LIST.md` for the full checklist; use this file to keep the final game direction clear.

---

## Current Project State

- Stack: Odin + Sokol + FMOD.
- `learn/` is the training path.
- `sauce/` is the real production game template.
- `sauce/game.odin` currently has a single-player demo entity.
- Working co-op prototype reference exists at `learn/95_solutions/co_op/different_views_puzzle/prototype/main.odin`.
- Build verified on macOS with `./build_mac.sh`.

---

## Game Pitch

Two people are trapped in the same place, but each sees a different truth. They cannot solve rooms alone. One sees clues, one operates locks. One can walk through one layer, the other through another. Progress happens only through communication.

First version: local same-screen co-op, one keyboard.

Later version: split view or different render layers.

Last version: online rooms.

---

## Hard Rule

Do not start with networking.

Networking comes after the local game is fun with two people in the same room. Early networking is the biggest scope trap for this project.

Do one network-ready thing early: use `Player_Intent` so gameplay does not read keyboard directly.

Read: `learn/85_networking/03_input_for_networked_coop.md`.

Player intent is not optional for this project. Add it before the first real co-op prototype gets big. If player movement reads keyboard directly, local co-op, split controls, replay, and networking all become harder later.

Minimal version:

```odin
Player_Intent :: struct {
    move: Vec2,
    interact: bool,
}
```

Rule:
- input layer fills `Player_Intent`
- gameplay reads `Player_Intent`
- gameplay never asks "which key is down?"

---

## Learning Roadmap

### Phase 0 - Setup

Goal: prove environment works, then stop thinking about setup.

Do:
- Run `odin version`.
- Run `./build_mac.sh`.
- Run a tiny graphics lesson with `zsh build.sh`.

Read:
- `learn/00_START_HERE.md`
- `learn/02_MASTER_TICKET_LIST.md`

Exit criteria:
- You can build the repo.
- You know where the next ticket lives.

### Phase 1 - Odin Basics

If Odin is new, do:
- `learn/10_odin_for_js_devs/o01` through `o16`.

Focus on:
- structs
- enums
- procs
- arrays/slices
- pointers
- defer
- context
- compiler errors

Exit criteria:
- You can write a small Odin program without copying.
- You can explain every line you wrote.

### Phase 2 - Game Thinking

Read:
- `learn/20_game_thinking_for_web_devs/`

Focus on:
- game loop
- state without hooks
- immediate mode vs retained mode
- no async in game loop
- input every frame
- delta time
- GPU basics

Exit criteria:
- You understand why games update every frame.
- You stop thinking in React component lifecycle terms.

### Phase 3 - Fundamentals

Do these lessons in order:
- `t01_hello_window`
- `t02_shapes_colors`
- `t03_movement`
- `t07_tilemap`
- `t08_camera`
- `t10_particles_screenshake`
- `t12_integration_room`

Important for this game:
- movement
- collision
- tilemap
- camera
- simple feedback
- level state

Exit criteria:
- You can move a player around a tile room.
- You can draw different tile types.
- You can detect wall collision.

### Phase 4 - Single-Player Puzzle Logic

Do:
- `learn/60_projects/sokoban/`

Why:
- Puzzle games are rules + state + reset.
- Co-op puzzle is harder if single-player puzzle rules are shaky.

Learn:
- grid movement
- box push
- goal check
- reset
- level data

Exit criteria:
- You can explain how Sokoban checks valid movement.
- You can add one new tile type.

### Phase 5 - Local Co-op Prototype

Do:
- `learn/70_co_op/different_views_puzzle/prototype/LESSON.md`

Reference only when instructed:
- `learn/95_solutions/co_op/different_views_puzzle/prototype/main.odin`

Learn:
- two players
- WASD + arrows
- role-based collision
- pressure plates
- shared door
- both-on-goal win condition

Exit criteria:
- Two people can play one room.
- One player cannot solve alone.

### Phase 6 - Your First Lovers Prototype

Create a throwaway prototype under `learn/80_design/coop_lovers_puzzle/` or a scratch folder.

Milestone 1:
- one room
- two players
- wall collision
- same camera

Milestone 2:
- red-only floor
- blue-only floor
- each player has different collision truth

Milestone 3:
- red lever
- blue lever
- shared door opens when both are active

Milestone 4:
- clue only one player can see
- lock only other player can operate
- communication required

Milestone 5:
- second room
- both reach exit
- tiny complete campaign

Exit criteria:
- You and your wife can finish 2-3 rooms.
- At least one room requires talking.

Room design checklist:
- One new idea per room.
- Room can be understood in 10 seconds.
- Room teaches before it tests.
- Player A owns one missing piece.
- Player B owns one missing piece.
- Neither player can solve alone.
- Failure state is clear.
- Reset is instant.
- Hint exists if players get stuck for 2 minutes.
- Visual language is consistent: same symbol means same rule.

Playtest checklist:
- Test with two humans, not only yourself.
- Do not explain first; watch what confuses them.
- Write down first 3 confusion points.
- If both players stop talking, puzzle failed.
- If one player commands and the other only obeys, role balance failed.
- If they solve by brute force, clue design failed.
- If they laugh, argue, or say "wait, what do you see?", puzzle is working.
- After test, fix only the biggest confusion. Do not redesign whole game.

### Phase 7 - Move Into Sauce

After standalone prototype works, rebuild inside `sauce/`.

Read:
- `learn/90_production_with_sauce/04_coop_puzzle_in_sauce.md`
- `learn/90_production_with_sauce/01_architecture_map.md`
- `learn/templates/SAUCE_MIGRATION_TICKETS.md`
- for the BOKURA two-world look in sauce (two players + theme fork, with exact
  file/line references): `learn/90_production_with_sauce/13_parallel_worlds_coop_in_sauce.md`

Add to `sauce/game.odin`:
- `player2_handle`
- player role enum
- door/plate state
- tile data
- two input mappings
- shared camera midpoint
- level complete state

Small migration tickets:

1. Add empty co-op mode flag.
   - Add simple enum: `Game_Mode :: enum { demo, coop_lovers }`.
   - Keep old demo running.

2. Add `Player_Intent`.
   - Add struct.
   - Add `intent` field or per-player intent storage.
   - Refactor current player movement to read intent.

3. Add second local intent.
   - Red: WASD + E.
   - Blue: arrows + right shift / enter.
   - No second player entity yet.

4. Add second player entity.
   - Add `player2_handle`.
   - Spawn red and blue.
   - Both move independently.

5. Add roles.
   - `Player_Role :: enum { red, blue }`.
   - Store role on entity or lookup table.
   - Draw red/blue tint.

6. Add tiny tile map.
   - ASCII map first.
   - Wall + empty only.
   - Both collide with walls.

7. Add role collision.
   - Red-only tile blocks blue.
   - Blue-only tile blocks red.
   - Keep rule in one proc: `tile_blocks_player`.

8. Add shared puzzle state.
   - Red plate.
   - Blue plate.
   - Door opens when both active.

9. Add win state.
   - Both players reach exit.
   - Show simple UI text.

10. Add camera midpoint.
   - Camera target = average of red and blue positions.
   - Clamp later, not now.

11. Add reset.
   - Press `R` to reload room state.
   - Must work before adding more rooms.

12. Add second room.
   - Prove level loading is not hardcoded to one map.
   - Only then add more puzzle mechanics.

Touch `core_*` only if needed for:
- split screen
- multiple gamepads
- networking
- post-process view differences

Exit criteria:
- Your local co-op game runs from `./build_mac.sh`.

### Phase 8 - BOKURA-Style Different Truth

Do this after local same-screen version works.

THE TRICK (this is the part people get stuck on): there are NOT two worlds.
There is ONE world (one tile grid, one set of entities, one collision truth),
drawn TWICE with a different costume each time. A `Theme` enum (e.g. tech /
nature) chosen at DRAW time picks each tile's and each character's sprite. Same
wall → metal panel for one player, mossy log for the other. Same partner → robot
to one, animal to the other. That is the whole BOKURA illusion.

Two layers, build in order:
- Cosmetic fork: every tile exists for both, collision identical, only the
  sprite/palette differ per theme. Communication = describing what you see.
- Truth fork: some tiles are solid ground in one theme and empty void in the
  other. Communication = guiding each other across gaps you cannot see.

Read + run (this is the missing lesson that explains and proves it):
- `learn/80_design/coop_lovers_puzzle/PARALLEL_WORLDS.md`
- `learn/70_co_op/parallel_worlds_puzzle/README.md`
- `learn/70_co_op/parallel_worlds_puzzle/prototype/LESSON.md`
- runnable answer: `learn/95_solutions/co_op/parallel_worlds_puzzle/prototype/`

How each player gets their own view (same `draw_world(theme)` call either way):
- split screen (prototype)
- two cameras / two windows (local)
- networked, full-screen per client (the real BOKURA setup)
- optional moods per view via `learn/45_shaders_postfx/` (fog, CRT, grading, bloom)

Design rule:
- Same world, different truth.
- Different truth must create communication, not confusion.
- The two-worlds LOOK is a costume. It is empty without a puzzle under it.

Exit criteria:
- Each player has information the other does not.
- The puzzle is impossible without verbal exchange.

### Phase 9 - Polish

Add only after core rooms are fun:
- sound cues
- glow
- fog/darkness
- screen shake
- particle feedback
- hint UI
- title screen
- short reunion ending

Do not polish boring rooms. Fix room design first.

### Phase 10 - Online Co-op

Last phase.

Recommended path:
- Steam lobbies and relay via `sauce/steamworks/`.

Read:
- `learn/85_networking/README.md`
- `learn/85_networking/04_steam_lobbies_path.md`

Avoid early raw sockets unless goal is learning networking itself.

---

## First 30 Days

Week 1:
- Finish Odin basics you need most.
- Do `t01`, `t02`, `t03`.

Week 2:
- Do `t07`, `t08`.
- Build tiny tile room.
- Start Sokoban.

Week 3:
- Finish Sokoban basics.
- Do `different_views_puzzle` prototype.

Week 4:
- Build your first lovers room.
- Add one information-gap puzzle.
- Playtest with your wife.

---

## Design Rules

- One mechanic per room at first.
- Room 1 must teach communication in 30 seconds.
- Never let one player solve the full room alone.
- Do not make both players do the same job in parallel.
- Use symbols/shapes, not only colors.
- Add reset from day one.
- Add hints before players get annoyed.
- Test with two real humans early.
- Keep first complete game to 3 rooms.
- Prefer authored rooms over random/procedural puzzles.
- Make puzzle answer feel earned, not guessed.
- Build tension with information gaps, not obscure UI.

---

## Technical Rules

- Use ASCII maps first.
- Use rectangles before sprites.
- Use `Player_Intent` from the start.
- Keep gameplay in game layer first.
- Avoid touching renderer/core until needed.
- Local first, online last.
- Build playable slices, not systems in isolation.
- Keep one source of truth for level state.
- Keep collision rules in one proc.
- Keep room reset cheap and reliable.
- Save split screen for after same-screen co-op works.

---

## Today's Task

Run the existing co-op reference:

```sh
cd learn/95_solutions/co_op/different_views_puzzle/prototype
zsh build.sh
```

Then read:

`learn/70_co_op/different_views_puzzle/prototype/LESSON.md`

Then write the same idea from memory in the lesson folder. Change one thing: add a new tile or make a new room layout.
