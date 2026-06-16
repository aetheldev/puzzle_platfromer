/*
PRACTICE GAME 16 — Level Devil (NOT a Troll Game)
==================================================
A platformer where the level LIED to you:
  fake walls, crumble floors, trigger spikes, moving platforms.
  Reach the exit. Die. Learn the trick. Try again.

CONTROLS:
  A/D or LEFT/RIGHT — move
  SPACE / W / UP — jump
  R — restart

TILES:
  #  wall     .  air       S  spawn      E  exit
  F  fake wall (looks solid, walk through)
  C  crumble (collapses underfoot, respawns)
  ^  spike (instant death)
  T  trigger (step here → spikes drop from ceiling)
  =  moving platform (oscillates left-right)
*/

package p16_level_devil

import sapp  "../../../../sauce/sokol/app"
import sg    "../../../../sauce/sokol/gfx"
import sgl   "../../../../sauce/sokol/gl"
import sglue "../../../../sauce/sokol/glue"
import slog  "../../../../sauce/sokol/log"
import "base:runtime"
import "core:math"
import "core:strings"

W :: 960
H :: 540
TILE :: 40

GRAVITY  :: 1800.0
JUMP_VEL :: -660.0
SPEED    :: 300.0
LERP_SPEED :: 8.0
COLS :: 80
ROWS :: 14

CRUMBLE_STAND_TIME :: 0.4
CRUMBLE_RESPAWN_TIME :: 3.0
TRIGGER_ACTIVE_TIME :: 2.5
PLATFORM_SPEED :: 1.4
PLATFORM_RANGE :: 120.0

WALL  :: '#'
FAKE  :: 'F'
CRUMB :: 'C'
SPIKE :: '^'
TRIG  :: 'T'
EXIT  :: 'E'
MOVE  :: '='

WORLD_W :: f32(COLS * TILE)
WORLD_H :: f32(ROWS * TILE)

LEVEL :=
`################################################################################
#.S............................................................................#
#..............................................................................#
#..............................................................................#
#..............................................................................#
#..............................................................................#
#..............................................................................#
#..............................................................................#
#..............................................................................#
#.....................................................................FF.......#
#.........................................................====........FFE......#
#################CCCCCCCC#########TTT######TTT##########...........#############
#################^^^^^^^^################################^^^^^^^^^^#############
################################################################################`

tiles: [ROWS][COLS]u8
spawn_x, spawn_y: f32
exit_x, exit_y: f32

crumble_state: [ROWS][COLS]f32
trigger_state: [ROWS][COLS]f32

PlatformInfo :: struct {
    col, row, width: int,
    x, prev_x, y, offset: f32,
}
platforms: [10]PlatformInfo
platform_count: int

Player :: struct { x, y, w, h, vel_y: f32, on_ground: bool }
player: Player
Camera :: struct { x, y: f32 }
cam: Camera

key_left, key_right, key_r: bool
jump_buffer: f32
dead: bool
won: bool
death_timer: f32
pass_action: sg.Pass_Action
rt_ctx: runtime.Context

load_level :: proc() {
    row := 0
    for line in strings.split_lines_iterator(&LEVEL) {
        if len(line) == 0 { continue }
        for ch, col in line {
            if col >= COLS || row >= ROWS { continue }
            switch ch {
            case WALL, FAKE, CRUMB, SPIKE, TRIG:
                tiles[row][col] = u8(ch)
            case MOVE:
                tiles[row][col] = 0
                if platform_count < len(platforms) && (col == 0 || line[col-1] != u8(MOVE)) {
                    width := 1
                    for col+width < len(line) && line[col+width] == u8(MOVE) {
                        width += 1
                    }
                    px := f32(col) * TILE
                    py := f32(row) * TILE
                    platforms[platform_count] = { col, row, width, px, px, py, f32(platform_count) * 1.7 }
                    platform_count += 1
                }
            case 'S':
                spawn_x = f32(col) * TILE
                spawn_y = f32(row) * TILE
                tiles[row][col] = 0
            case 'E':
                exit_x = f32(col) * TILE
                exit_y = f32(row) * TILE
                tiles[row][col] = u8(EXIT)
            }
        }
        row += 1
    }
}

is_solid :: proc(col, row: int) -> bool {
    if col < 0 || col >= COLS || row < 0 || row >= ROWS { return true }
    ch := tiles[row][col]
    if ch == FAKE { return false }
    if ch == CRUMB && crumble_state[row][col] < 0 { return false }
    if ch == MOVE { return false }
    return ch == WALL || ch == CRUMB || ch == TRIG
}

is_spike :: proc(col, row: int) -> bool {
    if col < 0 || col >= COLS || row < 0 || row >= ROWS { return false }
    if tiles[row][col] == SPIKE { return true }
    if trigger_state[row][col] > 0 { return true }
    return false
}

