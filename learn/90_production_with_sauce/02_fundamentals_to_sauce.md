# Fundamentals To Sauce

This maps each lesson to production blueprint usage.

## T01 Hello Window

Fundamental:
- create window
- clear screen

Sauce version:
- already solved by `core_main.odin` + `core_render.odin`
- you do not re-implement this

Use instead:
- `app_init`
- `app_frame`

## T02 Shapes And Colors

Fundamental:
- immediate shape drawing

Sauce version:
- use existing quad batching in renderer
- use helper draw calls already built around sprites/quads/text

Do not add raw `sokol_gl` into production unless needed.

## T03 Movement

Fundamental:
- keyboard state
- delta time movement

Sauce version:
- use action map and core input helpers
- apply movement inside entity update proc or `game_update`

## T04 / T05 / T06 Platformer Feel

Fundamental:
- gravity
- jump
- coyote
- wall jump

Sauce version:
- store movement state on player entity
- update in `update_player`
- draw through player sprite/anim

## T07 Tilemap

Fundamental:
- grid map
- tile collision

Sauce version:
- put level arrays into game code
- or load from file into `Game_State`
- optionally instantiate entities from level markers

For Sokoban, this is main foundation.

## T08 Camera

Fundamental:
- world vs screen
- follow camera

Sauce version:
- update `ctx.gs.cam_pos`
- renderer already uses camera info through coord-space helpers

## T09 Shader

Fundamental:
- custom pipeline

Sauce version:
- use existing shader pipeline first
- add flags/params before rewriting render backend
- only touch `core_render` when gameplay really needs new render data

## T10 Particles / Shake

Fundamental:
- tiny short-lived visual feedback

Sauce version:
- either small VFX entities
- or direct draw-side transient arrays in `Game_State`

For production, entity path is usually easier to grow.

## T11 Editor Basics

Fundamental:
- paint tiles
- export text layout

Sauce version:
- same level format can become real content pipeline
- later build in-game editor state inside `game.odin`
- or external tool that outputs level files under `res/`

## Rule Of Thumb

Fundamentals teach concept in isolation.
Sauce teaches where concept belongs in bigger game structure.
