# A03 Production Glow And Bloom

Goal: learn what separates beginner glow from production-looking glow.

## Beginner Glow

- stacked transparent sprites/quads
- additive layers
- cheap and useful

## Production Glow

- emissive objects identified intentionally
- brightness extraction
- blur/composite pass
- controlled bloom radius
- color grading awareness

## Good Progression

1. additive glow sprite
2. emissive shader pulse
3. selective bloom mask
4. full bloom chain

## Read

- `learn/40_vfx/v01_glow_highlight/LESSON.md`
- `learn/90_production_with_sauce/09_visual_effects_roadmap.md`

## Practice

- decide which objects in your puzzle game deserve bloom
- decide which should stay only as simple additive glow

Good candidates:
- active goals
- lasers
- magic switches
- elemental pickups

Bad candidates:
- every wall
- every UI element
- everything all the time
