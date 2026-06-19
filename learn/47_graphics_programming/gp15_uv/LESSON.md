# GP15 — UV Unwrapping [GUIDE]

## Goal

Understand and do **UV unwrapping**: flattening a 3D surface into a 2D layout
so a texture image can wrap onto it cleanly. This is the bridge between modeling
(gp14) and texturing (gp16). [GUIDE] — done in Blender.

---

## The Concept

A texture is a flat 2D image. A model is a 3D surface. **UV coordinates** map
each point on the 3D surface to a `(u, v)` spot on the flat image — like the
flat paper net of a cube you fold into a box. "U" and "V" are just the names
for the texture's X and Y (X/Y/Z were taken by geometry).

Bad UVs = stretched, smeared, or seam-ugly textures. Good UVs = even texel
density (no part more blurry than another) and seams hidden in unseen places.

### Key ideas

- **Seam**: a cut edge where the surface is split so it can lie flat. Like
  scissors on the box's edges. Hide seams where they won't be seen.
- **Island**: a connected flattened chunk in the UV layout.
- **Texel density**: pixels-per-surface-unit. Keep it even so detail is
  consistent.
- The `0..1` UV square is the texture; islands packed inside it use space.

---

## Exercise — Unwrap the Crate

Use your crate from gp14 (or any cube).

1. Edit Mode (`Tab`). Open a UV Editor area (split the window, set one side to
   "UV Editing" workspace tab at the top).
2. Mark seams: select the edges you want to cut (often the vertical back edges
   of a box), `Edge` menu → **Mark Seam** (or `Ctrl+E`). Seams turn red.
3. Select all faces (`A`). `U` → **Unwrap**.
4. Look at the UV Editor: your faces are now flat islands.
5. Add a test grid: in the UV Editor image header, `New` → **UV Grid** /
   **Color Grid**. Assign it so the 3D model shows the checker. Even squares =
   even texel density; stretched squares = bad UVs to fix.

### Quick unwrap modes to try
- **Smart UV Project** (`U` menu): automatic, good first pass for props.
- **Unwrap**: respects your seams, best control.
- **Cube/Cylinder/Sphere Projection**: for primitive shapes.

---

## Finish Rule

- Unwrap the crate so the checker grid is even on every face.
- Change one seam placement; re-unwrap; see the islands change.
- Break it: remove all seams and unwrap → watch it stretch badly. Fix it.
- Pack the islands tightly (`UV` menu → Pack Islands).

---

## Exit Criteria

- [ ] You can explain what a UV map is (paper-net analogy)
- [ ] You marked seams and unwrapped a model
- [ ] You used a checker grid to judge texel density / stretching
- [ ] Your islands fit inside the 0..1 UV space, packed reasonably

---

## Next Lesson

`learn/47_graphics_programming/gp16_texture`
