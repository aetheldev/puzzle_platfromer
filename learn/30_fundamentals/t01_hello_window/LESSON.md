# T01 — Hello Window

## Goal

Open a window, initialize the GPU, and clear the screen to a color
every frame. This is the foundation of every game in this repository.

---

## The Concept

Every game starts the same way:

1. Create a window
2. Initialize the graphics system (GPU)
3. Run a loop that clears and redraws the screen 60 times per second
4. Clean up when the window closes

In web dev, you never do this — the browser creates the window, manages
the GPU context, and handles the render loop. In game dev with Sokol,
YOU set all of this up.

---

## If You Know JS/React...

In React:
```jsx
function App() {
  return <div style={{ background: "#0a0d1a", width: "100vw", height: "100vh" }} />;
}
```

React creates a div with a background color. The browser handles
everything else: window, rendering, display.

In a game, the equivalent requires:
1. Telling the OS to create a window (Sokol does this)
2. Creating a GPU context (Metal on macOS, D3D11 on Windows)
3. Every frame: telling the GPU "clear to this color" then "present"

There is no browser. No DOM. No CSS. You talk to the GPU directly.

---

## What Happens Under The Hood

When you call `sapp.run(...)`, Sokol:
1. Creates a native window on your OS
2. Sets up a Metal (macOS) or D3D11 (Windows) graphics context
3. Starts calling your `init_cb` once
4. Then calls your `frame_cb` ~60 times per second
5. When the window closes, calls your `cleanup_cb`

This is the "app loop" — the heartbeat of every game. Your `frame` proc
IS the game. It runs until the player quits.

---

## Key Concepts

### `sapp.run()` — starts the app
Hands control to Sokol. Your code runs inside callbacks. You never
return to `main` until the app exits. This is like `ReactDOM.render()`
handing control to React's reconciler — except there is no virtual DOM,
just raw frame callbacks.

### `sg.setup()` — initializes the GPU
Must be called inside `init`. Creates the GPU device, allocates internal
buffers, sets up the render pipeline. Without this, no drawing is possible.

### `Pass_Action` — what happens at frame start
The pass action tells the GPU what to do when a new frame begins.
`.CLEAR` means "fill the entire screen with this color before any
drawing." Every frame starts clean.

### `sg.begin_pass() / sg.end_pass()` — one render frame
Everything between `begin_pass` and `end_pass` is one frame of rendering.
In this lesson, we only clear the screen. Later lessons add drawing.

### `sg.commit()` — present to screen
Tells the GPU: "I am done drawing. Show this frame on the monitor."
Without commit, nothing appears.

### The `"c"` calling convention
Sokol is a C library. When it calls your Odin procs, it uses C calling
conventions. That is why callbacks are `proc "c" ()`. And that is why
each callback starts with `context = rt_ctx` — to restore the Odin
context that C does not carry. (You learned this in o09.)

---

## Line-by-Line Breakdown

Open:
- `learn/95_solutions/fundamentals/t01_hello_window/main.odin`

### Lines 38-56: `init`
```odin
init :: proc "c" () {
    context = rt_ctx                    // restore Odin context (from o09)
    sg.setup({                          // initialize GPU
        environment = sglue.environment(),  // connect to window's GPU context
        logger = { func = slog.func },      // enable debug logging
    })
    pass_action = {                     // define what "clear screen" means
        colors = {
            0 = {
                load_action = .CLEAR,           // clear the color buffer
                clear_value = { r=0.05, g=0.08, b=0.18, a=1 },  // dark blue
            },
        },
    }
}
```

`sg.setup` is like `const gl = canvas.getContext("webgl")` but for
native GPU. `sglue.environment()` connects Sokol's app window to its
graphics system.

The `pass_action` is a struct describing what happens at the START of
each frame. `load_action = .CLEAR` means "fill with clear_value color."
The RGBA values are 0-1 floats, not 0-255 bytes.

### Lines 58-92: `frame`
```odin
frame :: proc "c" () {
    context = rt_ctx
    // update clear color pulse (optional)
    sg.begin_pass({ action = pass_action, swapchain = sglue.swapchain() })
    // (nothing drawn yet — just cleared)
    sg.end_pass()
    sg.commit()
}
```

`begin_pass` starts a render frame with the clear action.
`end_pass` finishes the frame's command recording.
`commit` sends the commands to the GPU and presents.