is_trigger :: proc(col, row: int) -> bool {
    if col < 0 || col >= COLS || row < 0 || row >= ROWS { return false }
    return tiles[row][col] == TRIG
}

check_player_spike :: proc() {
    if dead || won { return }
    corners := [4][2]f32{
        {player.x, player.y}, {player.x+player.w, player.y},
        {player.x, player.y+player.h}, {player.x+player.w, player.y+player.h},
    }
    for c in corners {
        col := int(c[0] / TILE)
        row := int(c[1] / TILE)
        if is_spike(col, row) {
            dead = true
            death_timer = 1.0
            return
        }
    }
}

check_player_trigger :: proc() {
    if dead || won { return }
    col := int((player.x + player.w/2) / TILE)
    row := int((player.y + player.h) / TILE)
    if is_trigger(col, row) && player.on_ground {
        c0 := max(col-1, 0)
        c1 := min(col+1, COLS-1)
        r1 := min(row-1, ROWS-1)
        if r1 <= 1 { return }
        for c := c0; c <= c1; c += 1 {
            for r := 1; r < r1; r += 1 {
                trigger_state[r][c] = TRIGGER_ACTIVE_TIME
            }
        }
    }
}

check_player_exit :: proc() {
    if dead || won { return }
    col := int((player.x + player.w/2) / TILE)
    row := int((player.y + player.h/2) / TILE)
    if col < 0 || col >= COLS || row < 0 || row >= ROWS { return }
    if tiles[row][col] == EXIT {
        won = true
    } else if row+1 < ROWS && tiles[row+1][col] == EXIT {
        won = true
    }
}

is_moving_platform :: proc(col, row: int) -> (bool, int) {
    for i in 0..<platform_count {
        p := platforms[i]
        if row == p.row && col >= p.col && col < p.col + p.width {
            return true, i
        }
    }
    return false, -1
}

get_moving_platform_y :: proc(idx: int) -> f32 {
    return platforms[idx].y
}

update_moving_platforms :: proc(dt: f32) {
    for i in 0..<platform_count {
        p := &platforms[i]
        p.prev_x = p.x
        p.offset += PLATFORM_SPEED * dt
        p.x = f32(p.col) * TILE + math.sin(p.offset) * PLATFORM_RANGE
    }
}

get_moving_platform_x :: proc(idx: int) -> f32 {
    return platforms[idx].x
}

ride_moving_platforms :: proc() {
    if dead || won || player.vel_y < 0 { return }
    for i in 0..<platform_count {
        p := platforms[i]
        px := p.x
        py := p.y
        pw := f32(p.width) * TILE
        if player.x + player.w > px && player.x < px + pw &&
           player.y + player.h >= py - 4 && player.y + player.h <= py + 16 {
            player.y = py - player.h
            player.vel_y = 0
            player.on_ground = true
            player.x += p.x - p.prev_x
            return
        }
    }
}

resolve_crumble :: proc(dt: f32) {
    for row in 0..<ROWS {
        for col in 0..<COLS {
            if tiles[row][col] != CRUMB { continue }
            state := &crumble_state[row][col]
            if state^ == 0 {
                tile_x := f32(col) * TILE
                tile_y := f32(row) * TILE
                if player.x + player.w > tile_x && player.x < tile_x + TILE &&
                   player.y + player.h > tile_y && player.y < tile_y + TILE {
                    state^ = CRUMBLE_STAND_TIME
                }
            } else if state^ > 0 {
                state^ -= dt
                if state^ <= 0 { state^ = -1 }
            } else if state^ == -1 {
                state^ = -CRUMBLE_RESPAWN_TIME
            } else if state^ < 0 {
                state^ += dt
                if state^ >= 0 { state^ = 0 }
            }
        }
    }
}

update_triggers :: proc(dt: f32) {
    for row in 0..<ROWS {
        for col in 0..<COLS {
            if trigger_state[row][col] > 0 {
                trigger_state[row][col] -= dt
            }
        }
    }
}

