# A04 — Color Without Fear

Goal: never invent colors blind again. Color theory for pixel art =
two rules + theft.

## Rule 1 — Steal Palettes (seriously)

Go to **lospec.com/palette-list**. Sort by downloads. Grab one 8-16
color palette (classic starters: "SLSO8" 8 colors, "Endesga 32",
"Resurrect 64"). In Aseprite: palette menu (tiny bars icon above
palette) → Load Palette / paste hex codes.

Pros do this. A curated palette = thousands of color decisions already
made by someone good at color. Constraint kills option paralysis.

The full track rule: **everything until a09 uses ONE stolen palette.**

## Rule 2 — Hue Shift (the secret sauce)

Beginner ramps: same hue, darker/lighter (boring, muddy).
Pro ramps: as colors get darker they also ROTATE hue toward
blue/purple; lighter rotates toward yellow/warm.

```
boring skin ramp:  dark-brown  -> brown      -> light-brown
pro skin ramp:     purple-brown-> brown      -> peach-yellow
boring grass:      dark-green  -> green      -> light-green
pro grass:         blue-green  -> green      -> yellow-green
```

Why it works: real shadows take the sky's blue; real light is warm.
Stolen palettes have hue shift BUILT IN — another reason to steal.
Check your palette: find a ramp, watch the hue rotate.

## Rule 3 — Fewer Colors Than You Think

16x16 sprite: 3-5 colors. 32x32 character: 6-10. Full scene: a 16-32
palette total. When a sprite looks bad, REMOVING a color fixes it more
often than adding one.

## Aseprite Color Workflow

- `Alt+click` eyedrop constantly — work FROM the palette, not the wheel
- Shading mode: ink dropdown (top bar) → "Shading" + select your ramp
  = paint walks up/down the ramp automatically (try it, it is magic)
- Replace a color everywhere: select color → Edit → Replace Color
  (in a11 you SCRIPT this — the carbscode color-swap extension is
  exactly this, automated)

## Drills

1. Load a Lospec palette. Find its ramps (sort palette by hue helps).
2. Redo a03's ball/cube/cylinder with a real ramp from the palette.
   Watch them stop being gray homework and start being objects.
3. Hue shift proof: make ONE 4-color ramp by hand — pick mid color,
   darken+rotate cold twice, lighten+rotate warm once. Compare with
   no-shift version side by side.
4. Mood swap: fill 3 small canvases with the same simple scene blocked
   in flats (sky/ground/box) using 3 different palettes. Feel how
   palette = mood. (Your detective game's mood lives here.)

## Exit Criteria

- [ ] One Lospec palette loaded and used end-to-end
- [ ] You can explain hue shifting in one sentence
- [ ] a03 forms re-shaded in color and they look 2x better

## Next

`a05_item_icons_16x16` — first REAL assets: your game's items.
