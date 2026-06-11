# P02 — Pong (Solo Flight — no solution)

**Unlocks after:** `t03 movement`. (Do it any time after; pairs well
with p01.)

## Goal

Two paddles, one ball, first to 5. Left paddle = W/S, right paddle =
UP/DOWN. **This is the first time you write two-player input — the
seed of your entire co-op plan.**

## Why No Solution

You have built t01-t03 with an instructor. Pong is geometrically the
simplest game that is actually a game. If you can build it alone, you
KNOW you learned, not memorized. Struggle is the feature.

## Spec

- Window 960x540. Two paddles (16x80), ball (14x14 square is fine)
- Ball starts center, moves diagonally; serve toward last scorer
- Ball bounces off top/bottom (`vel.y = -vel.y`)
- Paddle hit: `vel.x = -vel.x`, and add a slice — offset from paddle
  center changes `vel.y` (this one rule makes it FUN)
- Ball exits left/right: other side scores, ball re-serves
- Score as pips (rects), like snake. First to 5 → freeze + R restarts
- Ball speeds up slightly on each paddle hit

## Hints (only if stuck — each one collapses one wall)

1. Two players = two structs of the same type, two key sets writing
   into them. NOT two copies of the code.
2. Ball-paddle overlap is point_in_rect's big sibling: AABB overlap —
   `a.x < b.x+b.w && a.x+a.w > b.x && (same for y)`.
3. The slice: `vel.y += (ball.y - paddle_center_y) * 0.1`
4. Move everything with `* dt` (t03!) or accept frame-tied speed and
   note why it is wrong.

## The Real Lesson Hiding Inside

When both paddles work, look at your input code. You wrote something
like "read keys → set player N's intended movement → apply". You are
one rename away from `Player_Intent` (Ticket 075). Two-player Pong on
one keyboard is rung 1 of the networking ladder
(`learn/85_networking/06_two_windows_local_to_network.md`).

## Stretch

- CPU paddle: tracks the ball with a max speed (instant = unbeatable, boring)
- Two-ball chaos mode after 3-3
- Juice pass after t10: shake on score, particles on hit

## Done When

- [ ] Two humans played a full match on your keyboard
- [ ] The slice rule is in and you can explain why it makes Pong fun
- [ ] You never opened a solution, because there is none
