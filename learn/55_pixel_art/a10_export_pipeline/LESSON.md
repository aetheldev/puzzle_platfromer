# A10 — Export Pipeline

Goal: art flows from Aseprite into the game with ONE KEYBIND. The
repo already ships this — `asset_workbench/aseprite_asset_export.lua`.
You learn to USE it, then (a11) to MODIFY it.

## How The Repo Pipeline Works

```
asset_workbench/player.aseprite     <- you draw here
        | (run export script)
res/images/player_idle.png          <- one strip PNG per animation TAG
res/images/player_run.png
        | (game build: sauce/build packs res/)
sauce/ atlas -> sprites on screen
```

Read the script top: `asset_workbench/aseprite_asset_export.lua`.
It does two things:
- static layer → exports active layer as `res/images/<layername>.png`
- tagged animation → exports each TAG as horizontal strip
  `res/images/<spritename>_<tagname>.png` (this is why a07 demanded
  tags!)

## Install The Keybind

1. Aseprite → File → Scripts → Open Scripts Folder
2. Copy `aseprite_asset_export.lua` there (or symlink:
   `ln -s <repo>/asset_workbench/aseprite_asset_export.lua <scripts-folder>/`)
3. File → Scripts → Rescan Scripts Folder
4. Edit → Keyboard Shortcuts → search the script name → bind
   `Ctrl/Cmd+E`
5. IMPORTANT: the script exports RELATIVE to the .aseprite file
   (`../res/images/`), so your art files must LIVE in
   `asset_workbench/`. That is the contract.

## Do It

1. Open your a05 icon file (move it into `asset_workbench/` if not
   there). Name the layer `icons`. Hit your keybind →
   `res/images/icons.png` appears. Confirm.
2. Open your a07 detective (tags: `idle`, `walk`). Export →
   `detective_idle.png` + `detective_walk.png` strips.
3. Loop test: change one pixel, re-export, look — sub-second
   iteration. THIS is why the pipeline exists: art iteration speed =
   art quality (same loop as `:make` for code).

## Use It In A Lesson Build

Fundamentals lessons draw rects — but you have real PNGs now. Two
options:
- easy: point your t07/t13 build at colored rects still, but use your
  a08 tile COLORS sampled from the art (eyedropper → hex → code)
- real: `sauce/` loads `res/images/` automatically — Ticket 060+
  territory. Your art is already in the right place for that day.

## Exit Criteria

- [ ] Keybind exports in under a second
- [ ] Tagged animation produces per-tag strips
- [ ] You can explain the `asset_workbench/ → res/images/` contract

## Next

`a11_script_aseprite` — the script you just used is Lua. You are a
programmer. Make your own tools.
