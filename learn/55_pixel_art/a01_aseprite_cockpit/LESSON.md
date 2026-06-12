# A01 — Aseprite Cockpit

Goal: hands stop thinking about the tool. Like learning vim motions
before writing code.

## Setup (10 min)

1. Buy/build Aseprite (aseprite.org — ~$20, or compile free from source)
2. New file: 32x32, RGBA, transparent background
3. View → Show → Pixel Grid ON. Zoom to ~800% (mouse wheel / `+`)
4. Open `asset_workbench/player.aseprite` too — a real file from this
   repo to poke at

## The Only Tools You Need For A Month

| Key | Tool | Notes |
|-----|------|-------|
| `B` | Pencil | THE tool. 1px, hard edge, always |
| `E` | Eraser | |
| `G` | Bucket | fill region |
| `M` | Rect select | move chunks with `Ctrl/Cmd+drag` |
| `Alt+click` | Eyedropper | steal color under cursor — used CONSTANTLY |
| `I` | Eyedropper (toggle) | |
| `X` | Swap FG/BG color | two-color workflow |
| `Z` zoom, `Space+drag` pan | navigation | |
| `Ctrl/Cmd+Z` | undo | drawing IS undoing |

Never touch: brush tool with soft edges, blur, gradients. Pixel art =
hard pixels, hand-placed.

## Screen Map (5 min looking)

- Left: tool bar. Top: tool options (brush SIZE — keep 1px).
- Right: color palette (bottom) + preview (top).
- Bottom: timeline — frames (animation, a07) and layers.
- Layers: like Photoshop/Figma. Background layer + sprite layer
  minimum. Name them.

## Drills (do all, ~30 min)

1. **Dot drill:** place single pixels in each canvas corner + center.
   Zoom out to 100%. See how far 1px reads.
2. **Line drill:** `B`, draw horizontal, vertical, 45° lines. Hold
   `Shift` for straight lines — feel the snap.
3. **Square/circle drill:** `U` (shapes tool) rectangle + ellipse,
   filled and outline. Then draw a 9x9 circle BY HAND with `B` (yes,
   it is hard — a02 explains the rules).
4. **Color drill:** pick 4 palette colors, fill 4 squares (`G`),
   eyedrop (`Alt`) between them, `X`-swap, paint with both.
5. **Select drill:** `M`, grab half your drawing, move it, undo.
6. **Save drill:** save as `.aseprite` into `asset_workbench/`
   (native format keeps layers; PNG export comes in a10).

## Exit Criteria

- [ ] B/E/G/M/Alt-eyedrop/X without looking at the toolbar
- [ ] You know what 100% zoom looks like vs 800% (judge at 100%!)
- [ ] One saved .aseprite file exists with 2 named layers

## Next

`a02_pixels_have_rules` — why your hand-drawn circle looks wrong, and
the rules that fix it.
