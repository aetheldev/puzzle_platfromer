# Parallel-Worlds Co-op In Sauce (the BOKURA trick, productionized)

Goal: take the standalone parallel-worlds prototype
(`learn/95_solutions/co_op/parallel_worlds_puzzle/`) and rebuild it as a real
mode inside `sauce/`, using the engine's entity system, input, renderer, and
camera. This is the "how do I actually wire two players and two world-views into
sauce, and where does each piece live?" guide.

Prereqs: do `04_coop_puzzle_in_sauce.md` first (it covers the same-screen ability
fork). This doc adds the THEME fork (two looks) and the two-player input wiring.

---

## What Sauce Already Gives You (don't rebuild these)

Read these in the real code before you touch anything:

- `Game_State` — `sauce/game.odin:42`. Your data hangs here.
- `Entity` megastruct — `sauce/game.odin:87`. One big struct, add fields freely.
- `Entity_Kind` enum + `entity_setup` switch — `sauce/game.odin:116` and `:122`.
- `entity_create(kind)` / `entity_from_handle` / `entity_destroy` —
  `sauce/entity.odin:63`, `:50`, `:87`.
- Entity loop (update then draw) — `game_update` `sauce/game.odin:269`,
  `game_draw` `sauce/game.odin:327`.
- Input action map (SINGLE, shared) — `action_map` `sauce/game.odin:64`,
  `Input_Action` `:74`, `get_input_vector` `sauce/game_utils.odin:110`,
  `is_action_down` `:88`.
- Draw helpers — `draw_sprite` `sauce/core_draw.odin:30`, `draw_rect` `:109`,
  `draw_text` `sauce/core_draw_text.odin:10`, `push_coord_space`
  `sauce/core_render.odin:361`, `get_world_space` `sauce/game_utils.odin:45`.
- Camera — `ctx.gs.cam_pos` `sauce/game.odin:45` (renderer reads this).
- Z sorting — `ZLayer` enum `sauce/game.odin:144`.

Layer rule (from `01_architecture_map.md`): keep ALL of this work in the GAME
layer (`game.odin`). Touch `core_*` only for split screen / second window, which
is a LATER step.

---

## The Two Problems To Solve, And Where Each Lives

1. **Two independent players from ONE keyboard.**
   The blueprint's input is a single global `action_map` + `get_input_vector()`.
   That is built for ONE player. You must not make both players read it, or they
   move together. Fix: give each player its own intent, filled from its own keys.
   Lives in: `game.odin` (state + input), no core changes.

2. **Two world LOOKS (the BOKURA fork).**
   Same entity/tile, different sprite per `Theme` at draw time.
   Lives in: `game.odin` draw procs. Cosmetic fork needs NO core changes.
   Showing both views at once (split screen) DOES need core — do that last.

---

## Step 1 — Player Intent (do this FIRST, it unlocks everything)

The blueprint reads keys directly inside the player's `update_proc`
(`get_input_vector()` at `sauce/game.odin:409`). For two players — and for future
networking — gameplay must read an INTENT, not the keyboard.

Add to `game.odin`:

```odin
Player_Intent :: struct {
    move:     Vec2,   // -1..1 per axis
    interact: bool,
}
```

Add a second action set. The blueprint's `action_map` is fine for player A; add
explicit keys for player B (the map approach doesn't have to be the only way —
for the second player you can just read raw `Key_Code`s):

```odin
// Player A uses the existing action_map (.up/.down/.left/.right = WASD).
// Player B reads arrows directly.
fill_intents :: proc(a: ^Player_Intent, b: ^Player_Intent) {
    a.move = get_input_vector()                 // existing WASD path
    a.interact = is_action_pressed(.interact)   // existing E

    bm: Vec2
    if key_down(.LEFT)  do bm.x -= 1
    if key_down(.RIGHT) do bm.x += 1
    if key_down(.DOWN)  do bm.y -= 1
    if key_down(.UP)    do bm.y += 1
    b.move = bm == {} ? {} : linalg.normalize(bm)
    b.interact = key_pressed(.RIGHT_SHIFT)
}
```

Now the player update reads `e.intent`, never the keyboard. Store intent on the
entity (it is a megastruct — just add the field).

Why first: once movement reads intent, "second player", "split controls", and
later "network player" are all just different ways to FILL the intent. This is
the single habit that turns networking into a port, not a rewrite
(`learn/85_networking/03_input_for_networked_coop.md`).

---

## Step 2 — Theme On The Entity

Add the BOKURA enum and put a theme + intent on every relevant entity. Extend the
megastruct (`sauce/game.odin:87`) — adding fields to it is the intended workflow:

