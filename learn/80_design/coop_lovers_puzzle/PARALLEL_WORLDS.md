# The BOKURA Trick — How Two Players See Different Worlds In The Same Place

This doc answers ONE question that kept you stuck:

> In BOKURA, two players are in the same world but see totally different things —
> one sees a tech/future world where characters are robots, the other sees a
> green nature world where characters are animals. How is that possible? I want
> this in my game.

Short answer: **there are not two worlds. There is one world, drawn twice, with a
different costume each time.** Read on — and then run the working prototype that
proves it (link at the bottom).

---

## The Core Idea (the whole secret)

A game has two separate things that people confuse:

1. **The world's TRUTH** — the tile grid, where walls are, where players are,
   what collides. This is the *simulation*. It is the single source of truth.
2. **The world's LOOK** — what sprites/colors you DRAW for that truth. This is
   the *presentation*. It happens at draw time and changes nothing about the
   simulation.

BOKURA keeps **one** truth and forks the **look** per player. The same wall tile
is drawn as a metal panel for Player A and a mossy log for Player B. Same tile,
same collision box, two costumes. Multiply that across every tile and every
character, and one player "is in a tech world" while the other "is in a nature
world" — even though they are standing on the exact same grid.

```
            ONE shared simulation (truth)
                       |
        +--------------+--------------+
        |                             |
  draw with THEME = tech       draw with THEME = nature
   (robots, metal, blue)        (animals, plants, green)
        |                             |
   Player A's screen            Player B's screen
```

That is the entire illusion. No parallel level data. No duplicated physics. Just
a `theme` chosen at draw time.

---

## The One New Concept: `Theme`

Add an enum:

```odin
Theme :: enum { tech, nature }
```

Every tile and every character gets a **costume per theme** — in a real game a
sprite handle; in a prototype just a color:

```odin
Visual :: struct {
    sprites: [Theme]Sprite,   // same tile, two looks
}
```

Your draw function takes the **viewer's theme** and picks the matching costume:

```odin
draw_world :: proc(viewer: Theme) {
    for tile in tiles {
        spr := tile.visual.sprites[viewer]   // <- the whole trick
        draw_sprite(tile.pos, spr)
    }
}
```

Call it once per player with that player's theme. Done. Same world, two looks.

---

## Two Layers Of The Trick (build them in this order)

You decided to learn both, staged. Here they are.

### Layer 1 — Cosmetic Fork (the BOKURA base feeling)

- Every tile EXISTS for both players.
- Collision is IDENTICAL for both players.
- Only the **sprite + palette** differ per theme.
- A wall is a wall for both; it just looks like metal vs bark.

What makes it co-op: players must **describe what they see** to coordinate,
because the same object looks different to each. "My switch is a glowing flower
on the left" / "mine is a server panel — got it, pulling now." The geometry is
shared; the language is forked.

This is the simplest honest version of BOKURA. **Build this first.**

### Layer 2 — Truth Fork (the info-gap / ability-gap layer)

Now some tiles **disagree** between worlds:

- A tile is **solid walkable ground** in the nature world but an **empty void**
  in the tech world (or vice versa).
- So the two players genuinely cannot walk the same path. One must guide the
  other across gaps the guide cannot even see as gaps.

This is no longer pure cosmetics — collision now depends on the player. It is the
same per-player collision idea your existing `different_views_puzzle` lesson
teaches, just dressed in the two-worlds theme:

```odin
tile_blocks_player :: proc(tile: Tile, p: Player) -> bool {
    #partial switch tile {
    case .wall:               return true
    case .nature_only_ground: return p.theme == .tech    // void for tech
    case .tech_only_ground:   return p.theme == .nature   // void for nature
    case:                     return false
    }
}
```

What makes it co-op: real **information + ability gaps**. Neither player can
finish alone, because each one's world hides or blocks what the other needs.

**Rule:** ship Layer 1 first and feel it. Add Layer 2 only once the cosmetic fork
works and you understand `draw_world(theme)`.

