# Game Thinking For Web Developers

## Who This Is For

You completed `learn/odin_for_js_devs/` (or already know Odin basics).
You understand JS/TS/React well.
You have never built a game.

## What This Track Teaches

The mental model shift from web development to game development.

This is NOT code-heavy. This is concept-heavy.
After these 8 lessons, the fundamentals code will make sense
because you will understand WHY games are structured the way they are.

## Why This Matters

Web dev and game dev look similar (both draw pixels on screen) but
think very differently:

| Web Dev | Game Dev |
|---------|----------|
| React re-renders when state changes | Game redraws everything every frame |
| DOM persists between renders | Nothing persists — you redraw from scratch |
| Event-driven (click, fetch, etc.) | Frame-driven (60 updates per second) |
| async/await everywhere | Synchronous frame loop |
| CSS positions elements | You calculate pixel positions manually |
| Virtual DOM diffs | No diffing — just draw |

If you jump into game code with web thinking, everything feels
backwards. These lessons fix that.

## Order

1. `g01_game_loop_vs_react`
2. `g02_state_without_hooks`
3. `g03_immediate_vs_retained`
4. `g04_no_async_in_game_loop`
5. `g05_pixels_not_divs`
6. `g06_input_every_frame`
7. `g07_time_and_dt`
8. `g08_gpu_basics_for_web_devs`

## How To Use

Read each `LESSON.md` in order. These are reading lessons, not coding
lessons. Take notes. Draw diagrams. Explain concepts to yourself.

After completing all 8, move to `learn/fundamentals/t01_hello_window`.

## No Solutions Folder

These lessons have no runnable code. They are pure concept building.
The "solutions" are the fundamentals lessons themselves — once you
understand the mental model, the code makes sense.
