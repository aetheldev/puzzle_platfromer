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

**macOS keyboard focus:** every graphics lesson's `build.sh` builds the game,
wraps it in a tiny throwaway `.app` bundle in `/tmp`, and `open`s that. This
is required on macOS — a binary run straight from the terminal (`./game`)
launches as a background process whose window can never grab keyboard focus,
so arrow keys type into the terminal instead. Always launch with `zsh build.sh`,
never `./<binary>` directly. The shared logic lives in `learn/run_graphics.sh`.

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

Folder numbers are a SORT order, not all "do next". Each folder is one of:
**[DO]** build it now (main path), **[READ]** a reading path for later,
**[REF]** lookup anytime. Follow only the [DO] folders in number order.

The big-picture [DO] order it follows:

```
10_odin_for_js_devs/      [DO]  o01..o16   learn the language (JS comparison)
20_game_thinking_for_web_devs/ [DO] g01..g08  learn the mindset (no code)
30_fundamentals/          [DO]  t01..t11   window, input, gravity, tilemap, camera, shaders
30_fundamentals/t12       [DO]  integration room: wire t01..t11 into one playable game
40_vfx/                   [DO]  v01..v04   glow, elements, fire, lasers
45_shaders_postfx/        [DO]  s00..s06   render-to-texture post-FX: darkness, fog, lights, CRT, grading, bloom
60_projects/              [DO]  juice_playground, sokoban, card game  first full games
70_co_op/                 [DO]  asymmetric two-player puzzle prototype
90_production_with_sauce/ [DO]  how to rebuild it all inside the real sauce/ engine
sauce/                          real production game work  <- the actual destination
```

Off the [DO] line (open only when a lesson sends you there):
```
50_advanced/    [READ] AFTER 60_projects: redo a project with production FX
80_design/      [REF]  idea bank + your own co-op game plan
85_networking/  [READ] LAST: online co-op, only after LOCAL co-op works
95_solutions/   [REF]  runnable answers for every lesson
```

The numbers on 50 / 85 are high ON PURPOSE so they sort to the bottom — not
because they come late in the [DO] sequence. The whole point: standalone
lessons are practice. The real goal is rebuilding your games inside `sauce/`.
Do not rush to `sauce/` early.

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
- **Want the personal roadmap for your BOKURA / We Were Here style co-op game:**
  see `learn/04_COOP_LOVERS_ROADMAP.md`.
- **Stuck on "how do two players see two DIFFERENT worlds in the same room?"**
  (BOKURA tech-robots vs nature-animals): read
  `learn/80_design/coop_lovers_puzzle/PARALLEL_WORLDS.md` and run
  `learn/70_co_op/parallel_worlds_puzzle/`. Short answer: one world, drawn twice,
  a `Theme` picks each tile's costume at draw time.
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
| `04_COOP_LOVERS_ROADMAP.md` | Personal learning + production roadmap for your co-op lovers game. |
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