---

## Characters Use The Same Trick

The "you are a robot / I am an animal" part is the same idea applied to the
player avatars. The player ENTITY is shared (one position, one logic). Its
AVATAR is themed by the viewer:

- Viewed in the tech world → draw a robot sprite.
- Viewed in the nature world → draw an animal sprite.

So Player A sees themselves and their partner as robots; Player B sees the exact
same two entities as animals. One entity, two avatars, chosen by viewer theme —
identical to how tiles work.

---

## How Each Player Actually Gets Their Own View

Three ways to put two themed views in front of two people. Pick by your stage.

| Method | When | Cost |
|---|---|---|
| **Split screen** (left = tech, right = nature) | prototype, same-keyboard testing | cheapest; one window, draw world twice into two halves |
| **Two windows / two cameras** | local, two displays | medium |
| **Networked, full-screen per client** | the real BOKURA setup | hardest; each client runs `draw_world(its_own_theme)` full-screen |

The beautiful part: **all three call the same `draw_world(viewer_theme)`**. Going
from split screen to networked does NOT change the trick — it only changes where
the second view is shown. So you can prototype the whole feeling on one keyboard
with split screen, and the networking is a later port, not a rewrite.

The provided prototype uses **split screen** so you can see both worlds at once
and confirm the illusion with your own eyes.

---

## Add The Mood With Post-FX (optional, later)

The cosmetic fork alone already reads as two worlds. To go further, run each
view through a different post-process shader so the *whole picture* gets a mood:

- Tech world: cool color grade, faint scanlines/CRT, sharp lights.
- Nature world: warm grade, soft fog, bloom on plants.

You already have these exact tools: `learn/45_shaders_postfx/` (s02 fog, s04 CRT,
s05 color grading, s06 bloom). This is decoration — do it AFTER the gameplay
fork is fun, never before.

---

## Run The Working Prototype

A complete, runnable proof of everything above lives at:

- Lesson: `learn/70_co_op/parallel_worlds_puzzle/prototype/LESSON.md`
- Runnable answer: `learn/95_solutions/co_op/parallel_worlds_puzzle/prototype/main.odin`

Run it:

```sh
cd learn/95_solutions/co_op/parallel_worlds_puzzle/prototype
zsh build.sh
```

You will see ONE grid drawn as two worlds side by side. Left half = tech (metal,
robots, blue). Right half = nature (plants, animals, green). Player A (WASD) lives
in the left view, Player B (arrows) in the right. The `n`/`t` tiles are the Layer
2 truth fork: ground in one world, void in the other. Read `main.odin` — the
whole illusion is the single `draw_world(viewer, ...)` proc.

---

## Where This Sits In Your Roadmap

This is your **Milestone 6** ("different view") made concrete — but you can now
reach for the *cosmetic* half of it earlier, because it is genuinely simple. Do
NOT skip Milestones 1–5 (movement, ability gap, levers, info gap, two rooms) to
chase it; the two-worlds look is empty without a puzzle underneath. Sequence:

1. Milestones 1–5 from `README.md` (one-screen, gameplay first).
2. Layer 1 cosmetic fork from this doc (reskin the same room two ways).
3. Layer 2 truth fork (some ground exists in only one world).
4. Post-FX moods, then split/network.

The renderer is replaceable. The puzzle is the game. The two-worlds look is a
costume you add on top of a puzzle that already works.

---

## Building It In The Real `sauce/` Engine

Once the standalone prototype feels right, rebuild it as a real mode in `sauce/`
(entities, two-player input, themed draw, camera, optional split screen). Full
step-by-step with exact file/line references:

- `learn/90_production_with_sauce/13_parallel_worlds_coop_in_sauce.md`

It covers the two real wiring problems: (1) two independent players from one
keyboard via `Player_Intent` (the blueprint's input is single-player), and (2)
the theme fork in the entity draw procs. Read `04_coop_puzzle_in_sauce.md` first.
