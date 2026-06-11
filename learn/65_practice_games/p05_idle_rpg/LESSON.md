# P05 — Idle RPG (console)

**Unlocks after:** `o19` (language track done). No graphics lessons
needed — that is the point. The o-track ALONE builds a real game.

## Goal

Pick a class (warrior / mage / rogue / priest). Hunt monsters that
scale with your level. Auto-battle. Loot drops with rarities. Equip
decisions. Numbers go up, the loop that powers half of Steam's
top-sellers.

```
==== IDLE RPG ====
A level 2 Goblin appears! (27 hp)
  CRIT! you hit Goblin for 18 (9 left)
  ...
Goblin slain! +50 xp
  DROP: [RARE] Chainmail (armor)  +4 hp +2 def
>>> LEVEL UP! Now level 2
```

## What You Are Combining (the whole o-track, on purpose)

| Piece | Lesson |
|---|---|
| `Stats`, `Item`, `Player`, `Monster` structs | o04 |
| `Class`, `Slot`, `Rarity` enums + exhaustive switches | o05 |
| `[dynamic]Item` inventory | o06 |
| pointer procs mutating the player | o07 |
| `[Class]Stats` base/growth tables, `[Rarity]f32` drop rates | o17 |
| `Maybe(Item)` equipment slots (empty or filled) | o18 |
| menu loop, battle loop | o12 |
| `rand` damage variance, drop rolls | o16 |
| `defer delete(inventory)` | o14 |

## Design Pillars (decide these BEFORE coding)

1. **Stats are a struct, classes are TABLES.** `BASE[class]` +
   `GROWTH[class]` enumerated arrays — adding a 5th class = two table
   rows, zero new code. Data-driven design, smallest possible dose.
2. **Gear is additive.** `total_stats(p) = base + sum(equipped
   bonuses)`. One proc. Everything reads total, nothing mutates base.
3. **Monsters scale FROM the player.** `player_level ± 1` keeps it
   tense forever with zero content authoring. (This is the idle-game
   trick.)
4. **Drops are a rarity roll, power = level × rarity multiplier.**
   One `roll_item` proc owns all loot math.

## Build Order (run after EVERY step)

1. Class selection menu + stat tables, print chosen stats
2. `spawn_monster` + one auto-battle (turn order by speed), win/lose print
3. XP + level-up loop (`while xp >= needed`)
4. Hunt = 5 fights; defeat ends the hunt early
5. Drop rolls + inventory listing
6. Equip menu with slot-swap (old item returns to inventory)
7. Class flavor: rogue crit chance, priest post-battle prayer, etc.

## Solution

`learn/95_solutions/practice_games/p05_idle_rpg/main.odin` (~330 lines)
Build steps 1-4 yourself first. Compare after.

Note its `read_line` proc: stdin reading with EOF handling — console
games need the `(value, ok)` pattern (o11) even for input.

## Stretch Goals

- Sell items for gold; gold buys potions (a `map[string]int` wallet — o17)
- Offline progress: save `kills` + timestamp to a file, simulate the
  gap on next launch (the actual "idle" in idle games)
- Combat log as `[dynamic]Combat_Event` union (o18) printed at hunt end
- A second monster TABLE per biome, unlocked by level

## About "selling drops on the Steam Market"

Real feature (Steamworks Inventory Service + Community Market), but it
requires a shipped Steam app, item server config, and Valve fees. The
GAME design underneath — items, rarities, drop tables — is exactly what
you build here. Park the market; build the loot.

## Done When

- [ ] All 4 classes play differently enough that you have a favorite
- [ ] An epic drop genuinely spikes your dopamine
- [ ] You can add a 5th class by editing only data tables
- [ ] You ran a 30-minute session voluntarily (the idle litmus test)
