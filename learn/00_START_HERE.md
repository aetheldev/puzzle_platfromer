# Start Here

You are here because you want to make games in Odin and you keep getting
stuck on *where to begin*. This file fixes that. Read it top to bottom once.
Do not open any other file until it tells you to.

There are only ever three things you need to know:
1. Is my setup working?
2. What is the ONE next thing I do today?
3. Where do I go when I finish it?

---

## Step 0 — Check Your Setup (5 minutes, do once)

Run these three commands. You want all three to succeed before anything else.

```sh
# 1. Is Odin installed?
odin version
```
If this errors: install Odin first. Stop here until `odin version` prints a version.

```sh
# 2. Does a tiny lesson compile and run?
cd learn/95_solutions/odin_for_js_devs/o01_first_program
zsh build.sh
```
Expected: prints `Hello from Odin!` and a few more lines. If yes, Odin works.

```sh
# 3. Does a graphics lesson open a window?
cd learn/95_solutions/fundamentals/t01_hello_window
zsh build.sh
```
Expected: a dark blue window opens. Close it.

If step 3 fails with a missing Sokol library, build the libs once:

```sh
cd sauce/sokol
zsh build_clibs_macos.sh
```
Then retry step 3.

When all three pass, your environment is correct. You will not touch setup again.

---

## Step 1 — Pick Your Starting Track (answer one question)

Answer this honestly. It decides your first file.

**"Have I written Odin, C, C++, Rust, or Go before?"**

- **No / only JavaScript / TypeScript / Python:**
  Start at `learn/10_odin_for_js_devs/o01_first_program/LESSON.md`.
  This teaches Odin by comparing every concept to JS. Do `o01` through `o16`.

- **Yes, I know a systems or compiled language:**
  Skim `learn/10_odin_for_js_devs/README.md`, then jump to
  `learn/30_fundamentals/t01_hello_window/LESSON.md`.

That is your starting line. You do not need to choose anything else right now.

---

## Step 2 — The Daily Loop (how you actually make progress)

Every lesson, every day, you do the same loop. This is the whole method:

1. Open the current `LESSON.md`. Read it.
2. Read ONLY the solution lines the lesson points you to.
3. Close the solution.
4. Open / create `main.odin` in the **lesson** folder (not the solution folder).
5. Write it from memory. Run `zsh build.sh`.
6. When it runs and you can explain each line: move to the lesson's "Next Lesson".

Full version of this method: `learn/01_LEARNING_METHOD.md`.

Rule for finishing any lesson — do all five:
- run it
- change one thing
- break one thing on purpose
- fix it yourself
- add one tiny extra feature

If you cannot do those five, you are not done. Stay on the lesson.

---

## Step 3 — The Full Ordered Path (your map)

The single ordered checklist of everything, start to finished games, is:

`learn/02_MASTER_TICKET_LIST.md`

Open it, find the next unchecked box, do that ticket. That file IS your
to-do list for the whole journey. Tick boxes as you go.

The big-picture order it follows:

```
10_odin_for_js_devs/      o01..o16   learn the language (JS comparison)
20_game_thinking_for_web_devs/ g01..g08  learn the mindset (no code)
30_fundamentals/          t01..t11   window, input, gravity, tilemap, camera, shaders
30_fundamentals/t12       integration room: wire t01..t11 into one playable game
40_vfx/                   v01..v04   glow, elements, fire, lasers
60_projects/              sokoban, card game   first full games (standalone)
70_co_op/                 asymmetric two-player puzzle prototype
90_production_with_sauce/  how to rebuild it all inside the real sauce/ engine
sauce/                     real production game work  <- the actual destination
```

The whole point: standalone lessons are practice. The real goal is rebuilding
your games inside `sauce/`. Do not rush to `sauce/` early.

---

## Step 4 — When You Get Stuck

- **Compiler error you don't understand:** read
  `learn/10_odin_for_js_devs/o15_reading_compiler_errors/LESSON.md`.
- **Want me (or anyone) to review your code:** fill in
  `learn/templates/ATTEMPT_TEMPLATE.md` and `learn/templates/REVIEW_TEMPLATE.md`.
- **Ready to move a standalone game into `sauce/`:** read
  `learn/templates/SAUCE_MIGRATION_TICKETS.md` — but only after the standalone version
  works and you can explain it.
- **Want another explanation, a video, or real shipped-game code:** see
  `learn/03_RESOURCES.md` (curated external links, organized by phase).
- **Want to work on YOUR co-op "two lovers" game idea:** see
  `learn/80_design/coop_lovers_puzzle/` — design doc + how to build it with or
  without this repo. (Build it AFTER you finish fundamentals + the co-op lesson.)
- **Want online rooms / remote co-op (host + friend connects over internet):**
  see `learn/85_networking/` — but read it LAST, only after your LOCAL co-op game
  is fully playable. Networking is the hardest part; local first, always.

---

## What Each Top-Level File Is (so you stop wondering)

| File | When to open it |
|------|-----------------|
| `00_START_HERE.md` | Right now. The front door. |
| `02_MASTER_TICKET_LIST.md` | Daily. Your ordered checklist. |
| `01_LEARNING_METHOD.md` | Once, to internalize the daily loop. |
| `README.md` | Reference. Map of folders. |
| `03_RESOURCES.md` | When you want a video/doc/example for another angle. |
| `80_design/coop_lovers_puzzle/` | When working on YOUR two-lovers game idea. |
| `85_networking/` | LAST. When adding online rooms / remote co-op. |
| `templates/ATTEMPT_TEMPLATE.md` | When you submit code for review. |
| `templates/REVIEW_TEMPLATE.md` | When you review code. |
| `templates/SAUCE_MIGRATION_TICKETS.md` | Only when moving a game into `sauce/`. |

---

## One Rule Above All

You are never "choosing what to do next" again. There is always exactly one
next unchecked box in `MASTER_TICKET_LIST.md`. Do that box. Repeat. That is
the entire system.