`sglue.swapchain()` tells Sokol to render to the window's display
surface. "Swapchain" is a GPU term for the set of buffers that alternate
between being drawn to and displayed.

### Lines 94-104: `main`
```odin
main :: proc() {
    rt_ctx = context    // save Odin context before C takes over
    sapp.run({
        init_cb    = init,
        frame_cb   = frame,
        cleanup_cb = cleanup,
        width      = 960,
        height     = 540,
        window_title = "T01 – Hello Window",
        logger     = { func = slog.func },
    })
}
```

`sapp.run` creates the window and starts the loop. The `_cb` fields
are callback procs — Sokol calls them at the right time.

`rt_ctx = context` saves the Odin context BEFORE `sapp.run` takes
over. This is why every callback can do `context = rt_ctx`.

---

## What Would Break If...

### You removed `sg.setup(...)`?
The GPU is not initialized. Any draw call crashes. Like trying to
use `gl.drawArrays()` before `getContext("webgl")`.

### You removed `sg.begin_pass(...)`?
No render frame starts. Nothing clears. GPU commands have no target.

### You removed `sg.commit()`?
Commands are recorded but never presented. Screen stays black or stale.

### You removed `context = rt_ctx` from init?
`sg.setup` internally uses `context` for allocation. Without valid
context, it crashes or allocates from garbage memory.

### You set clear color to `{1, 0, 0, 1}`?
Screen becomes bright red. RGBA (1,0,0,1) = full red, no green, no
blue, full opacity. Try it.

---

## Common Mistakes

1. **Expecting something to appear without drawing.**
   This lesson only clears. Nothing is drawn ON TOP of the clear color.
   T02 adds actual shapes.

2. **Forgetting `context = rt_ctx` in callbacks.**
   Crashes. Every `proc "c"` callback needs this.

3. **Using 0-255 color values instead of 0-1.**
   Clear color uses 0.0-1.0 floats. `255` would be wrong — it clamps
   to 1.0 but intent is unclear.

4. **Expecting the window to close cleanly without cleanup.**
   `cleanup` calls `sg.shutdown()`. Without it, GPU resources leak.

---

## Performance Note

Clearing the screen is nearly free on modern GPUs. The GPU fills all
pixels in parallel. Even at 4K resolution, a clear takes microseconds.

The expensive part is DRAWING things on top. This lesson has nothing to
draw, so it runs extremely fast. Later lessons add quads, textures,
and shaders — that is where performance begins to matter.

---

## Mental Model

Think of each frame as taking a fresh piece of paper:

1. `begin_pass(CLEAR)` — pick up clean paper (or paint over old one)
2. (later: draw things on the paper)
3. `end_pass()` — paper is done
4. `commit()` — hold up the paper for everyone to see

60 papers per second = smooth animation.

---

## Exercises

### Exercise 1 — Build And Run The Solution
Run `learn/95_solutions/fundamentals/t01_hello_window/build.sh`.
Verify a dark blue window appears.

### Exercise 2 — Write Your Own
Close the solution. Create `main.odin` in this folder.
Write the minimum: package, imports, init, frame, cleanup, main.
Clear to any color you choose. Run with `zsh build.sh`.

### Exercise 3 — Change The Color
Make the clear color change based on `sapp.frame_count()`.
Hint: use `f32(sapp.frame_count()) * 0.01` for a slowly changing value.

### Exercise 4 — Change Window Size
Modify width and height in `sapp.run`. Try 1280x720. Try 320x240.
Observe the window changes.

### Exercise 5 — Print Frame Count
Add `fmt.println("frame:", sapp.frame_count())` inside `frame` with
a gate: only print every 60 frames. Verify it prints once per second.

---

## Exit Criteria

- [x] Window opens and shows a clear color
- [x] You can explain what `sg.setup`, `begin_pass`, `end_pass`, `commit` do
- [x] You can explain why `context = rt_ctx` is needed
- [x] You can change the clear color
- [x] You can explain the init/frame/cleanup pattern
- [x] You can relate this to `g01_game_loop_vs_react`

---

## Why This Matters

This is the skeleton of every game. The init/frame/cleanup pattern
appears in every lesson from here onward. Every Sokoban frame, every
card game frame, every co-op puzzle frame starts with `begin_pass` and
ends with `commit`.

In `sauce/core_main.odin`, this same pattern runs the production game.
Understanding it here means understanding the entire repo's heartbeat.

---

## Next Lesson

`learn/30_fundamentals/t02_shapes_colors`
