# A06 — Your First Character

Goal: a 32x32 detective that reads as A PERSON WITH A JOB at 100%
zoom. No anatomy degree needed — pixel characters are proportions +
silhouette, both cheatable.

## Proportion Cheat Sheet

Pixel characters are NOT realistic 7-heads-tall humans:

```
32x32 game sprite:  2-3 heads tall ("chibi") — head ~10-12px!
16x16 sprite:       basically a head with legs
```

Big head = readable face = character. Small game sprites live or die
by the head.

## The Recipe (same as a05, plus order-of-body)

1. **Silhouette first.** Fill one dark color:
   - head blob (big!), body smaller, legs short
   - THE JOB read: detective = hat brim + trench coat flare.
     Silhouette must say "detective" before any detail exists.
2. **Flat colors:** coat, hat, skin, shoes. 4-6 palette colors.
3. **Face minimal:** 2 eye pixels (dark), maybe 1px brow line.
   NO mouth at this size usually. Resist detail.
4. **Light top-left:** hat brim casts 1px shadow band on face,
   coat gets light edge left, shadow edge right.
5. **Contrast check at 100%:** head vs body vs background must
   separate. Squint test: blur eyes, three masses still distinct?

## Two Detectives, One Rule

Your co-op game needs Detective A and B distinguishable IN THE CORNER
OF THE EYE (p06's glanceability, now in art):

- different SILHOUETTE (hat vs no hat / coat vs jacket / tall vs short)
- different KEY COLOR (warm coat vs cold coat)
- NOT just palette-swapped same body — silhouette first, always

Draw A fully. Then draw B by changing silhouette + key color only.

## Common Beginner Tells (check yourself)

- Symmetric everything → mirror tool (`Shift` on pencil w/ symmetry
  option ON) is fine for blocking, but break symmetry in pose/detail
- Outline same black everywhere → use selective outline (darker coat
  color for coat edge) at least on inner lines
- Pillow-shaded face (a03!) → hat shadow band fixes it free
- Detail soup → if it needs >8 colors, you are painting, not pixeling

## Drills

1. 5 silhouette-only thumbnails (1 color, 10 min) — pick the best
2. Full recipe on the winner → Detective A
3. Detective B: new silhouette, swapped key color, same palette
4. Both on one canvas vs dark bg: corner-of-eye test — can a friend
   tell who is who at a glance from 2m away?
5. Study loop: find one 32x32 character you love (itch packs /
   Lospec), recreate, list 3 differences, apply.

## Exit Criteria

- [ ] Detective A reads "person + hat + coat" at 100%
- [ ] A and B distinguishable by silhouette alone (1-color test)
- [ ] Head is bigger than realistic and it looks RIGHT

## Next

`a07_make_it_move` — idle breath + walk cycle. The sprite becomes
alive.
