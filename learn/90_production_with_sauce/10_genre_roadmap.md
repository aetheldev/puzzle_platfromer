# Genre Roadmap

You like puzzle, co-op, roguelike, and turn-based card games.
Good news: they share many core skills.

## Shared Skills Across Genres

All of them need:
- state machines
- level/content structure
- entities
- feedback/VFX
- camera/UI
- save/load eventually

## Puzzle Game Path

Learn these first:
1. tile/grid logic
2. interaction rules
3. reset/undo
4. level loading
5. editor/export

Good starter types:
- Sokoban
- switches/doors
- mirror/laser
- gravity room puzzles

## Asymmetric Co-op Puzzle Path

Core ingredient is not two players.
Core ingredient is incomplete information or incomplete ability.

Strong patterns:
1. one sees solution, one sees obstacles
2. one moves objects, one changes world
3. one sees past, one sees present
4. one decodes symbols, one executes actions

Best learning order:
1. local same-screen prototype
2. local shared keyboard/controller prototype
3. several rooms proving communication is fun
4. only then online/networking if still wanted

## Roguelike Path

Learn these first:
1. deterministic turn/action loop
2. enemy rules
3. combat resolution
4. room generation or map generation
5. loot/progression loop
6. run reset/meta progression

Good first version:
- one floor
- 3 enemy types
- 3 item types
- one boss or one exit

Do not start with giant procgen system.

## Turn-Based Card Game Path

Learn these first:
1. turn phase state machine
2. deck / hand / discard model
3. legal action validation
4. action resolution order
5. AI or second-player turn flow
6. UI clarity for selected/playable cards

Good first version:
- 2 players
- number cards only
- match by color or value
- draw when blocked
- first empty hand wins

Why this path is useful:
- extremely good for learning deterministic logic
- future networking is much easier than action games
- teaches clean state transitions

## Where These Genres Diverge

Puzzle focus:
- clarity
- authored content
- exact rules

Roguelike focus:
- systemic replayability
- combat/economy balance
- procgen content variation

Co-op focus:
- communication design
- role separation
- shared failure/win states

## Best Personal Path For You

1. Finish puzzle foundations in `sauce`
2. Make one good Sokoban-like or switch-door game
3. Make one asymmetric co-op room prototype
4. Optionally make one small turn-based card game
5. Add effects and style
6. Later branch into roguelike with stronger architecture confidence

Why this order:
- puzzle teaches clean rules
- co-op teaches layered state and communication design
- turn-based card game teaches deterministic state machines
- roguelike benefits from all of them
