# P09 — Idle Auto-Battler (numbers must be SEEN)

**Unlocks after:** p06 + t10 — p05's combat math + p06's glanceable UI
+ t10's juice = a real screen-filling idle game.

## Goal

A full-window (960x540) idle auto-battler. Your hero stands on the
left and fights an endless parade of monsters on the right, all by
itself: lunge, hit, recoil, repeat. Monsters die, burst into particles
and coins, the coins FLY to your gold counter, the next wave walks in
stronger. Every 10th wave is a BOSS. Gold buys three upgrades. There
is no fail state: dying sets you back a few waves and the hero gets
back up.

The mechanical core is p05/p06 again — so what is new? The LESSON:
**idle games live or die on feedback.** In p06 a hit was a color swap
and a number changing in place. Here, NOTHING is allowed to change
silently. Damage becomes floating text. A hit becomes a white flash
plus an impact burst. A crit becomes a bigger, gold-colored number and
a tiny screen shake. A kill becomes a particle explosion and coins
that physically travel to the counter — which only ticks up when they
land. Same math as before; completely different game to watch.

## What You Are Combining

| Piece | From |
|---|---|
| scaling combat math, crits, geometric costs | p05 |
| glanceable HUD, hit flashes, buttons, hover/dim states | p06 + t13 |
| particle pool + lifetime + screen shake | t10 |
| attack-beat timers | p01 |
| rect-art everything (fighters, icons, digits) | t02 |
| `[Upgrade]f32` cost table, `[Upgrade]Rect` button table | o17 |
| crit rolls, damage variance, coin scatter | o16 |
| NEW-ish: 7-segment digits — numbers drawn from 7 rects and a `bit_set[Seg]` table per digit. p06 used sdtx text; here we go full no-text-module as a constraint exercise. It is just t02 rects + an o17-style table. |

## Design Pillars (decide these BEFORE coding)

1. **One source of truth for combat math.** `dps = damage * speed`,
   period. `hero_damage()`, `hero_attack_rate()`, `hero_dps()` are THE
   procs; the DPS readout calls `hero_dps()`, the strike code calls
   `hero_damage()`. The UI reads, it never computes its own version —
   the moment two places compute dps, they will disagree.
2. **Feedback pools are all ONE pattern.** Damage numbers, impact
   particles, hit flashes, flying coins: every one is `fixed array +
   active flag + life timer` (t10). Four costumes, one idea, zero
   per-frame allocation.
3. **The coin IS the transaction.** Gold does not increment on kill.
   It increments when a coin lands on the counter, with a pulse. The
   feedback is not decoration on top of the state change — it IS the
   presentation of the state change. (Watch how much this one rule
   does for the feel.)
4. **No fail state.** Hero death = wave setback + revive countdown.
   Idle games forgive; punishment is lost time, never lost progress.
5. **Costs are geometric.** `cost = base * 1.15^level` — one proc,
   every button. The 1.15 is the genre's standard magic number.

## Build Order (run after EVERY step)

1. Static scene: ground, rect-art hero left, monster right, panel band
2. Auto-attack timers + lunge/recoil sine animation; apply damage at
   the lunge PEAK (not when the timer fires — feel the difference)
3. 7-segment digits: `bit_set[Seg]` table, `draw_digit`, then
   gold / wave / DPS readouts in a top bar
4. HP bars with the lagging white segment (a `hp_lag` that drains
   slowly toward `hp` — the white sliver is "what you just lost")
5. Floating damage numbers pool; crits 15% / 2x: bigger + gold color
6. Hit flash (0.08s white) + impact particle burst + tiny crit shake
7. Death: particle burst + coins that scatter, then ease toward the
   counter; gold += on arrival, counter pulses
8. Upgrade buttons: hover outline, unaffordable dimming, cost in
   7-seg, geometric pricing
9. Waves + boss every 10th (bigger, 4.5x hp, shake on its hits AND
   death, 5x gold); hero death -> setback + revive countdown
10. Idle polish: hero bob, background color breathing, R reset

## Solution

`learn/95_solutions/practice_games/p09_idle_autobattler/main.odin`
(~1030 lines). FULL SOLUTION exists — this one is big and the juice
ordering matters (what is shaken vs. screen-space, when damage lands
inside the animation). Build steps 1-6 yourself first; compare after.

Note the draw split in `frame`: world (ground, fighters, particles,
damage numbers) renders inside the shake matrix; coins, top bar and
panel render OUTSIDE it. Coins must fly to a counter that does not
move — shake the world, never the ledger.

## Stretch Goals

- **Prestige:** a button (unlocks at wave 50) that resets gold, waves
  and upgrades but grants a permanent +damage% multiplier. The genre's
  endgame loop, and a test of Pillar 1: it must touch ONE proc.
- **Offline progress:** on quit, write gold + wave + a timestamp to a
  file (`core:os`); on launch, compute elapsed seconds, simulate
  `elapsed * hero_dps()` worth of kills instantly, and SHOW the haul
  with a giant coin burst — feedback rules apply to offline gains too.
- **Multiple heroes:** turn `hero` into a small fixed array (warrior /
  archer back row); each gets its own attack timer and lunge. Watch
  Pillar 1 force the right design: per-hero damage procs, one shared
  dps readout summing them.
- **Background shader:** the solution does background "breathing" as a
  plain clear-color lerp — deliberately. If you want the s00-style
  hand-written fullscreen shader (gradient, vignette), keep it to one
  uniform (time) or it stops being an idle-game background and starts
  being a project.
- Health potion drops the hero auto-quaffs at low hp (a 4th feedback
  pool: green cross floats up)

## Done When

- [ ] You watched a boss wave start to finish without touching anything
- [ ] A crit is unmistakable from across the room (size, color, shake)
- [ ] You covered the gold NUMBER with your thumb and still knew you
      got paid (the coins + pulse carry it)
- [ ] Hero death reads as "setback", not "game over"
- [ ] You left it running through lunch and checking back felt good
