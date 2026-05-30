# Co-op Puzzle In Sauce

Goal: build your wife-playable local co-op puzzle prototype using real project structure.

## Best First Production Version

Do top-down or simple room-based platforming first.
Not full online co-op.

Use local shared-screen asymmetric puzzle.

## Add To Game State

- second player handle
- coop rule data
- shared door/plate state
- per-player collision mask or role enum
- camera target derived from both players

Example:

```odin
Player_Role :: enum { red, blue }

Game_State :: struct {
    ...
    player_handle: Entity_Handle,
    player2_handle: Entity_Handle,
    coop_door_open: bool,
}
```

## Add Entity Kinds

- `player_red`
- `player_blue`
- optional `push_box_red`
- optional `push_box_blue`

## Input Plan

Map different actions for each player:
- player 1: WASD + E
- player 2: arrows + right shift / slash / enter

If current input layer only supports one action map, extend input system minimally.
Do not rewrite everything.

## Collision Truth Trick

Represent tiles as masks:
- wall
- bridge_red
- bridge_blue
- both
- goal
- plate_red
- plate_blue

Then collision function checks tile against player role.

## Camera In Sauce

Set `ctx.gs.cam_pos` to midpoint of both players.
Clamp if needed.

## Production Ticket Order

1. Add second player entity
2. Add second input mapping
3. Add shared camera midpoint
4. Add red-only and blue-only bridges
5. Add pressure plate logic
6. Add shared exit door
7. Add level complete state
8. Add dialogue / hint UI
9. Add polish: particles, sound, shader feedback

## When To Touch Core

Touch `core_*` only if needed for:
- multiple gamepads
- split screen
- post-process view differences
- networking or Steam lobbies

Everything else can stay in game layer first.

## Steamworks Timing

Steam integration comes after local co-op prototype is fun.
Not before.
