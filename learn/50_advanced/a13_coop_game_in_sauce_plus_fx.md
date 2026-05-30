# A13 Co-op Game In Sauce Plus FX

Goal: understand how an asymmetric co-op puzzle becomes a polished production game inside `sauce/`.

## Core Game Layer

Main game pieces:
- two player entities
- role-specific collision/visibility rules
- shared puzzle state
- shared win/fail state
- shared camera or camera rules

Start here:
- `learn/90_production_with_sauce/04_coop_puzzle_in_sauce.md`

## Where Effects Fit

Co-op puzzle effects should improve communication and readability.
Not just look pretty.

### Role Clarity
- red player aura / blue player aura
- red-only bridge pulse / blue-only bridge pulse
- role-colored highlights on interactables

### Communication Feedback
- plate glows when active
- bridge lights up for correct player
- locked door shows color-coded missing condition

### Shared Success Feedback
- both plates active -> door flare
- both players near goal -> room glow ramp-up
- solved room -> synchronized pulse/sparkle sequence

## Shader Opportunities

- different visibility layers
- red/blue role-tinted materials
- hidden clue shimmer for one player only
- doorway activation glow

## Important Design Rule

Effects must help both players understand:
- who can use what
- what changed
- what is still missing

## What Stays In Game Code

- asymmetric rules
- puzzle state transitions
- per-player permissions
- local/network action handling

## What May Move Into `core_render`

- view filters for asymmetric information
- player-specific highlight materials
- shared room transition effects

## Practice

- define one room where red sees answer and blue sees obstacle timing
- define what visual feedback each player needs to not get confused
- decide which effect is clarity-critical vs pure polish
