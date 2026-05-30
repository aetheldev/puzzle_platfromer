# A05 Lasers, Mirrors, And Beam FX

Goal: connect gameplay simulation and visual quality.

## Gameplay Side

Need:
- beam origin
- direction
- hit test
- reflection rule
- target activation

## Visual Side

Need:
- beam core
- soft glow
- hit spark
- maybe impact ring
- optional flicker/pulse

## Read

- `learn/40_vfx/v04_laser_beam/LESSON.md`
- `learn/90_production_with_sauce/09_visual_effects_roadmap.md`

## Practice

- define how beam data should be stored in game state
- define how many line segments a reflected beam can have
- define what happens when beam hits mirror, wall, target

## Production Hint

Laser puzzle usually starts in `game.odin` as rule system.
Only later do you move visual parts into stronger render features if needed.
