/*
TICKET 08 — Camera Follow
===========================
GOAL: Implement a smooth-following camera so the level can be larger than
      the screen.

CONCEPTS:
  - World space vs screen space
      World space : coordinates in the game world (can be any size).
      Screen space: 0,0 top-left, W×H bottom-right — what you see.
  - Camera offset : translate every draw call by (-cam_x, -cam_y).
                    cam_x/cam_y = world position of the top-left of the screen.
  - Lerp (linear interpolation):
        cam_x = lerp(cam_x, target_x, LERP_SPEED * dt)
        Moves cam_x toward target_x at a rate that is faster when far away,
        slower when close → smooth "elastic" follow.
  - Camera bounds : clamp the camera so it doesn't show outside the level.

  - sgl.translate() : offsets all subsequent vertices by (x, y, z).
                      Use (-cam_x, -cam_y, 0) to scroll the world.
  - sgl.push_matrix / pop_matrix : save / restore the matrix stack,
                                   so UI drawn after pop_matrix is unaffected.

LEVEL SIZE:
  This ticket uses a wider tilemap (40 cols × 11 rows = 1600×440 px).
  The screen is 960 wide — the camera scrolls to follow the player.

TASKS FOR YOU:
  [ ] Run it. Walk right — the camera follows.
  [ ] Change LERP_SPEED to 2.0 and notice how sluggish it feels.
  [ ] Change LERP_SPEED to 30.0 and notice how snappy it feels.
  [ ] Add vertical camera follow (the level is already taller than the screen
      if you add more rows).
  [ ] Draw a HUD rectangle in screen space (after pop_matrix) that doesn't move.
*/

package t08

import sapp  "../../../../sauce/sokol/app"
import sg    "../../../../sauce/sokol/gfx"
import sgl   "../../../../sauce/sokol/gl"
import sglue "../../../../sauce/sokol/glue"
import slog  "../../../../sauce/sokol/log"
import "base:runtime"
import "core:strings"
import "core:math"

W :: 960
H :: 540
TILE :: 40

GRAVITY  :: 1800.0
JUMP_VEL :: -660.0
SPEED    :: 300.0

LERP_SPEED :: 8.0   // camera follow speed (higher = snappier)

// --- Wide level (40 cols) ---
LEVEL := `
########################################
#......................................#
#......................................#
#...####.......####................#...#
#......................................#
#..........####..........####..........#
#......................................#
#...#..................................#
#...#..................................#
#...#.............S....................#
########################################
`

COLS :: 40
ROWS :: 11

WORLD_W :: f32(COLS * TILE)
WORLD_H :: f32(ROWS * TILE)

tiles: [ROWS][COLS]u8
spawn_x, spawn_y: f32

load_level :: proc() {
    row := 0
    for line in strings.split_lines_iterator(&LEVEL) {
        if len(line) == 0 { continue }
        for ch, col in line {
            if col >= COLS || row >= ROWS { continue }
            switch ch {
            case '#': tiles[row][col] = 1
            case 'S':
                spawn_x = f32(col) * TILE
                spawn_y = f32(row) * TILE
            }
        }
        row += 1
    }
}

is_solid :: proc(col, row: int) -> bool {
    if col < 0 || col >= COLS || row < 0 || row >= ROWS { return true }
    return tiles[row][col] == 1
}

Player :: struct { x, y, w, h, vel_y: f32, on_ground: bool }
player: Player

Camera :: struct { x, y: f32 }
cam: Camera

key_left, key_right: bool
jump_buffer: f32

pass_action: sg.Pass_Action
rt_ctx: runtime.Context

init :: proc "c" () {
    context = rt_ctx
    sg.setup({ environment = sglue.environment(), logger = { func = slog.func } })
    sgl.setup({ logger = { func = slog.func } })
    pass_action = {
        colors = { 0 = { load_action = .CLEAR, clear_value = { r=0.05, g=0.06, b=0.10, a=1 } } },
    }
    load_level()
    player = { x = spawn_x, y = spawn_y, w = 24, h = 36 }
    // start camera centered on player
    cam.x = player.x - W/2
    cam.y = player.y - H/2
}

