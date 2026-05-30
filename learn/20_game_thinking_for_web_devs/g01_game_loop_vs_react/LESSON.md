# G01 — The Game Loop vs React's Render Cycle

## Goal

Understand the fundamental execution model difference between a web app
and a game.

---

## How React Works

React is **event-driven and lazy:**

```
1. App mounts → render once
2. Nothing happens (idle)
3. User clicks button → setState
4. React re-renders changed components
5. Nothing happens (idle)
6. Fetch resolves → setState
7. React re-renders again
8. Nothing happens (idle)
```

React only does work when something changes. Between events, the CPU
is essentially idle. The DOM persists — React patches it minimally.

You never write "draw the button." You declare what the button should
look like, and React figures out when to update the real DOM.

This is **retained mode** + **event-driven** + **declarative.**

---

## How A Game Works

A game is **frame-driven and eager:**

```
Frame 1:  read input → update state → draw everything → present
Frame 2:  read input → update state → draw everything → present
Frame 3:  read input → update state → draw everything → present
...
Frame 60: read input → update state → draw everything → present
(1 second has passed)
```

This loop runs 60 times per second (or more), every second, whether
or not anything changed. Even if the player is standing still, the
game redraws every pixel.

There is no "idle." There is no "only re-render when state changes."
The loop runs. Always.

---

## Why Constant Redrawing?

In a web app, the page can sit still. A news article does not move.

In a game:
- Animations play continuously
- Particles move every frame
- Physics simulates every frame
- Camera follows the player every frame
- Time passes even when the player does nothing
- AI thinks every frame
- Sound positions update every frame

Even "nothing happening" means: draw the world, check the clock,
update any ambient effects. The loop never stops.

---

## The Three Phases

Every game frame has three phases:

### 1. Input
Read what the player did since last frame. Keyboard, mouse, gamepad.
This is like `addEventListener` but polled every frame instead of
waiting for callbacks.

### 2. Update
Change game state based on input + rules + time. Move player, apply
gravity, check collisions, resolve puzzle logic, advance animations.

This is where your game logic lives. It is like `useReducer` dispatch
but happens automatically 60 times per second.

### 3. Draw
Render the entire visible world from scratch. Clear the screen. Draw
background. Draw tiles. Draw entities. Draw UI. Present to screen.

This is NOT like React's `return <JSX>`. There is no diffing. There is
no virtual DOM. You draw every pixel explicitly, every frame.

---

## In Code (Sokol)

```odin
init :: proc "c" () {
    // Setup GPU, load assets, create initial state
    // Runs ONCE at startup
}

frame :: proc "c" () {
    // Runs 60 times per second
    // 1. Read input (Sokol stores it for you)
    // 2. Update game state
    // 3. Draw everything
    // 4. Present (sg.commit)
}

cleanup :: proc "c" () {
    // Free resources at shutdown
    // Runs ONCE when window closes
}
```

Compare with React:

```jsx
function App() {
  // Runs when React decides to re-render
  // Declares what should appear
  // React handles when/how to update DOM
  return <div>...</div>;
}
```

The key difference: in React, the framework controls when your code
runs. In a game, YOUR code runs every frame, and you control everything.

---

## What This Means For You

### "setState" does not exist
You mutate game state directly: `player.x += speed * dt`.
There is no re-render trigger. The next frame will pick up the change
automatically because it reads the latest state.

### "Mounting" and "unmounting" do not exist
There is no component lifecycle. `init` runs once at startup.
`frame` runs forever. `cleanup` runs once at shutdown.

### "Side effects" are the main thing
In React, side effects are managed carefully with `useEffect`.
In a game, EVERYTHING is a side effect: moving the player, spawning
particles, playing sound. The entire update phase is side effects.

### Performance is always on your mind
React re-renders only changed components. A game redraws everything.
If your draw code is slow, every frame is slow. You cannot hide
behind virtual DOM optimization.

---

## Mental Model

**React:** You describe a poster. React prints it and hangs it on the
wall. When data changes, React prints a new poster and replaces only
the parts that differ.

**Game:** You have a whiteboard. 60 times per second, you erase the
entire whiteboard and redraw everything from scratch. If you can draw
fast enough, it looks smooth. If you are too slow, it stutters.

---

## Exercises (Thinking, Not Coding)

1. In your own words, explain why a game redraws every frame even when
   nothing changes.

2. List 3 things that happen in React only on state change, and explain
   why games do them every frame instead.

3. Draw a timeline of 5 game frames. For each frame, write what input,
   update, and draw would do if the player is walking right.

---

## Exit Criteria

- [ ] You can explain the init/frame/cleanup pattern
- [ ] You understand "frame-driven" vs "event-driven"
- [ ] You know why games redraw everything every frame
- [ ] You can map React concepts to game concepts

---

## Next Lesson

`g02_state_without_hooks`
