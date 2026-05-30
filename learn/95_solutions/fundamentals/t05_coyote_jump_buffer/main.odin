/*
TICKET 05 — Coyote Time & Jump Buffer
=======================================
GOAL: Make jumping feel great with two classic game-feel tricks.

CONCEPTS:

  COYOTE TIME
    Problem: if you walk off a ledge and press jump 1 frame later it feels
             like the game "missed" your input because you were already airborne.
    Fix: keep a timer.  When the player leaves the ground start counting down.
         If jump is pressed while coyote_timer > 0 → allow the jump.
    Typical value: 0.10 – 0.15 seconds.

  JUMP BUFFER
    Problem: if you press jump just before you hit the ground the game
             ignores it because you weren't on_ground yet.
    Fix: store the time jump was pressed.  When the player lands, check if
         jump_buffer_timer > 0 → perform the jump immediately on landing.
    Typical value: 0.10 – 0.15 seconds.

  VARIABLE JUMP HEIGHT
    Problem: tapping vs holding space gives the same jump height.
    Fix: when space is released early, cut vel_y in half (or clamp it).
         This makes short taps give small jumps, holds give big jumps.

TASKS FOR YOU:
  [ ] Run it. Walk off the edge and press SPACE slightly late — still jumps!
  [ ] Press SPACE just before landing — lands and jumps immediately!
  [ ] Change COYOTE_TIME to 0 and feel the difference.
  [ ] Change JUMP_BUFFER_TIME to 0 and feel the difference.
  [ ] Tap vs hold SPACE — notice the jump height difference.

PLATFORM LAYOUT:
  - Ground at bottom
  - Two floating platforms to jump between
*/

package t05

import sapp  "../../../../sauce/sokol/app"
import sg    "../../../../sauce/sokol/gfx"
import sgl   "../../../../sauce/sokol/gl"
import sglue "../../../../sauce/sokol/glue"
import slog  "../../../../sauce/sokol/log"
import "base:runtime"

W :: 960
H :: 540

GRAVITY           :: 1800.0
JUMP_VEL          :: -640.0
SPEED             :: 300.0
COYOTE_TIME       :: 0.12   // seconds
JUMP_BUFFER_TIME  :: 0.12   // seconds

Rect :: struct { x, y, w, h: f32 }

Player :: struct {
    using pos: Rect,
    vel_y:            f32,
    on_ground:        bool,
    coyote_timer:     f32,   // counts DOWN from COYOTE_TIME
    jump_buffer_timer: f32,  // counts DOWN from JUMP_BUFFER_TIME
}

// Platforms (including the floor treated as a very wide platform)
platforms := [3]Rect{
    { x =   0, y = H - 50,  w = W,   h = 50  },   // floor
    { x = 150, y = H - 180, w = 220, h = 20  },   // left platform
    { x = 560, y = H - 280, w = 220, h = 20  },   // right platform
}

player: Player
key_left, key_right: bool
space_held: bool   // used for variable jump height

pass_action: sg.Pass_Action
rt_ctx: runtime.Context

init :: proc "c" () {
    context = rt_ctx
    sg.setup({ environment = sglue.environment(), logger = { func = slog.func } })
    sgl.setup({ logger = { func = slog.func } })
    pass_action = {
        colors = { 0 = { load_action = .CLEAR, clear_value = { r=0.06, g=0.07, b=0.13, a=1 } } },
    }
    player = { x = 60, y = H - 50 - 48, w = 32, h = 48 }
}

event :: proc "c" (e: ^sapp.Event) {
    context = rt_ctx
    #partial switch e.type {
    case .KEY_DOWN:
        #partial switch e.key_code {
        case .A, .LEFT:  key_left  = true
        case .D, .RIGHT: key_right = true
        case .SPACE, .W, .UP:
            space_held = true
            // Buffer the jump press regardless of ground state
            player.jump_buffer_timer = JUMP_BUFFER_TIME
        }
    case .KEY_UP:
        #partial switch e.key_code {
        case .A, .LEFT:  key_left  = false
        case .D, .RIGHT: key_right = false
        case .SPACE, .W, .UP:
            space_held = false
            // Variable jump height: cut upward velocity early if key released
            if player.vel_y < 0 {
                player.vel_y *= 0.45
            }
        }
    }
}

// AABB overlap test — returns true if two rects overlap
overlaps :: proc(a, b: Rect) -> bool {
    return a.x < b.x+b.w && a.x+a.w > b.x &&
           a.y < b.y+b.h && a.y+a.h > b.y
}

frame :: proc "c" () {
    context = rt_ctx
    dt := f32(sapp.frame_duration())

    // --- horizontal ---
    vx: f32 = 0
    if key_left  { vx = -SPEED }
    if key_right { vx =  SPEED }
    player.x += vx * dt
    if player.x < 0           { player.x = 0 }
    if player.x + player.w > W { player.x = W - player.w }

    // --- tick timers ---
    player.coyote_timer      -= dt
    player.jump_buffer_timer -= dt

    // --- jump logic ---
    can_jump := player.on_ground || player.coyote_timer > 0
    if player.jump_buffer_timer > 0 && can_jump {
        player.vel_y             = JUMP_VEL
        player.on_ground         = false
        player.coyote_timer      = 0
        player.jump_buffer_timer = 0
    }

    // --- gravity ---
    player.vel_y += GRAVITY * dt
    player.y     += player.vel_y * dt

    // --- platform collisions ---
    was_on_ground := player.on_ground
    player.on_ground = false

    for plat in platforms {
        // Only resolve when falling onto the top of a platform
        player_bottom := player.y + player.h
        plat_top      := plat.y
        if player.vel_y >= 0 &&
           player_bottom >= plat_top &&
           player_bottom - player.vel_y * dt <= plat_top &&
           player.x + player.w > plat.x &&
           player.x < plat.x + plat.w
        {
            player.y         = plat_top - player.h
            player.vel_y     = 0
            player.on_ground = true
        }
    }

    // Start coyote timer the moment we leave the ground
    if was_on_ground && !player.on_ground {
        player.coyote_timer = COYOTE_TIME
    }

    // --- draw ---
    sgl.defaults()
    sgl.matrix_mode_projection()
    sgl.ortho(0, W, H, 0, -1, 1)

    // platforms
    for plat in platforms {
        draw_rect(plat.x, plat.y, plat.w, plat.h, 80, 140, 80)
    }

    // coyote time visualiser: yellow bar above player shrinks as timer runs out
    if player.coyote_timer > 0 {
        bar_w := player.w * (player.coyote_timer / COYOTE_TIME)
        draw_rect(player.x, player.y - 8, bar_w, 4, 255, 220, 60)
    }
    // jump buffer visualiser: cyan bar below player
    if player.jump_buffer_timer > 0 {
        bar_w := player.w * (player.jump_buffer_timer / JUMP_BUFFER_TIME)
        draw_rect(player.x, player.y + player.h + 4, bar_w, 4, 60, 220, 255)
    }

    // player
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
        window_title = "T05 – Coyote Time & Jump Buffer",
        logger     = { func = slog.func },
    })
}