```odin
Theme :: enum { tech, nature }

// ...inside Entity struct, in the "big sloppy entity state dump" area:
    theme:  Theme,          // which world this entity belongs to / is the player of
    intent: Player_Intent,  // filled by input or network, read by update
```

Add the player kinds to `Entity_Kind` (`sauce/game.odin:116`):

```odin
Entity_Kind :: enum {
    nil,
    player,        // keep the demo player if you like
    player_a,      // tech lover (robot avatar)
    player_b,      // nature lover (animal avatar)
}
```

Wire them in `entity_setup` (`sauce/game.odin:122`):

```odin
switch kind {
    case .nil:
    case .player:   setup_player(e)
    case .player_a: setup_lover(e, .tech)
    case .player_b: setup_lover(e, .nature)
    case .thing1:   setup_thing1(e)
}
```

---

## Step 3 — One Lover Setup, Themed

One setup proc for both, parameterized by theme. Movement reads `e.intent`, not
keys:

```odin
setup_lover :: proc(e: ^Entity, theme: Theme) {
    e.kind  = (theme == .tech) ? .player_a : .player_b
    e.theme = theme
    e.draw_pivot = .bottom_center

    e.update_proc = proc(e: ^Entity) {
        e.pos += e.intent.move * 100.0 * ctx.delta_t
        if e.intent.move.x != 0 do e.last_known_x_dir = e.intent.move.x
        e.flip_x = e.last_known_x_dir < 0
        // collision/puzzle hooks go here (see Step 5)
    }

    e.draw_proc = proc(e: Entity) {
        // THE THEME FORK: same entity, sprite chosen by theme.
        spr: Sprite_Name = (e.theme == .tech) ? .robot_idle : .animal_idle
        draw_sprite(e.pos, .shadow_medium, col={1,1,1,0.2})
        draw_sprite(e.pos, spr)
    }
}
```

Add `robot_idle` / `animal_idle` to `Sprite_Name` (`sauce/game.odin:159`) and
drop the `.png`s in `res/images` (that is the whole "add a sprite" flow per the
comment at `sauce/game.odin:169`). Prototype with two `draw_rect` colors first if
you have no art yet.

Spawn both on first tick (mirror the demo spawn at `sauce/game.odin:261`):

```odin
if ctx.gs.ticks == 0 {
    a := entity_create(.player_a); ctx.gs.player_a = a.handle
    b := entity_create(.player_b); ctx.gs.player_b = b.handle
}
```

And fill intents each frame BEFORE the entity update loop:

```odin
// near the top of game_update, before the get_all_ents loop:
pa := entity_from_handle(ctx.gs.player_a)
pb := entity_from_handle(ctx.gs.player_b)
fill_intents(&pa.intent, &pb.intent)
```

Add the two handles to `Game_State` (`sauce/game.odin:42`):

```odin
player_a: Entity_Handle,
player_b: Entity_Handle,
```

---

## Step 4 — Tiles + The Theme Costume Table

Tiles in a puzzle are usually NOT entities — keep them as a grid on `Game_State`
(cheaper, easier to reset). Same model as both prototypes:

```odin
Tile :: enum u8 { empty, wall, nature_only_ground, tech_only_ground, exit_a, exit_b }

// on Game_State:
tiles: [ROWS][COLS]Tile,
```

The costume table is the illusion (identical idea to the standalone prototype). In
sauce, costumes are `Sprite_Name`s instead of colors:

```odin
Tile_Visual :: struct { sprite: [Theme]Sprite_Name }

tile_visuals := [Tile]Tile_Visual {
    .wall = { sprite = { .tech = .metal_panel, .nature = .bark_wall } },
    .nature_only_ground = { sprite = { .tech = .void_tile, .nature = .leaf_ground } },
    // ...
}
```

Draw the grid in `game_draw` (inside the world coord space, `sauce/game.odin:319`),
picking costume by the VIEWER's theme:

```odin
draw_world :: proc(viewer: Theme) {
    for row in 0..<ROWS do for col in 0..<COLS {
        t := ctx.gs.tiles[row][col]
        spr := tile_visuals[t].sprite[viewer]   // <- the BOKURA line, in sauce
        draw_sprite(tile_world_pos(row, col), spr, z_layer=.background)
    }
}
```

---

## Step 5 — Collision Truth (shared) + The Truth Fork

Keep ONE collision proc, exactly like the prototype. This is the "different
truth" half. Cosmetic-only games delete the `*_only_ground` cases.

```odin
tile_blocks_player :: proc(t: Tile, e: ^Entity) -> bool {
    #partial switch t {
    case .wall:               return true
    case .nature_only_ground: return e.theme == .tech    // void for tech
    case .tech_only_ground:   return e.theme == .nature   // void for nature
    case:                     return false
    }
}
```

