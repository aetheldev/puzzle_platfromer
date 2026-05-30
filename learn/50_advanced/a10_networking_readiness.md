# A10 Networking Readiness

Goal: understand what to learn now so future online co-op does not hurt later.

## Best Preparation Right Now

Build deterministic systems.

That means:
- small explicit game state
- clear legal actions
- easy replay of actions
- less hidden time-dependent randomness

## Why This Matters

Your future co-op puzzle game may become online.
If local version already has:
- deterministic puzzle rules
- explicit state transitions
- replayable actions

then networking becomes much easier.

## Best Genres For Networking Practice

1. turn-based card game
2. tile/grid puzzle game
3. discrete room-based co-op puzzle

## Practice

- for your co-op puzzle, define actions as messages
- for your card game, define full turn log
- for Sokoban, define move log and undo log
