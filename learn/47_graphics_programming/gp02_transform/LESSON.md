# GP02 — Transform (Model Matrix) [RUN]

## Goal

Bundle position + rotation + scale into one "transform" and turn it into a
single **model matrix**. This is how every game object positions itself in the
world. Understand local space vs world space.

---

## The Concept

Every object stores a small struct:

```odin
Transform :: struct {
    position: [2]f32,
    rotation: f32,     // radians
    scale:    [2]f32,
}
```

Each frame you turn that into one matrix — the **model matrix** — that maps the
object's **local space** (its own little coordinate system, origin at its
pivot) into **world space** (the shared level coordinates):

```
model = translate(position) * rotate(rotation) * scale(scale)
```

Order matters (gp01): scale first, then rotate, then translate. So an object
scales/rotates around its OWN origin, then gets placed in the world. Get the
order wrong and it orbits the world origin instead of spinning in place.

### Local vs world space

- **Local space**: a 1×1 square centered on `(0,0)`. Always the same.
- **World space**: where that square ends up after the model matrix.

This separation is gold: you author art once in local space, then place many
copies with different transforms.

---

## If You Know JS/React...

A DOM node with `transform-origin: center` + `transform:` is exactly a model
matrix with a pivot. A "component instance" reused with different props is the
same square drawn with different transforms.

---

## Key Concepts

### Build the model matrix
```odin
model_matrix :: proc(t: Transform) -> matrix[3,3]f32 {
    T := linalg.matrix3_translate_f32(t.position)
    R := linalg.matrix3_rotate_f32(t.rotation)
    S := linalg.matrix3_scale_f32(t.scale)
    return T * R * S
}
```

### Transform the 4 local corners
```odin
local := [4][2]f32{{-0.5,-0.5},{0.5,-0.5},{0.5,0.5},{-0.5,0.5}}
for c in local {
    p := M * [3]f32{c.x, c.y, 1}    // local -> world
    draw_point(p.xy)
}
```

---

## Line-by-Line Breakdown

Open `learn/95_solutions/graphics_programming/gp02_transform/main.odin`.

- `model_matrix`: T*R*S in one place.
- `frame`: several objects, each a `Transform`, all drawn by the SAME draw code
  through their own model matrix. That reuse is the whole point.

---

## Exercises

1. Animate `rotation` and `scale` over time; watch each spin in place.
2. Move the local square so it is NOT centered (`0..1` instead of `-0.5..0.5`).
   It now rotates around a corner. Explain why.
3. Add a child object whose matrix is `parent_model * child_model` (parenting).
4. Make one object's scale negative on X — it mirrors. Why?

---

## Exit Criteria

- [ ] You can build a model matrix from a Transform struct
- [ ] You can explain local vs world space
- [ ] You understand why pivot location changes rotation behavior
- [ ] It builds and runs

---

## Next Lesson

`learn/47_graphics_programming/gp03_camera`
