# Master Ticket List

> New here? Read `learn/00_START_HERE.md` first. It checks setup and points you to
> your starting track. This file is the full ordered checklist you work through
> after that — find the next unchecked box and do it.
>
> Want videos / docs / real-game examples for any phase? See `learn/03_RESOURCES.md`.
> Working on your own co-op "two lovers" game? See `learn/80_design/coop_lovers_puzzle/`.

Goal: one ordered path from beginner Odin/Sokol learning to real `sauce/` production game work.

Main goal reminder:
- standalone lessons are practice only
- real destination is making those games inside `sauce/`
- if you finish Sokoban, card game, or co-op prototype outside `sauce/`, next step is rebuilding them in `sauce/`

How to use this file:
- Do tickets in order.
- Do not skip practice.
- Do not chase polish too early.
- Only move on when you can explain what you built.

## Progress Tracker

- [x] Ticket o01 - First Odin Program
- [x] Ticket o02 - Variables And Types
- [x] Ticket o03 - Procs Not Functions
- [x] Ticket o04 - Structs Not Classes
- [x] Ticket o05 - Enums And Switches
- [x] Ticket o06 - Arrays Slices Dynamic
- [x] Ticket o07 - Pointers And Refs
- [x] Ticket o08 - Memory Without GC
- [x] Ticket o09 - Context System
- [x] Ticket o10 - Imports And Packages
- [x] Ticket o11 - Error Handling
- [x] Ticket o12 - For Loops And Iteration
- [x] Ticket o13 - Strings And CStrings
- [x] Ticket o14 - Defer And Cleanup
- [x] Ticket o15 - Reading Compiler Errors
- [x] Ticket o16 - Debugging And Printing
- [x] Ticket o17 - Maps And Lookups
- [x] Ticket o18 - Unions And Variants
- [x] Ticket o19 - Bit Sets And Flags
- [x] Ticket g01 - Game Loop vs React
- [x] Ticket g02 - State Without Hooks
- [x] Ticket g03 - Immediate vs Retained Mode
- [x] Ticket g04 - No Async In Game Loop
- [x] Ticket g05 - Pixels Not Divs
- [x] Ticket g06 - Input Every Frame
- [x] Ticket g07 - Time And Delta Time
- [x] Ticket g08 - GPU Basics For Web Devs
- [x] Ticket 000 - Make Sure Repo Builds
- [x] Ticket 001 - Learn Folder Map
- [x] Ticket 010 - T01 Hello Window
- [x] Ticket 011 - T02 Shapes And Colors
- [x] Ticket 012 - T03 Movement
- [ ] Ticket 013 - T04 Gravity And Jump
- [ ] Ticket 014 - T05 Coyote And Jump Buffer
- [ ] Ticket 015 - T06 Wall Jump
- [ ] Ticket 016 - T07 Tilemap
- [ ] Ticket 017 - T08 Camera
- [ ] Ticket 018 - T09 Shader And Glow
- [ ] Ticket 019 - T10 Particles And Screen Shake
- [ ] Ticket 020 - T11 Level Editor Basics
- [ ] Ticket 020B - T12 Integration Room (combine t01-t11 into one playable room)
- [ ] Ticket 020C - T13 Point And Click (escape-room tech: hotspots, inventory, ordered code)
- [ ] Ticket 021 - V01 Glow Highlight
- [ ] Ticket 022 - V02 Elemental Orbs
- [ ] Ticket 023 - V03 Burning Effect
- [ ] Ticket 024 - V04 Laser Beam
- [ ] Ticket 025 - Advanced Rendering Mindset
- [ ] Ticket 026 - Advanced Shader Pipeline And Post FX
- [ ] Ticket 027 - Advanced Production Glow And Bloom
- [ ] Ticket 028 - Advanced Fire And Elemental FX
- [ ] Ticket 029 - Advanced Laser And Beam FX
- [ ] Ticket 029A - Advanced Sokoban In Sauce Plus FX
- [ ] Ticket 029B - Advanced Card Game In Sauce Plus FX
- [ ] Ticket 029C - Advanced Co-op Game In Sauce Plus FX
- [ ] Ticket 030 - Sokoban Starter
- [ ] (side) P01 Snake — after t07
- [ ] (side) P02 Pong — after t03 (first two-player input!)
- [ ] (side) P03 Breakout — after t10
- [ ] (side) P04 Memory Match — after t13
- [ ] (side) P05 Idle RPG — after o19 (console, no graphics)
- [ ] (side) P06 Idle Widget — after p05 + t13 (tamagotchi corner window)
- [ ] (side) ART a01-a04 — Aseprite basics: tool, lines, light, color (no prerequisite)
- [ ] (side) ART a05-a07 — icons, detective character, animation
- [ ] (side) ART a08-a09 — tiles (feeds t07), Rusty Lake scene mockup
- [ ] (side) ART a10-a11 — export pipeline + Lua tooling (carbscode-style)
- [ ] Ticket 031 - Co-op Prototype
- [ ] Ticket 031B - Parallel-Worlds Co-op (BOKURA different-world look)
- [ ] Ticket 031C - Visual-First Sauce Bridge Mindset
- [ ] Ticket 031D - Snake/Tetris/Sokoban Sauce Bridge Practice
- [ ] Ticket 031E - Parallel-Worlds Sauce Bridge (main target)
- [ ] Ticket 032 - Turn-Based Card Game Starter
- [ ] Ticket 040 - Architecture Map
- [ ] Ticket 041 - Fundamentals To Sauce
- [ ] Ticket 042 - What Is Sokol
- [ ] Ticket 043 - Sokol Header Map
- [ ] Ticket 044 - Build Pipeline
- [ ] Ticket 050 - How To Make A Game
- [ ] Ticket 051 - Visual Effects Roadmap
- [ ] Ticket 052 - Genre Roadmap
- [ ] Ticket 060 - Read Game Layer
- [ ] Ticket 061 - Read Renderer Layer
- [ ] Ticket 062 - First Production Mode Plan
- [ ] Ticket 063 - Production Turn-Based Card Game Plan
- [ ] Ticket 070 - Production Sokoban In Sauce
- [ ] Ticket 071 - Production Co-op In Sauce
- [ ] Ticket 071B - Production Parallel-Worlds Co-op (BOKURA look in sauce)
- [ ] Ticket 072 - Mirror Laser Puzzle Study
- [ ] Ticket 073 - Roguelike Study Path
- [ ] Ticket 074 - Turn-Based Card Game Study Path
- [ ] Ticket 075 - Network-Ready Input (do EARLY, while game is local)
- [ ] Ticket 076 - Online Co-op Networking (do LAST, after local game is fun)
- [ ] Ticket 080 - Editor Future
- [ ] Ticket 081 - Sokol Upgrade Future

