# G06 — Input Every Frame

## Goal

Understand how game input works: polling key state every frame instead
of reacting to events asynchronously.

---

## How The Web Handles Input

```js
document.addEventListener("keydown", (e) => {
  if (e.key === "ArrowRight") moveRight();
});

document.addEventListener("keyup", (e) => {
  if (e.key === "ArrowRight") stopMoving();
});

button.addEventListener("click", () => attack());
```

Web input is **event-driven:** the browser fires events when things
happen. Your code reacts. Between events, nothing happens.

This works for web because interactions are discrete: click a button,
type in a field, scroll. There is no "hold the key for continuous
movement" in most web apps.

---

## How Games Handle Input

Games need to know what keys are held RIGHT NOW, not just when they
changed. The pattern:

```odin
// Store held state per key
key_left:  bool
key_right: bool
key_jump:  bool

// Event callback updates the state
event :: proc "c" (e: ^sapp.Event) {
    if e.type == .KEY_DOWN || e.type == .KEY_UP {
        held := e.type == .KEY_DOWN
        #partial switch e.key_code {
        case .LEFT:  key_left  = held
        case .RIGHT: key_right = held
        case .SPACE: key_jump  = held
        }
    }
}

// Frame reads the current state
frame :: proc "c" () {
    if key_right { player.x += speed * dt }
    if key_left  { player.x -= speed * dt }
    if key_jump  { try_jump() }
}
```

The event callback records what changed. The frame loop reads what
is currently held. This separation is key.

---

## Why Polling Instead Of Events?

### 1. Continuous actions
Holding "right" should move the player every frame, not fire one event.
Web's `keydown` fires repeatedly with auto-repeat delay. Games need
smooth, delta-time-based movement.

### 2. Input buffering
Game feel tricks like jump buffering need to know WHEN a key was pressed
relative to game state. Raw events plus a timer give you this control.

### 3. Multiple keys simultaneously
Diagonal movement = left+up held at same time. Event-driven code makes
this awkward. Polled state makes it simple: `if key_left && key_up`.

### 4. Input mapping
Games often map keys to actions: "attack" might be spacebar, left click,
or gamepad button A. Abstracting this is easier with polled state.

---

## Single-Frame Actions

Some actions should happen once per press, not every held frame:

```odin
// Jump should trigger once, not every frame while held
jump_pressed: bool  // single-frame flag

event :: proc "c" (e: ^sapp.Event) {
    if e.type == .KEY_DOWN {
        #partial switch e.key_code {
        case .SPACE: jump_pressed = true
        }
    }
}

frame :: proc "c" () {
    if jump_pressed && player.on_ground {
        player.vel_y = JUMP_VEL
    }
    jump_pressed = false  // consume the flag every frame
}
```

The flag is set on key-down and cleared every frame. This gives
exactly one frame of "just pressed" signal.

---

## Mental Model

**Web input:** A doorbell. When someone presses it, you hear it and
react. Between presses, silence.

**Game input:** Security cameras. Every frame you check every camera:
"Is left held? Is right held? Is jump held?" You make decisions based
on the current state of all cameras simultaneously.

---

## Exercises (Thinking, Not Coding)

1. Explain why `keydown` auto-repeat is bad for game movement.

2. Design an input state for a card game: what booleans would you need
   for left/right selection and card play?

3. Explain the difference between "jump held" and "jump just pressed"
   and why both are useful.

---

## Exit Criteria

- [ ] You understand event → state → poll pattern
- [ ] You know why games poll key state every frame
- [ ] You can design held-key booleans for multiple actions
- [ ] You understand single-frame vs continuous input

---

## Next Lesson

`g07_time_and_dt`
