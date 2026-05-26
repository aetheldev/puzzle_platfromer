# T03 — Movement And Delta Time

## Goal

Move a rectangle with keyboard input. Understand why delta time makes
movement frame-rate independent.

---

## The Concept

In g06 you learned that games poll input every frame. In g07 you
learned that delta time keeps speed consistent. Now you combine both:
read which keys are held, multiply movement speed by dt, update position.

This is the most fundamental game mechanic. Every genre needs it.

---

## If You Know JS/React...

In React, you might handle movement with events:
```jsx
const [x, setX] = useState(0);
useEffect(() => {
  const handle = (e) => {
    if (e.key === "ArrowRight") setX(prev => prev + 5);
  };
  window.addEventListener("keydown", handle);
  return () => window.removeEventListener("keydown", handle);
}, []);
```

Problems with this in a game:
- `keydown` auto-repeat has OS-controlled delay and rate
- Movement is tied to key-repeat, not frame timing
- No delta time = speed depends on repeat rate
- setState triggers React re-render (expensive for 60fps)

Game approach:
1. Store boolean per key (held or not)
2. In event callback: set boolean on keydown, clear on keyup
3. In frame: check booleans, move by `speed * dt`

---

## Key Concepts

### Held-key pattern
```odin
key_left, key_right, key_up, key_down: bool

event :: proc "c" (e: ^sapp.Event) {
    if e.type == .KEY_DOWN || e.type == .KEY_UP {
        held := e.type == .KEY_DOWN
        #partial switch e.key_code {
        case .A, .LEFT:  key_left  = held
        case .D, .RIGHT: key_right = held
        case .W, .UP:    key_up    = held
        case .S, .DOWN:  key_down  = held
        }
    }
}
```

Event sets/clears boolean. Frame reads boolean. Clean separation.

### Delta time movement
```odin
dt := f32(sapp.frame_duration())
if key_right { player.x += SPEED * dt }
```

`SPEED` is pixels per second. `dt` is seconds per frame. Product =
pixels this frame. Same real-world speed at any frame rate.

### Diagonal normalization
If both right and down are held, naive addition gives `sqrt(2)` speed
(~41% faster diagonally). Fix:
```odin
vx, vy: f32
if key_left  { vx -= 1 }
if key_right { vx += 1 }
if key_up    { vy -= 1 }
if key_down  { vy += 1 }
len := math.sqrt(vx*vx + vy*vy)
if len > 0 { vx /= len; vy /= len }
player.x += vx * SPEED * dt
player.y += vy * SPEED * dt
```

---

## Line-by-Line Breakdown

Open:
- `learn/solutions/fundamentals/t03_movement/main.odin`

### Lines 69-81: `event`
Records key state. Uses `#partial switch` because we only care about
a few keys — ignore rest. The `held` boolean flips on key-down/up.

### Lines 83-126: `frame`
Reads key booleans → builds velocity → normalizes → applies with dt →
draws player. Notice: movement and drawing happen every frame.

---

## What Would Break If...

### You removed `* dt`?
Movement depends on frame rate. 30fps = slow. 120fps = fast.

### You only handled KEY_DOWN, not KEY_UP?
Keys stay "held" forever. Player never stops moving.

### You used `switch` instead of `#partial switch`?
Compiler error: must handle ALL key codes (hundreds). `#partial`
ignores unhandled cases.

---

## Common Mistakes

1. **Tying movement to keydown events directly** — gives stuttery,
   auto-repeat-dependent movement.
2. **Forgetting dt** — movement speed varies with frame rate.
3. **Not normalizing diagonal** — diagonal is 41% faster.
4. **Forgetting KEY_UP** — keys stuck held.

---

## Exercises

### Exercise 1 — WASD Movement
Move a rectangle with WASD. Use delta time.

### Exercise 2 — Screen Clamping
Keep the player rectangle inside the window bounds.

### Exercise 3 — Sprint Key
Hold SHIFT to double movement speed.

### Exercise 4 — Normalize Diagonal
Implement diagonal normalization. Test: moving diagonally should feel
the same speed as moving horizontally.

---

## Exit Criteria

- [ ] Player moves with keyboard input
- [ ] Speed is consistent regardless of frame rate (dt works)
- [ ] You understand the held-key boolean pattern
- [ ] You can clamp position to screen bounds
- [ ] You relate this to g06 and g07

---

## Next Lesson

`learn/fundamentals/t04_gravity_jump`
