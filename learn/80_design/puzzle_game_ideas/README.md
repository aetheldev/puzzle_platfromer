# Puzzle Game Ideas

Goal: use fundamentals + Sokoban to branch into other puzzle styles.

## Good Small Puzzle Types

1. Sokoban
Push boxes onto goals. Best for learning grid logic, undo, level design.

2. Ice Slide Puzzle
Player slides until hitting wall. Good for state-space thinking and level planning.

3. Switch & Door Puzzle
Buttons open doors. Good for event systems and dependency chains.

4. Mirror / Laser Puzzle
Rotate mirrors, route beam to target. Good for line stepping and simulation.

5. Clone / Time Echo Puzzle
Record one run, replay ghost, solve with past self. Good for deterministic simulation.

6. Gravity Direction Puzzle
Rotate gravity instead of moving normally. Good for camera + physics rules.

7. Shared Resource Puzzle
Two characters use same energy, light, or move budget. Good for co-op design.

## Good Build Order

1. Sokoban
2. Switch & Door puzzle
3. Ice Slide puzzle
4. Gravity puzzle
5. Co-op asymmetric puzzle

## Questions To Ask For Any Puzzle

1. What is one turn?
2. What is allowed move?
3. What is failure state?
4. What is win state?
5. What creates interesting choice, not busywork?
6. Can player understand rules in 5 seconds?

## Fast Prototype Recipe

1. Make one mechanic only.
2. Make 5 levels.
3. Remove anything not helping puzzle.
4. If level 3 already repeats, mechanic too weak or rules too many.
5. If players solve by random pushing, add better feedback or stronger constraints.