Success rule for every ticket:
- run it
- change one thing
- break one thing
- fix it yourself
- add one tiny extra feature

---

## Phase -1 — Odin For JS/TS Developers

Complete this before anything else if you are coming from JS/TS/React.

Each lesson has:
- deep JS comparison
- Odin explanation
- code snippets (not full solutions)
- exercises
- exit criteria

Read: `learn/10_odin_for_js_devs/README.md`

Then work through `o01` to `o19` in order.
Each lesson is in `learn/10_odin_for_js_devs/oXX_name/LESSON.md`.
Solutions in `learn/95_solutions/odin_for_js_devs/oXX_name/`.

---

## Phase -0.5 — Game Thinking For Web Developers

Complete this after Odin lessons, before fundamentals.
These are reading lessons. No code. Pure concept building.

Read: `learn/20_game_thinking_for_web_devs/README.md`

Then work through `g01` to `g08` in order.
Each lesson is in `learn/20_game_thinking_for_web_devs/gXX_name/LESSON.md`.

---

## Phase 0 - Setup And Orientation

### Ticket 000 - Make Sure Repo Builds

Read:
- `build_mac.sh`
- `sauce/build/build.odin`

Do:
- run `./build_mac.sh`
- run `cd build/mac_debug && ./game`

Practice:
- run `odin run ./sauce/build`
- run `odin run ./sauce/build -- skip_shader_regen`
- explain what build script does in your own words

Verify:
- game window opens
- no missing `res` error

### Ticket 001 - Learn Folder Map

Read:
- `learn/README.md`
- `learn/90_production_with_sauce/README.md`

Do:
- write down difference between:
  - `fundamentals`
  - `projects`
  - `co_op`
  - `production_with_sauce`

Practice:
- explain why `learn/60_projects/sokoban` is useful
- explain why it is not the same as building in `sauce/`

---

## Phase 1 - Fundamentals

### Ticket 010 - T01 Hello Window

Read:
- `learn/30_fundamentals/t01_hello_window/LESSON.md`

Do:
- run `zsh build.sh`

Practice:
- change clear color
- make color pulse faster
- print something every 120 frames

If you do this, also try:
- change window title
- change window size

### Ticket 011 - T02 Shapes And Colors

