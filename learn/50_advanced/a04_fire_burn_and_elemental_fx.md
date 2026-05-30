# A04 Fire, Burn, And Elemental FX

Goal: make effects feel like systems, not isolated particles.

## Production Thinking

Fire effect is often made of layers:
1. base sprite or core shape
2. emissive pulse
3. upward embers
4. smoke or heat haze later
5. status readability on target

Different elements need different motion language:
- fire: fast upward, flicker, heat
- ice: calm drift, shards, pale glow
- poison: wobble, fog, sickly pulse
- lightning: brief, sharp, directional

## Read

- `learn/40_vfx/v02_elemental_orbs/LESSON.md`
- `learn/40_vfx/v03_burning_effect/LESSON.md`

## Practice

- for each element, define:
  - color palette
  - motion style
  - lifetime style
  - glow style
  - sound idea

## Production Question

Should this be:
- particles only
- shader only
- particles + shader + sound together

Best effects usually combine them.
