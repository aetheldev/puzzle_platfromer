/*
TICKET 02 — Drawing Shapes & Colors
=====================================
GOAL: Draw rectangles and lines using sokol_gl (the immediate-mode 2D helper).

CONCEPTS:
  - sokol_gl (sgl)  : thin OpenGL-style immediate-mode layer on top of sokol_gfx.
                      You call begin_quads / v2f_c4b / end like old-school OpenGL.
  - sgl.setup()     : must be called after sg.setup()
  - sgl.ortho()     : set an orthographic (flat 2D) projection matrix.
                      Params: left, right, bottom, top, near, far
  - sgl.begin_quads(): start submitting quad vertices (4 verts = 1 quad)
  - sgl.v2f_c4b()  : emit a vertex at (x,y) with RGBA color (0-255 bytes)
  - sgl.end()       : finish the primitive batch
  - sgl.draw()      : flush everything to the GPU (call inside begin_pass/end_pass)

TASKS FOR YOU:
  [ ] Run it: `zsh build.sh`
  [ ] Add a second rectangle with a different color
  [ ] Draw a horizontal line across the screen using sgl.begin_lines()
  [ ] Make one rectangle move left and right using sapp.frame_count()

WHAT TO READ NEXT:
  - ../../sauce/sokol/gl/gl.odin  (full sgl API)
*/

package t02

import sapp  "../../../../sauce/sokol/app"
import sg    "../../../../sauce/sokol/gfx"
import sgl   "../../../../sauce/sokol/gl"
import sglue "../../../../sauce/sokol/glue"
import slog  "../../../../sauce/sokol/log"
import "base:runtime"

W :: 960
H :: 540

pass_action: sg.Pass_Action
rt_ctx: runtime.Context

init :: proc "c" () {
    context = rt_ctx

    sg.setup({
        environment = sglue.environment(),
        logger      = { func = slog.func },
    })

    // sokol_gl must be set up after sokol_gfx
    sgl.setup({
        logger = { func = slog.func },
    })

    pass_action = {
        colors = {
            0 = { load_action = .CLEAR, clear_value = { r=0.1, g=0.1, b=0.15, a=1 } },
        },
    }
}

// draw_rect draws a filled axis-aligned rectangle.
// x, y = top-left corner.  All values are in screen pixels (0,0 = top-left).
draw_rect :: proc(x, y, w, h: f32, r, g, b: u8) {
    sgl.begin_quads()
    sgl.v2f_c4b(x,     y,     r, g, b, 255)   // top-left
    sgl.v2f_c4b(x+w,   y,     r, g, b, 255)   // top-right
    sgl.v2f_c4b(x+w,   y+h,   r, g, b, 255)   // bottom-right
    sgl.v2f_c4b(x,     y+h,   r, g, b, 255)   // bottom-left
    sgl.end()
}

// draw_line draws a single line segment.
draw_line :: proc(x0, y0, x1, y1: f32, r, g, b: u8) {
    sgl.begin_lines()
    sgl.v2f_c4b(x0, y0, r, g, b, 255)
    sgl.v2f_c4b(x1, y1, r, g, b, 255)
    sgl.end()
}

frame :: proc "c" () {
    context = rt_ctx

    // Set up a 2D projection that maps pixels: (0,0) top-left, (W,H) bottom-right.
    sgl.defaults()
    sgl.matrix_mode_projection()
    sgl.ortho(0, W, H, 0, -1, 1)   // left, right, bottom, top, near, far

    // --- draw some shapes ---

    // A static red rectangle
    draw_rect(50, 50, 200, 120, 220, 60, 60)

    // A green rectangle that slides horizontally
    t := f32(sapp.frame_count()) * 0.5
    slide_x := 300 + 100 * _sin(t)
    draw_rect(slide_x, 200, 100, 100, 60, 200, 100)

    // A blue outline (4 lines forming a box)
    bx, by, bw, bh: f32 = 600, 80, 150, 80
    draw_line(bx,    by,    bx+bw, by,    80, 140, 240)
    draw_line(bx+bw, by,    bx+bw, by+bh, 80, 140, 240)
    draw_line(bx+bw, by+bh, bx,    by+bh, 80, 140, 240)
    draw_line(bx,    by+bh, bx,    by,    80, 140, 240)

    // --- render ---
    sg.begin_pass({ action = pass_action, swapchain = sglue.swapchain() })
    sgl.draw()   // flush sokol_gl draw calls
    sg.end_pass()
    sg.commit()
}

cleanup :: proc "c" () {
    context = rt_ctx
    sgl.shutdown()
    sg.shutdown()
}

@(private)
_sin :: proc(x: f32) -> f32 {
    x2 := x * x
    return x * (1 - x2/6 + x2*x2/120)
}

main :: proc() {
    rt_ctx = context
    sapp.run({
        init_cb    = init,
        frame_cb   = frame,
        cleanup_cb = cleanup,
        width      = W,
        height     = H,
        window_title = "T02 – Shapes & Colors",
        logger     = { func = slog.func },
    })
}
