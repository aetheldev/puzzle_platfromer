/*
TICKET 01 — Hello Window
========================
GOAL: Open a window using sokol_app and clear it to a color each frame.

CONCEPTS:
  - sapp.run()         : starts the app loop (init / frame / cleanup)
  - sg.setup()         : initialise the GPU
  - sg.begin_pass()    : start a render pass (clears the screen here)
  - sg.end_pass()      : finish the pass
  - sg.commit()        : present the frame
  - Pass_Action        : controls what happens at the start of a pass
                         (CLEAR = fill with a color)

TASKS FOR YOU:
  [x] Run it: `zsh build.sh` from this folder
  [x] Change the clear color to something you like
  [x] Make the color slowly change over time using sapp.frame_count()
  [x] Print something to the console every 60 frames

WHAT TO READ NEXT:
  - ../../sauce/sokol/app/app.odin  (all sapp procs / types)
  - ../../sauce/sokol/gfx/gfx.odin  (all sg procs / types)
*/

package t01

import sapp "../../../../sauce/sokol/app"
import sg   "../../../../sauce/sokol/gfx"
import sglue "../../../../sauce/sokol/glue"
import slog  "../../../../sauce/sokol/log"
import "core:fmt"

// Pass_Action tells sokol what to do at the start of each render pass.
// CLEAR means "fill the screen with clear_value before drawing anything".
pass_action: sg.Pass_Action

init :: proc "c" () {
    context = runtime_context

    // Boot sokol_gfx. We give it the environment (Metal on macOS) and a logger.
    sg.setup({
        environment = sglue.environment(),
        logger      = { func = slog.func },
    })

    // Set up the clear color: dark blue-ish
    pass_action = {
        colors = {
            0 = {
                load_action  = .CLEAR,
                clear_value  = { r = 0.05, g = 0.08, b = 0.18, a = 1 },
            },
        },
    }
}

frame :: proc "c" () {
    context = runtime_context

    // --- optional: pulse the clear color to show time passing ---
    t := f32(sapp.frame_count()) * 0.01
    pass_action.colors[0].clear_value.g = 0.08 + 0.04 * (0.5 + 0.5 * _sin(t))

    // Begin pass → clears screen with the color above
    sg.begin_pass({ action = pass_action, swapchain = sglue.swapchain() })
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

// Small helper — "c" procs can't use math package directly
@(private)
_sin :: proc(x: f32) -> f32 {
    // Taylor series sin, accurate enough for color pulsing
    x2 := x * x
    return x * (1 - x2/6 + x2*x2/120)
}

// We need a global Odin context because sokol callbacks are "c" procs
// (they don't carry the Odin context pointer automatically).
runtime_context: runtime.Context

main :: proc() {
    runtime_context = context  // capture before handing control to sokol

    sapp.run({
        init_cb    = init,
        frame_cb   = frame,
        cleanup_cb = cleanup,
        width      = 960,
        height     = 540,
        window_title = "T01 – Hello Window",
        icon       = { sokol_default = true },
        logger     = { func = slog.func },
    })
}

// Bring in the runtime package so we can name runtime.Context above.
import "base:runtime"
