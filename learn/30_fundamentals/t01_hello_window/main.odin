package t01_hello_window

import sapp "../../../sauce/sokol/app"
import sg "../../../sauce/sokol/gfx"
import sglue "../../../sauce/sokol/glue"
import slog "../../../sauce/sokol/log"

import "core:fmt"
import "core:math"
import "core:runtime"

pass_action: sg.Pass_Action
init :: proc "c" () {
	context = runtime_context
	sg.setup({environment = sglue.environment(), logger = {func = slog.func}})

	pass_action = {
		colors = {0 = {load_action = .CLEAR, clear_value = {r = 0.05, g = 0.08, b = 0.18, a = 1}}},
	}
}

frame :: proc "c" () {
	context = runtime_context

	t := f32(sapp.frame_count()) * 0.01
	pass_action.colors[0].clear_value.g = 0.08 + 0.04 * (0.5 + 0.5 * math.sin(t))

	// Begin pass → clears screen with the color above
	sg.begin_pass({action = pass_action, swapchain = sglue.swapchain()})
	// (nothing else drawn yet — that comes in T02)
	sg.end_pass()
	sg.commit()

	// Print frame number every 60 frames so you can see the loop ticking
	if sapp.frame_count() % 60 == 0 {
		fmt.println("frame:", sapp.frame_count())
	}

}

cleanup :: proc "c" () {
	context = runtime_context
	sg.shutdown()
}

runtime_context: runtime.Context

main :: proc() {
	runtime_context = context
	sapp.run(
		{
			init_cb = init,
			frame_cb = frame,
			cleanup_cb = cleanup,
			// width = 1280,
			// height = 720,
			width = 960,
			height = 540,
			// width = 320,
			// height = 240,
			window_title = "T01 – Hello Window",
			icon = {sokol_default = true},
			logger = {func = slog.func},
		},
	)
}

