# T08 Camera

## Step 1 - Concept

Camera separates world coordinates from what the player sees on screen.
A follow camera usually moves toward a target instead of snapping instantly.

## Step 2 - Read This

Open:
- `learn/solutions/fundamentals/t08_camera/main.odin`

Read only:
- camera struct
- `lerp`
- target camera math in `frame`
- `sgl.translate(-cam.x, -cam.y, 0)`

## Step 3 - Question

Why do we translate the world by negative camera position instead of moving the player toward the screen center manually?

## Step 4 - Your Turn

Close the solution.
Write your own file here.

Task:
- bigger level than screen
- player moves in world space
- camera follows player smoothly

## Step 5 - Stop

Write it first.
