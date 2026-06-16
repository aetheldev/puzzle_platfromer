# P16 — Level Devil (NOT a Troll Game)

**Unlocks after:** `t08 camera`. Combines tilemap (t07), camera (t08),
input (t03), gravity/jump (t04-05), and AABB collision (t07).

But more than that — it teaches you **deceptive level design** as a
mechanic. The level tells you one thing and does another. Fake walls
you walk through. Ground that crumbles. Spikes that appear from
nowhere. Platforms that move. Every trap teaches the player something.

---

## What You Are Building

Level Devil is a platformer where the level is the enemy. Not monsters.
Not a timer. The tiles themselves lie to you.

| Mechanic | What it teaches | Where from |
|---|---|---|
| Multiple tile types | Tilemap with semantic types, not just solid/air | t07 |
| Tile constants | Clean enum-like design with byte values | o05 |
| Fake walls | Look solid, walk through — first deception | New |
| Crumble tiles | State machine per tile (solid → shake → gone → respawn) | New |
| Spike traps | Instant death, respawn at checkpoint | New |
| Trigger traps | Stepping on trigger activates remote spikes | New |
| Moving platforms | Physics beyond static tiles, platform riding | New |
| Level design | Designing rooms that teach through failure | New |

---

## The Core Idea

The game loop is the same one you have built 4 times now:

```
Input → Move X → Resolve X → Gravity → Move Y → Resolve Y → Draw
```

What changes is: **the tiles have behavior**. Some disappear when you
stand on them. Some kill you. Some activate other tiles. Some move.

Every new mechanic is just more logic between `Resolve Y` and `Draw`.

---

## Build Order (run after EVERY step)

### Step 1: Scaffold + tilemap (5 min)

Copy your t07 or t08 `build.sh` and `main.odin` skeleton:

- Window 960×540, tile size 40
- One `load_level()` that reads a string grid into `tiles[row][col]`
- Constants: `WALL = '#'`, `AIR = '.'`, `SPAWN = 'S'`
- `is_solid(col, row)` returns true for `WALL`
- Player: W×H = 24×36, gravity, jump, collision

Make the level small at first — maybe 30×10. Just get it running.

### Step 2: Fake walls (15 min)

Add a new tile type: `FAKE = 'F'`.

- **Rule:** Fake walls render EXACTLY like walls but `is_solid()` returns false.
- The player walks right through them.
- Visual tell: draw FAKE tiles 2 pixels inset with a slightly lighter shade.
  Just enough that AFTER learning the trick, the player can spot them.
  NOT enough to be obvious on first play. That is the design sweet spot.

```odin
case FAKE:
    draw_rect(x, y, TILE, TILE, 70, 75, 85)       // slightly lighter
    draw_rect(x+2, y+2, TILE-4, TILE-4, 90, 95, 105) // inner highlight
```

Test: place an `F` in a wall. Walk into it. You pass through. The
first time a player does this, they will laugh or curse. That is
Level Devil.

### Step 3: Spikes + death (20 min)

Add `SPIKE = '^'`.

- `is_spike(col, row)` checks for `SPIKE` tiles.
- After collision resolve, call `check_player_spike()`.
- Check all 4 corners of the player. If any corner is in a spike tile:
  - Set `dead = true`, start a 1-second death timer.
  - During death timer, skip all input/physics.
  - When timer hits 0, call `reset_game()` which sets player back to spawn.
- Draw spikes as red triangles (use `sgl.begin_triangles()`).

```odin
case SPIKE:
    cx := x + TILE/2
    sgl.begin_triangles()
    sgl.v2f_c4b(cx, y,      200, 40, 40, 255)
    sgl.v2f_c4b(x+4, y+TILE, 200, 40, 40, 255)
    sgl.v2f_c4b(x+TILE-4, y+TILE, 200, 40, 40, 255)
    sgl.end()
```

Test: place `^` under a platform. Jump on platform. Die. Press R.
Respawn. Works? Good. Now you have stakes.

### Step 4: Exit + win (10 min)

Add `EXIT = 'E'`.

- `check_player_exit()`: if player overlaps an EXIT tile, set `won = true`.
- When won: freeze all physics, draw a win indicator (golden box).
- Playing field: draw exit as gold/yellow so it is the only thing the
  player wants to reach.

```odin
case EXIT:
    draw_rect(x, y, TILE, TILE, 200, 180, 40)
    draw_rect(x+4, y+4, TILE-8, TILE-8, 240, 220, 80)
```

Place `E` on the right side of your level. You now have a complete
game: start → avoid spikes → reach exit. This is the bones.

### Step 5: Crumble tiles (40 min — the big one)

Add `CRUMB = 'C'`. This is your first **tile with state**.

Each CRUMB tile needs a timer that tracks its lifecycle:

```
solid (0) → player stands on → timer counts down → gone (-1)
  → respawn timer counts up → solid (0) again
```

