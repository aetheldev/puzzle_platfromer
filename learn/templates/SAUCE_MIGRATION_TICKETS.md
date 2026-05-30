# Sauce Migration Tickets

Goal: after standalone learning, rebuild same ideas inside `sauce/`.

## Rule

Do not migrate too early.
Only migrate after you understand standalone version.

## Migration Ladder

1. Standalone lesson/project works
2. You can explain rules/data
3. You identify what belongs in `game.odin`
4. You identify what belongs in `core_render.odin`
5. Rebuild smallest version in `sauce/`

## Good First Migrations

1. Sokoban
2. Co-op room prototype
3. Turn-based card game
4. Laser puzzle

## Migration Questions

Before moving feature into `sauce`, answer:
- what is tile data?
- what is entity data?
- what is transient VFX?
- what is input action?
- what draw behavior needs renderer support?

## Minimal Sauce Tickets

### Sokoban
- add mode/state
- add level grid
- add player + box entities
- add push rules
- add win/reset

### Co-op
- add second player entity
- add asymmetric collision rules
- add shared puzzle state
- add room complete condition

### Card Game
- add turn state
- add deck/hand/discard data
- add legal move rules
- add play/draw/end turn flow

### VFX
- keep event trigger in game layer
- promote only reusable render feature into `core_render`
