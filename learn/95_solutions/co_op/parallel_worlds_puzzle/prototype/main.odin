/*
Parallel-Worlds Co-op Prototype (the "BOKURA trick")
====================================================
GOAL: prove how two players can stand in the SAME world but SEE two completely
different worlds — one a cold tech/future world, one a lush nature world.

THE WHOLE SECRET (read this, it's the thing you were stuck on):
  There are NOT two worlds. There is ONE logical world: one tile grid, one set
  of entities, one collision truth. The "two different worlds" is purely a DRAW
  choice. We render the same grid TWICE, once per viewer, and at draw time we
  pick a different sprite + palette per tile based on the viewer's THEME.

  - Same tile  -> two costumes (tech sprite vs nature sprite)
  - Same wall  -> same collision box, different look
  - Same partner entity -> drawn as a robot to one viewer, an animal to the other

  That is the entire BOKURA illusion. Gameplay is shared; presentation forks.

TWO LAYERS OF THE TRICK (this prototype shows both, staged):

  LAYER 1 — COSMETIC FORK (the base BOKURA feeling)
    Every tile exists for both players and collides the same for both. Only the
    sprite + palette differ per theme. Communication comes from DESCRIBING what
    you see ("my exit is a glowing flower" / "mine is a server rack").

  LAYER 2 — TRUTH FORK (the harder, info-gap layer)
    Some tiles only EXIST for one theme (a bridge that is solid ground in the
    nature world but empty void in the tech world). Now the worlds disagree about
    what is walkable, so players MUST guide each other.

CONTROLS:
  - Player A (tech)   : WASD
  - Player B (nature) : arrow keys
  - R : reset
  - Both must reach their exit tile to win.

RENDERING:
  Split screen. Left half = Player A's world (tech theme). Right half = Player
  B's world (nature theme). Same grid, two themes, two viewports. This is the
  cheapest honest way to show "same world, different truth" on one screen. In a
  networked build each client would just render its own theme full-screen — the
  exact same draw_world() call, different viewer theme.
*/

package prototype

import sapp  "../../../../../sauce/sokol/app"
import sg    "../../../../../sauce/sokol/gfx"
import sgl   "../../../../../sauce/sokol/gl"
import sglue "../../../../../sauce/sokol/glue"
import slog  "../../../../../sauce/sokol/log"
import "base:runtime"

W :: 1120
H :: 540
TILE :: 40
COLS :: 13
ROWS :: 10

// ---------------------------------------------------------------------------
// THEME: the only thing that differs between the two views.
// ---------------------------------------------------------------------------
Theme :: enum {
	tech,    // Player A's world: cold, metallic, future
	nature,  // Player B's world: warm, green, alive
}

// Logical tile kinds. These are the TRUTH. Both views share these.
Tile :: enum u8 {
	empty,
	wall,
	// LAYER 2 (truth fork): exists/solid in ONE theme only.
	// In nature it is solid walkable ground; in tech it is empty void you fall
	// into (here: blocked, you cannot step on it).
	nature_only_ground,
	tech_only_ground,
	exit_a,   // Player A's goal tile
	exit_b,   // Player B's goal tile
}

// A tiny "skin" for a tile: a color per theme = the costume.
// In a real game these would be sprite handles, not colors.
Visual :: struct {
	color: [Theme][3]u8,
}

// ---------------------------------------------------------------------------
// Per-tile costumes. SAME tile, TWO looks. This table IS the BOKURA illusion.
// ---------------------------------------------------------------------------
visuals := [Tile]Visual {
	.empty = {
		color = {
			.tech   = {28, 32, 40},    // dark steel floor
			.nature = {40, 74, 44},    // mossy grass
		},
	},
	.wall = {
		color = {
			.tech   = {90, 110, 130},  // metal panel
			.nature = {86, 60, 40},    // tree-bark / dirt wall
		},
	},
	.nature_only_ground = {
		color = {
			.tech   = {16, 18, 24},    // looks like a pit/void to tech player
			.nature = {120, 170, 70},  // looks like solid leafy ground
		},
	},
	.tech_only_ground = {
		color = {
			.tech   = {70, 130, 160},  // looks like a tech platform
			.nature = {18, 24, 18},    // looks like a dark gap to nature player
		},
	},
	.exit_a = {
		color = {
			.tech   = {120, 220, 255}, // glowing tech exit
			.nature = {120, 220, 255},
		},
	},
	.exit_b = {
		color = {
			.tech   = {255, 200, 120}, // glowing nature exit
			.nature = {255, 200, 120},
		},
	},
}

