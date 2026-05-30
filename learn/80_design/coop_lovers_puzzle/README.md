# Two Lovers — Co-op Puzzle Game (Your Game)

This folder is for YOUR game idea. It is a living design doc. Edit it freely.

> The fastest way to never finish a game is to design forever. This doc exists
> so you can stop holding the idea in your head and start building the smallest
> version. Read it, then go build "Milestone 1" in this same repo's learning
> lessons.

---

## The Pitch (one paragraph)

Two lovers are separated. Each is trapped in their own side of the same place.
They cannot reach each other directly. Each one can see things the other cannot
and can do things the other cannot — pull a lever, see a key pattern, walk a
path. By talking to each other ("I see three red symbols: circle, square,
circle" / "there's a lever on my left, pull yours now") they open each other's
doors and solve the room. They progress together or not at all. The story is
them working back toward each other.

This is a real, loved genre. Closest references: **We Were Here**, **It Takes
Two**, **Keep Talking and Nobody Explodes**. See `learn/03_RESOURCES.md` section 4.

---

## The One Rule That Makes It Work

**Each player has information OR ability the other lacks.**

If both players see the same thing and do the same thing, it is not co-op — it
is two people playing solo next to each other. The magic is the gap. Protect
the gap. Examples of gaps:

- Player A sees the symbols on a lock; Player B stands at the lock and enters them.
- Player A can pull levers; Player B can walk through the doors those levers open.
- Player A sees the safe path; Player B is the one who has to walk it (blind).
- Player A sees the room in "day", Player B sees the same room in "night" with
  different platforms visible.

---

## Two Ways To Build The "Different View"

You described "different view in same room". There are two technical approaches.
Pick ONE for your first version. They are very different in difficulty.

### Approach A — Same screen, asymmetric ABILITY (EASY — start here)
Both players see the whole room on one screen. The asymmetry is in what each can
*do* and *touch*, not in what they *see*.
- Red lover can stand on red platforms, pull red levers.
- Blue lover can stand on blue platforms, pull blue levers.
- A door opens only when both correct levers are pulled.
- This is EXACTLY what the repo's existing co-op prototype teaches. You already
  have a starting point: `learn/70_co_op/different_views_puzzle/`.

### Approach B — Two views / split screen, asymmetric INFORMATION (HARDER)
Each player sees only their own half (split screen, or each sees a different
"layer" of the same room). One sees a clue the other needs.
- This needs: two cameras OR two render regions, and a rule for what each player
  can see.
- Powerful (this is the We Were Here feeling) but more rendering work.
- Do this in version 2, after Approach A works.

**Recommendation:** Build Approach A first. Get the *feeling* of "we solved this
together" working with the simplest tech. Add split view later.

---

## Core Loop (what a player does, second to second)

1. Look at your side. Notice what you can see/do that your partner can't.
2. Tell your partner what you see ("I have a lever and three symbols").
3. Listen to what they need ("I need the symbol order to open my door").
4. Act in sync (you pull, they walk through).
5. Both reach the meeting point / next door -> room solved -> next room.

Win = both lovers reach the shared exit (or finally reunite at the end).

---

## Minimal Data Model (version 1, Approach A)

Reuse everything from the tilemap + co-op lessons. Add a "lover" flavor.

```
Tile :: enum {
    empty,
    wall,
    floor_red,    // only the red lover can stand here
    floor_blue,   // only the blue lover can stand here
    lever_red,    // only red can pull
    lever_blue,   // only blue can pull
    door,         // opens when its required levers are pulled
    clue,         // shows a symbol/pattern (info gap)
    exit,         // both must reach to win
}

Lover :: struct {
    x, y: f32,
    w, h: f32,
    vx, vy: f32,
    is_red: bool,   // controls which tiles/levers they can use
}

red:  Lover     // player 1 (WASD)
blue: Lover     // player 2 (arrow keys)

levers_pulled: bit_set[...]   // which levers are currently active
door_open: bool
```

Collision rule (the heart of the asymmetry):
```
red  collides with: wall, floor_blue   (cannot stand on blue floor)
blue collides with: wall, floor_red    (cannot stand on red floor)
both collide with: door (unless door_open)
```

---

## Milestones (build in THIS order — do not skip)

Each milestone is playable. That is the rule. Never build for a week with
nothing to play.

### Milestone 1 — Two lovers move in one room (NO puzzle yet)
- Load a tilemap room (you learned this in `t07`).
- Two players, two control schemes (WASD + arrows). (`co_op` prototype.)
- Both collide with walls.
- DONE LOOKS LIKE: two squares move independently in a walled room.

### Milestone 2 — The ability gap
- Add red floors and blue floors.
- Red can't stand on blue, blue can't stand on red.
- DONE LOOKS LIKE: each lover is fenced into parts of the room the other can't enter.

### Milestone 3 — Levers and one shared door
- Add a red lever and a blue lever.
- Door opens only when both are pulled.
- DONE LOOKS LIKE: red pulls their lever, blue pulls theirs, the shared door opens.

### Milestone 4 — The information gap (the "lovers" magic)
- Add a clue only ONE lover can see (e.g. a 3-symbol pattern on red's side).
- Add a lock the OTHER lover operates, that needs that pattern.
- DONE LOOKS LIKE: red must read the pattern out loud; blue enters it. Neither
  can solve it alone. THIS is your game's soul. Get this feeling right.

### Milestone 5 — A second room + an exit
- Solving room 1 opens the path to room 2.
- Both lovers must reach a shared exit to "win".
- DONE LOOKS LIKE: a tiny 2-room campaign you can finish with a friend.

### Milestone 6 (optional, version 2) — Split / different view
- Give each lover their own camera or visible layer.
- Now the information gap is enforced by the rendering, not just trust.

### Milestone 7 (LAST, big) — Online rooms / remote co-op
- Create a room, host it, friend connects over the internet.
- This is a whole project on its own. Do NOT attempt until Milestones 1-5 are
  done and the game is fun on one keyboard.
- One thing to do EARLY that makes this much easier: structure player input as an
  "intent" instead of reading the keyboard directly in gameplay. Doing this from
  Milestone 1 turns networking into a port instead of a rewrite.
- Full guidance: `learn/85_networking/` (reality check, concepts, the input
  pattern, Steam path, raw-sockets path).

Stop after Milestone 5 for your first finished thing. Milestone 6 is polish.
Milestone 7 (networking) is a separate project — see the warning below.

---

## Story / Theme Notes (keep light at first)

- Theme: separation and reunion. Two lovers pulled apart, working back together.
- You do NOT need story to start. Build the mechanic first (Milestones 1-5).
- Add theme later with: color palette, a title screen, a short reunion at the end.
- Resist writing a big story before the puzzle is fun. Fun first, feels second.

---

## Design Warnings (learned from the genre)

1. **Do not let one player solve a room alone.** If they can, the gap is broken.
2. **Do not make both players do the identical task.** That is not co-op.
3. **Keep room 1 trivially easy.** It should teach "we must talk" in 30 seconds.
4. **Test with a real second person early.** Co-op design bugs only show with two
   humans. A room that is clear to you (you know both sides) may be impossible
   for two people who each see only one side.
5. **One mechanic per room at first.** Introduce lever-gap, THEN info-gap, THEN
   combine. Do not stack three new ideas in one room.
6. **Networking is NOT part of the first game.** "Online rooms" is a real goal,
   but it is the LAST layer, built after the local game is fun and playtested. The
   #1 way solo multiplayer games die is bolting on networking too early. Local
   first. See `learn/85_networking/01_networking_reality_check.md`.

### The ONE networking-shaped thing to do early
Even though networking comes last, do this from Milestone 1: make gameplay read a
`Player_Intent` (move + verbs), not the keyboard directly. Filling that intent
from local keys now, or from the network later, becomes a swappable detail. This
single habit makes adding online play a port, not a rewrite. Details:
`learn/85_networking/03_input_for_networked_coop.md`.

---

## Where To Build It

See `learn/80_design/coop_lovers_puzzle/BUILD_PATH.md` for two concrete paths:
- building it inside THIS repo (recommended — you get the boilerplate)
- building it WITHOUT this repo (from scratch, if you ever want to)

---

## Your Next Action

Do not design more right now. Do this:
1. Finish the fundamentals up through `t12_integration_room`.
2. Do the co-op prototype lesson: `learn/70_co_op/different_views_puzzle/prototype/`.
3. Then come back and build Milestone 1 above.

That is the whole plan. The idea is good. Go make the smallest version real.
