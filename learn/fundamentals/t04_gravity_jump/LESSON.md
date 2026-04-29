# T04 Gravity And Jump

## Step 1 - Concept

Jumping works by changing vertical velocity, not by teleporting position upward.
Gravity adds downward velocity every frame, then position integrates from velocity.

## Step 2 - Read This

Open:
- `learn/solutions/fundamentals/t04_gravity_jump/main.odin`

Read only:
- jump input handling
- gravity lines in `frame`
- floor collision lines

Focus on:
- `vel_y`
- `GRAVITY * dt`
- landing on floor

## Step 3 - Question

Why is jump implemented by setting `vel_y` instead of directly subtracting from `y`?

## Step 4 - Your Turn

Close the solution.
Write your own file here.

Task:
- horizontal movement
- gravity
- one jump
- floor collision

## Step 5 - Stop

Write it first.
