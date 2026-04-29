# Sokoban Project Lesson

## Step 1 - Concept

Sokoban teaches grid logic, push rules, win checking, and level design.
It is one of the best bridges from fundamentals into real puzzle game code.

## Step 2 - Read This

Open:
- `learn/solutions/projects/sokoban/main.odin`

Read only:
- `Cell`
- `load_level`
- `try_move`
- `check_win`

Then open:
- `learn/solutions/projects/sokoban/levels/level_01.txt`

Read only that one level first.

## Step 3 - Question

Why are walls and goals stored as grid data while the player move is handled by rules on top of that grid?

## Step 4 - Your Turn

Close the solution.
In this folder, create your own `main.odin`.

Task:
- load one level from text
- move player on grid
- push one box
- detect win when all goals are covered

## Step 5 - Stop

Write it first.

## Practice After It Works

- add reset key
- add next level key
- add move counter
- add one new level of your own

## Sauce Goal

When this standalone version makes sense to you, next step is:
- `learn/production_with_sauce/03_sokoban_in_sauce.md`

That is the production-ready path inside `sauce/`.