event :: proc "c" (e: ^sapp.Event) {
    context = rt_ctx
    #partial switch e.type {
    case .KEY_DOWN:
        #partial switch e.key_code {
        case .A, .LEFT:  key_left  = true
        case .D, .RIGHT: key_right = true
        case .SPACE, .W, .UP: jump_buffer = 0.14
        }
    case .KEY_UP:
        #partial switch e.key_code {
        case .A, .LEFT:  key_left  = false
        case .D, .RIGHT: key_right = false
        case .SPACE, .W, .UP:
            if player.vel_y < 0 { player.vel_y *= 0.5 }
        }
    }
}

lerp :: proc(a, b, t: f32) -> f32 { return a + (b - a) * t }
clamp :: proc(v, lo, hi: f32) -> f32 { return min(max(v, lo), hi) }

resolve_axis :: proc(axis: int) {
    corners := [4][2]f32{
        {player.x, player.y}, {player.x+player.w, player.y},
        {player.x, player.y+player.h}, {player.x+player.w, player.y+player.h},
    }
    for corner in corners {
        col := int(corner[0] / TILE)
        row := int(corner[1] / TILE)
        if !is_solid(col, row) { continue }
        tx := f32(col) * TILE
        ty := f32(row) * TILE
        if axis == 0 {
            ol := (player.x + player.w) - tx
            or_ := (tx + TILE) - player.x
            if ol < or_ { player.x -= ol } else { player.x += or_ }
        } else {
            ot := (player.y + player.h) - ty
            ob := (ty + TILE) - player.y
            if ot < ob {
                player.y -= ot; player.vel_y = 0; player.on_ground = true
            } else {
                player.y += ob; player.vel_y = 0
            }
        }
    }
}

frame :: proc "c" () {
    context = rt_ctx
    dt := f32(sapp.frame_duration())

    jump_buffer -= dt

    vx: f32 = 0
    if key_left  { vx = -SPEED }
    if key_right { vx =  SPEED }
    player.x += vx * dt
    resolve_axis(0)

    if jump_buffer > 0 && player.on_ground {
        player.vel_y = JUMP_VEL; player.on_ground = false; jump_buffer = 0
    }

    player.on_ground = false
    player.vel_y += GRAVITY * dt
    player.y     += player.vel_y * dt
    resolve_axis(1)

    // --- camera lerp toward player center ---
    target_x := player.x + player.w/2 - W/2
    target_y := player.y + player.h/2 - H/2
    cam.x = lerp(cam.x, target_x, LERP_SPEED * dt)
    cam.y = lerp(cam.y, target_y, LERP_SPEED * dt)

    // clamp so we don't show outside the world
    cam.x = clamp(cam.x, 0, WORLD_W - W)
    cam.y = clamp(cam.y, 0, WORLD_H - H)

    // --- draw ---
    sgl.defaults()
    sgl.matrix_mode_projection()
    sgl.ortho(0, W, H, 0, -1, 1)

    // Push a translation matrix for the camera offset
    sgl.matrix_mode_modelview()
    sgl.push_matrix()
    sgl.translate(-cam.x, -cam.y, 0)

    // Tilemap (in world space)
    for row in 0..<ROWS {
        for col in 0..<COLS {
            if tiles[row][col] == 0 { continue }
            x := f32(col) * TILE
            y := f32(row) * TILE
            draw_rect(x, y,   TILE, 4,      130, 180, 100)
            draw_rect(x, y+4, TILE, TILE-4,  80, 130, 60 )
        }
    }

    // Player (world space)
    draw_rect(player.x, player.y, player.w, player.h, 240, 200, 80)

    sgl.pop_matrix()  // back to screen space

    // HUD: a small indicator showing camera x position (screen space — doesn't scroll)
    progress := cam.x / (WORLD_W - W)
    draw_rect(10, H - 18, (W-20) * progress, 8, 80, 160, 240)
    draw_rect(10, H - 18, W - 20, 8, 60, 60, 80)   // background bar
    draw_rect(10, H - 18, (W-20) * progress, 8, 80, 160, 240)  // filled bar

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
        window_title = "T08 – Camera Follow",
        logger     = { func = slog.func },
    })
}