Player :: struct {
	x, y: int,
	theme: Theme,
	reached_exit: bool,
}

tiles: [ROWS][COLS]Tile
player_a: Player  // tech
player_b: Player  // nature
won: bool

// Map legend:
//   # wall      . empty floor
//   n nature-only ground (solid for nature, void for tech)
//   t tech-only ground  (solid for tech,  void for nature)
//   A spawn player A     a exit for player A
//   B spawn player B     b exit for player B
MAP :: [ROWS]string{
	"#############",
	"#A..t...n..a#",
	"#...t...n...#",
	"#...t...n...#",
	"#nnnn...tttt#",
	"#...n...t...#",
	"#...n...t...#",
	"#B..n...t..b#",
	"#...........#",
	"#############",
}

pass_action: sg.Pass_Action
rt_ctx: runtime.Context

draw_rect :: proc(x, y, w, h: f32, r, g, b: u8) {
	sgl.begin_quads()
	sgl.v2f_c4b(x,   y,   r, g, b, 255)
	sgl.v2f_c4b(x+w, y,   r, g, b, 255)
	sgl.v2f_c4b(x+w, y+h, r, g, b, 255)
	sgl.v2f_c4b(x,   y+h, r, g, b, 255)
	sgl.end()
}

init_level :: proc() {
	m := MAP
	for row in 0..<ROWS {
		for col in 0..<COLS {
			switch m[row][col] {
			case '#': tiles[row][col] = .wall
			case 'n': tiles[row][col] = .nature_only_ground
			case 't': tiles[row][col] = .tech_only_ground
			case 'a': tiles[row][col] = .exit_a
			case 'b': tiles[row][col] = .exit_b
			case 'A':
				tiles[row][col] = .empty
				player_a.x = col; player_a.y = row
			case 'B':
				tiles[row][col] = .empty
				player_b.x = col; player_b.y = row
			case:
				tiles[row][col] = .empty
			}
		}
	}
	player_a.theme = .tech
	player_b.theme = .nature
	player_a.reached_exit = false
	player_b.reached_exit = false
	won = false
}

// ---------------------------------------------------------------------------
// COLLISION = the shared truth. Note this is per-PLAYER, not per-VIEW.
// The asymmetry here is LAYER 2 (truth fork). For a pure cosmetic game you would
// delete the nature_only / tech_only cases and both players would collide
// identically — same world, only the *look* forks.
// ---------------------------------------------------------------------------
tile_blocks_player :: proc(tile: Tile, p: Player) -> bool {
	#partial switch tile {
	case .wall:
		return true
	case .nature_only_ground:
		// solid ground for nature player, void (blocked) for tech player
		return p.theme == .tech
	case .tech_only_ground:
		// solid ground for tech player, void (blocked) for nature player
		return p.theme == .nature
	case:
		return false
	}
}

try_move :: proc(p: ^Player, dx, dy: int) {
	if won do return
	nx := p.x + dx
	ny := p.y + dy
	if nx < 0 || nx >= COLS || ny < 0 || ny >= ROWS { return }
	if tile_blocks_player(tiles[ny][nx], p^) { return }
	p.x = nx
	p.y = ny
}

update_game_state :: proc() {
	player_a.reached_exit = tiles[player_a.y][player_a.x] == .exit_a
	player_b.reached_exit = tiles[player_b.y][player_b.x] == .exit_b
	won = player_a.reached_exit && player_b.reached_exit
}

// ---------------------------------------------------------------------------
// THE KEY PROC. Draw the ONE shared world from ONE viewer's THEME.
// Called once per player. Same grid in, different costume out.
// origin_x lets us place each view on its own half (split screen).
// ---------------------------------------------------------------------------
draw_world :: proc(viewer: Theme, origin_x: f32) {
	for row in 0..<ROWS {
		for col in 0..<COLS {
			tile := tiles[row][col]
			c := visuals[tile].color[viewer]   // <- pick costume by viewer theme
			x := origin_x + f32(col*TILE)
			y := f32(row*TILE) + 30
			draw_rect(x, y, TILE-1, TILE-1, c[0], c[1], c[2])
		}
	}

	// Draw both players, but THEMED by the viewer.
	// Same entity, different avatar per world: robot vs animal.
	draw_player(player_a, viewer, origin_x)
	draw_player(player_b, viewer, origin_x)
}

