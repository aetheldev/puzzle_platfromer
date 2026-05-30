/*
TICKET 04 — Gravity & Jumping
===============================
GOAL: Add gravity and a basic jump. Understand velocity accumulation.

CONCEPTS:
  - velocity (vel_y)  : speed in the Y direction in pixels/second.
                        Positive = moving down (screen Y grows downward).
  - gravity           : a constant we ADD to vel_y every frame scaled by dt.
                        Over time the player accelerates downward.
  - jump              : set vel_y to a large negative value instantly —
                        the player shoots up, gravity pulls them back down.
  - on_ground         : only allow jumping when the player is standing on
                        something (prevents infinite air jumps).
  - AABB collision    : Axis-Aligned Bounding Box. For a flat floor we just
                        check: if player bottom >= floor_y → land.

TASKS FOR YOU:
  [ ] Run it: SPACE to jump.
  [ ] Tune GRAVITY and JUMP_VEL until the jump feels good.
  [ ] Add a second platform at a different height.
  [ ] Try holding jump vs tapping — they feel the same. How would you fix that?
      (Hint: in T05 we'll add variable jump height.)

PHYSICS LOOP (runs every frame):
  1. vel_y += GRAVITY * dt         ← accumulate gravity
  2. player.y += vel_y * dt        ← integrate position
  3. if player.bottom >= floor_y   ← resolve collision (land)
       player.y = floor_y - player.h
       vel_y = 0
       on_ground = true
*/

package t04

import sapp  "../../../../sauce/sokol/app"
import sg    "../../../../sauce/sokol/gfx"
import sgl   "../../../../sauce/sokol/gl"
import sglue "../../../../sauce/sokol/glue"
import slog  "../../../../sauce/sokol/log"
import "base:runtime"
import "core:math"

W       :: 960
H       :: 540
GRAVITY  :: 1800.0   // pixels / second²  (tweak me!)
JUMP_VEL :: -620.0   // pixels / second, negative = upward
SPEED    :: 280.0    // horizontal speed

FLOOR_Y :: f32(H - 60)   // y position of the ground surface

Player :: struct {
    x, y:     f32,
    w, h:     f32,
    vel_y:    f32,
    on_ground: bool,
}

player: Player

key_left, key_right: bool
jump_pressed: bool   // single-frame signal from event callback

pass_action: sg.Pass_Action
rt_ctx: runtime.Context

init :: proc "c" () {
    context = rt_ctx
    sg.setup({ environment = sglue.environment(), logger = { func = slog.func } })
    sgl.setup({ logger = { func = slog.func } })
    pass_action = {
        colors = { 0 = { load_action = .CLEAR, clear_value = { r=0.07, g=0.07, b=0.12, a=1 } } },
    }
    player = { x = 100, y = FLOOR_Y - 48, w = 32, h = 48, vel_y = 0, on_ground = false }
}

event :: proc "c" (e: ^sapp.Event) {
    context = rt_ctx
    if e.type == .KEY_DOWN || e.type == .KEY_UP {
        held := e.type == .KEY_DOWN
        #partial switch e.key_code {
        case .A, .LEFT:  key_left  = held
        case .D, .RIGHT: key_right = held
        case .SPACE, .W, .UP:
            if e.type == .KEY_DOWN {
                jump_pressed = true   // one-shot flag, cleared after use
            }
        }
    }
}

frame :: proc "c" () {
    context = rt_ctx

    dt := f32(sapp.frame_duration())

    // --- horizontal movement ---
    vx: f32 = 0
    if key_left  { vx = -SPEED }
    if key_right { vx =  SPEED }
    player.x += vx * dt

    // --- jump ---
    if jump_pressed && player.on_ground {
        player.vel_y  = JUMP_VEL
        player.on_ground = false
    }
    jump_pressed = false   // consume the flag every frame

    // --- gravity ---
    player.vel_y += GRAVITY * dt

    // --- integrate Y ---
    player.y += player.vel_y * dt

    // --- floor collision ---
    player.on_ground = false
    if player.y + player.h >= FLOOR_Y {
        player.y      = FLOOR_Y - player.h
        player.vel_y  = 0
        player.on_ground = true
    }

    // --- clamp to screen edges (left/right only) ---
    if player.x < 0             { player.x = 0 }
    if player.x + player.w > W  { player.x = W - player.w }

    // --- draw ---
    sgl.defaults()
    sgl.matrix_mode_projection()
    sgl.ortho(0, W, H, 0, -1, 1)

    // floor
    draw_rect(0, FLOOR_Y, W, H - FLOOR_Y, 80, 140, 80)

    // player (green when on ground, yellow when airborne)
    if player.on_ground {
        draw_rect(player.x, player.y, player.w, player.h, 240, 210, 60)
    } else {
        draw_rect(player.x, player.y, player.w, player.h, 200, 160, 60)
    }

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
        window_title = "T04 – Gravity & Jump",
        logger     = { func = slog.func },
    })
}
