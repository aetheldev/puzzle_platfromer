# GP01 — Matrices [RUN]

## Goal

Stop fearing the word "matrix". A matrix is just a small grid of numbers that
transforms a point. Learn the four you actually use: identity, translate,
scale, rotate — and why multiply ORDER matters.

---

## The Concept

A point is `(x, y)`. A matrix is a recipe that turns one point into another:

```
new_point = matrix * old_point
```

That is the whole idea. Different number grids = different recipes:

- **Identity**: change nothing. The "1" of matrices. `M * p == p`.
- **Translate**: add an offset. Moves things.
- **Scale**: multiply each axis. Grows/shrinks.
- **Rotate**: spin around the origin.

In 2D we use 3×3 matrices (the extra row/column carries the translation). In
3D, 4×4. Odin's `core:math/linalg` gives you these for free.

### Why a grid instead of just `x += dx`?

Because you can **combine** transforms by multiplying matrices once, then
apply that single result to thousands of points. The GPU loves this: send one
matrix, transform every vertex with it.

### Multiply order is NOT commutative

`A * B` ≠ `B * A`. "Rotate then move" looks different from "move then rotate".

```
T * R * p   // p is rotated first, THEN translated   (read right-to-left)
R * T * p   // p is translated first, THEN rotated
```

The rightmost matrix touches the point first. Burn this in: **right-to-left**.

---

## If You Know JS/React...

CSS already does this:

```css
transform: translate(100px, 0) rotate(45deg) scale(2);
```

The browser reads these left-to-right but applies them as a stacked matrix —
exactly `translate * rotate * scale`. You have been using matrix multiplication
without knowing it. Here you build the matrix yourself.

---

## Key Concepts

### Build them with linalg
```odin
import "core:math/linalg"

I  := linalg.MATRIX3F32_IDENTITY
T  := linalg.matrix3_translate_f32({100, 50})
S  := linalg.matrix3_scale_f32({2, 2})
R  := linalg.matrix3_rotate_f32(angle_radians)   // 2D rotation
```

### Combine, then apply
```odin
M := T * R * S                      // one matrix that does all three
p := M * [3]f32{px, py, 1}          // the trailing 1 enables translation
screen := p.xy
```

---

## Line-by-Line Breakdown

Open `learn/95_solutions/graphics_programming/gp01_matrices/main.odin`.

- Read the `apply` proc: it multiplies a matrix by a point.
- Read the `frame` proc: it builds `T * R * S` and draws the same square under
  each transform so you SEE what each matrix does.

---

## Exercises

1. Swap the order to `S * R * T`. Watch the square move differently.
2. Make rotation depend on time so it spins.
3. Add a second square that uses only `T` (translate) and confirm it never
   rotates or scales.
4. Set the scale to `{1, 0.5}` — non-uniform scale. Explain what happened.

---

## Exit Criteria

- [ ] You can say what identity/translate/scale/rotate each do
- [ ] You can predict the difference between `T*R*S` and `S*R*T`
- [ ] You know why the trailing `1` exists in the point
- [ ] It builds and runs with `zsh build.sh`

---

## Next Lesson

`learn/47_graphics_programming/gp02_transform`
