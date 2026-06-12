# A02 — Pixels Have Rules

Goal: clean lines. This is 80% of "why does mine look amateur".
Good news for a non-artist: lines have RULES, not talent.

## Rule 1 — Jaggies Are The Enemy

A pixel line reads clean when its steps are CONSISTENT.

```
GOOD (1,1,1 steps):      BAD (jaggy — 1,2,1 steps):
. . . X                  . . . X
. . X .                  . . X .
. X . .                  X X . .
X . . .                  X . . .   <- double-step breaks rhythm
```

A 45° line = perfect stairs, 1 step each. A shallower line = steps of
2,2,2 or 3,3,3 — same length each. Mixed step lengths (2,1,3,2) =
jaggy = instantly amateur.

Drill: draw lines at all angles on 32x32. For each, write the step
pattern in your head ("2-2-2", "1-1-1"). Fix every inconsistency.

## Rule 2 — Curves Are Step Ramps

A circle = step lengths that RAMP: long flats at top/sides, tightening
to 1-1-1 at the 45° points.

```
16px circle quadrant steps: 4, 2, 1, 1, 1, 2, 4  (symmetric!)
```

Drill: hand-draw circles 8x8, 12x12, 16x16. Compare against the
ellipse tool's output (`U`) — study ITS step pattern, then redo by
hand. The tool knows the rules; learn from it.

## Rule 3 — Avoid Orphans And Doubles

- **Orphan pixel:** lone pixel touching a line diagonally → looks like
  noise. Delete or connect it.
- **Doubled line:** a 1px line that is 2px thick for one step → looks
  like a tumor. Pick one row.

Zoom to 100% after EVERY shape. Errors invisible at 800% scream at 100%.

## Rule 4 — Outlines: Decide And Commit

Three valid styles — pick ONE per project:
1. Full black outline (readable, cartoony — good for items/characters)
2. Selective outline (darker version of fill color — softer)
3. No outline (modern, needs strong contrast — harder)

Your detective game: start with style 1, switch to 2 when confident.

## Drills

1. 10 straight lines, all clean steps, all angles
2. 3 hand circles (8/12/16) matching tool output ±1px
3. Take `asset_workbench/player.aseprite`, zoom in, find where ITS
   lines use 1-1-1 vs 2-2-2 steps. Real sprites = open textbooks.
4. Draw a simple closed shape (leaf, drop, egg) with clean curve
   ramps + style-1 outline. Save it.

## Exit Criteria

- [ ] You SEE jaggies now (curse: everywhere, forever)
- [ ] Hand circle ≈ tool circle
- [ ] You can name the 3 outline styles and chose one

## Next

`a03_light_is_everything` — same shapes, now they look 3D.
