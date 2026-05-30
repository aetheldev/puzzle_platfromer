/*
Turn-Based Card Game Starter
============================
Goal: learn turn state, hands, deck, discard pile, legal move validation,
and hot-seat multiplayer.

Rules:
  - 2 players
  - colors: red, blue, green, yellow
  - values: 0..4
  - play card if color OR value matches discard top
  - if no legal card, draw one with S or Down
  - first empty hand wins

Controls:
  - A / Left:  select previous card
  - D / Right: select next card
  - Enter / Space: play selected card
  - S / Down: draw one card if blocked
  - Tab: reveal both hands
  - R: reset game

Why this project matters:
  - very clear state machine
  - deterministic rules
  - good preparation for future networking
*/

package turn_based_card_game

import sapp  "../../../../sauce/sokol/app"
import sg    "../../../../sauce/sokol/gfx"
import sgl   "../../../../sauce/sokol/gl"
import sglue "../../../../sauce/sokol/glue"
import slog  "../../../../sauce/sokol/log"
import "base:runtime"
import "core:fmt"

W :: 960
H :: 540

CARD_W :: 84
CARD_H :: 120
HAND_SIZE :: 5

Card_Color :: enum u8 {
	red,
	blue,
	green,
	yellow,
}

Card :: struct {
	color: Card_Color,
	value: int,
}

Player :: struct {
	hand: [dynamic]Card,
}

players: [2]Player
deck: [dynamic]Card
discard: [dynamic]Card

current_player: int
selected_index: int
winner: int = -1
turn_count: int
reveal_all: bool

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

draw_outline :: proc(x, y, w, h: f32, r, g, b: u8) {
	sgl.begin_lines()
	sgl.v2f_c4b(x,   y,   r, g, b, 255)
	sgl.v2f_c4b(x+w, y,   r, g, b, 255)

	sgl.v2f_c4b(x+w, y,   r, g, b, 255)
	sgl.v2f_c4b(x+w, y+h, r, g, b, 255)

	sgl.v2f_c4b(x+w, y+h, r, g, b, 255)
	sgl.v2f_c4b(x,   y+h, r, g, b, 255)

	sgl.v2f_c4b(x,   y+h, r, g, b, 255)
	sgl.v2f_c4b(x,   y,   r, g, b, 255)
	sgl.end()
}

color_rgb :: proc(color: Card_Color) -> (u8, u8, u8) {
	#partial switch color {
	case .red:    return 220, 80, 80
	case .blue:   return 90, 150, 255
	case .green:  return 90, 200, 110
	case .yellow: return 230, 200, 80
	}
	return 200, 200, 200
}

append_card :: proc(cards: ^[dynamic]Card, color: Card_Color, value: int) {
	append(cards, Card{color = color, value = value})
}

top_discard :: proc() -> Card {
	assert(len(discard) > 0)
	return discard[len(discard)-1]
}

is_playable :: proc(card, against: Card) -> bool {
	return card.color == against.color || card.value == against.value
}

current_hand :: proc() -> ^[dynamic]Card {
	return &players[current_player].hand
}

other_player :: proc() -> int {
	return (current_player + 1) % 2
}

any_playable_in_hand :: proc(hand: []Card) -> bool {
	top := top_discard()
	for card in hand {
		if is_playable(card, top) {
			return true
		}
	}
	return false
}

refill_deck_from_discard :: proc() {
	if len(deck) > 0 || len(discard) <= 1 do return

	top := discard[len(discard)-1]
	for i in 0..<len(discard)-1 {
		append(&deck, discard[i])
	}
	clear(&discard)
	append(&discard, top)

	// Deterministic reverse-style shuffle.
	for i in 0..<len(deck)/2 {
		j := len(deck)-1-i
		deck[i], deck[j] = deck[j], deck[i]
	}
}

