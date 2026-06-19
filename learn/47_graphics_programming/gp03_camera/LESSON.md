# GP03 — Camera (View Matrix) [RUN]

## Goal

You met camera-as-offset in `30_fundamentals/t08`. Now understand it as a
**view matrix**: the inverse of the camera's own transform. Same result,
proper mental model, and the exact concept used in 3D.

---

## The Concept

A camera is just another object with a transform (position, rotation, zoom).
But the camera does not move — it makes the WORLD move the opposite way so the
camera stays at the screen center.

That "opposite way" is the **inverse**:

```
view = inverse(camera_model)
```

If the camera is at `(cx, cy)`, its model translates by `(cx, cy)`, so the view
translates everything by `(-cx, -cy)`. Zoom 2× on the camera = scale the world
2×. Rotate the camera = rotate the world the other way.

### The full chain

A vertex goes through three matrices to reach the screen:

```
clip = projection * view * model * local_point
        ^gp04        ^this  ^gp02
```

This is the famous **MVP** (Model · View · Projection). In 2D you often skip a
real projection (you just map pixels to NDC), but the M and V are real and
useful right now.

### Why inverse instead of "subtract camera pos"?

Subtracting works for position only. The inverse also handles camera ROTATION
and ZOOM correctly, in one operation. Same trick scales straight to 3D.

---

## If You Know JS/React...

`overflow` container + `scrollLeft/scrollTop` moves the viewport by subtracting
an offset. A view matrix is that, plus rotate and zoom, expressed as one
invertible transform.

---

## Key Concepts

### Build the view matrix
```odin
Camera :: struct { position: [2]f32, zoom: f32, rotation: f32 }

view_matrix :: proc(c: Camera) -> matrix[3,3]f32 {
    cam_model := linalg.matrix3_translate_f32(c.position) *
                 linalg.matrix3_rotate_f32(c.rotation) *
                 linalg.matrix3_scale_f32({c.zoom, c.zoom})
    return linalg.inverse(cam_model)
}
```

### Apply to objects
```odin
clip_ish := view * model * [3]f32{corner.x, corner.y, 1}
```

---

## Line-by-Line Breakdown

Open `learn/95_solutions/graphics_programming/gp03_camera/main.odin`.

- `view_matrix`: inverse of the camera's own model.
- `frame`: arrow keys move the camera; objects are drawn through
  `view * model`. HUD is drawn WITHOUT the view (screen space).

---

## Exercises

1. Add camera zoom on a key; confirm `inverse` handles it (objects shrink).
2. Add camera rotation; the whole world tilts the opposite way.
3. Draw a HUD element and confirm it ignores the camera (no view matrix).
4. Replace `inverse(cam_model)` with manual `translate(-pos)` and prove they
   match when rotation = 0 and zoom = 1, but differ otherwise.

---

## Exit Criteria

- [ ] You can explain "view = inverse of camera transform"
- [ ] You know the MVP chain order
- [ ] You can move/zoom/rotate the camera correctly
- [ ] HUD draws in screen space; it builds and runs

---

## Next Lesson

`learn/47_graphics_programming/gp04_projection`