Read:
- `learn/30_fundamentals/t02_shapes_colors/LESSON.md`
- `sauce/sokol/gl/gl.odin`

Do:
- run it

Practice:
- add one more rectangle
- add diagonal line
- make one shape move with time

If you do this, also try:
- make a tiny face out of rectangles and lines
- make a health bar shape

### Ticket 012 - T03 Movement

Read:
- `learn/30_fundamentals/t03_movement/LESSON.md`

Do:
- run it
- move with keys

Practice:
- clamp player to screen edges
- remove delta time and feel why it is bad
- restore delta time

If you do this, also try:
- add sprint key
- add dash cooldown timer

### Ticket 013 - T04 Gravity And Jump

Read:
- `learn/30_fundamentals/t04_gravity_jump/LESSON.md`

Do:
- tune gravity and jump velocity

Practice:
- add one extra platform
- make jump feel heavy
- make jump feel floaty

If you do this, also try:
- add fall speed cap
- add landing color flash

### Ticket 014 - T05 Coyote And Jump Buffer

Read:
- `learn/30_fundamentals/t05_coyote_jump_buffer/LESSON.md`

Do:
- feel difference with timers on and off

Practice:
- set coyote to zero
- set jump buffer to zero
- explain why both make game feel better

If you do this, also try:
- add double jump visual marker
- add short hop vs full hop tuning

### Ticket 015 - T06 Wall Jump

Read:
- `learn/30_fundamentals/t06_wall_jump/LESSON.md`

Do:
- tune wall slide and wall jump

Practice:
- remove wall jump lock and compare
- add wall slide particles
- add different color while on wall

If you do this, also try:
- add climb stamina idea
- add wall grab instead of auto slide

### Ticket 016 - T07 Tilemap

Read:
- `learn/30_fundamentals/t07_tilemap/LESSON.md`

Do:
- edit level text
- make small platform room

Practice:
- add spike tile
- add checkpoint tile
- add moving hazard as simple entity later

If you do this, also try:
- make one Sokoban-like room in text form
- make one laser puzzle room layout in text form

### Ticket 017 - T08 Camera

Read:
- `learn/30_fundamentals/t08_camera/LESSON.md`

Do:
- tune camera lerp

Practice:
- make snappy camera
- make slow camera
- add small screen-space HUD element

If you do this, also try:
- add look-ahead camera
- add room-based camera snap

### Ticket 018 - T09 Shader And Glow

Read:
- `learn/30_fundamentals/t09_shaders_bloom/LESSON.md`

Do:
- run it
- change glow size and color pulse

Practice:
- add another glow object
- weaken glow
- strengthen glow

If you do this, also try:
- make collectible item glow
- make exit door glow when active

### Ticket 019 - T10 Particles And Screen Shake

Read:
- `learn/30_fundamentals/t10_particles_screenshake/LESSON.md`

Do:
- jump and land
- press `X`

Practice:
- change burst count
- change particle gravity
- change shake strength

If you do this, also try:
- make explosion effect
- make magic sparkle effect
- make wall-slide dust effect

### Ticket 020 - T11 Level Editor Basics

Read:
- `learn/30_fundamentals/t11_level_editor_basics/LESSON.md`

Do:
- paint walls
- place spawn, box, goals
- press `Enter` and capture level text

Practice:
- build 3 Sokoban levels
- build 1 switch-door puzzle room idea
- build 1 asymmetric co-op room layout on paper

If you do this, also try:
- make tile `5` for door
- make tile `6` for pressure plate

### Ticket 020B - T12 Integration Room

This is the bridge ticket. It combines t01-t11 into one playable thing.
No new concepts. The skill is wiring known mechanics into one program.

Read:
- `learn/30_fundamentals/t12_integration_room/LESSON.md`

Do (one layer at a time, run between each):
- draw a tilemap room
- add a moving player
- add gravity and jump
- add tile collision
- add a following camera
- add one goal tile with a win message

Practice:
- add a spike hazard that resets the player (lose condition)
- design one room that is actually fun to traverse

Exit:
- player moves, jumps, collides, camera follows, goal works — all in ONE file
- you can name which earlier lesson each piece came from
- you can explain your fixed update order and why order matters

Why it matters:
- the jump from single mechanics to a full project is where most people quit
- this removes that cliff before `60_projects/sokoban`

### Ticket 020C - T13 Point And Click

The genre tech for the two-detective escape game: hit-testing,
hotspots-as-data, state flags, one-slot inventory, ordered-code lock.
Technically simpler than the platformer lessons — design carries the genre.