resolve_axis :: proc(axis: int) {
    right := player.x + player.w - 1
    bottom := player.y + player.h - 1
    corners := [4][2]f32{
        {player.x, player.y}, {right, player.y},
        {player.x, bottom}, {right, bottom},
    }
    for corner in corners {
        col := int(corner[0] / TILE)
        row := int(corner[1] / TILE)
        if is_solid(col, row) {
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
}

lerp :: proc(a, b, t: f32) -> f32 { return a + (b - a) * t }
clamp :: proc(v, lo, hi: f32) -> f32 { return min(max(v, lo), hi) }

init :: proc "c" () {
    context = rt_ctx
    sg.setup({ environment = sglue.environment(), logger = { func = slog.func } })
    sgl.setup({ logger = { func = slog.func } })
    pass_action = {
        colors = { 0 = { load_action = .CLEAR, clear_value = { r=0.05, g=0.06, b=0.10, a=1 } } },
    }
    load_level()
    player = { x = spawn_x, y = spawn_y, w = 24, h = 36 }
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
        case .R: key_r = true
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

reset_game :: proc() {
    player.x = spawn_x
    player.y = spawn_y
    player.vel_y = 0
    player.on_ground = false
    dead = false
    won = false
    death_timer = 0
    for row in 0..<ROWS {
        for col in 0..<COLS {
            crumble_state[row][col] = 0
            trigger_state[row][col] = 0
        }
    }
    for i in 0..<platform_count {
        platforms[i].offset = 0
        platforms[i].x = f32(platforms[i].col) * TILE
        platforms[i].prev_x = platforms[i].x
    }
}

draw_game :: proc() {
    sgl.defaults()
    sgl.matrix_mode_projection()
    sgl.ortho(0, W, H, 0, -1, 1)

    sgl.matrix_mode_modelview()
    sgl.push_matrix()
    sgl.translate(-cam.x, -cam.y, 0)

    for row in 0..<ROWS {
        for col in 0..<COLS {
            x := f32(col) * TILE
            y := f32(row) * TILE
            ch := tiles[row][col]
            switch ch {
            case WALL:
                draw_rect(x, y, TILE, TILE, 80, 80, 90)
            case FAKE:
                draw_rect(x, y, TILE, TILE, 70, 75, 85)
                draw_rect(x+2, y+2, TILE-4, TILE-4, 90, 95, 105)
            case CRUMB:
                state := crumble_state[row][col]
                if state < 0 {
                    draw_rect(x+8, y+8, TILE-16, TILE-16, 40, 50, 30)
                } else if state > 0 {
                    shake := math.sin(state * 80) * 2
                    draw_rect(x+shake, y, TILE, TILE, 100, 140, 70)
                } else {
                    draw_rect(x, y, TILE, TILE, 100, 160, 80)
                }
            case SPIKE:
                cx := x + TILE/2
                sgl.begin_triangles()
                sgl.v2f_c4b(cx, y,      200, 40, 40, 255)
                sgl.v2f_c4b(x+4, y+TILE, 200, 40, 40, 255)
                sgl.v2f_c4b(x+TILE-4, y+TILE, 200, 40, 40, 255)
                sgl.end()
            case TRIG:
                draw_rect(x, y, TILE, TILE, 80, 50, 100)
                draw_rect(x+TILE/2-2, y-8, 4, 8, 120, 80, 150)
            case EXIT:
                draw_rect(x, y, TILE, TILE, 200, 180, 40)
                draw_rect(x+4, y+4, TILE-8, TILE-8, 240, 220, 80)
            }
            if trigger_state[row][col] > 0 && tiles[row][col] != SPIKE {
                cx := x + TILE/2
                sgl.begin_triangles()
                sgl.v2f_c4b(cx, y+TILE,   200, 60, 60, 200)
                sgl.v2f_c4b(x+4, y,        200, 60, 60, 200)
                sgl.v2f_c4b(x+TILE-4, y,   200, 60, 60, 200)
                sgl.end()
            }
        }
    }

    for i in 0..<platform_count {
        p := platforms[i]
        draw_rect(p.x, p.y, f32(p.width) * TILE, TILE/2, 60, 120, 220)
        draw_rect(p.x+4, p.y+4, f32(p.width) * TILE-8, 6, 120, 180, 255)
    }

    if !dead {
        draw_rect(player.x, player.y, player.w, player.h, 240, 200, 80)
    }

    sgl.pop_matrix()

    if won {
        draw_rect(W/2-100, H/2-20, 200, 40, 60, 180, 60)
        draw_rect(W/3-20, H/2-12, 40, 24, 255, 255, 200)
        draw_rect(W/2-20, H/2-12, 40, 24, 255, 255, 200)
        draw_text("YOU WIN", W/2-84, H/2-8, 3, 245, 245, 160)
    }
    if dead {
        draw_rect(W/2-60, H/2-10, 120, 20, 200, 40, 40)
        draw_text("TRY AGAIN", W/2-108, H/2+24, 3, 255, 120, 120)
    }
    draw_text("LEVEL DEVIL", 18, 18, 2, 240, 220, 120)
    draw_text("R RESTART", W-150, 18, 2, 180, 190, 210)
    if !dead && !won {
        if player.x < 1200 {
            draw_text("GREEN FALLS", 18, 48, 2, 140, 220, 120)
        } else if player.x < 1900 {
            draw_text("PURPLE DONT JUMP", 18, 48, 2, 210, 140, 245)
        } else {
            draw_text("BLUE MOVES", 18, 48, 2, 120, 190, 255)
        }
    }
    progress := (player.x - spawn_x) / (exit_x - spawn_x)
    progress = clamp(progress, 0, 1)
    draw_rect(10, H-18, (W-20)*progress, 8, 200, 160, 60)
}

frame :: proc "c" () {
    context = rt_ctx
    dt := f32(sapp.frame_duration())
    if dt > 0.05 { dt = 0.05 }

    if key_r {
        reset_game()
        key_r = false
    }

    if !dead && !won {
        jump_buffer -= dt
        update_moving_platforms(dt)

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
        player.y += player.vel_y * dt
        resolve_axis(1)

        ride_moving_platforms()

        check_player_spike()
        check_player_trigger()
        check_player_exit()
        resolve_crumble(dt)
        update_triggers(dt)
    }

    if dead {
        death_timer -= dt
        if death_timer <= 0 { reset_game() }
    }

    target_x := player.x + player.w/2 - W/2
    target_y := player.y + player.h/2 - H/2
    cam.x = lerp(cam.x, target_x, LERP_SPEED * dt)
    cam.y = lerp(cam.y, target_y, LERP_SPEED * dt)
    cam.x = clamp(cam.x, 0, WORLD_W - W)
    cam.y = clamp(cam.y, 0, WORLD_H - H)

    draw_game()

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

draw_text :: proc(text: string, x, y, scale: f32, r, g, b: u8) {
    cx := x
    for ch in text {
        draw_char(ch, cx, y, scale, r, g, b)
        cx += 6 * scale
    }
}

draw_char :: proc(ch: rune, x, y, scale: f32, r, g, b: u8) {
    p := [7]string{".....", ".....", ".....", ".....", ".....", ".....", "....."}
    switch ch {
    case 'A': p = {".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"}
    case 'B': p = {"####.", "#...#", "#...#", "####.", "#...#", "#...#", "####."}
    case 'C': p = {".####", "#....", "#....", "#....", "#....", "#....", ".####"}
    case 'D': p = {"####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####."}
    case 'E': p = {"#####", "#....", "#....", "####.", "#....", "#....", "#####"}
    case 'F': p = {"#####", "#....", "#....", "####.", "#....", "#....", "#...."}
    case 'G': p = {".####", "#....", "#....", "#.###", "#...#", "#...#", ".###."}
    case 'H': p = {"#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"}
    case 'I': p = {"#####", "..#..", "..#..", "..#..", "..#..", "..#..", "#####"}
    case 'J': p = {"..###", "...#.", "...#.", "...#.", "#..#.", "#..#.", ".##.."}
    case 'K': p = {"#...#", "#..#.", "#.#..", "##...", "#.#..", "#..#.", "#...#"}
    case 'L': p = {"#....", "#....", "#....", "#....", "#....", "#....", "#####"}
    case 'M': p = {"#...#", "##.##", "#.#.#", "#...#", "#...#", "#...#", "#...#"}
    case 'N': p = {"#...#", "##..#", "#.#.#", "#..##", "#...#", "#...#", "#...#"}
    case 'O': p = {".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."}
    case 'P': p = {"####.", "#...#", "#...#", "####.", "#....", "#....", "#...."}
    case 'Q': p = {".###.", "#...#", "#...#", "#...#", "#.#.#", "#..#.", ".##.#"}
    case 'R': p = {"####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"}
    case 'S': p = {".####", "#....", "#....", ".###.", "....#", "....#", "####."}
    case 'T': p = {"#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."}
    case 'U': p = {"#...#", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."}
    case 'V': p = {"#...#", "#...#", "#...#", "#...#", "#...#", ".#.#.", "..#.."}
    case 'W': p = {"#...#", "#...#", "#...#", "#...#", "#.#.#", "##.##", "#...#"}
    case 'X': p = {"#...#", ".#.#.", "..#..", "..#..", "..#..", ".#.#.", "#...#"}
    case 'Y': p = {"#...#", ".#.#.", "..#..", "..#..", "..#..", "..#..", "..#.."}
    case 'Z': p = {"#####", "....#", "...#.", "..#..", ".#...", "#....", "#####"}
    case ' ': return
    }
    for row in 0..<7 {
        for col in 0..<5 {
            if p[row][col] != '.' {
                draw_rect(x + f32(col)*scale, y + f32(row)*scale, scale, scale, r, g, b)
            }
        }
    }
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
        window_title = "P16 — Level Devil (NOT a Troll Game)",
        logger     = { func = slog.func },
    })
}
