# Visual Effects Roadmap

Goal: know what to learn for glow, particles, shadows, lights, lasers.

## Learn In This Order

1. basic sprite/quad rendering
2. color tint and alpha
3. additive blending
4. particles
5. camera shake
6. simple shadows
7. custom shader params
8. offscreen render targets
9. bloom/post-process
10. lighting systems

Do not jump to bloom before understanding alpha, blend, and shader uniforms.

## 1. Color Tint And Alpha

Needed for:
- hover highlight
- damage flash
- fade in/out
- UI emphasis

Look at:
- `sauce/core_render.odin`
- shader color path in `sauce/shader.glsl`

## 2. Additive Blending

Needed for:
- glow sprites
- magic sparkles
- energy effects
- laser bloom look

Concept:
- normal alpha: sprite covers things
- additive: sprite adds brightness

Use for:
- fire
- laser core
- explosions
- highlights

## 3. Particles

Needed for:
- dust
- explosion bits
- wall slide dust
- magic sparks
- hit feedback

Learn first with:
- fixed pool array
- life
- velocity
- color/size fade

Then later:
- particle emitters
- burst presets
- curve-based control

## 4. Camera Shake

Needed for:
- impact
- explosions
- landing
- door slam

Do not overuse.
Small shake feels better than huge shake.

## 5. Simple Shadows

Start simple:
- fake blob shadow under character
- darker quad projected under object

You do not need real shadow maps for 2D puzzle game.

Good enough for long time:
- soft circle/ellipse shadow sprite
- opacity based on height if platforming

## 6. Light Effects

For 2D puzzle games, start fake.

Fake light tools:
- radial gradient sprite
- additive glow sprites
- dark overlay with holes/lights
- emissive color in shader

Real dynamic lighting is later.

## 7. Bloom

Bloom means bright things bleed light into nearby pixels.

You need before doing proper bloom:
- render target / offscreen texture
- fullscreen pass
- blur pass or cheap approximate glow

For your repo:
- first do cheap fake bloom with additive sprites
- later add offscreen pass in `core_render`

## 8. Mirror And Laser Puzzle

What to learn first:
1. line tracing / ray stepping
2. grid or geometry intersection
3. reflection rule
4. beam state update
5. beam rendering
6. hit targets / splitters / switches

Where to look:
- gameplay logic in `game.odin`
- draw beam segments in `core_render` helpers or game draw code
- additive blending for beam glow
- particles for hit sparks

Best first version:
- discrete line segments
- no real light system
- fake glow sprite/quad on beam

## 9. Explosion Look

Great simple explosion formula:
1. bright core sprite
2. outward particles
3. smoke particles
4. tiny shake
5. one sound
6. brief screen flash or additive burst

No need complex simulation first.

## Great-Looking Game Rule

Great look usually comes from layered simple effects:
- strong shapes
- readable colors
- good timing
- sound sync
- small motion
- consistent art language

Not from one giant shader alone.
