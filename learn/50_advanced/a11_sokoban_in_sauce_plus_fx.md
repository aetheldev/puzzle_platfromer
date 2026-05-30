# A11 Sokoban In Sauce Plus FX

Goal: understand how a simple grid puzzle becomes a polished production game inside `sauce/`.

## Core Game Layer

Main game pieces:
- level grid in `Game_State`
- player entity
- box entities
- goal tile data
- move counter / undo stack
- level progression state

Start here:
- `learn/90_production_with_sauce/03_sokoban_in_sauce.md`

## Where Effects Fit

Keep first version simple.
Then add layered feedback:

### Push Feedback
- tiny dust particles at box base
- short camera nudge
- box edge flash
- soft thud sound

### Goal Feedback
- goal tile glow pulse when uncovered
- stronger glow when box lands on it
- tiny sparkle burst on correct placement

### Level Complete Feedback
- all goals pulse together
- brief vignette/glow bloom on solved board
- next-level transition

## What Stays In Game Code

- push rules
- win detection
- undo logic
- level load/reset
- when a VFX event triggers

## What May Move Into `core_render`

- shared glow material path
- emissive/bloom support
- reusable fullscreen transition pass

## Good Advanced Milestones

1. production Sokoban works with no polish
2. add push dust and shake
3. add goal glow
4. add solve transition
5. add nice UI and animation timing

## Practice

- decide 3 effects that should happen on `push`
- decide 3 effects that should happen on `goal reached`
- decide whether bloom is really needed or additive glow is enough
