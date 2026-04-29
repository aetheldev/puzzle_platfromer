# T02 Shapes And Colors

## Step 1 - Concept

You need some way to put colored geometry on screen.
`sokol_gl` is a simple immediate-mode helper, good for learning quads and lines before building bigger render systems.

## Step 2 - Read This

Open:
- `learn/solutions/fundamentals/t02_shapes_colors/main.odin`

Read only:
- `draw_rect`
- `draw_line`
- `frame`

Focus on:
- `sgl.ortho(...)`
- `sgl.begin_quads()`
- `sgl.v2f_c4b(...)`
- `sgl.draw()`

## Step 3 - Question

Why do we call `sgl.ortho(0, W, H, 0, -1, 1)` before drawing?

## Step 4 - Your Turn

Close the solution.
Create your own `main.odin` here.

Task:
- draw one rectangle
- draw one line
- use different colors

## Step 5 - Stop

Write it first.
