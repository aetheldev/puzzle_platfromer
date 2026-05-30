# G04 — No Async In The Game Loop

## Goal

Understand why games are synchronous, why there is no async/await or
Promises in the frame loop, and how this simplifies everything.

---

## How The Web Works

The web is built on asynchronous operations:

```js
// Network request
const data = await fetch("/api/levels");

// Timer
setTimeout(() => handleExplosion(), 500);

// File read
const text = await fs.readFile("level.txt");

// Animation frame (closest to game loop)
requestAnimationFrame(draw);
```

JavaScript has ONE thread for your code. The event loop lets async
operations happen "in the background" and resume your code when ready.
This is essential for web: you cannot freeze the browser while waiting
for a server response.

---

## How Games Work

A game frame must complete in ~16ms (for 60fps). Everything in the
frame happens synchronously, in order:

```
frame() {
    dt = get_delta_time()       // 1. measure time
    process_input()             // 2. read all input
    update_game(dt)             // 3. update all state
    draw_everything()           // 4. draw all visuals
    present()                   // 5. show on screen
}
// Total: must be < 16ms
```

There is no `await` anywhere in this loop. No Promises. No callbacks
that might fire later. Everything runs top-to-bottom, synchronously,
in one shot.

---

## Why No Async?

### 1. Timing must be exact
If physics waits for a network response, the game freezes. Players see
a stutter. In web, "loading..." spinners are normal. In games at 60fps,
any frame that takes too long is a visible stutter.

### 2. State must be consistent within a frame
If update() modifies player position, draw() must see the new position
in the SAME frame. If update was async and draw ran before it finished,
you would draw stale state.

### 3. Order matters
Input must happen before update. Update must happen before draw.
Async operations can resolve in any order. Game frames need strict order.

### 4. Simplicity
No race conditions. No callback hell. No Promise chains. No "what
state am I in when this resolves?" Just: read state, change state,
draw state.

---

## "But What About Loading?"

Asset loading (textures, sounds, levels) DOES take time. Games handle
this differently:

### Option 1: Load everything at startup
```odin
init :: proc "c" () {
    // Block here as long as needed
    load_all_textures()
    load_all_sounds()
    load_all_levels()
    // Player sees a loading screen
}
```

### Option 2: Loading state
```odin
frame :: proc "c" () {
    if game_state.loading {
        load_next_chunk()        // load a little bit each frame
        draw_loading_screen()
    } else {
        update_game()
        draw_game()
    }
}
```

### Option 3: Background thread (advanced)
Some engines load assets in a background thread. But the game loop
itself is still synchronous. It checks "is the asset ready?" each frame.

For your learning projects, Option 1 is perfectly fine. Load everything
in `init`.

---

## What About setTimeout / setInterval?

Games do not use timers. Instead, they use delta time:

```js
// Web approach
setTimeout(() => explode(), 500);
```

```odin
// Game approach
explosion_timer -= dt
if explosion_timer <= 0 {
    explode()
}
```

The game checks every frame: "has enough time passed?" This is more
precise and does not depend on a timer callback system.

---

## Mental Model

**Web:** A restaurant with waiters. You order (request), the waiter
goes to the kitchen (async), brings food later (callback). Meanwhile
you chat (other code runs). Orders can arrive in any order.

**Game:** A factory assembly line. Every 16ms, one unit moves through:
read → process → assemble → ship. Nothing waits. Nothing is out of
order. The line runs at constant speed. If one station is too slow,
the entire line slows down (frame drop).

---

## Exercises (Thinking, Not Coding)

1. Explain why `await fetch()` inside a game frame would freeze the
   game for hundreds of milliseconds.

2. A bomb should explode 2 seconds after being placed. In React, you
   would use setTimeout. In a game, how would you implement this?

3. Explain why race conditions are essentially impossible in a
   single-threaded synchronous game loop.

---

## Exit Criteria

- [ ] You understand why the game loop is synchronous
- [ ] You know there is no await/Promise in game frames
- [ ] You can explain timer-based delays using delta time
- [ ] You understand loading happens in init or loading state

---

## Next Lesson

`g05_pixels_not_divs`
