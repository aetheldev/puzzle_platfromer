# A07 — Make It Move

Goal: idle + walk for the detective. Animation at this size =
surprisingly few frames. The repo's own `player.aseprite` has idle /
run / death — your reference and target format.

## Aseprite Animation Cockpit

- Timeline (bottom): frames as columns, layers as rows
- `Alt+N` new frame, `Alt+M` duplicate frame
- **Onion skin ON** (timeline burger menu) — see prev/next frames ghosted
- `Enter` = play, set FPS per frame (right-click frame header →
  Frame Properties → duration ms)
- **Tags:** right-click frame header → New Tag → name it `idle` /
  `walk`. Tags are what the export script (a10) and `sauce/` use!

## Idle: 2-4 Frames Of Breathing

The cheapest life-giving animation in games:

```
frame 1: base pose
frame 2: everything 1px DOWN, maybe coat 1px wider  (exhale)
(optional 3-4: 1px up = inhale top)
duration: 300-500ms per frame — slow!
```

Move the WHOLE body, not just the head. Select-all (`M`,
`Ctrl/Cmd+A`) → drag 1px down. Two frames already read as alive.

## Walk: The 4-Frame Cycle

Full walk = 8 frames. Game-sized sprites: 4 carries fine:

```
1: contact   (legs apart, left forward)
2: pass      (legs together, body 1px UP)
3: contact   (legs apart, RIGHT forward)
4: pass      (legs together, body 1px UP)
duration: ~120ms/frame
```

The 1px body bounce on pass frames = 80% of the walk feel. Arms:
opposite to legs, or hands-in-coat-pockets (detective! zero arm
animation, maximum mood — the pros' lazy trick).

## Principles That Matter At This Size

- **Squash & stretch, 1px version:** jump frame = 1px taller/narrower,
  land frame = 1px shorter/wider (you MET this in p03 breakout juice!)
- **Anticipation:** before a big action, 1-2 frames opposite direction
- **Secondary motion:** coat hem lags 1 frame behind body movement.
  One pixel of coat-flap on walk = disproportionate quality.

## Drills

1. Idle 2-frame on Detective A. Play. Then 4-frame version. Compare.
2. Walk 4-frame, side view. Onion skin throughout. Loop it for 30
   seconds and stare — fix the frame that "pops".
3. Tag both `idle` and `walk` in one file (player.aseprite format).
4. Study: open `asset_workbench/player.aseprite`, play its tags,
   step frame-by-frame. Steal one trick.
5. Stretch: 2-frame "inspect" animation (head tilts down 1px, hand
   up) — your detective examining a clue. Game-ready.

## Exit Criteria

- [ ] Idle loops without popping
- [ ] Walk has the pass-frame bounce
- [ ] File has named tags, repo format
- [ ] You can explain why hands-in-pockets is genius

## Next

`a08_tiles_that_repeat` — environments: the room around the detective.
