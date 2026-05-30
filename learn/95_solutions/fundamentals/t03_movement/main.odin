/*
TICKET 03 — Player Movement & Delta Time
=========================================
GOAL: Move a rectangle with keyboard input. Learn why delta time matters.

CONCEPTS:
  - sapp.key_event / sapp.event_cb  : raw input events from sokol_app
  - delta time (dt)                 : seconds since last frame.
                                      Multiply speed by dt so movement is
                                      framerate-independent (same speed at
                                      30fps and 120fps).
  - sapp.frame_duration()           : returns dt as f64 (seconds)
  - "held key" pattern              : store a bool per key, set on KEY_DOWN,
                                      clear on KEY_UP, read every frame.

TASKS FOR YOU:
  [ ] Run it: `zsh build.sh`. Move with WASD or arrow keys.
  [ ] Change SPEED and observe the difference.
  [ ] Add diagonal movement and make sure speed stays constant
      (hint: normalise the velocity vector).
  [ ] Clamp the player so it can't leave the screen.

WHY DELTA TIME:
  Without dt: pos += speed  → at 30fps player moves at 30*speed px/s
                             → at 120fps player moves at 120*speed px/s
  With dt:    pos += speed*dt → always speed px/s regardless of fps
*/

package t03

import sapp  "../../../../sauce/sokol/app"
import sg    "../../../../sauce/sokol/gfx"
import sgl   "../../../../sauce/sokol/gl"
import sglue "../../../../sauce/sokol/glue"
import slog  "../../../../sauce/sokol/log"
import "base:runtime"
import "core:math"

W :: 960
H :: 540
SPEED :: 300.0  // pixels per second

Player :: struct {
    x, y: f32,   // top-left position
    w, h: f32,   // size
}

player: Player

// Key state: true = currently held down
key_left, key_right, key_up, key_down: bool

pass_action: sg.Pass_Action
rt_ctx: runtime.Context

init :: proc "c" () {
    context = rt_ctx
    sg.setup({ environment = sglue.environment(), logger = { func = slog.func } })
    sgl.setup({ logger = { func = slog.func } })

    pass_action = {
        colors = { 0 = { load_action = .CLEAR, clear_value = { r=0.08, g=0.08, b=0.12, a=1 } } },
    }

    player = { x = W/2 - 20, y = H/2 - 20, w = 40, h = 40 }
}

// sokol_app calls this for every input event (key, mouse, etc.)
event :: proc "c" (e: ^sapp.Event) {
    context = rt_ctx
    if e.type == .KEY_DOWN || e.type == .KEY_UP {
        held := e.type == .KEY_DOWN
        #partial switch e.key_code {
        case .A, .LEFT:  key_left  = held
        case .D, .RIGHT: key_right = held
        case .W, .UP:    key_up    = held
        case .S, .DOWN:  key_down  = held
        case: // ignore other keys
        }
    }
}

frame :: proc "c" () {
    context = rt_ctx

    // --- delta time ---
    dt := f32(sapp.frame_duration())  // seconds since last frame (~0.016 at 60fps)

    // --- input → velocity ---
    vx: f32 = 0
    vy: f32 = 0
    if key_left  { vx -= 1 }
    if key_right { vx += 1 }
    if key_up    { vy -= 1 }
    if key_down  { vy += 1 }

    // Normalise so diagonal speed == horizontal speed
    len := math.sqrt(vx*vx + vy*vy)
    if len > 0 {
        vx /= len
        vy /= len
    }

    // --- move player ---
    player.x += vx * SPEED * dt
    player.y += vy * SPEED * dt

    // --- draw ---
    sgl.defaults()
    sgl.matrix_mode_projection()
    sgl.ortho(0, W, H, 0, -1, 1)

    // ground line
    sgl.begin_lines()
    sgl.v2f_c4b(0, H-40, 100, 200, 100, 255)
    sgl.v2f_c4b(W, H-40, 100, 200, 100, 255)
    sgl.end()

    // player rect
    draw_rect(player.x, player.y, player.w, player.h, 240, 200, 80)

    sg.begin_pass({ action = pass_action, swapchain = sglue.swapchain() })
    sgl.draw()
    sg.end_pass()
    sg.commit()
}

draw_rect :: proc(x, y, w, h: f32, r, g, b: u8) {
    sgl.begin_quads()
    sgl.v2f_c4b(x,   y,   r, g, b, 255)
    sgl.v2f_c4b(x+w, y,   r, g, b, 255)
    sgl.v2f_c4b(x+w, y+h, r, g, b, 255)
    sgl.v2f_c4b(x,   y+h, r, g, b, 255)
    sgl.end()
}

cleanup :: proc "c" () {
    context = rt_ctx
    sgl.shutdown()
    sg.shutdown()
}

main :: proc() {
    rt_ctx = context
    sapp.run({
        init_cb    = init,
        frame_cb   = frame,
        event_cb   = event,
        cleanup_cb = cleanup,
        width      = W,
        height     = H,
        window_title = "T03 – Movement & Delta Time",
        logger     = { func = slog.func },
    })
}
