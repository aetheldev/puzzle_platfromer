/*
TICKET 06 — Wall Jump & Wall Slide
=====================================
GOAL: Implement wall detection, wall sliding, and wall jumping.

CONCEPTS:

  WALL SLIDE
    When the player is airborne AND pressing into a wall, cap the downward
    velocity to a small value (WALL_SLIDE_VEL).  This makes them "stick" and
    slide slowly instead of falling fast.

  WALL JUMP
    When touching a wall and the player presses jump, launch them away from
    the wall at an angle:
      vel_x = -wall_dir * WALL_JUMP_X    ← push away horizontally
      vel_y = WALL_JUMP_Y                ← push up

  WALL DETECTION
    A simple way: check if the player rect + 1px right overlaps any wall,
    and +1px left overlaps any wall.  Store wall_dir: +1 = touching right
    wall, -1 = touching left wall, 0 = no wall.

  WALL JUMP TIMER
    After a wall jump we briefly lock horizontal input (WALL_JUMP_LOCK seconds)
    so the player doesn't immediately stick back to the wall.

TASKS FOR YOU:
  [ ] Run it. Use A/D + SPACE to wall-jump between the two tall walls.
  [ ] Tune WALL_JUMP_X / WALL_JUMP_Y for different jump arcs.
  [ ] Remove WALL_JUMP_LOCK and notice how it feels without it.
  [ ] Add a wall-slide particle (a small rect falling from the player feet).
*/

package t06

import sapp  "../../../../sauce/sokol/app"
import sg    "../../../../sauce/sokol/gfx"
import sgl   "../../../../sauce/sokol/gl"
import sglue "../../../../sauce/sokol/glue"
import slog  "../../../../sauce/sokol/log"
import "base:runtime"

W :: 960
H :: 540

GRAVITY          :: 1800.0
JUMP_VEL         :: -650.0
SPEED            :: 320.0
WALL_SLIDE_VEL   :: 60.0     // max fall speed while sliding
WALL_JUMP_X      :: 380.0    // horizontal kick away from wall
WALL_JUMP_Y      :: -580.0   // vertical kick (negative = up)
WALL_JUMP_LOCK   :: 0.18     // seconds of horizontal input lock after wall jump

Rect :: struct { x, y, w, h: f32 }

Player :: struct {
    using pos:       Rect,
    vel_x:           f32,
    vel_y:           f32,
    on_ground:       bool,
    wall_dir:        f32,   // -1 = left wall, +1 = right wall, 0 = none
    wall_jump_timer: f32,   // > 0 = lock horizontal input
}

// Walls and platforms
// Two tall walls on the sides, a floor, and a small center platform
walls := [4]Rect{
    { x = 0,         y = 0,       w = 60,  h = H     },  // left wall
    { x = W - 60,    y = 0,       w = 60,  h = H     },  // right wall
    { x = 0,         y = H - 40,  w = W,   h = 40    },  // floor
    { x = W/2 - 60,  y = H - 200, w = 120, h = 20    },  // center platform
}

player: Player
key_left, key_right: bool
jump_buffer: f32

pass_action: sg.Pass_Action
rt_ctx: runtime.Context

init :: proc "c" () {
    context = rt_ctx
    sg.setup({ environment = sglue.environment(), logger = { func = slog.func } })
    sgl.setup({ logger = { func = slog.func } })
    pass_action = {
        colors = { 0 = { load_action = .CLEAR, clear_value = { r=0.06, g=0.06, b=0.12, a=1 } } },
    }
    player = { x = W/2 - 16, y = H - 40 - 48, w = 32, h = 48 }
}

event :: proc "c" (e: ^sapp.Event) {
    context = rt_ctx
    #partial switch e.type {
    case .KEY_DOWN:
        #partial switch e.key_code {
        case .A, .LEFT:  key_left  = true
        case .D, .RIGHT: key_right = true
        case .SPACE, .W, .UP:
            jump_buffer = 0.14
        }
    case .KEY_UP:
        #partial switch e.key_code {
        case .A, .LEFT:  key_left  = false
        case .D, .RIGHT: key_right = false
        case .SPACE, .W, .UP:
            // variable jump height
            if player.vel_y < 0 { player.vel_y *= 0.5 }
        }
    }
}