Read:
- `learn/30_fundamentals/t13_point_and_click/LESSON.md`

Do:
- run it, escape the room, press R, speedrun it

Practice:
- add a rug hotspot hiding a coin
- make the drawer need key AND painting moved
- randomize the code so the note is the only source of truth

If you do this, also try:
- Exercise 5: friend reads the note, you press buttons — your co-op
  detective game's core loop, played with zero networking
- read `learn/85_networking/06_two_windows_local_to_network.md` to see
  how a click becomes a network intent later

---

## Phase 1.5 - VFX Practice

### Ticket 021 - V01 Glow Highlight

Read:
- `learn/40_vfx/v01_glow_highlight/LESSON.md`

Do:
- make one selected object feel special

Practice:
- add left/right selection
- make glow stronger on selected item
- change one glow color completely

### Ticket 022 - V02 Elemental Orbs

Read:
- `learn/40_vfx/v02_elemental_orbs/LESSON.md`

Do:
- build at least 2 elements

Practice:
- fire rises quickly
- ice drifts softly
- poison hangs and pulses

### Ticket 023 - V03 Burning Effect

Read:
- `learn/40_vfx/v03_burning_effect/LESSON.md`

Do:
- ignite one target

Practice:
- spawn embers upward
- add glow while burning
- tune burn time

### Ticket 024 - V04 Laser Beam

Read:
- `learn/40_vfx/v04_laser_beam/LESSON.md`

Do:
- draw one beam and impact

Practice:
- pulse beam width
- add impact sparks
- imagine how this maps into mirror puzzle later

## Phase 1.6 - Shaders & Post-Processing

Hands-on, runnable post-FX. Render the game into a texture, then a fragment
shader reinterprets the whole picture. This is how games look "pro" without
better art. Do AFTER t09 (first shader) and the VFX tickets.

### Ticket 024a - Post-FX Foundation (render to texture)

Read:
- `learn/45_shaders_postfx/README.md`
- `learn/45_shaders_postfx/s00_foundation/LESSON.md`

Do:
- get the two-pass skeleton working: scene -> texture -> post shader -> window
- confirm the vignette darkens the edges

### Ticket 024b - Darkness / Torch

Read:
- `learn/45_shaders_postfx/s01_darkness/LESSON.md`

Do:
- one mouse-controlled light circle with an ambient floor

Practice:
- change radius and ambient
- add flicker

### Ticket 024c - Fog

Read:
- `learn/45_shaders_postfx/s02_fog/LESSON.md`

Do:
- GPU-noise fog that scrolls over time, heavier near the ground

### Ticket 024d - Multiple 2D Lights

Read:
- `learn/45_shaders_postfx/s03_lights/LESSON.md`

Do:
- pass a uniform array of lights; accumulate them in the shader

### Ticket 024e - CRT / Old TV

Read:
- `learn/45_shaders_postfx/s04_crt/LESSON.md`

Do:
- curvature + chromatic aberration + scanlines

### Ticket 024f - Color Grading

Read:
- `learn/45_shaders_postfx/s05_grade/LESSON.md`

Do:
- contrast, saturation, split-toning; lock in one mood

### Ticket 024g - Bloom / Glow

Read:
- `learn/45_shaders_postfx/s06_bloom/LESSON.md`

Do:
- bright-pass + blur + composite in one shader

If you do this, also try:
- run your sokoban or juice_playground scene through s01 darkness + s02 fog

## Phase 1.75 - Advanced Preview

### Ticket 025 - Advanced Rendering Mindset

Read:
- `learn/50_advanced/README.md`
- `learn/50_advanced/a01_sauce_rendering_mindset.md`

Do:
- understand what changes when effect becomes render feature

### Ticket 026 - Advanced Shader Pipeline And Post FX

Read:
- `learn/50_advanced/a02_shader_pipeline_and_postfx.md`

Do:
- explain object shader vs full-screen post-process shader

### Ticket 027 - Advanced Production Glow And Bloom

Read:
- `learn/50_advanced/a03_production_glow_and_bloom.md`

Do:
- decide what should use fake glow vs real bloom in your game

### Ticket 028 - Advanced Fire And Elemental FX

Read:
- `learn/50_advanced/a04_fire_burn_and_elemental_fx.md`

Do:
- define 3-element visual language for your future game

### Ticket 029 - Advanced Laser And Beam FX

Read:
- `learn/50_advanced/a05_lasers_mirrors_and_beam_fx.md`

Do:
- map beam gameplay rules to beam rendering needs

### Ticket 029A - Advanced Sokoban In Sauce Plus FX

