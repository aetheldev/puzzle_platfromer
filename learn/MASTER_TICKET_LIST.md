# Master Ticket List

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

- [x] Ticket 000 - Make Sure Repo Builds
- [ ] Ticket 001 - Learn Folder Map
- [ ] Ticket 010 - T01 Hello Window
- [ ] Ticket 011 - T02 Shapes And Colors
- [ ] Ticket 012 - T03 Movement
- [ ] Ticket 013 - T04 Gravity And Jump
- [ ] Ticket 014 - T05 Coyote And Jump Buffer
- [ ] Ticket 015 - T06 Wall Jump
- [ ] Ticket 016 - T07 Tilemap
- [ ] Ticket 017 - T08 Camera
- [ ] Ticket 018 - T09 Shader And Glow
- [ ] Ticket 019 - T10 Particles And Screen Shake
- [ ] Ticket 020 - T11 Level Editor Basics
- [ ] Ticket 030 - Sokoban Starter
- [ ] Ticket 031 - Co-op Prototype
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
- [ ] Ticket 072 - Mirror Laser Puzzle Study
- [ ] Ticket 073 - Roguelike Study Path
- [ ] Ticket 074 - Turn-Based Card Game Study Path
- [ ] Ticket 080 - Editor Future
- [ ] Ticket 081 - Sokol Upgrade Future

Success rule for every ticket:
- run it
- change one thing
- break one thing
- fix it yourself
- add one tiny extra feature

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
- `learn/production_with_sauce/README.md`

Do:
- write down difference between:
  - `fundamentals`
  - `projects`
  - `co_op`
  - `production_with_sauce`

Practice:
- explain why `learn/projects/sokoban` is useful
- explain why it is not the same as building in `sauce/`

---

## Phase 1 - Fundamentals

### Ticket 010 - T01 Hello Window

Read:
- `learn/fundamentals/t01_hello_window/LESSON.md`

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
- `learn/fundamentals/t02_shapes_colors/LESSON.md`
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
- `learn/fundamentals/t03_movement/LESSON.md`

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
- `learn/fundamentals/t04_gravity_jump/LESSON.md`

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
- `learn/fundamentals/t05_coyote_jump_buffer/LESSON.md`

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
- `learn/fundamentals/t06_wall_jump/LESSON.md`

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
- `learn/fundamentals/t07_tilemap/LESSON.md`

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
- `learn/fundamentals/t08_camera/LESSON.md`

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
- `learn/fundamentals/t09_shaders_bloom/LESSON.md`

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
- `learn/fundamentals/t10_particles_screenshake/LESSON.md`

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
- `learn/fundamentals/t11_level_editor_basics/LESSON.md`

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

---

## Phase 2 - Small Standalone Projects

### Ticket 030 - Sokoban Starter

Read:
- `learn/projects/sokoban/LESSON.md`
- `learn/projects/sokoban/README.md`

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
- `learn/co_op/different_views_puzzle/README.md`
- `learn/co_op/different_views_puzzle/prototype/LESSON.md`

Do:
- play with two sets of controls

Practice:
- add one more room
- add one more red-only bridge
- add one more blue-only bridge

If you do this, also try:
- make one player see a clue, other executes it
- add one object only one player can move

### Ticket 032 - Turn-Based Card Game Starter

Read:
- `learn/projects/turn_based_card_game/LESSON.md`

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
- `learn/production_with_sauce/01_architecture_map.md`
- `sauce/core_main.odin`

Do:
- trace frame flow from app start to draw end

Practice:
- write your own short note: where input happens, where update happens, where draw happens

If you do this, also try:
- point to exact place `app_frame` gets called

### Ticket 041 - Fundamentals To Sauce

Read:
- `learn/production_with_sauce/02_fundamentals_to_sauce.md`

Do:
- map each fundamentals ticket to one `sauce` area

Practice:
- answer: where should jump logic live in production?
- answer: where should camera logic live in production?
- answer: where should bloom live in production?

### Ticket 042 - What Is Sokol

