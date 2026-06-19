# GP14 — Blender From Zero [GUIDE]

## Goal

Get comfortable in Blender: navigate the 3D viewport, model one simple game
prop, and export it. This is a [GUIDE] — no Odin code; you follow steps inside
Blender (free: https://www.blender.org/download/).

> Even for a 2D game you will use Blender: rendering 3D props down to 2D
> sprites (pre-rendered art, like Donkey Kong Country / Diablo) is a powerful
> pipeline. And these skills transfer directly if you ever go 3D.

---

## Setup

1. Install Blender (latest LTS).
2. Open it, delete the splash. You see the default cube, a camera, a light.
3. Enable "Emulate Numpad" (Preferences → Input) if you have no numpad.

---

## Navigation (do until automatic)

- **Orbit**: Middle-Mouse-Button drag (or trackpad two-finger).
- **Pan**: Shift + MMB drag.
- **Zoom**: scroll.
- **Frame selected**: select an object, press `.` (numpad) or `View > Frame
  Selected`.
- **Views**: Numpad 1 (front), 3 (side), 7 (top), 0 (camera).

The 3 essentials of any object: **G** grab/move, **R** rotate, **S** scale.
Press, then type an axis (`X`/`Y`/`Z`) to constrain, then a number, then Enter.

---

## Modes

- **Tab** toggles Object Mode (move whole objects) ↔ Edit Mode (move
  vertices/edges/faces).
- In Edit Mode: `1` = vertices, `2` = edges, `3` = faces.

---

## Exercise — Model a Simple Crate / Chest

1. Start from the default cube (it is your crate).
2. Tab into Edit Mode. Select the top face (`3`, click).
3. **Inset** (`I`), drag in a little → makes a lid rim.
4. **Extrude** (`E`) down slightly → recessed lid.
5. Add a bevel: select all (`A`), `Ctrl+B`, drag for soft edges, scroll to add
   segments. Soft edges catch light and look far less "programmer cube".
6. Tab back to Object Mode.

You just modeled a game prop with the four verbs you will use forever: inset,
extrude, bevel, transform.

---

## Exercise — Export It

1. With the object selected: `File > Export > glTF 2.0 (.glb/.gltf)`.
   - glTF is the modern game-friendly format (geometry + materials + UVs).
   - For sprite pre-rendering you do not even export — you render to PNG
     instead (`F12` after setting up the camera).
2. Save into `asset_workbench/` (this repo already has that folder for art
   scratch work).

---

## Finish Rule

- Model the crate from memory (no instructions open).
- Change one thing (taller, more bevel).
- Break one thing (delete a face → see the hole) and fix it (F to fill).
- Add one detail (a small handle cube).

---

## Exit Criteria

- [ ] You can orbit/pan/zoom without thinking
- [ ] You can G/R/S with axis constraints
- [ ] You modeled a prop using inset/extrude/bevel
- [ ] You exported a `.glb` (or rendered a sprite PNG)

---

## Next Lesson

`learn/47_graphics_programming/gp15_uv`
