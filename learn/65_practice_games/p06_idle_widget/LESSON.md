# P06 — Idle Widget (tamagotchi mode)

**Unlocks after:** p05 idle RPG + t13 point and click. This is p05
wearing a body.

## Goal

A TINY window (340x460) you park in the corner of your screen while
you work. Inside it, your hero fights monsters BY ITSELF. You glance
over now and then: did it level up? what dropped? enough gold for an
upgrade? Hit PAUSE (button or SPACE) to manage calmly: left-click an
item to equip, RIGHT-CLICK to sell, buy from the shop (heal, +1 atk,
or a mystery BOX with a random item). Resume. Walk away again.

Everything is colored rects + retro text from **sokol debugtext
(sdtx)** — the bundled 8x8 pixel-font module. Real labels ("GOLD 123",
"RARE ARMOR +2 DEF"), zero font files, zero art.

## The Design Shift From p05 (this is the real lesson)

p05 was menu-driven: the game WAITED for you. A widget INVERTS that:

| p05 console | p06 widget |
|---|---|
| game waits for input | game runs on a tick timer (p01's!) |
| you read a combat log | you read HP bars + flashes |
| "press 2 for inventory" | inventory is always visible, click = equip |
| numbers scroll away in a log | numbers live at fixed spots: bars + labels |
| full attention | designed for the CORNER OF YOUR EYE |

That last row is a genuine game-design discipline: every state must be
readable in a half-second glance. Color does the work — rarity =
border color, danger = monster redness, affordable = button
brightness. This "glanceability" thinking is exactly what HUD design
in your detective game will need.

## What You Are Combining

- p05's game core: stats, scaling monsters, drops, rarity, gold
- p01's tick timer: combat beats every ~0.8s, not every frame
- t13's point-in-rect: inventory clicks, shop buttons, hover outlines
- o17 `[Rarity][3]u8` color tables, o18 `Maybe(Item)` equip slots
- NEW (tiny): `sokol/debugtext` — setup once, then
  `sdtx.pos(col, row); sdtx.printf("GOLD %d", gold)`. Note: pos is in
  8-pixel CHARACTER CELLS, not pixels (the solution wraps it in a
  pixel-based `text()` helper). Same module real games use for debug
  overlays — you will meet it again in `sauce/`.

## Build Order (run after EVERY step)

1. Small window + hero rect vs monster rect + HP bars
2. Tick timer + auto-combat (reuse p05 damage math) + hit flashes
3. Kill → gold/xp/level-up → respawn monster (scaled)
4. sdtx text: setup + canvas, label hero/monster, show LV + GOLD + KILLS
5. Drop rolls → auto-equip if slot empty, else inventory grid
6. Click inventory item → equip (slot swap, t13 hit-testing)
7. PAUSE: button + SPACE toggles `paused`; tick skipped while paused
   (so you can manage gear without the fight moving on)
8. Sell: RIGHT-click a bag item → gold += `sell_value` (one proc owns
   the pricing: stats + rarity)
9. Shop: HEAL (fixed cost) + ATK+1 (scaling cost) + BOX (buy a random
   item, better odds than drops); buttons dim when unaffordable
10. Defeat rule: lose 10% gold, full heal, continue (idle games forgive)

## Solution

`learn/95_solutions/practice_games/p06_idle_widget/main.odin` (~470 lines)
Steps 1-4 alone first. The sdtx setup is 1 line in `init`, 2 lines in
`frame` (canvas + origin), one `sdtx.draw()` inside the render pass.

## Item Rect-Art Cheat Sheet (used in the solution)

- border color = rarity (gray / blue / purple)
- inner shape = slot: tall blade = weapon, wide band = armor,
  small gem = trinket

You just designed an icon system with zero image files.

## Stretch Goals

- **Offline progress** — THE tamagotchi feature: on quit, save
  `kills/gold/level + timestamp` to a file (`core:os` write). On
  launch, compute elapsed time, simulate that many ticks instantly,
  show what happened. Suddenly closing the widget is not losing
  progress, and opening it is a present.
- Always-on-top: sokol has no API for it — macOS workaround is a
  one-line AppleScript or a window manager rule; or just park it.
- **Tiling WM users (AeroSpace etc.):** the WM will tile the widget to
  full size. `run_graphics.sh` names every lesson app `learn-<name>`,
  so one rule floats them all:
  ```toml
  [[on-window-detected]]
      if.app-name-regex-substring = 'learn-'
      run = 'layout floating'
  ```
- A second monster tier every 5 levels with a new color family
- Sound: a tiny "ding" on level-up (FMOD lives in `sauce/` — preview)
- Prestige: reset to level 1, keep a permanent +atk% multiplier
  (the idle-game endgame loop)

## Layout Discipline (the overlap lesson)

First version of this solution had labels colliding (GEAR slot names
ran into the BAG header). The fix is a rule worth keeping: **give every
UI band its own y-range and write the map down as a comment:**

```
arena 28..140 / xp+gold 152..196 / gear 208..288 / bag 296..398
info 402..414 / shop 422..452
```

Before adding any text, ask: which band does it live in? If it does
not fit its band, the band grows and everything below shifts — you
never nudge pixels blindly. This tiny discipline scales all the way to
real HUD work in `sauce/`.

## Done When

- [ ] It survives 10 minutes unattended and you came back to a surprise
- [ ] You can read your full status in a one-second glance
- [ ] You paused, sold the junk, bought a BOX, equipped the result, resumed
- [ ] No two texts overlap at any game state (level 1 and level 50)
- [ ] You added one stretch goal because you WANTED to