Read:
- `learn/production_with_sauce/06_what_is_sokol.md`

Do:
- explain Sokol in one paragraph

Practice:
- write down what Sokol does not provide
- write down what `sauce` provides on top

### Ticket 043 - Sokol Header Map

Read:
- `learn/production_with_sauce/07_sokol_header_map.md`
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
- `learn/production_with_sauce/08_how_to_make_a_game.md`

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
- `learn/production_with_sauce/09_visual_effects_roadmap.md`

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
- `learn/production_with_sauce/10_genre_roadmap.md`
- `learn/design/puzzle_game_ideas/README.md`

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
- `learn/production_with_sauce/03_sokoban_in_sauce.md`
- `learn/production_with_sauce/04_coop_puzzle_in_sauce.md`
- `learn/production_with_sauce/05_production_tickets.md`

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
- `learn/production_with_sauce/12_turn_based_card_game_in_sauce.md`

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
- `learn/production_with_sauce/03_sokoban_in_sauce.md`

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

Read first:
- `learn/production_with_sauce/04_coop_puzzle_in_sauce.md`

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

### Ticket 072 - Mirror Laser Puzzle Study

Read:
- `learn/production_with_sauce/09_visual_effects_roadmap.md`

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
- `learn/production_with_sauce/10_genre_roadmap.md`

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
- `learn/projects/turn_based_card_game/README.md`
- `learn/production_with_sauce/12_turn_based_card_game_in_sauce.md`

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

## Phase 7 - Future Tooling And Upgrade Work

### Ticket 080 - Editor Future

Read:
- `t11_level_editor_basics`
- `learn/production_with_sauce/03_sokoban_in_sauce.md`

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
- `learn/production_with_sauce/11_sokol_upgrade_checklist.md`

Do:
- keep this for later milestone

Practice:
- do not execute now unless current tooling blocks real work

---

## Recommended Exact Reading Order

1. `learn/README.md`
2. `learn/MASTER_TICKET_LIST.md`
3. `learn/LEARNING_METHOD.md`
4. `learn/fundamentals/t01_hello_window/LESSON.md`
5. `learn/fundamentals/t02_shapes_colors/LESSON.md`
6. `learn/fundamentals/t03_movement/LESSON.md`
7. `learn/fundamentals/t04_gravity_jump/LESSON.md`
8. `learn/fundamentals/t05_coyote_jump_buffer/LESSON.md`
9. `learn/fundamentals/t06_wall_jump/LESSON.md`
10. `learn/fundamentals/t07_tilemap/LESSON.md`
11. `learn/fundamentals/t08_camera/LESSON.md`
12. `learn/fundamentals/t09_shaders_bloom/LESSON.md`
13. `learn/fundamentals/t10_particles_screenshake/LESSON.md`
14. `learn/fundamentals/t11_level_editor_basics/LESSON.md`
15. `learn/projects/sokoban/main.odin`
16. `learn/co_op/different_views_puzzle/prototype/main.odin`
17. `learn/projects/turn_based_card_game/README.md`
18. `learn/production_with_sauce/README.md`
19. `learn/production_with_sauce/01_architecture_map.md`
20. `learn/production_with_sauce/02_fundamentals_to_sauce.md`
21. `learn/production_with_sauce/06_what_is_sokol.md`
22. `learn/production_with_sauce/07_sokol_header_map.md`
23. `learn/production_with_sauce/08_how_to_make_a_game.md`
24. `learn/production_with_sauce/09_visual_effects_roadmap.md`
25. `learn/production_with_sauce/10_genre_roadmap.md`
26. `learn/production_with_sauce/12_turn_based_card_game_in_sauce.md`
27. `learn/production_with_sauce/03_sokoban_in_sauce.md`
28. `learn/production_with_sauce/04_coop_puzzle_in_sauce.md`
29. `learn/production_with_sauce/05_production_tickets.md`
30. `sauce/core_main.odin`
31. `sauce/game.odin`
32. `sauce/entity.odin`
33. `sauce/core_render.odin`
34. `sauce/build/build.odin`

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
