/*
TICKET 07 — Tilemap & Simple Level
=====================================
GOAL: Represent a level as a 2D grid of tiles. Draw it. Collide against it.

CONCEPTS:
  - Tilemap           : a 2D array of integers.  0 = empty, 1 = solid, etc.
  - Tile size         : each tile occupies TILE x TILE pixels on screen.
  - Tile collision    : instead of storing individual Rect objects, check
                        which tile(s) the player overlaps and resolve.
  - Tile index math   : col = int(world_x / TILE),  row = int(world_y / TILE)
  - Separating axis   : resolve X and Y collisions independently to avoid
                        corner-catching bugs.

LEVEL FORMAT (read from bottom to top in the source — row 0 = top):
  '.' = empty
  '#' = solid block
  'S' = player spawn

WHY TILEMAPS:
  - Small memory: a 100×20 map is just 2000 integers.
  - Fast collision: only check the ~9 tiles around the player, not every object.
  - Easy to design: a text grid is readable.
  - Foundation for a level editor (T11, future ticket).

TASKS FOR YOU:
  [ ] Run it: WASD/arrows to move, SPACE to jump.
  [ ] Edit the LEVEL string below to build a different layout.
  [ ] Add a new tile type (2 = spike, kills the player — reset position).
  [ ] Count and print how many solid tiles are in the level.
*/

package t07

import sapp  "../../../../sauce/sokol/app"
import sg    "../../../../sauce/sokol/gfx"
import sgl   "../../../../sauce/sokol/gl"
import sglue "../../../../sauce/sokol/glue"
import slog  "../../../../sauce/sokol/log"
import "base:runtime"
import "core:strings"

W :: 960
H :: 540
TILE :: 40   // pixels per tile

LEVEL := `
##########################
#........................#
#........................#
#........##..............#
#........................#
#...........####.........#
#........................#
#....#...................#
#....#...................#
#....#.......S...........#
##########################
`

GRAVITY  :: 1800.0
JUMP_VEL :: -660.0
SPEED    :: 300.0

// ----- Tilemap -----

COLS :: 26
ROWS :: 11

tiles: [ROWS][COLS]u8   // 0=empty, 1=solid

spawn_x: f32
spawn_y: f32

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

// ----- Player -----

Player :: struct {
    x, y:     f32,
    w, h:     f32,
    vel_y:    f32,
    on_ground: bool,
}
player: Player

key_left, key_right: bool
jump_buffer: f32

// ----- Sokol -----

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

// Resolve player against solid tiles on one axis.
// axis=0 → horizontal, axis=1 → vertical
resolve_axis :: proc(axis: int) {
    // Test the 4 corners of the player
    corners := [4][2]f32{
        { player.x,            player.y            },
        { player.x + player.w, player.y            },
        { player.x,            player.y + player.h },
        { player.x + player.w, player.y + player.h },
    }
    for corner in corners {
        col := int(corner[0] / TILE)
        row := int(corner[1] / TILE)
        if !is_solid(col, row) { continue }

        tile_x := f32(col) * TILE
        tile_y := f32(row) * TILE

        if axis == 0 {
            // horizontal
            overlap_l := (player.x + player.w) - tile_x
            overlap_r := (tile_x + TILE) - player.x
            if overlap_l < overlap_r {
                player.x  -= overlap_l
            } else {
                player.x  += overlap_r
            }
        } else {
            // vertical
            overlap_t := (player.y + player.h) - tile_y
            overlap_b := (tile_y + TILE) - player.y
            if overlap_t < overlap_b {
                player.y     -= overlap_t
                player.vel_y  = 0
                player.on_ground = true
            } else {
                player.y     += overlap_b
                player.vel_y  = 0
            }
        }
    }
}

frame :: proc "c" () {
    context = rt_ctx
    dt := f32(sapp.frame_duration())

    jump_buffer -= dt

    // --- horizontal ---
    vx: f32 = 0
    if key_left  { vx = -SPEED }
    if key_right { vx =  SPEED }
    player.x += vx * dt
    resolve_axis(0)

    // --- jump ---
    if jump_buffer > 0 && player.on_ground {
        player.vel_y    = JUMP_VEL
        player.on_ground = false
        jump_buffer      = 0
    }

    // --- gravity + vertical ---
    player.on_ground = false
    player.vel_y += GRAVITY * dt
    player.y     += player.vel_y * dt
    resolve_axis(1)

    // --- draw tilemap ---
    sgl.defaults()
    sgl.matrix_mode_projection()
    sgl.ortho(0, W, H, 0, -1, 1)

    for row in 0..<ROWS {
        for col in 0..<COLS {
            if tiles[row][col] == 0 { continue }
            x := f32(col) * TILE
            y := f32(row) * TILE
            // slightly lighter color for top face illusion
            draw_rect(x,   y,   TILE, 4,        130, 180, 100)
            draw_rect(x,   y+4, TILE, TILE-4,   80,  130, 60 )
        }
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
        window_title = "T07 – Tilemap",
        logger     = { func = slog.func },
    })
}
