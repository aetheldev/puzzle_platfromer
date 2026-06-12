# A05 — Item Icons 16x16

Goal: first shippable assets. Items are the perfect first sprite:
no anatomy, no animation, instantly useful (p06's BAG, the detective
game's inventory).

## The Icon Recipe (every icon, same steps)

1. **Silhouette first.** One dark color, shape only. Zoom 100%:
   readable? A key must read as a key as a BLOB. If the silhouette
   fails, no shading saves it.
2. **Flat colors.** 2-3 palette colors inside the silhouette.
3. **Light.** Top-left. Light edge top/left, shadow edge bottom/right
   (selective outline style from a02 works great here).
4. **One highlight.** Single brightest pixel where material shines
   (glass, metal, gem). Matte stuff (paper, cloth) gets none.
5. **100% zoom check** against a dark AND a light background.

15-30 minutes per icon at first. That is normal.

## Build This Set (your game's starter kit)

Classic adventure six:
- [ ] potion (cylinder + ball glass, liquid line, glass highlight)
- [ ] key (the silhouette king — circle + bar + teeth)
- [ ] sword/knife (45° line discipline from a02)
- [ ] book/dossier (cube perspective lite — detective flavor)
- [ ] magnifying glass (circle + handle; glass = 2 highlight pixels)
- [ ] pocket watch (circle in circle + chain — your Saatçi killer's
      calling card!)

All on one 16x16 grid-of-frames file or separate files — your call
(a10 pipeline handles both).

## Material Cheat Codes

| Material | Trick |
|----------|-------|
| Glass | strong single highlight + see-through gap on one edge |
| Metal | high contrast ramp, sharp light/shadow boundary |
| Wood | low contrast ramp + 1-2 grain lines in base color |
| Paper | flattest ramp, almost no shading, maybe a fold line |
| Gem | facet = hard triangles of light/base/shadow + 1 highlight |

## Study Method (do once)

Find one professional 16x16 icon set (itch.io free packs / Lospec).
Pick the potion. Recreate it pixel-for-pixel next to yours. List 3
differences (their contrast? outline? highlight placement?). Apply to
your remaining icons. This loop = the entire learning method.

## Stretch

- Rarity recolor: common/rare/epic versions of one icon by swapping
  the ramp (p06's border-color system, now in the art itself —
  and in a11 you script this swap)
- 12-icon set, consistent style, exported into `res/images/` (a10)

## Exit Criteria

- [ ] 6 icons, same palette, same light, same outline style
- [ ] Each one readable at 100% zoom on both bg colors
- [ ] You used the recipe order: silhouette → flats → light → highlight

## Next

`a06_first_character` — the detective. Same recipe, plus anatomy
cheats.
