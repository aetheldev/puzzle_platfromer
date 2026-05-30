# How To Make A Game

This is not specific to puzzle only.
This is general game-making order.

## Step 1: Find Core Loop

One sentence.

Examples:
- Sokoban: push boxes onto goals.
- Roguelike: move room to room, fight, loot, survive, build run.
- Co-op asymmetric puzzle: communicate because each player has incomplete truth.
- Turn-based card game: play legal card, resolve effect, empty hand first.

If you cannot state loop clearly, project is still foggy.

## Step 2: Pick World Model

Choose one:
- grid/tile
- free movement 2D physics-ish
- turn-based nodes/rooms
- card/state machine

Examples:
- Sokoban -> grid
- mirror laser puzzle -> grid or line network
- roguelike -> grid or room graph
- platform co-op -> free movement 2D
- turn-based card game -> turn state + deck/hand/discard data model

World model decides everything later.

## Step 3: Pick Game State Shape

Before juice, decide data.

Ask:
- what are tiles?
- what are entities?
- what is transient effect?
- what gets saved?

Good split:
- stable map data in arrays
- moving/interactable things in entities
- short VFX in transient arrays or VFX entities

## Step 4: Make Ugly But Playable

First milestone is not pretty.
First milestone is answer to one question:

"Is this mechanic actually fun?"

Do this first:
1. input
2. update rules
3. draw plain shapes or simple sprites
4. reset/restart loop
5. win/fail condition

## Step 5: Content Before Polish

Make 5 levels or 5 encounters.

If content is already repetitive, mechanic needs work.
Do not hide weak core loop behind glow and particles.

## Step 6: Add Feedback

Once mechanic works, add:
- sound
- particles
- screen shake
- hit flash
- glow/highlight
- camera movement

Feedback should explain game state, not only decorate it.

## Step 7: Build Tools

Only after repeated content work hurts.

Build editor/tooling when:
- making levels manually is slow
- changing values is annoying
- you are repeating export steps

## For Your Genres

### Puzzle
First solve:
- clarity of rules
- level structure
- reset/undo

### Roguelike
First solve:
- turn loop or action loop
- procgen structure
- enemy AI rules
- progression economy

### Co-op Puzzle
First solve:
- asymmetric information or asymmetric ability
- communication pressure
- shared win condition

## Bad Order

Bad order is:
1. shader first
2. big architecture first
3. networking first
4. Steam first
5. level editor first

## Good Order For You

1. fundamentals
2. standalone prototype
3. same idea in `sauce/`
4. real level content
5. polish
6. tooling
7. local co-op
8. networking only if still needed
