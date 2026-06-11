# P04 — Memory Match (Solo Flight — no solution)

**Unlocks after:** `t13 point and click`.

## Goal

4x4 grid of face-down cards (8 color pairs). Click two: match = they
stay revealed; miss = they flip back after a beat. Clear the board,
count your moves. **Secretly a detective game: revealing hidden
information IS the mechanic.**

## Spec

- 16 cards, 8 colors, shuffled at start (`rand.shuffle` on a slice)
- Card states: `hidden`, `revealed`, `matched` (an enum, o05 — and a
  state machine per card, exactly g02's "state without hooks")
- Click flow: first click reveals A; second click reveals B; if
  colors match → both `.matched`; else → flip both back to `.hidden`
- Move counter; win screen shows total moves; R restarts

## The One Hard Part (and the lesson inside it)

After a miss, the cards must stay revealed for ~0.6s so the player
SEES them — but the game must not freeze. You cannot `sleep`. You
need a tiny game-state machine:

```
Phase :: enum { waiting_first, waiting_second, showing_miss }
```

plus a countdown timer (`f32`, minus `dt`, like t05's coyote timer).
During `showing_miss` clicks are IGNORED until the timer fires the
flip-back. This pattern — "the game is in a phase, phases gate
input, timers move phases" — is the exact skeleton of every puzzle
interaction in your detective game (lock animations, door sequences,
partner-waiting states). Memory Match is the smallest game that
forces you to learn it.

## Hints

1. Cards as data: `[16]Card` where `Card :: struct { color: Color_Id,
   state: Card_State, rect: Rect }`. Build rects from grid math, t13 style.
2. Hit-testing: your t13 `point_in_rect`, verbatim.
3. Track `first_pick`/`second_pick` as indices (`int`), reset each round.
4. Shuffle: fill `[16]Color_Id` with pairs, `rand.shuffle(slice[:])`.

## Stretch

- Two players, alternating turns, score = pairs found (one mouse is
  FINE here — turn-based! Notice: turn-based sidesteps the
  one-mouse-two-players problem... until the network, doc 06.)
- Peek powerup: once per game, reveal everything for 1 second
- Card flip animation: scale x from 1 → 0 → 1 over 8 frames

## Done When

- [ ] Miss-delay works without freezing the game
- [ ] You drew the phase diagram on paper before coding it
- [ ] Win + move counter + restart all work