draw_player :: proc(p: Player, viewer: Theme, origin_x: f32) {
	x := origin_x + f32(p.x*TILE) + 6
	y := f32(p.y*TILE) + 30 + 6
	sz := f32(TILE - 12)

	// Avatar look depends on WHICH WORLD it is being viewed in (the BOKURA trick
	// applied to characters): in the tech world everyone is a robot; in the
	// nature world everyone is an animal. We still tint by who they are so each
	// player can tell themselves apart from their partner.
	is_self := p.theme == viewer
	r, g, b: u8
	switch viewer {
	case .tech:
		// robots: steel-blue, brighter for "you"
		if is_self { r, g, b = 150, 220, 255 } else { r, g, b = 90, 130, 160 }
	case .nature:
		// animals: warm tones, brighter for "you"
		if is_self { r, g, b = 255, 210, 130 } else { r, g, b = 170, 140, 90 }
	}
	draw_rect(x, y, sz, sz, r, g, b)

	// little marker so the two avatars never get confused regardless of theme
	if p.theme == .tech {
		draw_rect(x + sz/2 - 3, y + 4, 6, 6, 255, 255, 255)        // square = robot
	} else {
		draw_rect(x + 6, y + sz - 10, sz - 12, 4, 255, 255, 255)   // bar = animal
	}
}

event :: proc "c" (e: ^sapp.Event) {
	context = rt_ctx
	if e.type != .KEY_DOWN do return
	#partial switch e.key_code {
	case .W:     try_move(&player_a, 0, -1)
	case .S:     try_move(&player_a, 0, 1)
	case .A:     try_move(&player_a, -1, 0)
	case .D:     try_move(&player_a, 1, 0)
	case .UP:    try_move(&player_b, 0, -1)
	case .DOWN:  try_move(&player_b, 0, 1)
	case .LEFT:  try_move(&player_b, -1, 0)
	case .RIGHT: try_move(&player_b, 1, 0)
	case .R:     init_level()
	}
	update_game_state()
}

init :: proc "c" () {
	context = rt_ctx
	sg.setup({ environment = sglue.environment(), logger = { func = slog.func } })
	sgl.setup({ logger = { func = slog.func } })
	pass_action = {
		colors = { 0 = { load_action = .CLEAR, clear_value = { r = 0.04, g = 0.05, b = 0.07, a = 1 } } },
	}
	init_level()
	update_game_state()
}

frame :: proc "c" () {
	context = rt_ctx
	sgl.defaults()
	sgl.matrix_mode_projection()
	sgl.ortho(0, W, H, 0, -1, 1)

	half := f32(W) / 2

	// LEFT HALF: Player A sees the TECH world.
	draw_world(.tech, 20)
	// RIGHT HALF: Player B sees the NATURE world.
	draw_world(.nature, half + 20)

	// thin divider between the two views
	draw_rect(half - 1, 0, 2, H, 0, 0, 0)

	// status bars (top-left of each half)
	if player_a.reached_exit { draw_rect(20, 8, 40, 8, 120, 220, 255) }
	if player_b.reached_exit { draw_rect(half + 20, 8, 40, 8, 255, 200, 120) }
	if won {
		draw_rect(W/2 - 90, 8, 180, 14, 240, 230, 120)
	}

	sg.begin_pass({ action = pass_action, swapchain = sglue.swapchain() })
	sgl.draw()
	sg.end_pass()
	sg.commit()
}

cleanup :: proc "c" () {
	context = rt_ctx
	sgl.shutdown()
	sg.shutdown()
}

main :: proc() {
	rt_ctx = context
	sapp.run({
		init_cb = init,
		frame_cb = frame,
		event_cb = event,
		cleanup_cb = cleanup,
		width = W,
		height = H,
		window_title = "Parallel-Worlds Co-op Prototype (BOKURA trick)",
		logger = { func = slog.func },
	})
}
