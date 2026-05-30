# T12 — Integration Room (The Bridge Lesson)

## Goal

Build ONE small playable thing that combines several mechanics you already
learned: a tilemap level, a player that moves and jumps with gravity, tile
collision, and a following camera. No new concepts. The only new skill is
**wiring things you already know into one program.**

This lesson exists because the jump from tiny single-mechanic lessons (t01–t11)
to a full game (`projects/sokoban`) is the place most beginners get stuck. This
is the missing step in the middle.

---

## Why This Lesson Is Different

Every lesson before this taught ONE thing and gave you a solution to read.
This lesson gives you NO new solution. That is on purpose.

A real game is not one mechanic. It is many small mechanics from different
lessons, glued together in one file, sharing one game state. Gluing is a
separate skill from learning each mechanic. You only get it by doing it.

So here you are the integrator. Your "solution" is the set of solutions you
already read:
- `learn/solutions/fundamentals/t03_movement/main.odin` (input + dt)
- `learn/solutions/fundamentals/t04_gravity_jump/main.odin` (gravity, jump)
- `learn/solutions/fundamentals/t07_tilemap/main.odin` (tile array, collision)
- `learn/solutions/fundamentals/t08_camera/main.odin` (camera follow, world vs screen)

You will pull pieces from each into ONE new `main.odin` in this folder.

---

## If You Know JS/React...

Imagine you built four small CodeSandbox demos: one for keyboard input, one
for a physics bouncing box, one for a CSS grid level, one for a scrolling
viewport. Each works alone.

Now a client says: "make them into one little game." Suddenly you have to
decide: one shared state object or four? What order do things update in? Who
owns the player position? That decision work — not the individual demos — is
the real job. This lesson is that job, in Odin.

---

## The Plan (do it in this exact order)

Do NOT write everything at once. Add one layer, run it, confirm it works, then
add the next. This is how real games are built and how you avoid a 300-line
file that crashes with no clue why.

### Layer 1 — Window + tilemap drawing
Start from your t07 understanding. Define one text level, parse it into a tile
array, draw each tile as a rectangle. Run it. You should see a static room.
No player yet.

```odin
LEVEL := []string{
    "############################",
    "#..........................#",
    "#.....###..................#",
    "#..............###.........#",
    "#..........................#",
    "#...###.............####...#",
    "#..........................#",
    "############################",
}
```

### Layer 2 — Player that moves left/right
Add a player struct (x, y, w, h, vx, vy). Pull the held-key pattern from t03.
Move left/right only for now. Ignore gravity. Run it. Player slides around.

### Layer 3 — Gravity + jump
Pull gravity and jump from t04. Apply gravity to vy every frame, jump on key
press. Run it. Player now falls. It will fall through the floor — that is
expected, you fix it next.

### Layer 4 — Tile collision
Pull the collision idea from t07: after moving, check player corners against
solid tiles, resolve X and Y separately. Run it. Player now lands on floors and
stops at walls. This is the hardest layer. Go slow.

### Layer 5 — Camera
Make the level wider than the screen (add columns to LEVEL). Pull camera follow
+ clamp + push/pop matrix from t08. Run it. Camera now tracks the player and
stops at level edges.

### Layer 6 — One goal tile
Add a goal tile type (`G`). When the player overlaps it, print `"Reached goal!"`
once. This is your win condition — the seed of every real game.

---

## Key Concepts (the integration-specific ones)

### One shared state, not four
In single lessons, globals were fine. Here, group related data so update order
is obvious:

```odin
Player :: struct { x, y, w, h, vx, vy: f32, on_ground: bool }
player: Player

tiles: [ROWS][COLS]u8
cam_x, cam_y: f32
```

### Fixed update order every frame
The bugs in integration almost always come from doing things in the wrong
order. Use this order and do not deviate until it works:

```
1. read input        -> sets vx, triggers jump
2. apply gravity      -> vy += GRAVITY * dt
3. move X, resolve X collision
4. move Y, resolve Y collision
5. update camera toward player
6. draw world (offset by camera)
7. draw HUD (no camera offset)
```

### Resolve X and Y in separate passes
This is the single most common integration bug. If you move both axes then
check collision once, the player catches on corners and sticks. Move X, fix X.
Then move Y, fix Y. Two passes.

---

## What Would Break If...

### You apply gravity AFTER moving instead of before?
Player reacts one frame late. Feels mushy and can tunnel through thin floors.

### You resolve X and Y together in one check?
Player snags on tile corners when running along a floor. Classic bug. Separate
the passes.

### You forget to set `on_ground` during Y collision?
Jump never works (or works infinitely in mid-air), because jump checks
`on_ground` and nothing ever sets it true.

### You draw the HUD inside the camera matrix?
The HUD scrolls away with the world. HUD must draw after `sgl.pop_matrix()`.

### You build all six layers before running once?
You get a pile of bugs with no way to tell which layer caused them. Always run
between layers.

---

## Exercises

### Exercise 1 — Get To Layer 4
Complete layers 1–4. A player that moves, jumps, and collides with a tilemap.
This alone is a huge milestone — it is a platformer engine.

### Exercise 2 — Add The Camera
Complete layer 5. Make the level wider than the window and watch the camera
follow.

### Exercise 3 — Add A Goal
Complete layer 6. Print a message when the player reaches the goal tile.

### Exercise 4 — Add A Hazard
Add a spike tile (`!`). Touching it resets the player to spawn. (You now have
lose AND win conditions — that is a complete game loop.)

### Exercise 5 — Design Your Own Room
Edit the LEVEL text into a room that is actually fun to traverse. A jump that
feels just barely reachable. This is level design — the real craft.

---

## Exit Criteria

- [ ] Player moves, jumps, and collides with tiles — all in ONE file
- [ ] You added the mechanics one layer at a time, running between each
- [ ] Camera follows the player and clamps to level bounds
- [ ] A goal tile triggers a win message
- [ ] You can explain your fixed update order and why order matters
- [ ] You can point to which earlier lesson each piece came from

If you can do all of the above, you have done the thing a full project needs.
You are ready for `projects/sokoban`.

---

## Why This Matters

Sokoban, the co-op puzzle, the card game, and every `sauce/` mode are all "many
mechanics sharing one state, updated in a fixed order, drawn through a camera."
You just did that at small scale. The projects are the same skill with more
rules. The cliff is gone.

---

## Next Lesson

`learn/projects/sokoban/LESSON.md`
