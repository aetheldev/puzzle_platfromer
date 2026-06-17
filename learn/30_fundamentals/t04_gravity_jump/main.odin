package t04

import sapp "../../../sauce/sokol/app"
import sdtx "../../../sauce/sokol/debugtext"
import sg "../../../sauce/sokol/gfx"
import sgl "../../../sauce/sokol/gl"
import sglue "../../../sauce/sokol/glue"
import slog "../../../sauce/sokol/log"
import "base:runtime"

W :: 960
H :: 540
GRAVITY :: 1800.0

JUMP_VEL :: -600.
SPEED :: 300
Floor :: struct {
	x, y: f32,
	w, h: f32,
}
floors: [dynamic]Floor
Player :: struct {
	x, y:      f32,
	w, h:      f32,
	vel_y:     f32,
	on_ground: bool,
}
player: Player
key_left, key_right: bool
jump_pressed: bool
jump_held: bool
prev_jump_held: bool

pass_action: sg.Pass_Action
rt_ctx: runtime.Context
init :: proc "c" () {
	context = rt_ctx
	sg.setup({environment = sglue.environment(), logger = {func = slog.func}})
	// sokol_gl must be set up after sokol_gfx
	sgl.setup({logger = {func = slog.func}})
	sdtx.setup({fonts = {0 = sdtx.font_kc853()}})
	sdtx.canvas(W, H)
	pass_action = {
		colors = {0 = {load_action = .CLEAR, clear_value = {r = 0.1, g = 0.1, b = 0.15, a = 1}}},
	}

	player = {
		x         = W / 2 - 20,
		y         = H / 2 - 20,
		w         = 40,
		h         = 40,
		vel_y     = 0,
		on_ground = false,
	}


	append(
		&floors,
		Floor{x = 0, y = f32(H - 60), w = W, h = H - f32(H - 60)},
		Floor{x = f32(W - 300), y = f32(H - 150), w = 100, h = 100},
	)
}

draw_rect :: proc(x, y, w, h: f32, r, g, b: u8) {
	sgl.begin_quads()
	sgl.v2f_c4b(x, y, r, g, b, 255)
	sgl.v2f_c4b(x + w, y, r, g, b, 255)
	sgl.v2f_c4b(x + w, y + h, r, g, b, 255)
	sgl.v2f_c4b(x, y + h, r, g, b, 255)
	sgl.end()
}
floor_maker :: proc(f: Floor) {
	r, g, b: u8 = 80, 140, 80
	sgl.begin_quads()
	sgl.v2f_c4b(f.x, f.y, r, g, b, 255)
	sgl.v2f_c4b(f.x + f.w, f.y, r, g, b, 255)
	sgl.v2f_c4b(f.x + f.w, f.y + f.h, r, g, b, 255)
	sgl.v2f_c4b(f.x, f.y + f.h, r, g, b, 255)
	sgl.end()
}

aabb :: proc(px, py, pw, ph, fx, fy, fw, fh: f32) -> bool {
	return px < fx + fw && px + pw > fx && py < fy + fh && py + ph > fy
}

frame :: proc "c" () {
	context = rt_ctx

	// --- delta time ---
	dt := f32(sapp.frame_duration())

	// --- input → velocity ---
	vx: f32 = 0
	if key_left {vx = -SPEED}
	if key_right {vx = SPEED}
	player.x += vx * dt

	// --- variable jump: release mid-air → cut vel_y ---
	if prev_jump_held && !jump_held && player.vel_y < 0 {
		player.vel_y *= 0.5
	}
	prev_jump_held = jump_held

	// --- jump ---
	if jump_pressed && player.on_ground {
		player.vel_y = JUMP_VEL
		player.on_ground = false
	}
	jump_pressed = false

	// --- gravity ---
	player.vel_y += GRAVITY * dt
	// --- integrate Y ---
	player.y += player.vel_y * dt


	// --- floor collision ---
	player.on_ground = false
	for floor in floors {
		if aabb(player.x, player.y, player.w, player.h, floor.x, floor.y, floor.w, floor.h) {
			player.y = floor.y - player.h
			player.vel_y = 0
			player.on_ground = true
		}
	}

	// --- clamp to screen edges (left/right only) ---
	if player.x < 0 {player.x = 0}
	if player.x + player.w > W {player.x = W - player.w}

	// --- draw ---
	sgl.defaults()
	sgl.matrix_mode_projection()
	sgl.ortho(0, W, H, 0, -1, 1)
	// floor

	for floor in floors {
		floor_maker(floor)
	}

	draw_rect(player.x, player.y, player.w, player.h, 240, 200, 80)

	sg.begin_pass({action = pass_action, swapchain = sglue.swapchain()})
	sgl.draw()
	sdtx.draw()
	sg.end_pass()
	sg.commit()
}

event :: proc "c" (e: ^sapp.Event) {
	context = rt_ctx
	if e.type == .KEY_DOWN || e.type == .KEY_UP {
		held := e.type == .KEY_DOWN
		#partial switch e.key_code {
		case .A, .LEFT:
			key_left = held
		case .D, .RIGHT:
			key_right = held
		case .W, .UP, .SPACE:
			jump_pressed = held
			jump_held = held
		// case .LEFT_SHIFT, .RIGHT_SHIFT:
		// 	key_sprint = held
		case: // ignore other keys
		}
	}
}

cleanup :: proc "c" () {
	context = rt_ctx
	sdtx.shutdown()
	sgl.shutdown()
	sg.shutdown()
}

main :: proc() {
	rt_ctx = context
	sapp.run(
		{
			init_cb = init,
			frame_cb = frame,
			event_cb = event,
			cleanup_cb = cleanup,
			width = W,
			height = H,
			window_title = "T04 – Gravity & Jump",
			logger = {func = slog.func},
		},
	)
}

