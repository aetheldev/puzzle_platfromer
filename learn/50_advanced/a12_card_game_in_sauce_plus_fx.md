# A12 Card Game In Sauce Plus FX

Goal: understand how a turn-based card game becomes a polished production game inside `sauce/`.

## Core Game Layer

Main game pieces:
- deck / discard / hands in `Game_State`
- turn phase enum
- legal action validation
- AI or second-player action flow
- replay/action log

Start here:
- `learn/90_production_with_sauce/12_turn_based_card_game_in_sauce.md`

## Where Effects Fit

Card games do not need huge particle spam.
They need readable, satisfying feedback.

### Card Play Feedback
- selected card glow/highlight
- smooth slide to discard pile
- tiny scale pop on play
- confirmation sound

### Action Card Feedback
- color burst behind discard pile
- symbol pulse
- slight screen tint

### Turn Feedback
- current player frame glow
- active hand brighten, inactive hand dim
- subtle table light pulse when turn changes

### Win Feedback
- winner hand glow
- board-wide color pulse
- final discard pile flare

## Shader Opportunities

- card foil shimmer
- magical wild card pulse
- emissive outline for selected card
- soft table glow under discard pile

## What Stays In Game Code

- card rules
- turn rules
- AI rules
- action resolution

## What May Move Into `core_render`

- reusable card highlight shader params
- soft UI glow material
- fullscreen turn transition effect

## Practice

- define 3 feedback layers for playing a normal card
- define 3 stronger feedback layers for playing a special card
- decide whether a card effect needs particles, shader, UI, or only sound
