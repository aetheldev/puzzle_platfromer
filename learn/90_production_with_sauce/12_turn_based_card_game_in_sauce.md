# Turn-Based Card Game In Sauce

Goal: build a production-style turn-based card game inside `sauce/`.

This is good training because it teaches game architecture without physics complexity.

## Why Card Games Are Great Learning

They force you to model:
- game state
- turn state
- legal actions
- UI state
- deterministic updates

This is excellent preparation for:
- local co-op
- online lockstep / action replication
- puzzle games with strict rules

## Recommended Game State

Add to `Game_State`:
- deck
- discard pile
- player hands
- active player index
- turn phase
- pending action effects
- winner

Example shape:

```odin
Card_Color :: enum { red, blue, green, yellow }
Card_Kind  :: enum { number, skip, reverse, draw_two, wild }

Card :: struct {
    color: Card_Color,
    kind: Card_Kind,
    value: int,
}

Turn_Phase :: enum {
    choose_card,
    resolve_card,
    draw_if_blocked,
    end_turn,
    game_over,
}
```

## Production Split

Keep this mostly in game layer:
- card rules
- turn logic
- AI logic
- hand layout logic
- action validation

Use core/render layer for:
- card drawing helpers
- highlights
- glow/shadow polish if needed

## Best First Version

1. 2 players
2. one human, one dummy/human
3. number cards only
4. match color or number
5. if blocked, draw one
6. empty hand wins

## Ticket Order

1. add card structs and turn phase enum
2. add small deck generation
3. add deal logic
4. add hand/discard rendering
5. add legal move check
6. add turn pass
7. add draw action
8. add win detection
9. add action cards later

## What To Learn Before Networking

Before online card game, learn:
1. deterministic action log
2. serializable game state
3. authoritative turn changes
4. replay from action list

Card games are one of the best places to learn networked game logic because the rules are discrete and state is compact.