Read:
- `learn/50_advanced/a11_sokoban_in_sauce_plus_fx.md`

Do:
- decide how your Sokoban in `sauce/` should feel, not just function

### Ticket 029B - Advanced Card Game In Sauce Plus FX

Read:
- `learn/50_advanced/a12_card_game_in_sauce_plus_fx.md`

Do:
- decide how card play feedback should look and feel in `sauce/`

### Ticket 029C - Advanced Co-op Game In Sauce Plus FX

Read:
- `learn/50_advanced/a13_coop_game_in_sauce_plus_fx.md`

Do:
- decide which effects are critical for two-player clarity in `sauce/`

## Phase 2 - Small Standalone Projects

### Ticket 029b - Juice Playground (game feel)

Do this right after the VFX tickets and BEFORE Sokoban. It teaches the cheap
tricks that stop your games looking basic: jump dust, landing dust, run dust,
squash & stretch, screen shake. Same particle pool as `t10`.

Read:
- `learn/60_projects/juice_playground/LESSON.md`
- `learn/60_projects/juice_playground/README.md`

Do:
- run it; jump, land hard, run; watch the dust + squash

Practice:
- retune `LAND_DUST` count/speeds so landings feel heavier
- speed up / slow down run dust spawn rate
- explain what each tuned number changed

If you do this, also try:
- short jump (release jump early)
- double jump that emits a ring of dust mid-air
- tint dust brighter on harder landings

### Ticket 030 - Sokoban Starter

The solution is already "juiced" using the functions from Ticket 029b: step
dust, a directional burst on box pushes, screen shake, smooth player slide,
and layered tiles. Read it after you can explain the juice playground.

Read:
- `learn/60_projects/sokoban/LESSON.md`
- `learn/60_projects/sokoban/README.md`

Do:
- play all current levels

Practice:
- add 2 more levels
- tune board colors
- add restart sound idea on paper

If you do this, also try:
- add undo stack
- add move counter text
- add win transition to next level

### Ticket 031 - Co-op Prototype

Read:
- `learn/70_co_op/different_views_puzzle/README.md`
- `learn/70_co_op/different_views_puzzle/prototype/LESSON.md`

Do:
- play with two sets of controls

Practice:
- add one more room
- add one more red-only bridge
- add one more blue-only bridge

If you do this, also try:
- make one player see a clue, other executes it
- add one object only one player can move

### Ticket 031B - Parallel-Worlds Co-op (BOKURA different-world look)

The "how can two players see two different worlds in the same room?" lesson.
The trick: ONE world, drawn twice, a `Theme` picks each tile's/character's
costume at draw time (tech robots vs nature animals). Same wall, two looks.

Read:
- `learn/80_design/coop_lovers_puzzle/PARALLEL_WORLDS.md` (the full explanation)
- `learn/70_co_op/parallel_worlds_puzzle/README.md`
- `learn/70_co_op/parallel_worlds_puzzle/prototype/LESSON.md`

Do:
- run the answer: `cd learn/95_solutions/co_op/parallel_worlds_puzzle/prototype && zsh build.sh`
- confirm the SAME grid renders as two worlds (split screen)

Practice:
- turn off the truth fork (make collision identical) → pure cosmetic fork
- add a new theme costume to one tile (look only, no gameplay change)
- design one room solvable only by describing your world to your partner

If you do this, also try:
- run each view through a post-FX mood (`learn/45_shaders_postfx/`)
- sketch how split screen becomes networked full-screen-per-client

### Ticket 032 - Turn-Based Card Game Starter

Read:
- `learn/60_projects/turn_based_card_game/LESSON.md`

Do:
- define smallest card game rules you can finish

Practice:
- write card struct on paper
- write turn phases on paper
- write legal move rules for number-card-only version

If you do this, also try:
- add one action card idea
- think how local multiplayer input would work
- think how networking would be easier in turn-based game than action game

---

## Phase 3 - Understand Production `sauce/`

### Ticket 040 - Architecture Map

Read:
- `learn/90_production_with_sauce/01_architecture_map.md`
- `sauce/core_main.odin`

Do:
- trace frame flow from app start to draw end

Practice:
- write your own short note: where input happens, where update happens, where draw happens

If you do this, also try:
- point to exact place `app_frame` gets called

### Ticket 041 - Fundamentals To Sauce

Read:
- `learn/90_production_with_sauce/02_fundamentals_to_sauce.md`

Do:
- map each fundamentals ticket to one `sauce` area

