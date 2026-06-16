# B02 — Snake In Sauce, But Juicy

Goal: rebuild Snake inside `sauce/` as a polished microgame.

Not rectangle homework. Neon snake, particles, CRT/color grade, score UI.

## Why Snake

Snake is small enough to port fast, but rich enough to teach production layout:

- board array in `Game_State`
- snake segments as data, not entities
- food as entity or board marker
- particles as entities
- score UI in screen space
- post-FX mood

## Sauce Structure

Add to `Game_State`:

```odin
Snake_Cell :: struct { x, y: int }
Snake_Dir :: enum { up, down, left, right }
Snake_Mode :: enum { title, playing, dead }

snake_body: [dynamic]Snake_Cell
snake_dir: Snake_Dir
snake_next_dir: Snake_Dir
snake_food: Snake_Cell
snake_score: int
snake_tick: f32
snake_mode: Snake_Mode
```

Entities:

- optional `food` entity for animation/glow
- `particle` entities for eat/death burst
- no entity per snake segment unless you want animated bodies later

## Milestones

1. Port plain Snake board into `Game_State`.
2. Draw board with `draw_sprite` or styled `draw_rect` in `game_draw`.
3. Add title/death UI using `draw_text`.
4. Add eat particles: green/yellow burst at food cell.
5. Add death shake + red flash.
6. Add CRT/color grade or bloom-like glow pass if available.
7. Add animated snake head sprite + tail fade.

## Visual Direction

Pick one:

- **Arcade CRT**: dark grid, neon green snake, scanline shader.
- **Potion Snake**: snake = glowing vine, food = magic orb, bloom particles.
- **Cyber Lab**: snake = data cable, food = battery cell, electric sparks.

## Important Lesson

Snake teaches: not everything is an entity. Board games often live cleaner as
arrays. Use sauce for renderer/input/UI/effects, not forced ECS everywhere.
