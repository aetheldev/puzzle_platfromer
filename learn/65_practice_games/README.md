# Practice Games — Confidence Ladder

Small complete games, ordered by what you have already learned. Each
one unlocks at a specific lesson: when you pass that lesson, you are
READY to build that game. No new concepts — only combinations of
things you know. That is the point: proving to yourself you can.

> Rule: a practice game counts as DONE when a friend can play it
> without you explaining the controls.

## The Ladder

| # | Game | Unlocks after | You will combine | Solution? |
|---|------|---------------|------------------|-----------|
| p01 | **Snake** | `t07 tilemap` | grid, input, dynamic array body, rand food, game over | YES — full solution |
| p02 | **Pong** | `t03 movement` | input x2 (FIRST two-player code!), AABB bounce, score | NO — solo flight |
| p03 | **Breakout** | `t10 particles` | pong skills + brick grid + juice (shake, particles) | NO — solo flight |
| p04 | **Memory Match** | `t13 point and click` | hit-testing, hidden state, turn logic | NO — solo flight |
| p05 | **Idle RPG** | `o19 (language track done)` | the WHOLE o-track: structs, enums, unions, maps, bit_sets, rand — no graphics needed | YES — full solution |
| p06 | **Idle Widget** | `p05 + t13` | p05 in a tiny corner-of-screen window: auto-combat, rect-art items, 7-segment digits, click-to-equip/shop | YES — full solution |
| p16 | **Level Devil** | `t08 camera` | fake walls, crumble tiles, spike traps, trigger traps, moving platforms, deceptive level design | YES — full solution |

Three have solutions (p01 to show the shape, p05 because it is big,
p16 because moving platform math is slippery). Two deliberately have
NONE. "Solo flight" means: you have flown with an instructor eleven
times; this plane you fly alone. Getting
stuck and unsticking YOURSELF is the confidence mechanic. If truly
stuck >1 day, the ATTEMPT/REVIEW templates in `learn/templates/`
exist.

## Why These Five

- **p01 Snake** — the classic first game for a reason: complete game
  loop, lose condition, score, infinite difficulty curve, ~200 lines.
- **p02 Pong** — your first two-player input code. The WASD/arrows
  split here is literally the seed of your co-op detective game.
- **p03 Breakout** — teaches the difference juice makes. Build it
  plain, then add shake + particles, feel the gap.
- **p04 Memory Match** — point-and-click + hidden state + turns.
  Secretly a tiny detective game: revealing information is the
  mechanic.
- **p05 Idle RPG** — the one you asked for: pick a class (mage,
  rogue, warrior, priest), monsters scale with your level, loot
  drops, equip decisions. Console only, zero graphics — proves the
  o-track alone can build a real game. (Steam Market for drops is a
  Steamworks economy feature — real, but years away; park it.)
- **p16 Level Devil** — platformer where the level lies to you.
  Fake walls, crumble floors, trigger spikes, moving platforms.
  Teaches tile state machines, trigger systems, and the art of
  teaching the player through death.

- **p06 Idle Widget** — p05 grown a body: a tamagotchi-sized window
  you park in a screen corner while you work. Auto-combat with HP
  bars and hit flashes, items as rect-art (rarity = border color),
  numbers as 7-segment displays, click to equip and shop. Teaches
  "glanceable" UI design — every state readable in half a second.

## Where These Fit In The Main Path

These are SIDE QUESTS. The main path (MASTER_TICKET_LIST) does not
require them. Insert them when motivation dips or after their unlock
lesson when you want to consolidate. Recommended natural points:

```
after t07  -> p01 snake          (1-2 evenings)
after t10  -> p03 breakout       (2-3 evenings; do p02 pong first if t03..t05 felt shaky)
after t08  -> p16 level devil    (3-5 evenings; the deceptive platformer)
after t13  -> p04 memory match   (1-2 evenings)
o-track done, any time -> p05 idle rpg  (a week of evenings; pure language practice)
after p05 + t13 -> p06 idle widget      (2-3 evenings; p05 logic + a face)
```

## A Note On "Will This Repo Become Outdated?"

You come from frontend, where the ground moves weekly. Game
programming is not like that:

- The game loop, input handling, AABB collision, tile grids, state
  machines — this knowledge is from the 1980s-90s and unchanged.
  Everything in `30_fundamentals/` would have been true 20 years ago
  and will be true in 20 years.
- Odin moves slowly and values stability; Sokol is a mature
  single-maintainer C library with years of API stability. Worst
  realistic case: a compiler update needs small syntax fixes
  (`sauce/build/build.odin` already pins/normalizes shader codegen
  for exactly this reason).
- There is no framework churn because there is no framework. You are
  learning the substrate, not this season's abstraction over it.

The skills transfer even if every tool here died tomorrow.
