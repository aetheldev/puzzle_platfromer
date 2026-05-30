# A06 Fake Lighting And Shadows

Goal: learn what is enough for a good-looking 2D game without overbuilding.

## First Truth

You usually do not need real dynamic lighting first.

Good fake lighting tools:
- additive glow sprites
- dark overlay with light holes
- radial gradients
- emissive pulses
- shadow blobs under characters/objects

## Shadow Progression

1. simple blob shadow
2. squash/stretch shadow by height
3. directional projected shadow sprite
4. only much later: real shadow system

## Read

- `learn/90_production_with_sauce/09_visual_effects_roadmap.md`

## Practice

- choose one puzzle-room scene
- decide where fake lights go
- decide what is shadow only, what is real glow only
