# Different-View Co-op Puzzle

Core idea: both players share same level, but each sees different truth.

Examples:
1. Player A sees solid walls that Player B sees as empty air.
2. Player A sees hidden switches, Player B sees moving hazards.
3. Player A can move boxes, Player B can rotate rooms.
4. Player A sees past-state layout, Player B sees present-state layout.
5. One player sees colors/symbols needed to decode locks for other player.

Why this is strong:
- Forces communication
- Creates asymmetric roles
- Makes simple geometry feel deep

## First Prototype Recommendation

Single screen. Local co-op. One keyboard side each.

Rules:
1. Player Red can stand on red-only platforms.
2. Player Blue can stand on blue-only platforms.
3. Shared goal door opens only when both stand on different pressure plates.
4. Some bridges visible only to one player.

## Technical Build Order

1. Start from `learn/fundamentals/t07_tilemap`
2. Duplicate player logic from `t05` or `t06`
3. Add second player struct
4. Add per-player collision masks
5. Draw tiles conditionally by viewer/player
6. Add win condition requiring both players
7. Add shared camera from `t08`

## Minimal Data Model

```txt
tile_kind: empty, wall, goal, plate, bridge_red, bridge_blue
player_mask: red, blue, both
```

Collision rule:
- red player collides with `wall`, `bridge_red`, `both`
- blue player collides with `wall`, `bridge_blue`, `both`

## Prototype Tickets

1. One room, two players, same camera
2. Red-only and blue-only platforms
3. Two pressure plates open goal
4. Add box only one player can push
5. Add section where one player guides other verbally

## Playable Prototype

Exercise folder lives in:

`learn/co_op/different_views_puzzle/prototype`

Runnable answer lives in:

`learn/solutions/co_op/different_views_puzzle/prototype`

Run with:

```sh
cd learn/solutions/co_op/different_views_puzzle/prototype
zsh build.sh
```

Production goal after standalone practice:
- `learn/production_with_sauce/04_coop_puzzle_in_sauce.md`

## Good Co-op Puzzle Variants

1. Different visibility
One sees platforms, one sees hazards.

2. Different time layers
One interacts with past, one with present.

3. Different gravity
Each player has own gravity direction.

4. Different verbs
One jumps, one dashes, one rotates, one carries.

5. Shared body / split mind
Both players control different systems of one machine/robot.

## Design Warning

Do not make both players do same thing in parallel. That is not strong co-op.
Better: each player has incomplete information or incomplete ability.
