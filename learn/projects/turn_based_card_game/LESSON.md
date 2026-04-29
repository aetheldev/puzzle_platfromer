# Turn-Based Card Game Project Lesson

## Step 1 - Concept

Turn-based card games teach state machines, legal actions, turn flow, and deterministic game rules.
This is excellent training for future networking because the actions are discrete and easy to replay.

## Step 2 - Read This

Open:
- `learn/solutions/projects/turn_based_card_game/main.odin`

Read only:
- `Card_Color`
- `Card`
- `setup_game`
- `is_playable`
- `play_selected_card`
- `draw_if_blocked`

## Step 3 - Question

Why is a turn-based card game easier to make deterministic than an action game?

## Step 4 - Your Turn

Close the solution.
In this folder, create your own `main.odin`.

Task:
- make 2 players
- create deck, hand, discard
- play card if color or value matches
- draw one card if blocked
- win when one hand is empty

## Step 5 - Stop

Write it first.

## Practice After It Works

- add skip card
- add reverse card
- add simple CPU turn
- add replay log idea in comments/notes

## Sauce Goal

When this standalone version makes sense to you, next step is:
- `learn/production_with_sauce/12_turn_based_card_game_in_sauce.md`

That is the production-ready path inside `sauce/`.
