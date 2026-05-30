# A09 Sauce Feature Promotion

Goal: know when a prototype trick should be promoted into `sauce`.

## Keep In Game Code When

- only one mechanic needs it
- simple quads/sprites are enough
- no reusable renderer behavior yet

## Promote To Core When

- multiple features need it
- it changes draw pipeline shape
- it requires offscreen/render-target support
- it adds reusable shader parameter flow

## Examples

Stay in game:
- one puzzle object pulses yellow
- one status effect spawns embers

Promote to core:
- bloom pass
- common light mask pipeline
- multi-pass distortion chain

## Practice

- list 3 things you would keep in `game.odin`
- list 3 things you would move into `core_render.odin`
