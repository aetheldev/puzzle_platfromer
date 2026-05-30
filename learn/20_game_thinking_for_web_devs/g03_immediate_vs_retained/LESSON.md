# G03 — Immediate Mode vs Retained Mode

## Goal

Understand the two rendering philosophies, why web uses one and games
often use the other, and what this means for how you write draw code.

---

## Retained Mode (React, DOM, HTML)

The browser maintains a persistent scene graph — the DOM:

```html
<div id="player" style="left: 100px; top: 200px;">
  <span class="hp">100</span>
</div>
```

This element exists in memory between renders. When you change it:
```js
document.getElementById("player").style.left = "150px";
```

The browser updates just that one property. The rest of the DOM stays.
React automates this with virtual DOM diffing.

**Retained mode = the framework remembers what is on screen.**
You describe objects. The framework persists them. You modify them.
The framework updates only what changed.

---

## Immediate Mode (Games, sokol_gl, Dear ImGui)

The game does NOT maintain a scene graph. Every frame:

```
1. Clear screen (erase everything)
2. Draw background
3. Draw tiles
4. Draw player at current position
5. Draw enemies at current positions
6. Draw particles
7. Draw UI
8. Present to screen
```

Nothing persists between frames. If you do not draw the player in
frame 47, the player does not appear in frame 47. There is no
"player element" sitting in memory waiting to be patched.

**Immediate mode = you draw everything from scratch every frame.**
The renderer does not remember anything. You tell it what to draw,
it draws it, done. Next frame you tell it again.

---

## Why Games Use Immediate Mode

### 1. Everything moves
In a web page, most elements are static. A sidebar, a nav bar, text.
Updating 5 elements out of 500 makes sense — retained mode wins.

In a game, almost everything changes every frame: positions, animations,
particles, camera. Diffing what changed would be more work than just
redrawing everything.

### 2. Draw order matters
In CSS, z-index handles overlap. In a game, you draw back-to-front:
background first, then far objects, then near objects, then UI.

Immediate mode gives you exact control over draw order because YOU
decide when each thing is drawn.

### 3. Simpler mental model
No object lifecycle for visual elements. No "create sprite, update
sprite, destroy sprite." Just: if it should be visible this frame,
draw it. If not, do not draw it.

### 4. Performance
Modern GPUs are designed for this pattern. They are extremely fast at
drawing thousands of quads per frame. The bottleneck is rarely "too
many draw calls" for 2D games — it is bad data access patterns.

---

## What This Means For Your Code

### React pattern:
```jsx
// Create once, update properties
<Player x={player.x} y={player.y} />
// React remembers the Player element and patches it
```

### Game pattern:
```odin
// Every single frame:
draw_rect(player.x, player.y, player.w, player.h, 255, 200, 100)
// Nothing remembered. Next frame, draw again.
```

If you want a particle to appear for 0.5 seconds:
- React: create element, set timeout, remove element
- Game: draw it each frame while `life > 0`, stop drawing when `life <= 0`

If you want a health bar:
- React: `<div style={{width: health + '%'}}>`
- Game: `draw_rect(x, y, health_width, bar_height, r, g, b)` — every frame

---

## The Hybrid Reality

Some game systems mix both modes:
- **UI frameworks** (Dear ImGui) are immediate mode even for UI
- **Scene graphs** in 3D engines (Unity, Unreal) are retained mode
- **Sokol_gl** (what you use in fundamentals) is immediate mode
- **Sprite batching** in `sauce/core_render.odin` is immediate-ish:
  you submit draw commands each frame, the renderer batches and draws

For your puzzle game, immediate mode is the right starting point.

---

## Mental Model

**Retained mode (React):** You build a puppet theater with persistent
puppets. To move a puppet, you pull a string. The theater remembers
where each puppet is.

**Immediate mode (games):** You have a whiteboard. Every frame, you
erase it and redraw everything. No puppets. No strings. Just markers
and a fast hand.

---

## Exercises (Thinking, Not Coding)

1. In immediate mode, what happens if your draw code has a bug that
   skips drawing the player for one frame? (Answer: player flickers)

2. In retained mode, what happens if you forget to remove a DOM element?
   (Answer: it stays visible forever)

3. For a particle system with 200 particles, explain why immediate mode
   is simpler than retained mode.

---

## Exit Criteria

- [ ] You can explain retained vs immediate mode
- [ ] You understand why games prefer immediate mode
- [ ] You know that game draw code runs from scratch every frame
- [ ] You can map React's persistent components to game's per-frame draws

---

## Next Lesson

`g04_no_async_in_game_loop`