Practice:
- answer: where should jump logic live in production?
- answer: where should camera logic live in production?
- answer: where should bloom live in production?

### Ticket 042 - What Is Sokol

Read:
- `learn/90_production_with_sauce/06_what_is_sokol.md`

Do:
- explain Sokol in one paragraph

Practice:
- write down what Sokol does not provide
- write down what `sauce` provides on top

### Ticket 043 - Sokol Header Map

Read:
- `learn/90_production_with_sauce/07_sokol_header_map.md`
- skim:
  - `sauce/sokol/app/app.odin`
  - `sauce/sokol/gfx/gfx.odin`
  - `sauce/sokol/glue/glue.odin`

Do:
- answer these:
  - where do I look for input?
  - where do I look for offscreen rendering?
  - where do I look for shader image bindings?

Practice:
- make your own “where to look” cheat sheet

### Ticket 044 - Build Pipeline

Read:
- `sauce/build/build.odin`

Do:
- explain:
  - generated files
  - shader generation
  - output copy step
  - `res` copy step

Practice:
- run `odin run ./sauce/build -- skip_shader_regen`
- run `odin run ./sauce/build -- regen_shaders`

---

## Phase 4 - Learn To Think Like Game Designer + Engineer

### Ticket 050 - How To Make A Game

Read:
- `learn/90_production_with_sauce/08_how_to_make_a_game.md`

Do:
- write one-sentence core loop for:
  - Sokoban
  - mirror laser puzzle
  - asymmetric co-op puzzle
  - simple roguelike

Practice:
- choose one world model for each
- explain why

### Ticket 051 - Visual Effects Roadmap

Read:
- `learn/90_production_with_sauce/09_visual_effects_roadmap.md`

Do:
- write what you need before real bloom
- write what fake lighting options exist

Practice:
- choose 3 effects for your future puzzle game
- choose 3 effects for your future roguelike

If you do this, also try:
- list which ones are gameplay clarity
- list which ones are only decoration

### Ticket 052 - Genre Roadmap

Read:
- `learn/90_production_with_sauce/10_genre_roadmap.md`
- `learn/80_design/puzzle_game_ideas/README.md`

Do:
- choose one puzzle idea
- choose one co-op idea
- choose one roguelike idea

Practice:
- write why each is interesting
- write smallest playable version of each

---

## Phase 5 - Start Real Production Work In `sauce`

### Ticket 060 - Read Game Layer

Read:
- `sauce/game.odin`
- `sauce/entity.odin`

Do:
- identify:
  - `Game_State`
  - entity setup
  - update procs
  - draw procs

Practice:
- add comments in your own notes, not repo, describing how one entity updates and draws

### Ticket 061 - Read Renderer Layer

Read:
- `sauce/core_render.odin`
- `sauce/shader.glsl`
- `sauce/generated_shader.odin`

Do:
- explain atlas load
- explain font load
- explain draw buffer flow

Practice:
- answer where texture slots bind
- answer where shader uniforms are described

### Ticket 062 - First Production Mode Plan

Read:
- `learn/90_production_with_sauce/03_sokoban_in_sauce.md`
- `learn/90_production_with_sauce/04_coop_puzzle_in_sauce.md`
- `learn/90_production_with_sauce/05_production_tickets.md`

Do:
- choose first production mode:
  - Sokoban
  - co-op room prototype

Practice:
- write exact scope for first milestone
- keep it tiny

Good first milestone examples:
- Sokoban: one level, one player, one box type, reset key
- Co-op: one room, two players, red/blue bridges, one shared door

### Ticket 063 - Production Turn-Based Card Game Plan

Read:
- `learn/90_production_with_sauce/12_turn_based_card_game_in_sauce.md`

Do:
- choose smallest playable card game ruleset

Practice:
- define deck
- define hand size
- define discard rules
- define turn phases

If you do this, also try:
- define replay log format
- define what game state must be deterministic

---

## Phase 6 - Your Best Next Project Path

### Ticket 070 - Production Sokoban In Sauce

Read first:
- `learn/90_production_with_sauce/03_sokoban_in_sauce.md`

Do:
- add `Game_Mode.sokoban`
- load one level text
- spawn player + boxes
- implement push rules

Practice:
- add reset
- add next level
- add move count

If you do this, also try:
- add undo
- add particles on push
- add goal glow when active

### Ticket 071 - Production Co-op In Sauce

This is where YOUR two-lovers game becomes real. See its design + build plan:
- `learn/80_design/coop_lovers_puzzle/README.md` (design + milestones)
- `learn/80_design/coop_lovers_puzzle/BUILD_PATH.md` (build with or without this repo)

