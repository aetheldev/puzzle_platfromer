# How To Build The Two-Lovers Game — With This Repo Or Without

You asked: "how do I build this, with this repo or without it?" Both work. Here
is an honest comparison and a concrete path for each.

---

## Short Answer

Build it **with this repo**, in stages:
1. First as a **standalone learning prototype** under `learn/` (fast, isolated).
2. Then as a **real mode inside `sauce/`** (the production engine with all the
   boilerplate you wanted).

You do NOT have to choose forever. The standalone prototype is throwaway practice.
The `sauce/` version is the real game. Doing both, in that order, is the point of
this whole `learn/` folder.

---

## Why The Repo Helps You (your instinct was right)

You said you came to this repo "because there is a bunch of boilerplate." Correct.
For a two-player puzzle game you need, and `sauce/` already provides:

- window + GPU setup (Sokol) — you don't write platform code
- a frame loop with update/draw split
- a renderer for sprites/shapes/text — `sauce/core_render.odin`
- a shader build pipeline — `sauce/build/build.odin` + `sokol-shdc`
- a game state struct to hang your data on — `Game_State` in `sauce/game.odin:42`
- input handling
- an entity system

Writing all of that yourself before you can even move two squares is exactly the
trap that makes people quit. The repo skips it. That is a real advantage.

---

## Path 1 — Build It WITH This Repo (recommended)

### Stage A — Standalone prototype (practice, throwaway)
Goal: feel the gameplay fast, in an isolated folder, no engine integration.

1. Do the existing co-op lesson first — it is literally your Milestone 1-3:
   - `learn/co_op/different_views_puzzle/README.md`
   - `learn/co_op/different_views_puzzle/prototype/LESSON.md`
   - runnable answer: `learn/solutions/co_op/different_views_puzzle/prototype/`
2. Copy that prototype into your own scratch folder and reshape it toward the
   "lovers" milestones in this folder's `README.md`.
3. Build/run a lesson-style folder with:
   ```sh
   cd <your-prototype-folder>
   zsh build.sh
   ```
   (Each lesson folder's `build.sh` shows the exact command, using
   `-collection:sokol=...`.)

When Milestones 1-5 feel fun with a friend, the prototype has done its job.

### Stage B — Rebuild as a real mode in `sauce/` (the actual game)
Goal: make it a production feature with the engine's renderer, build, and state.

1. Read the production guides (they exist for exactly this):
   - `learn/production_with_sauce/04_coop_puzzle_in_sauce.md`
   - `learn/production_with_sauce/01_architecture_map.md`
   - `learn/advanced/a13_coop_game_in_sauce_plus_fx.md`
2. Read the migration checklist: `learn/SAUCE_MIGRATION_TICKETS.md` (Co-op section).
3. In `sauce/`:
   - add a game mode for your co-op puzzle
   - put tile data + two `Lover`s + lever/door state on `Game_State`
     (`sauce/game.odin:42`)
   - per-player collision rules in the update proc
   - draw tiles/levers/lovers via the existing renderer (`sauce/core_render.odin`)
   - win when both reach the exit
4. Build the whole repo:
   ```sh
   ./build_mac.sh
   cd build/mac_debug && ./game
   ```
   (Build internals: `sauce/build/build.odin`. Skip shader regen with
   `odin run ./sauce/build -- skip_shader_regen` while iterating.)

This is your real game. The standalone prototype was the rehearsal.

---

## Path 2 — Build It WITHOUT This Repo (from scratch)

Valid, but you rebuild the boilerplate yourself. Choose this only if you want to
own every line, or want a cleaner/simpler base than `sauce/`.

### Option 2a — Odin + Sokol from scratch
Closest to what you already know from the lessons.
- Official Odin Sokol bindings: https://github.com/floooh/sokol-odin
- Study a real Odin+Sokol game's structure: Solar Storm
  https://odin-lang.org/showcase/solar_storm
- You reimplement: window, render loop, 2D drawing, shader build, input. The
  fundamentals lessons (`t01`-`t12`) already taught you each piece.

### Option 2b — Odin + Raylib (EASIEST from-scratch start)
Raylib ships with Odin's `vendor` collection. Far less setup than Sokol. Best if
you want to prototype your game fast outside this repo.
- Karl Zylinski's guide (do this exactly): 
  https://zylinski.se/posts/no-engine-gamedev-using-odin-and-raylib/
- Minimal start:
  ```odin
  package game
  import rl "vendor:raylib"
  main :: proc() {
      rl.InitWindow(1280, 720, "Two Lovers")
      for !rl.WindowShouldClose() {
          rl.BeginDrawing()
          rl.ClearBackground({160, 200, 255, 255})
          rl.EndDrawing()
      }
      rl.CloseWindow()
  }
  ```
  Run with `odin run .` in that folder.
- Raylib gives you draw-rectangle, input, and text in one function call each —
  perfect for a tile-based two-player puzzle prototype.

### Option 2c — Beginner 2D library: Karl2D
- https://github.com/karl-zylinski/karl2d
- Built for shipping small 2D Odin games, beginner-friendly. Even less to set up.

---

## Honest Comparison

| | This repo (`sauce/`) | Raylib from scratch | Sokol from scratch |
|---|---|---|---|
| Boilerplate done for you | Most | Some (Raylib helps a lot) | Least |
| Matches lessons you did | Yes (Sokol) | Partly | Yes |
| Setup pain | Already done | Very low | Medium |
| You understand every line | No (yet) | Mostly | Yes |
| Best for | Your real game | Fast solo prototype | Learning the guts |

---

## Recommendation For You Specifically

1. **Prototype the fun** in the existing `learn/co_op/` lesson + your milestones.
   Do not over-engineer. Colored rectangles, two keyboards, one screen.
2. **If the repo's `sauce/` feels good to you, build the real version there** —
   you already invested in learning its Sokol stack, and the boilerplate is the
   reason you came.
3. **If `sauce/` ever feels too heavy**, fall back to **Odin + Raylib** (Option
   2b) for a clean, fast restart. Your game logic (tiles, levers, two players,
   info gap) is identical regardless of the rendering layer — that logic is the
   real game, and it ports easily.

The renderer is replaceable. The puzzle design is the game. Build the design.
