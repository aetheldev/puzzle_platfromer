# Sauce VFX Event System Reference

Goal: avoid scattering one-off VFX triggers all over game code.

## Problem

Beginner code often does this:
- push box -> spawn particles directly here
- solve level -> flash directly here
- hit enemy -> shake directly here

That works at first, but scales badly.

## Better Pattern

Emit small VFX events from gameplay.
Resolve them centrally.

Example shape:

```odin
VFX_Event_Kind :: enum { box_push, laser_hit, card_play, burn_tick }

VFX_Event :: struct {
    kind: VFX_Event_Kind,
    pos: Vec2,
    color: Vec4,
    strength: f32,
}
```

## Where It Belongs

Game code:
- append `VFX_Event` when gameplay event happens

VFX system / draw side:
- consume queue
- spawn particles
- trigger shake
- start glow pulse
- start sound event

## Why This Helps

1. gameplay stays cleaner
2. polish is easier to tune
3. many features can reuse same event path
4. networking/replay becomes easier because events are explicit

## Good First Production Usage

Use for:
- Sokoban push
- box on goal
- card played
- laser hit
- co-op door unlock

## Upgrade Path

Later you can split into:
- gameplay event log
- VFX event queue
- audio event queue

But first version can stay simple.
