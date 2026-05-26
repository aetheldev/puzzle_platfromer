# T05 — Coyote Time And Jump Buffer

## Goal

Make jumping feel great with forgiveness timers. These are the tricks
that separate "this game feels clunky" from "this game feels amazing."

---

## The Concept

Two problems with raw jumping:

**Problem 1: Coyote time.**
Player walks off a ledge. Presses jump 2 frames later. Raw code says
"you are airborne, no jump allowed." Player feels cheated.

Fix: after leaving ground, allow jump for ~0.12 seconds. Named after
Wile E. Coyote running off a cliff and briefly standing on air.

**Problem 2: Jump buffer.**
Player presses jump 3 frames BEFORE landing. Raw code says "you are
airborne, no jump." Player lands and nothing happens. Feels unresponsive.

Fix: remember when jump was pressed. On landing, check if jump was
pressed recently (~0.12 seconds). If yes, jump immediately.

**Problem 3: Variable jump height.**
Tap vs hold space gives same height. Feels rigid.

Fix: when jump key is released mid-air, cut upward velocity. Short
taps = short jumps. Long holds = full height jumps.

---

## If You Know JS/React...

These are debounce/buffer patterns. In web dev:
```js
// Debounce: wait before acting
const debouncedSearch = debounce(search, 300);

// Buffer: remember action for later
let pendingAction = null;
setTimeout(() => { if (pendingAction) execute(pendingAction); }, 100);
```

Game feel timers are the same idea: buffer an action for a short window,
then execute when conditions are met.

---

## Key Concepts

### Coyote timer
```odin
// When player leaves ground (was_on_ground && !on_ground):
coyote_timer = COYOTE_TIME   // start countdown

// Each frame:
coyote_timer -= dt

// Jump check:
can_jump := on_ground || coyote_timer > 0
```

### Jump buffer
```odin
// On jump key press:
jump_buffer_timer = JUMP_BUFFER_TIME

// Each frame:
jump_buffer_timer -= dt

// Jump check:
if jump_buffer_timer > 0 && can_jump {
    do_jump()
    jump_buffer_timer = 0    // consume
    coyote_timer = 0         // consume
}
```

### Variable jump height
```odin
// On jump key RELEASE:
if vel_y < 0 {    // still rising
    vel_y *= 0.45  // cut upward speed
}
```

---

## Line-by-Line Breakdown

Open:
- `learn/solutions/fundamentals/t05_coyote_jump_buffer/main.odin`

### Lines 91-112: `event`
Jump buffer set on key-down. Variable height on key-up.

### Lines 123-205: `frame`
Timer decrements → jump check combines both timers → platform collision
→ coyote timer starts when leaving ground. Visual bars show timer state.

---

## How To Feel The Difference

1. Set both timers to 0. Try the game. Notice missed jumps.
2. Set `COYOTE_TIME = 0.12`. Walk off edges. Jump late. It works!
3. Set `JUMP_BUFFER_TIME = 0.12`. Press jump before landing. It buffers!
4. Hold vs tap jump key. Notice height difference.

These tiny numbers completely transform how the game feels.

---

## Exercises

### Exercise 1 — Add Both Timers
Implement coyote time and jump buffer in your T04 code.

### Exercise 2 — Zero Them Out
Set both to 0.0. Play. Feel the difference. Write down what changed.

### Exercise 3 — Extreme Values
Set both to 0.5 (half second). Play. Too forgiving? Find your sweet spot.

### Exercise 4 — Visual Feedback
Draw small colored bars showing remaining timer. Yellow for coyote,
cyan for jump buffer. Watch them shrink.

---

## Exit Criteria

- [ ] Coyote time lets you jump after leaving a ledge
- [ ] Jump buffer catches early presses before landing
- [ ] Variable jump height works (tap vs hold)
- [ ] You can explain why these timers improve game feel
- [ ] You can tune the values to your preference

---

## Next Lesson

`learn/fundamentals/t06_wall_jump`
