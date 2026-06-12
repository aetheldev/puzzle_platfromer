# A11 — Script Aseprite (Lua)

Goal: build your own art tools. The extensions you admired
(carbscode's quick-color-hotkeys, color-swap) are ~50 lines of Lua.
You write Odin daily; Lua is a weekend dialect. This is YOUR home
turf inside the art track.

## The Mental Model

Aseprite embeds Lua + exposes its objects:

```
app                  -> the editor (active sprite, fg/bg color, commands)
app.activeSprite     -> Sprite (layers, frames, cels, palettes)
cel.image            -> Image (the actual pixels: image:pixels() iterator)
app.pixelColor       -> pack/unpack rgba <-> integer
app.transaction(fn)  -> wrap edits = ONE undo step (always do this)
app.command.X{...}   -> any menu action, scripted (the export script
                        uses app.command.ExportSpriteSheet)
Dialog{...}          -> build small UIs
```

API reference: `github.com/aseprite/api`. The repo's
`asset_workbench/aseprite_asset_export.lua` is your local worked
example — you can already read it after this table.

## Ship Two Tools Today (provided, then dissect)

In `learn/55_pixel_art/a11_script_aseprite/scripts/`:

1. **`color_swap.lua`** — FG↔BG colors trade places across the whole
   sprite. Iterates every cel's pixels, compares packed rgba ints,
   swaps inside one transaction. The carbscode color-swap concept,
   minimal.
2. **`fg_palette_slot.lua`** — sets FG color to palette slot N. Copy
   the file per slot, edit `SLOT`, bind keys `Alt+1..4`. The
   quick-color-hotkeys concept, minimal.

Install both (a10's scripts-folder routine), bind keys, USE them on
your a05 icons (rarity recolor suddenly takes seconds — remember
doing it by hand?).

## Dissect Drill (the actual lesson)

Open `color_swap.lua`, answer in your head:
- why check `spr.colorMode ~= ColorMode.RGB`?
- why pack colors to ints (`pc.rgba(...)`) before comparing instead
  of comparing Color objects?
- what breaks without `app.transaction`? (try: comment it, run, hit
  undo — count the steps)
- why loop `spr.cels` and not just the active layer?

## Build Your Own (pick one, ship it)

- **outline-izer:** add 1px outline of BG color around all non-transparent
  pixels of active cel (neighbor check per pixel — t07 grid brain)
- **ramp shifter:** move every pixel one step up/down its palette ramp
  (your a04 hue-shifted ramps, automated — great for damage flashes)
- **rarity batcher:** apply 3 palette swaps and export 3 PNGs in one
  run (a05 rarity variants + a10 export, fused)
- **export-all upgrade:** modify the repo export script to also write
  a `.txt` manifest of exported files (Lua `io.open` — and your Odin
  game could parse it!)

## Stretch: Real Extension

A `.aseprite-extension` = zip with `package.json` listing commands +
scripts. That is the full carbscode format — docs:
`aseprite.org/docs/extensions`. Package your best tool; put it on
itch.io; you are now the person whose tools you used to download.

## Exit Criteria

- [ ] Both scripts installed, keybound, used on real art
- [ ] Dissect questions answered without rereading
- [ ] One self-built tool ships and saves you real time

## Track Done

Art track complete. You draw, animate, export, and TOOL. Loop back:
`a09`'s scene + `90_production_with_sauce/` = the real game's art
goes in. Side quest forever: one sprite a day.
