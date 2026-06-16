# B01 — Visual-First Sauce Mindset

Goal: learn to make even tiny games feel like real games, not homework.

## Problem

Classic learning path says: make Snake with rectangles, no effects, no mood.
Technically correct. Emotionally dead.

You already know basics are not enough. Your target is polished co-op puzzle,
so practice games should train production instincts early.

## Better Loop

For every small game, use this build order:

1. **Core rule** — one playable loop, ugly but correct.
2. **Readable art** — sprite/atlas or deliberate rect-art, not random boxes.
3. **Feedback** — particles, hitstop, shake, sound hook.
4. **Mood** — shader/post-FX, palette, background movement.
5. **UI** — title, score, restart, state transition.
6. **Sauce placement** — move rules into `Game_State`, objects into entities.

No game stays ugly past milestone 1.

## What Goes Where In Sauce

| Thing | Sauce home |
|---|---|
| board/grid/tile state | `Game_State` |
| player/enemy/projectile/coin/particle entity | `Entity` / entity helpers |
| sprite enum + atlas frame count | `Sprite_Name`, `sprite_data` |
| draw calls | `game_draw`, entity `draw_proc` |
| input mapping | `action_map`, `get_input_vector`, custom intents |
| camera | `ctx.gs.cam_pos` |
| screen-space UI | `push_coord_space(get_screen_space())` |
| reusable render capability | `core_render.odin` |

## Entity Rule

Use entities when object has lifetime:

- spawn/destroy
- movement
- animation
- collision
- handle/reference
- many instances

Do not use entities for pure grid truth:

- Snake board cells
- Tetris board cells
- Sokoban walls/floors
- Parallel Worlds tile truth

Use arrays for truth, entities for actors/effects.

## Minimum Polish Contract

Every bridge game must have:

- title text
- restart flow
- one particle type
- one screen shake or hitstop event
- one strong palette/mood choice
- one "feel" improvement that changes no rules

This keeps learning useful and not boring.
