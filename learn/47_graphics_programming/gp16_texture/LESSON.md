# GP16 — Textures [GUIDE]

## Goal

Make the texture maps that feed the materials you learned in gp08 (PBR): an
**albedo**, a **roughness**, and a **normal** map for your crate. Understand
what each map drives and how to bake them. [GUIDE] — Blender + optionally a free
texture tool.

---

## The Concept

A "texture" is rarely one image. A PBR material = a small SET of maps, each
controlling one physical property the shader reads per pixel:

| Map           | Stores            | Drives (gp08)              |
|---------------|-------------------|----------------------------|
| **Albedo**    | base color, no light | the surface's raw color  |
| **Roughness** | grayscale 0..1    | highlight width (smooth↔matte) |
| **Metallic**  | grayscale 0/1     | metal vs dielectric        |
| **Normal**    | RGB-encoded normals (gp09) | fake bumps         |
| **AO**        | grayscale         | baked ambient occlusion (gp12) |
| **Height**    | grayscale         | parallax / displacement    |

They share the SAME UV layout (gp15), so they line up on the model.

---

## Exercise A — Paint Albedo (Texture Paint)

1. With the crate unwrapped (gp15), go to the **Texture Paint** workspace.
2. Create a new image (1024×1024), assign as Base Color.
3. Paint wood planks / metal bands directly on the 3D model. The UVs make it
   stick. Save the image (`Image > Save As` → `asset_workbench/`).

## Exercise B — Roughness By Hand

1. Duplicate the albedo as a grayscale image.
2. Dark = smooth (shiny metal bands), light = rough (worn wood). Paint it.
3. In the material, plug it into the **Roughness** input. Spin the model under a
   light: shiny bands vs matte wood — that is gp08 roughness, authored.

## Exercise C — Bake A Normal Map

Baking = transfer detail from a high-detail model onto a flat one.

1. Make a high-poly version (sculpt or add bevels/dents).
2. Make a low-poly version with the same UVs.
3. `Render Properties → Bake → Bake Type: Normal`, select high then low,
   **Selected to Active**, bake. You get a blue-ish normal map (gp09 colors).
4. Plug it through a **Normal Map** node into the material's Normal input.

> No high-poly handy? Free tools that generate decent maps from a single photo:
> the open-source workflow in **Materialize** or node-based **Material Maker**.
> Even a height-from-albedo trick gives a usable normal map.

---

## Finish Rule

- Produce albedo + roughness + normal for the crate, all on the same UVs.
- Change one map (rougher wood) and see the highlight widen.
- Break it: assign the albedo to the Normal input → ugly lighting. Fix it.
- Export the set into `asset_workbench/`.

---

## Exit Criteria

- [ ] You can list the PBR maps and what each drives
- [ ] You painted an albedo on the UV-unwrapped model
- [ ] You authored a roughness map and saw the highlight respond
- [ ] You baked (or generated) a normal map

---

## Next Lesson

`learn/47_graphics_programming/gp17_lighting_setup`
