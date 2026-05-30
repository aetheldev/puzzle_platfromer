# G07 — Time And Delta Time

## Goal

Understand why game time is measured in "seconds since last frame"
and why multiplying by delta time makes everything frame-rate independent.

---

## How The Web Handles Time

```js
// Precise timing
performance.now()  // milliseconds since page load

// Animation
requestAnimationFrame((timestamp) => {
  const dt = timestamp - lastTimestamp;
  // dt is milliseconds since last frame
});

// Delays
setTimeout(fn, 500);  // fire after 500ms
setInterval(fn, 1000); // fire every 1000ms
```

Web apps rarely think about frame rate. CSS animations and
requestAnimationFrame handle timing. React batches updates automatically.

---

## How Games Handle Time

Every frame, you ask: "how many seconds passed since the last frame?"

```odin
frame :: proc "c" () {
    dt := f32(sapp.frame_duration())  // typically ~0.0166 at 60fps
    player.x += speed * dt
}
```

`dt` (delta time) is the heart of game timing.

### Why multiply by dt?

Without dt:
```odin
player.x += 5   // move 5 pixels per frame
// At 60fps: 300 pixels/second
// At 30fps: 150 pixels/second  ← half speed!
// At 120fps: 600 pixels/second ← double speed!
```

With dt:
```odin
player.x += 300 * dt  // move 300 pixels per SECOND
// At 60fps:  300 * 0.0166 = ~5 pixels per frame
// At 30fps:  300 * 0.0333 = ~10 pixels per frame
// At 120fps: 300 * 0.0083 = ~2.5 pixels per frame
// Same speed regardless of frame rate!
```

**dt makes motion independent of frame rate.** A player moves the same
real-world speed whether the game runs at 30fps or 144fps.

---

## Common Time Patterns

### Timer countdown
```odin
// Instead of setTimeout:
burn_timer -= dt
if burn_timer <= 0 {
    stop_burning()
}
```

### Cooldown
```odin
attack_cooldown -= dt
if attack_cooldown <= 0 && attack_pressed {
    do_attack()
    attack_cooldown = 0.5  // 0.5 seconds
}
```

### Animation timing
```odin
anim_time += dt
if anim_time >= frame_duration {
    next_frame()
    anim_time = 0
}
```

### Lerp (smooth interpolation)
```odin
camera.x = lerp(camera.x, target_x, 8.0 * dt)
// Moves 8x the remaining distance per second
// Higher = snappier, lower = smoother
```

---

## Key Numbers

| Frame rate | dt (seconds) | dt (ms) |
|-----------|-------------|---------|
| 30 fps | 0.0333 | 33.3 ms |
| 60 fps | 0.0166 | 16.6 ms |
| 120 fps | 0.0083 | 8.3 ms |
| 144 fps | 0.0069 | 6.9 ms |

If your frame takes longer than dt, the game drops below target fps.

---

## Mental Model

**Web time:** A clock on the wall. Events happen at specific wall-clock
times. setTimeout says "ring in 5 seconds."

**Game time:** A speedometer on the assembly line. Each frame, you check
how fast the line is moving (dt). You scale all work by that speed.
Fast line = small dt = small steps. Slow line = big dt = big steps.
The product (speed * dt) stays constant.

---

## Exercises (Thinking, Not Coding)

1. A player moves at 200 pixels/second. The game runs at 30fps.
   How many pixels should the player move per frame? (answer: ~6.67)

2. You want a glow to pulse once per 2 seconds. Write the pseudocode
   using dt, not setTimeout.

3. Explain what happens to game speed on a slow computer if you do NOT
   use dt.

---

## Exit Criteria

- [ ] You can explain what dt is and why it matters
- [ ] You know the formula: `distance = speed * dt`
- [ ] You can implement timers using dt
- [ ] You understand lerp with dt for smooth following
- [ ] You know dt values for common frame rates

---

## Next Lesson

`g08_gpu_basics_for_web_devs`
