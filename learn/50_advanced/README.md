# Advanced Phase

Purpose: show what comes after beginner lessons.

This folder is not your first coding path.
This is your:
- production-style path
- shader-heavy path
- sauce-oriented path
- "what good can look like later" path

Important:
- beginner path teaches concepts simply
- advanced path teaches how those same ideas grow into real production systems
- advanced path assumes you already understand basics like movement, tilemaps, camera, particles, and simple shaders

## What Advanced Means Here

Advanced does **not** mean:
- write huge code for no reason
- use clever abstractions everywhere
- overengineer

Advanced means:
- stronger rendering pipeline decisions
- better visual quality
- better separation of data/update/render
- sauce-first architecture
- performance awareness
- reusable gameplay systems

## Main Rule

If beginner path says:
- "draw a glowing box"

Advanced path says:
- "when does this become a renderer feature?"
- "when should this be a shader parameter?"
- "when should this be a game entity vs a transient effect?"
- "how does this fit inside `sauce/`?"

## Best Order

1. `a01_sauce_rendering_mindset.md`
2. `a02_shader_pipeline_and_postfx.md`
3. `a03_production_glow_and_bloom.md`
4. `a04_fire_burn_and_elemental_fx.md`
5. `a05_lasers_mirrors_and_beam_fx.md`
6. `a06_fake_lighting_and_shadows.md`
7. `a07_game_feel_and_juice.md`
8. `a08_optimization_mindset.md`
9. `a09_sauce_feature_promotion.md`
10. `a10_networking_readiness.md`
11. `a11_sokoban_in_sauce_plus_fx.md`
12. `a12_card_game_in_sauce_plus_fx.md`
13. `a13_coop_game_in_sauce_plus_fx.md`
14. focused refs in `learn/95_solutions/advanced/`

## End Goal

You should be able to answer:
- what belongs in `game.odin`
- what belongs in `core_render.odin`
- when a VFX trick is enough
- when you need real renderer support
- how to turn prototype effects into production effects

You should also be able to answer:
- how Sokoban gets polished inside `sauce/`
- how a card game gets polished inside `sauce/`
- how an asymmetric co-op game uses effects for readability, not only beauty