Call it from the lover's `update_proc` when applying `e.intent.move` (grid-step
or AABB, your choice). Shared puzzle state (levers/door/exit reached) lives on
`Game_State`, checked once per frame in `game_update`, same as the standalone
`update_game_state()`.

---

## Step 6 — Camera

Single shared camera = midpoint of both lovers (the blueprint already lerps
`cam_pos`, see `sauce/game.odin:287`):

```odin
mid := (pa.pos + pb.pos) * 0.5
utils.animate_to_target_v2(&ctx.gs.cam_pos, mid, ctx.delta_t, rate=10)
```

For the standalone same-screen version, that is enough: both players, one camera,
both themed sprites drawn in ONE pass. But ONE pass can only show ONE theme at a
time. To show BOTH worlds at once you need split screen — Step 7.

---

## Step 7 — Two Views (split screen) — the only CORE change, do LAST

To render the SAME world twice (tech on the left, nature on the right), you draw
two passes/viewports with different `viewer` theme and different camera. The
blueprint draws a single full-window pass (`game_draw` → one swapchain pass in
`core_render`). Showing two viewports means touching `core_render.odin`:

- Option A (simplest first step): two render-to-texture passes, each calling
  `draw_world(theme)` with its own camera, then blit each texture to half the
  screen. The post-FX lessons already set up render-to-texture:
  `learn/45_shaders_postfx/s00_foundation/`.
- Option B (networked, the real BOKURA): no split screen at all. Each client runs
  full-screen `draw_world(its_own_theme)`. Same `draw_world` call, the second
  view just lives on another machine. See `learn/85_networking/`.

Do NOT start here. Same-screen single-theme (Steps 1–6) must work and be fun
first. Per the architecture map, this is exactly the "post-process / split screen"
reason that justifies a core change — and only then.

---

## File-By-File: Where Everything Goes

| Thing | File | Why |
|---|---|---|
| `Theme`, `Tile`, `Player_Intent`, `Tile_Visual`, costume table | `sauce/game.odin` | game-specific data |
| `player_a` / `player_b` handles, `tiles` grid, door/lever state | `Game_State`, `sauce/game.odin:42` | one source of truth |
| `theme` + `intent` fields | `Entity` struct, `sauce/game.odin:87` | megastruct, add freely |
| `player_a` / `player_b` kinds + setup | `Entity_Kind` `:116`, `entity_setup` `:122` | lifecycle wiring |
| `fill_intents`, lover `update_proc`, collision, win check | `game_update`, `sauce/game.odin:249` | per-frame logic |
| `draw_world`, themed `draw_proc` | `game_draw`, `sauce/game.odin:303` | the look fork |
| new sprites | `Sprite_Name` `:159` + `res/images/*.png` | art |
| camera midpoint | `ctx.gs.cam_pos`, `sauce/game.odin:287` | shared cam |
| split screen / second view | `sauce/core_render.odin` | LAST, core change |

---

## Production Ticket Order (small, each playable)

1. Add `Player_Intent`; refactor the demo player to read intent (still one player).
2. Add `player_a` / `player_b` kinds + `setup_lover`; spawn both; `fill_intents`;
   two squares move independently from WASD + arrows.
3. Add `theme` field + themed `draw_proc` (rect colors first, sprites later).
4. Add `tiles` grid + `draw_world(theme)` with the costume table (cosmetic fork).
5. Add shared collision proc; both collide with walls.
6. Add the truth fork (`*_only_ground`); confirm worlds disagree about walkable.
7. Add shared puzzle state (lever/door) + win when both reach exits.
8. Add camera midpoint + reset (`R` reloads the grid).
9. Add second room (prove level loading isn't hardcoded).
10. (LATER) post-FX moods per view; then split screen; then networking.

---

## Common Mistakes (learned the hard way)

- Both players reading `get_input_vector()` → they move as one. Use per-player
  intent (Step 1).
- Duplicating the tile grid per theme → you reintroduced "two worlds" and broke
  the single-source-of-truth. There is ONE grid; only the costume forks.
- Putting collision in two places → keep ONE `tile_blocks_player`.
- Reaching for split screen on day one → it's a core change and a trap. Same
  screen, single theme, fun gameplay FIRST.
- Forking collision when you only wanted the LOOK → for a pure cosmetic BOKURA,
  delete the `*_only_ground` cases; collision stays identical, only sprites fork.

---

## Where To Go Next

- Mood per view: `learn/45_shaders_postfx/` (fog, CRT, grading, bloom).
- Online (each client = its own theme full-screen): `learn/85_networking/`.
- Effects for two-player clarity: `learn/50_advanced/a13_coop_game_in_sauce_plus_fx.md`.
- The standalone source this maps from:
  `learn/95_solutions/co_op/parallel_worlds_puzzle/prototype/main.odin`.