Read first:
- `learn/90_production_with_sauce/04_coop_puzzle_in_sauce.md`

Do:
- add second player
- add second input mapping
- add per-player collision rules

Practice:
- red-only bridge
- blue-only bridge
- two pressure plates open door

If you do this, also try:
- shared camera midpoint
- one player pushes special block
- one player sees hidden hint only

### Ticket 071B - Production Parallel-Worlds Co-op (BOKURA look in sauce)

Rebuild the parallel-worlds prototype as a real sauce mode: two players from one
keyboard, themed entities, themed tile costumes, shared collision + truth fork.

Read first:
- `learn/90_production_with_sauce/04_coop_puzzle_in_sauce.md`
- `learn/90_production_with_sauce/13_parallel_worlds_coop_in_sauce.md` (exact
  file/line references into `sauce/game.odin` + `sauce/entity.odin`)

Do (small, each playable):
- add `Player_Intent`, refactor demo player to read intent
- add `player_a` / `player_b` kinds + `setup_lover`; spawn both; `fill_intents`
- add `theme` field + themed draw proc (rect colors first, sprites later)
- add tile grid + `draw_world(theme)` costume table
- add shared collision proc, then the truth fork
- add shared puzzle state + win + camera midpoint + reset

If you do this, also try:
- second room
- post-FX mood per view (`learn/45_shaders_postfx/`)
- (LAST, core change) split screen, then networking

### Ticket 072 - Mirror Laser Puzzle Study

Read:
- `learn/90_production_with_sauce/09_visual_effects_roadmap.md`

Do:
- design first mirror-laser prototype on paper

