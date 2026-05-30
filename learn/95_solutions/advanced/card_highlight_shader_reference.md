# Card Highlight Shader Reference

Goal: make card selection and special cards feel premium without overcomplicating the whole renderer.

## Good Effects For Card Games

1. selected card outline glow
2. hover shimmer
3. discard pile pulse on play
4. special card emissive sweep

## Best Place To Start

Do not begin with full post-process.
Start with per-card shader params or additive overlay quads.

## Data You Need

Per card, you may want:
- selected
- playable
- special
- highlight_strength
- shimmer_time_offset

## Where It Belongs

Game layer:
- selected card index
- playable state
- special card state

Renderer/shader side:
- color tint
- border pulse
- shimmer animation

## Simple Production Route

1. draw normal card
2. if selected, draw additive border/glow quad
3. if special, send param to shader for pulse/shimmer

## Why Not Huge System First

Card games depend more on clarity than raw effect complexity.
Good card feedback is subtle but precise.
