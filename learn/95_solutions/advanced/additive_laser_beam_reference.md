# Additive Laser Beam Reference

Goal: map laser-beam visuals into production `sauce` structure.

## Game Side

Store beam as gameplay data:
- origin
- direction
- hit point
- reflected segments
- hit target state

Example shape:

```odin
Beam_Segment :: struct {
    start: Vec2,
    end: Vec2,
    intensity: f32,
}
```

Game layer computes segments.
Renderer draws them.

## Visual Stack

Good beam usually has 3 layers:
1. thin bright core
2. wider additive glow layer
3. impact spark / flare at hit point

## Where It Belongs

Game code:
- trace beam path
- reflection logic
- target activation

Renderer/game draw helper:
- draw additive quads or beam segments
- impact sprite
- pulse width/intensity over time

## Good First Production Version

In `game.odin`:
- compute array of beam segments

In draw code:
- for each segment draw 2 or 3 quads
  - glow quad
  - core quad
  - optional sparkle at endpoint

## Advanced Upgrade Path

Later you can add:
- beam noise shader
- bloom contribution
- endpoint distortion
- heat shimmer

## Why This Is Valuable

Laser puzzle is perfect for learning:
- gameplay simulation
- visual readability
- additive rendering
- effect layering