Add a `crumble_state: [ROWS][COLS]f32` array parallel to your tile grid.
Zero means solid. Positive = crumbling countdown. -1 = gone.
Negative = respawning countdown.

In `resolve_crumble(dt)`:
1. Loop every tile. Skip non-CRUMB tiles.
2. If state is 0 and player overlaps the tile: start timer (`CRUMBLE_STAND_TIME`).
3. If state > 0: count down. When it hits 0, set to -1 (gone).
4. If state == -1: start respawn (`-CRUMBLE_RESPAWN_TIME`).
5. If state < 0: count up (toward 0). At 0, tile is back.

Update `is_solid()`: CRUMB is solid only when state >= 0.

Visual feedback:
- Solid: greenish stone (`100, 160, 80`)
- Crumbling (timer > 0): lighter green, slight shake with `math.sin(timer * 80) * 2`
- Gone: faint outline only

```odin
case CRUMB:
    s := crumble_state[row][col]
    if s < 0 {
        draw_rect(x+8, y+8, TILE-16, TILE-16, 40, 50, 30) // ghost
    } else if s > 0 {
        shake := math.sin(s * 80) * 2
        draw_rect(x+shake, y, TILE, TILE, 100, 140, 70) // shaking
    } else {
        draw_rect(x, y, TILE, TILE, 100, 160, 80) // solid
    }
```

Test: place `CCCC` bridging a gap over spikes. Walk across. Feel the
panic as it shakes. Fall. Try again. This is the heart of Level Devil.

### Step 6: Trigger traps (30 min)

Add `TRIG = 'T'`.

Trigger tiles sit on the ground. When the player walks over them,
spikes DROP FROM THE CEILING for a few seconds, then disappear.

Add a `trigger_state: [ROWS][COLS]f32` array. Positive = spike visible
(counting down).

In `check_player_trigger()`:
1. Check if the tile under the player's feet is TRIG and on_ground.
2. If yes: for the 3 columns centered on the trigger, set every cell
   above it to `TRIGGER_ACTIVE_TIME`.

In `update_triggers(dt)`: decrement every positive trigger_state.

In `is_spike()`: check both static `SPIKE` tiles AND active trigger spikes.

Draw trigger-activated spikes as downward-pointing red triangles
(same shape, inverted position — base at top, point at bottom).

```odin
if trigger_state[row][col] > 0 && tiles[row][col] != SPIKE {
    cx := x + TILE/2
    sgl.begin_triangles()
    sgl.v2f_c4b(cx, y+TILE,   200, 60, 60, 200)
    sgl.v2f_c4b(x+4, y,        200, 60, 60, 200)
    sgl.v2f_c4b(x+TILE-4, y,   200, 60, 60, 200)
    sgl.end()
}
```

Visual tell for the trigger tile itself: purple with a small arrow
pointing up. `TRIG` must be solid in `is_solid()`, otherwise player
falls through it. In this version spikes stop one row above the player:
walking is safe, jumping is death.

Test: place `TTT` on the floor with empty space above. Walk over it.
Spikes drop from ceiling but do not touch you. Jump while on purple:
die. Level taught rule: **purple = don't jump**.

### Step 7: Moving platforms (30 min)

Add `MOVE = '='`.

Moving platforms need per-platform data:
```odin
PlatformInfo :: struct {
    col, row, width: int,
    x, prev_x, y, offset: f32,
}
```

In `load_level()`, register only the FIRST tile of a `===` run.
If you register every `=`, you create 3 overlapping platforms and
movement looks like teleporting:
```odin
if ch == MOVE && (col == 0 || line[col-1] != u8(MOVE)) {
    width := 1
    for col+width < len(line) && line[col+width] == u8(MOVE) {
        width += 1
    }
    px := f32(col) * TILE
    py := f32(row) * TILE
    platforms[platform_count] = { col, row, width, px, px, py, 0 }
    platform_count += 1
}
```

Each frame, store old X, then move:
```odin
p.prev_x = p.x
p.offset += PLATFORM_SPEED * dt
p.x = f32(p.col) * TILE + math.sin(p.offset) * PLATFORM_RANGE
```

#### Platform riding (the hard part)

After vertical collision resolve, call `ride_moving_platforms()`:
1. For each moving platform, check if player is standing on it.
2. If yes: snap player Y to platform top, set on_ground, add platform
   velocity to player X.

```odin
ride_moving_platforms :: proc() {
    if dead || won || player.vel_y < 0 { return }
    for i in 0..<platform_count {
        p := platforms[i]
        pw := f32(p.width) * TILE
        if player.x + player.w > p.x && player.x < p.x + pw &&
           player.y + player.h >= p.y - 4 && player.y + player.h <= p.y + 16 {
            player.y = p.y - player.h
            player.vel_y = 0
            player.on_ground = true
            player.x += p.x - p.prev_x
            return
        }
    }
}
```

