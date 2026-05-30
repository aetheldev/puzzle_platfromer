# Fake 2D Light Mask Reference

Goal: make rooms moodier with cheap 2D lighting tricks before building real lighting.

## Core Idea

Render dark room overlay.
Then punch light holes or add radial lights where needed.

## Good Fake Lighting Tools

1. radial gradient sprites
2. additive light sprites
3. dark fullscreen overlay with lighter circles
4. emissive objects plus blob shadows

## Where It Belongs

Game layer:
- which objects emit light
- light radius/intensity values

Renderer/draw layer:
- draw dark overlay
- draw radial masks or additive lights

## Good First Use Cases

- puzzle room torches
- glowing door/switch
- player lantern
- colored co-op role lights

## Why This Is Good

Much cheaper and easier than real lighting.
Often enough for 2D games.

## Upgrade Path

Later only if needed:
- normal maps
- shadow casters
- real light buffer

Most puzzle games do not need that first.