draw_from_deck :: proc() -> (Card, bool) {
	refill_deck_from_discard()
	if len(deck) == 0 {
		return {}, false
	}
	card := deck[len(deck)-1]
	resize(&deck, len(deck)-1)
	return card, true
}

advance_turn :: proc() {
	current_player = other_player()
	selected_index = 0
	turn_count += 1
}

check_win :: proc() {
	for i in 0..<len(players) {
		if len(players[i].hand) == 0 {
			winner = i
			fmt.println("Player", i+1, "wins in", turn_count, "turns")
			return
		}
	}
}

setup_game :: proc() {
	for i in 0..<len(players) {
		clear(&players[i].hand)
	}
	clear(&deck)
	clear(&discard)

	for color in Card_Color {
		for value in 0..=4 {
			append_card(&deck, color, value)
			append_card(&deck, color, value)
		}
	}

	// Deterministic shuffle so behavior stays stable and easy to debug.
	for i in 0..<len(deck) {
		j := (i*7 + 3) % len(deck)
		deck[i], deck[j] = deck[j], deck[i]
	}

	for _ in 0..<HAND_SIZE {
		for p in 0..<len(players) {
			card, ok := draw_from_deck()
			if ok {
				append(&players[p].hand, card)
			}
		}
	}

	first, ok := draw_from_deck()
	assert(ok)
	append(&discard, first)

	current_player = 0
	selected_index = 0
	winner = -1
	turn_count = 0
	reveal_all = false
}

play_selected_card :: proc() {
	if winner != -1 do return
	hand := current_hand()
	if len(hand^) == 0 do return
	if selected_index < 0 || selected_index >= len(hand^) do return

	card := hand^[selected_index]
	if !is_playable(card, top_discard()) {
		return
	}

	append(&discard, card)
	ordered_remove(hand, selected_index)
	if selected_index >= len(hand^) && len(hand^) > 0 {
		selected_index = len(hand^) - 1
	}
	check_win()
	if winner == -1 {
		advance_turn()
	}
}

draw_if_blocked :: proc() {
	if winner != -1 do return
	hand := current_hand()
	if any_playable_in_hand(hand^[:]) {
		return
	}
	card, ok := draw_from_deck()
	if ok {
		append(hand, card)
	}
	advance_turn()
}

move_selection :: proc(dir: int) {
	hand := current_hand()
	if len(hand^) == 0 {
		selected_index = 0
		return
	}
	selected_index = (selected_index + dir + len(hand^)) % len(hand^)
}

event :: proc "c" (e: ^sapp.Event) {
	context = rt_ctx
	if e.type != .KEY_DOWN do return

	#partial switch e.key_code {
	case .A, .LEFT:
		move_selection(-1)
	case .D, .RIGHT:
		move_selection(1)
	case .SPACE, .ENTER:
		play_selected_card()
	case .S, .DOWN:
		draw_if_blocked()
	case .TAB:
		reveal_all = !reveal_all
	case .R:
		setup_game()
	}
}

draw_card_face :: proc(x, y: f32, card: Card, selected, visible, playable: bool) {
	if !visible {
		draw_rect(x, y, CARD_W, CARD_H, 75, 80, 95)
		draw_outline(x, y, CARD_W, CARD_H, 120, 130, 150)
		for i in 0..<4 {
			draw_rect(x+14+f32(i*14), y+52, 8, 16, 160, 170, 190)
		}
		return
	}

	r, g, b := color_rgb(card.color)
	if !playable {
		r = u8(f32(r) * 0.45)
		g = u8(f32(g) * 0.45)
		b = u8(f32(b) * 0.45)
	}

	draw_rect(x, y, CARD_W, CARD_H, r, g, b)
	draw_rect(x+8, y+8, CARD_W-16, CARD_H-16, 245, 245, 245)
	draw_rect(x+14, y+14, CARD_W-28, CARD_H-28, r, g, b)

	// Draw the number as pips so we don't need text.
	for i in 0..=card.value {
		draw_rect(x+18+f32(i*10), y+22, 8, 8, 255, 255, 255)
		draw_rect(x+CARD_W-26-f32(i*10), y+CARD_H-30, 8, 8, 255, 255, 255)
	}

	if selected {
		draw_outline(x-3, y-3, CARD_W+6, CARD_H+6, 255, 220, 120)
	} else if playable {
		draw_outline(x, y, CARD_W, CARD_H, 255, 255, 255)
	} else {
		draw_outline(x, y, CARD_W, CARD_H, 60, 60, 70)
	}
}