`p.x - p.prev_x` is platform velocity for this frame. Add it to player
so standing on platform feels attached, not slippery/teleporty.

### Step 8: Design the level (∞ time)

Now design a level that teaches each mechanic one at a time.

A good Level Devil level uses this structure:

```
Room 1 — Safe fall + crumble (cols 0-33)
  • Spawn at row 1. Fall to ground at row 11.
  • Run right. Crumble bridge (`CCCCCCCC`) over spike pit.
  • CRUMB tiles are solid green stone — until you stand on them.
  • 0.4 seconds later they shake and collapse. Run fast.
  • Below the gap: spikes (`^^`) at row 11.
  • Player learns: green ground is a liar. Move or die.

Room 2 — Trigger corridor (cols 34-55)
  • Purple trigger tiles (`TTT`) on the ground (now solid).
  • Walk over them → spikes DROP FROM THE CEILING (rows 0-8).
  • Spikes are above your head — safe if you stay on ground.
  • Jump while on trigger → you jump INTO the spikes → DEATH.
  • Player learns: purple = DON'T JUMP. Walk past calmly.

Room 3 — Moving platform pit + fake wall (cols 56-79)
  • Moving platform (`====`) sits one tile above a spike pit.
  • Jump FROM ground ONTO blue platform.
  • Ride it right, jump to far ledge.
  • Fake wall (`FF`) stands before exit. It looks solid, but is passable.
  • Exit (`E`) behind fake wall.
  • Player learns: trust blue block, distrust gray wall.
```

Put it all in one level string — every row exactly 80 characters:
```odin
LEVEL :=
`################################################################################
#.S............................................................................#
#..............................................................................#
#..............................................................................#
#..............................................................................#
#..............................................................................#
#..............................................................................#
#..............................................................................#
#..............................................................................#
#.....................................................................FF.......#
#.........................................................====........FFE......#
#################CCCCCCCC#########TTT######TTT##########...........#############
#################^^^^^^^^################################^^^^^^^^^^#############
################################################################################`
```

### Step 9: Polish

- **Progress bar:** A bar at the bottom that fills as you move right.
  Gives the player a sense of progress through the gauntlet.
- **Death flash:** Screen flash or big red rectangle when you die.
- **Win screen:** Pulsing gold rectangle when you reach the exit.
- **R restart:** Immediate reset with no delay.
- **Camera smoothness:** Use lerp for the camera (from t08).

---

## Design Principles for Level Devil

1. **Teach through death.** Every death should teach the player
   something new. If they die and don't learn, the level is unfair.
   If they die and learn, it is Level Devil.

2. **Visual tells are mandatory.** Every trap needs a clue:
   - Crumble tiles are green (normal floor is brown).
   - Trigger tiles are purple with an upward arrow.
   - Fake walls have a subtle inner border.
   - Moving platforms are blue.
   These tells should be visible but not obvious on first glance.
   On replay, the player feels smart for spotting them.

3. **One mechanic at a time.** Room 1 teaches fake walls. Room 2
   teaches crumble. Room 3 teaches triggers. Room 4 teaches moving
   platforms. Never combine two new mechanics in the same room.

4. **Fair respawn.** Instant respawn at the start. No load screens.
   No animation. Dead → 1 second → back. The player should be
   trying again within 1 second of dying.

5. **The "NOT a Troll Game" contract.** The game is honest about
   being dishonest. The level designer's job is to make the player
   say "oh you BASTARD" with a smile, not ragequit. If a trap feels
   impossible to predict, add a tell. If a trap is easy after the
   first death, it is perfectly tuned.

---

## Solution

Full solution: `learn/95_solutions/practice_games/p16_level_devil/main.odin`

Try to build through Step 6 (trigger traps) without looking. The
moving platforms in Step 7 are the hardest part — peek at the
solution for the platform-riding math if you get stuck more than
30 minutes.

---

## Stretch Goals

- **Screen shake on death** (from t10 — borrow the shake offset)
- **Coyote time + jump buffer** (from t05 — copy verbatim)
- **Multiple levels** — design 3 levels of increasing difficulty,
  cycle through them with R
- **Collectible coins** — scatter coins, track score, encourage
  risky detours
- **Moving crushers** — platforms that move VERTICALLY and kill on
  contact (smoosh from above)
- **Checkpoints** — after clearing a room, respawn at a mid-level
  checkpoint instead of the start
- **Fake spikes** — draw `^` that are actually safe (level lies
  about what kills you too)

## Done When

- [ ] You can name every tile type and its behavior
- [ ] A friend plays it, dies at least 5 times, but keeps trying
- [ ] You died to your OWN level at least once while testing
- [ ] The crumble tile panic feels real every time
- [ ] You have an idea for a room that would be even meaner
