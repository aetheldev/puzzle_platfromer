# G02 — State Without Hooks

## Goal

Understand how game state works without useState, useReducer, Redux,
or any state management library.

---

## How React Manages State

```jsx
function Player() {
  const [x, setX] = useState(100);
  const [health, setHealth] = useState(100);

  const move = () => setX(prev => prev + 5);
  const damage = () => setHealth(prev => prev - 10);

  return <div style={{ left: x }}>HP: {health}</div>;
}
```

React state:
- Lives inside component closures
- Triggers re-render when changed
- Is immutable from the component's perspective (new value = new render)
- Can be shared via context, Redux, Zustand, etc.
- Component tree determines state hierarchy

---

## How Games Manage State

```odin
Game_State :: struct {
    player_x:    f32,
    player_y:    f32,
    health:      i32,
    score:       i32,
    level:       int,
    entities:    [MAX_ENTITIES]Entity,
    tiles:       [ROWS][COLS]Tile,
    camera_x:    f32,
    camera_y:    f32,
}

gs: Game_State
```

Game state:
- Lives in a plain struct (or a few global/scoped variables)
- Is mutated directly: `gs.player_x += speed * dt`
- Does NOT trigger anything — the next frame reads the new values
- No re-render. No diffing. No subscriber notifications.
- The entire game state is one big struct (or a few related structs)

---

## Why This Is Simpler Than It Sounds

In React, state management is complex because:
- Components are isolated — sharing state requires lifting, context, or stores
- Re-renders must be minimized — wrong state placement causes performance issues
- Immutability must be maintained — `setState(prev => ({...prev, x: 5}))` patterns
- Async state updates add complexity

In a game:
- All state is in one place
- The frame loop reads ALL state every frame anyway
- No re-render optimization needed — you always draw everything
- Direct mutation: `gs.health -= 10` — done
- No immutability requirement
- No subscription model

---

## The Pattern

```
init:   create Game_State with starting values
frame:  read Game_State → compute changes → write back to Game_State → draw from Game_State
```

That is the entire state management system. No library. No pattern.
Just a struct and direct reads/writes.

---

## Where State Lives In This Repo

In `sauce/game.odin`:
```odin
Game_State :: struct {
    ticks: u64,
    entities: [MAX_ENTITIES]Entity,
    free_list: [dynamic]int,
    player: Entity_Handle,
    cam_pos: Vec2,
    // ... game-specific fields
}
```

One struct. All game state. Read and written every frame.

---

## Common Confusion From React Developers

### "When does the UI update?"
Every frame. Always. There is no "trigger." The draw phase reads
the latest state and draws it. If health went from 100 to 90, the
next frame draws 90. No notification needed.

### "How do I share state between components?"
There are no components. Everything reads from the same Game_State.
The player update reads `gs.player_x`. The camera update reads
`gs.player_x`. The draw reads `gs.player_x`. Same data. No props.

### "How do I avoid unnecessary re-renders?"
You do not. Everything redraws every frame. The question becomes:
"how do I draw fast?" not "how do I avoid drawing?"

### "How do I handle async state updates?"
You do not have async state updates. Everything happens synchronously
within the frame. If you load a file, you block or use a loading state
flag — not a Promise.

---

## Mental Model

**React state:** Many small labeled boxes in different rooms (components).
To share, you carry copies between rooms or use a messenger service
(context/Redux). Changing a box triggers an announcement (re-render).

**Game state:** One big table in the center of one room. Everyone sits
around it. Everyone can see and touch everything. 60 times per second,
everyone looks at the table and does their job.

---

## Exercises (Thinking, Not Coding)

1. Design a `Game_State` struct for a Sokoban game. What fields would
   it need? (tiles, player position, box positions, move count, won)

2. In React, how would you share player position between a HUD component
   and a minimap component? In a game, how does the same sharing work?

3. Explain why direct mutation (`gs.health -= 10`) is safe in a game
   but dangerous in React.

---

## Exit Criteria

- [ ] You understand game state as a plain struct
- [ ] You understand direct mutation instead of setState
- [ ] You know why no re-render trigger is needed
- [ ] You can design a simple Game_State for a puzzle game

---

## Next Lesson

`g03_immediate_vs_retained`