// Returns true if rect a overlaps rect b
overlaps :: proc(a, b: Rect) -> bool {
    return a.x < b.x+b.w && a.x+a.w > b.x &&
           a.y < b.y+b.h && a.y+a.h > b.y
}

frame :: proc "c" () {
    context = rt_ctx
    dt := f32(sapp.frame_duration())

    jump_buffer      -= dt
    player.wall_jump_timer -= dt

    // --- horizontal input (locked after wall jump) ---
    vx: f32 = 0
    if player.wall_jump_timer <= 0 {
        if key_left  { vx = -SPEED }
        if key_right { vx =  SPEED }
    }

    // --- wall detection (probe 2px to each side) ---
    probe_l := Rect{ player.x - 2, player.y + 4, 2, player.h - 8 }
    probe_r := Rect{ player.x + player.w, player.y + 4, 2, player.h - 8 }
    touching_left  := false
    touching_right := false
    for w in walls {
        if overlaps(probe_l, w) { touching_left  = true }
        if overlaps(probe_r, w) { touching_right = true }
    }
    player.wall_dir = 0
    if touching_left  && !player.on_ground { player.wall_dir = -1 }
    if touching_right && !player.on_ground { player.wall_dir =  1 }

    // --- wall slide: cap downward velocity ---
    if player.wall_dir != 0 && player.vel_y > WALL_SLIDE_VEL {
        player.vel_y = WALL_SLIDE_VEL
    }

    // --- jump ---
    on_wall := player.wall_dir != 0
    if jump_buffer > 0 {
        if player.on_ground {
            // normal jump
            player.vel_y    = JUMP_VEL
            player.on_ground = false
            jump_buffer      = 0
        } else if on_wall {
            // wall jump
            player.vel_x         = -player.wall_dir * WALL_JUMP_X
            player.vel_y         = WALL_JUMP_Y
            player.wall_jump_timer = WALL_JUMP_LOCK
            player.wall_dir      = 0
            jump_buffer          = 0
        }
    }

    // Apply wall-jump horizontal velocity (decays back to input velocity)
    if player.wall_jump_timer > 0 {
        vx = player.vel_x
    }

    // --- gravity ---
    player.vel_y += GRAVITY * dt

    // --- integrate ---
    player.x += vx * dt
    player.y += player.vel_y * dt

    // --- collisions ---
    player.on_ground = false

    for rect in walls {
        if !overlaps(player.pos, rect) { continue }

        // resolve on whichever axis has the smallest overlap
        ox := min(player.x+player.w, rect.x+rect.w) - max(player.x, rect.x)
        oy := min(player.y+player.h, rect.y+rect.h) - max(player.y, rect.y)

        if ox < oy {
            // horizontal collision
            if player.x < rect.x {
                player.x -= ox
            } else {
                player.x += ox
            }
            player.vel_x = 0
        } else {
            // vertical collision
            if player.y < rect.y {
                player.y         -= oy
                player.vel_y      = 0
                player.on_ground  = true
            } else {
                player.y     += oy
                player.vel_y  = 0
            }
        }
    }

    // --- draw ---
    sgl.defaults()
    sgl.matrix_mode_projection()
    sgl.ortho(0, W, H, 0, -1, 1)

    for rect in walls {
        draw_rect(rect.x, rect.y, rect.w, rect.h, 70, 130, 70)
    }

    // wall-slide indicator: cyan strip on the side the player is touching
    if player.wall_dir == -1 {
        draw_rect(player.x - 4, player.y, 4, player.h, 80, 220, 255)
    } else if player.wall_dir == 1 {
        draw_rect(player.x + player.w, player.y, 4, player.h, 80, 220, 255)
    }

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
        window_title = "T06 – Wall Jump & Wall Slide",
        logger     = { func = slog.func },
    })
}