Practice:
- define tiles:
  - wall
  - mirror `/`
  - mirror `\`
  - laser emitter
  - target
  - blocker
- define one update step for beam tracing

If you do this, also try:
- draw beam as line segments first
- add additive glow later
- add particles on target hit later

### Ticket 073 - Roguelike Study Path

Read:
- `learn/90_production_with_sauce/10_genre_roadmap.md`

Do:
- write smallest roguelike you can finish

Practice:
- one room or one floor only
- 3 enemies
- 3 items
- one win/exit condition

If you do this, also try:
- choose grid movement or action real-time
- choose whether procgen is needed in prototype at all

### Ticket 074 - Turn-Based Card Game Study Path

Read:
- `learn/60_projects/turn_based_card_game/README.md`
- `learn/90_production_with_sauce/12_turn_based_card_game_in_sauce.md`

Do:
- choose if first version is:
  - one human vs one human
  - one human vs simple CPU

Practice:
- implement number cards only in design notes
- add skip/reverse later, not first
- decide whether to use sprites or colored rectangles first

If you do this, also try:
- write how to serialize one full game state
- write how to replay from action log

---

## Phase 6.5 - Networking (Only If You Want Online Co-op)

### Ticket 075 - Network-Ready Input (do EARLY)

Do this while your game is still LOCAL. It costs little now and saves a rewrite
later. Structure player input as an "intent", not direct keyboard reads.

Read:
- `learn/85_networking/03_input_for_networked_coop.md`

Do:
- define a `Player_Intent` struct (move + your verbs)
- give each player entity an `intent` field
- make the player update read `e.intent`, NOT the keyboard directly
- fill both players' intents each frame from two key sets

Exit:
- gameplay no longer reads keys directly; it reads intent
- you can serialize one intent to bytes and back

### Ticket 076 - Online Co-op Networking (do LAST)

Only start when the game is fully playable LOCAL and you have playtested it with a
real person. Networking is a separate project. Local first, always.

Read:
- `learn/85_networking/README.md`
- `learn/85_networking/01_networking_reality_check.md`
- `learn/85_networking/02_concepts_for_web_devs.md`
- choose a path:
  - `learn/85_networking/04_steam_lobbies_path.md` (recommended; repo bundles Steamworks)
  - `learn/85_networking/05_raw_sockets_path.md` (from scratch with `core:net`)

Do:
- decide Steam (Path A) or raw sockets (Path B)
- get two builds talking on localhost first
- send `Player_Intent` between them; keep the host authoritative

Exit:
- two machines connect (room created, friend joins)
- both players' intents flow over the network
- the host's game state stays the single source of truth

Do not start until ALL of these are true:
- local two-player game is fun
- you playtested it with a real second person
- input already uses intents (Ticket 075)

---

## Phase 7 - Future Tooling And Upgrade Work

### Ticket 080 - Editor Future

Read:
- `t11_level_editor_basics`
- `learn/90_production_with_sauce/03_sokoban_in_sauce.md`

Do:
- decide whether editor should be:
  - in-game mode
  - separate tool
  - text format first

Practice:
- define level file format version 1
- define export/import steps

### Ticket 081 - Sokol Upgrade Future

Read:
- `learn/90_production_with_sauce/11_sokol_upgrade_checklist.md`

Do:
- keep this for later milestone

Practice:
- do not execute now unless current tooling blocks real work

---

## Recommended Exact Reading Order

1. `learn/00_START_HERE.md`
2. `learn/README.md`
3. `learn/02_MASTER_TICKET_LIST.md`
4. `learn/01_LEARNING_METHOD.md`
5. `learn/10_odin_for_js_devs/o01_first_program/LESSON.md`
6. ... through `o19_bit_sets_and_flags/LESSON.md`
7. `learn/20_game_thinking_for_web_devs/g01_game_loop_vs_react/LESSON.md`
8. ... through `g08_gpu_basics_for_web_devs/LESSON.md`
9. `learn/30_fundamentals/t01_hello_window/LESSON.md`
10. `learn/30_fundamentals/t02_shapes_colors/LESSON.md`
11. `learn/30_fundamentals/t03_movement/LESSON.md`
12. `learn/30_fundamentals/t04_gravity_jump/LESSON.md`
13. `learn/30_fundamentals/t05_coyote_jump_buffer/LESSON.md`
14. `learn/30_fundamentals/t06_wall_jump/LESSON.md`
15. `learn/30_fundamentals/t07_tilemap/LESSON.md`
16. `learn/30_fundamentals/t08_camera/LESSON.md`
17. `learn/30_fundamentals/t09_shaders_bloom/LESSON.md`
18. `learn/30_fundamentals/t10_particles_screenshake/LESSON.md`
19. `learn/30_fundamentals/t11_level_editor_basics/LESSON.md`
20. `learn/30_fundamentals/t12_integration_room/LESSON.md`
20b. `learn/30_fundamentals/t13_point_and_click/LESSON.md`
21. `learn/40_vfx/v01_glow_highlight/LESSON.md`
22. `learn/40_vfx/v02_elemental_orbs/LESSON.md`
23. `learn/40_vfx/v03_burning_effect/LESSON.md`
24. `learn/40_vfx/v04_laser_beam/LESSON.md`
24a-g. `learn/45_shaders_postfx/` s00 foundation, then s01..s06
       (darkness, fog, lights, CRT, grading, bloom)
24h. `learn/60_projects/juice_playground/LESSON.md`
25. `learn/60_projects/sokoban/LESSON.md`
26. `learn/70_co_op/different_views_puzzle/prototype/LESSON.md`
26b. `learn/80_design/coop_lovers_puzzle/PARALLEL_WORLDS.md`
     + `learn/70_co_op/parallel_worlds_puzzle/prototype/LESSON.md` (BOKURA two-world look)
27. `learn/60_projects/turn_based_card_game/LESSON.md`
28. `learn/90_production_with_sauce/README.md`
29. `learn/90_production_with_sauce/01_architecture_map.md`
30. `learn/90_production_with_sauce/02_fundamentals_to_sauce.md`
31. `learn/90_production_with_sauce/06_what_is_sokol.md`
32. `learn/90_production_with_sauce/07_sokol_header_map.md`
33. `learn/90_production_with_sauce/08_how_to_make_a_game.md`
34. `learn/90_production_with_sauce/09_visual_effects_roadmap.md`
35. `learn/90_production_with_sauce/10_genre_roadmap.md`
36. `learn/90_production_with_sauce/12_turn_based_card_game_in_sauce.md`
37. `learn/90_production_with_sauce/03_sokoban_in_sauce.md`
38. `learn/90_production_with_sauce/04_coop_puzzle_in_sauce.md`
39. `learn/90_production_with_sauce/05_production_tickets.md`
40. `sauce/core_main.odin`
41. `sauce/game.odin`
42. `sauce/entity.odin`
43. `sauce/core_render.odin`
44. `sauce/build/build.odin`

---

## Best Personal Route For You Right Now

1. Finish Phase 1 fully
2. Build 3 extra Sokoban levels in `t11`
3. Improve standalone Sokoban a bit
4. Read production docs
5. Build real Sokoban in `sauce`
6. Build one asymmetric co-op room in `sauce`
7. Optionally build one small turn-based card game for state-machine practice
8. Add effects after those are playable
9. Later branch into mirror-laser or roguelike