draw_hand :: proc(player_idx: int, y: f32, face_up: bool) {
	hand := players[player_idx].hand
	count := len(hand)
	if count == 0 { return }
	spacing := f32(22)
	total_w := CARD_W + f32(count-1)*spacing
	start_x := f32(W)/2 - total_w/2
	top := top_discard()

	for card, i in hand {
		selected := player_idx == current_player && i == selected_index
		playable := is_playable(card, top)
		draw_y := y
		if selected {
			draw_y -= 12
		}
		draw_card_face(start_x+f32(i)*spacing, draw_y, card, selected, face_up, playable)
	}
}

init :: proc "c" () {
	context = rt_ctx
	sg.setup({ environment = sglue.environment(), logger = { func = slog.func } })
	sgl.setup({ logger = { func = slog.func } })
	pass_action = {
		colors = { 0 = { load_action = .CLEAR, clear_value = { r = 0.06, g = 0.09, b = 0.08, a = 1 } } },
	}
	setup_game()
}

frame :: proc "c" () {
	context = rt_ctx

	sgl.defaults()
	sgl.matrix_mode_projection()
	sgl.ortho(0, W, H, 0, -1, 1)

	// Table background and lane markers.
	draw_rect(0, 0, W, H, 28, 65, 52)
	draw_rect(0, H/2-2, W, 4, 50, 90, 72)

	// Current player highlight bars.
	if current_player == 0 {
		draw_rect(0, H-20, W, 12, 255, 210, 100)
	} else {
		draw_rect(0, 8, W, 12, 255, 210, 100)
	}

	// Draw deck and discard piles.
	draw_rect(250, H/2-CARD_H/2, CARD_W, CARD_H, 70, 75, 90)
	draw_outline(250, H/2-CARD_H/2, CARD_W, CARD_H, 150, 160, 180)
	for i in 0..<min(len(deck), 6) {
		draw_rect(258+f32(i*6), H/2-10, 4, 20, 180, 190, 210)
	}

	discard_top := top_discard()
	draw_card_face(420, H/2-CARD_H/2, discard_top, false, true, true)

	// Player hand count indicators.
	for i in 0..<len(players[0].hand) {
		draw_rect(40+f32(i*7), H-26, 5, 12, 255, 220, 120)
	}
	for i in 0..<len(players[1].hand) {
		draw_rect(40+f32(i*7), 14, 5, 12, 255, 220, 120)
	}

	// Turn count bars.
	for i in 0..<min(turn_count, 40) {
		draw_rect(W-20-f32(i*6), H/2-6, 4, 12, 180, 230, 255)
	}

	// Hands. Hide non-current player by default for hot-seat play.
	draw_hand(1, 36, reveal_all || current_player == 1 || winner != -1)
	draw_hand(0, H-CARD_H-36, reveal_all || current_player == 0 || winner != -1)

	// Winner banner.
	if winner != -1 {
		banner_y := f32(H/2 - 18)
		if winner == 0 {
			draw_rect(W/2-90, banner_y, 180, 36, 120, 220, 120)
		} else {
			draw_rect(W/2-90, banner_y, 180, 36, 120, 180, 255)
		}
		draw_outline(W/2-90, banner_y, 180, 36, 255, 255, 255)
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
		window_title = "Turn-Based Card Game Starter",
		logger = { func = slog.func },
	})
}
