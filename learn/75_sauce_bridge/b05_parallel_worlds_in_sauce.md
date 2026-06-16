# B05 — Parallel Worlds In Sauce (Main Bridge)

Goal: take your real target — same world, different views — and build it inside
`sauce/` with production structure and visual mood.

This is the bridge that matters most for your final co-op puzzle game.

## Core Fantasy

One shared simulation:

- same tile grid
- same entity positions
- same puzzle state

Two presentations:

- Player A sees tech/robot world
- Player B sees nature/animal world

Optional truth fork:

- some tiles solid for one player, void for other
- some interactables readable only in one theme

## Sauce Data Model

Add to `Game_State`:

```odin
Theme :: enum { tech, nature }
Tile :: enum u8 { empty, wall, tech_ground, nature_ground, switch, exit }

tiles: [ROWS][COLS]Tile
player_a: Entity_Handle
player_b: Entity_Handle
```

Add to `Entity`:

```odin
theme: Theme
intent: Player_Intent
```

Add entity kinds:

```odin
player_a,
player_b,
switch,
vfx_particle,
```

## Visual Costume Table

Same tile, two sprites:

```odin
Tile_Visual :: struct { sprite: [Theme]Sprite_Name }

tile_visuals := [Tile]Tile_Visual {
    .wall = { sprite = { .tech = .metal_panel, .nature = .bark_wall } },
    .switch = { sprite = { .tech = .server_button, .nature = .glowing_flower } },
}
```

The magic line:

```odin
spr := tile_visuals[tile].sprite[viewer_theme]
```

## Milestones

### 1. Same World, Two Looks

- Load one tile grid.
- Draw it twice: tech palette and nature palette.
- No truth fork yet.
- Add UI labels: `TECH VIEW`, `NATURE VIEW`.

### 2. Two Player Intents

- Player A uses WASD.
- Player B uses arrows.
- Store movement in `Player_Intent`.
- Player update reads intent, not keys.

### 3. Themed Avatars

- Same player entity.
- Draw robot sprite in tech view.
- Draw animal sprite in nature view.
- Partner also changes costume based on viewer.

### 4. Truth Fork Tiles

- `tech_ground` solid for tech player, void for nature.
- `nature_ground` solid for nature player, void for tech.
- Add subtle visual tell in each theme.

### 5. Puzzle Room

Build one room where:

- tech player sees a server switch
- nature player sees a flower switch
- both describe positions differently
- one opens a bridge for other
- both must reach exits

### 6. Mood Pass

Add visual difference:

- tech: cool blue, CRT/scanline, sharp glow
- nature: warm green, fog, soft bloom

If split-screen shader is hard, fake it first with palette + overlay rectangles.

### 7. Juice

- footstep particles per theme
- switch activation burst
- door open shake
- success particles
- small hitstop on puzzle completion

## What Not To Do Yet

- no networking
- no full editor
- no asset pipeline rewrite
- no ECS rewrite
- no giant story system

Make one beautiful room first.

## Done When

- [ ] One grid draws as two worlds.
- [ ] Two players move independently.
- [ ] One tile looks different per viewer.
- [ ] At least one truth-fork tile changes collision per player.
- [ ] One puzzle requires communication.
- [ ] Visual mood differs before any text explains it.
- [ ] It has particles or shader mood, not plain rectangles only.

## Next Docs

- `learn/70_co_op/parallel_worlds_puzzle/prototype/LESSON.md`
- `learn/80_design/coop_lovers_puzzle/PARALLEL_WORLDS.md`
- `learn/90_production_with_sauce/13_parallel_worlds_coop_in_sauce.md`
