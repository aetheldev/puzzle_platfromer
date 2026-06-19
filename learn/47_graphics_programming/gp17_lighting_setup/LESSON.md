# GP17 — Lighting Setup [GUIDE]

## Goal

Light a scene so your textured crate (gp14-16) looks great: the **three-point**
rig (key / fill / rim), HDRI environment lighting, color temperature, and
baking. Good lighting beats good models. [GUIDE] — Blender.

---

## The Concept

Lighting is what makes assets read as 3D and feel like a place. The classic
film/game rig is **three-point lighting**:

- **Key light** — the main light. Brightest, off to one side and above.
  Defines the primary shadows and the subject's shape.
- **Fill light** — softer, opposite the key, dimmer. Lifts the shadows so they
  are not pure black. Key:fill ratio controls drama (high ratio = moody).
- **Rim / back light** — behind the subject, edges it with a bright outline.
  Separates the subject from the background. (This is gp07 Fresnel in real
  light form.)

### Other essentials

- **HDRI environment**: a 360° image used as ambient light + reflections. The
  single fastest way to make a render look real. Free HDRIs:
  https://polyhaven.com/hdris . Set it in `World > Surface > Environment
  Texture`.
- **Color temperature**: warm (orange, ~3000K, sunset/lamp) vs cool (blue,
  ~6500K+, shade/moonlight). Contrasting key-warm / fill-cool reads as natural
  and cinematic (ties back to gp13 grading).
- **Soft vs hard**: bigger light size = softer shadows. Tiny light = sharp
  shadows. Match the mood.
- **Exposure / tone**: the render still needs tone mapping (gp11) — set
  `View Transform` to Filmic/AgX in Color Management.

### Baking lighting

For static scenes (and to pre-render 2D sprites), **bake** lighting into
textures so it is free at runtime: `Render → Bake → Combined` or use a
lightmap. This is how many 2D games get gorgeous lighting with zero runtime
cost — the light is painted into the sprite.

---

## Exercise — Light The Crate

1. Delete the default light. Set an HDRI in the World (Poly Haven).
2. Add an **Area light** as the key: large, warm (~4000K), upper-left.
3. Add a dimmer **Area light** as fill: opposite side, cool (~6500K), maybe
   half the key's power.
4. Add a small bright **Area/Spot** behind for the rim; aim it to catch the top
   edge.
5. Set Color Management → View Transform → AgX (or Filmic). Adjust Exposure.
6. `F12` to render. Iterate light positions/power until the crate has shape,
   lifted shadows, and a crisp rim.

---

## Finish Rule

- Build the three-point rig from memory.
- Change the key:fill ratio; see drama increase.
- Break it: turn off the rim → subject merges with background. Fix it.
- Render the crate to a PNG sprite and drop it in `asset_workbench/` — you now
  have a pre-rendered 2D asset for the game.

---

## Exit Criteria

- [ ] You can describe key / fill / rim and each one's job
- [ ] You used an HDRI for environment light
- [ ] You used warm/cool color temperature deliberately
- [ ] You rendered (or baked) a good-looking lit asset

---

## Where This Goes Next

You have now gone math → shaders → post-FX → assets. Bring it together:

- Pre-render Blender props to sprites, drop them into a `60_projects` game.
- Run that game's scene through your `45_shaders_postfx` + gp10/gp11/gp13
  post stack.
- Move the winning effects into `sauce/` via `learn/90_production_with_sauce/`.
