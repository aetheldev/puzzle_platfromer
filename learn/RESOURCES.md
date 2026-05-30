# External Resources

Curated outside links to back up the in-repo lessons. The lessons are still your
main path — use these when you want another explanation, a video, or real
shipped-game code to study.

All links verified working. Organized by where they fit in the learning path.

---

## How To Use This Page

Do NOT read all of this now. Match a resource to the phase you are in:
- stuck on Odin syntax -> Section 1
- want to see a full small game in Odin -> Section 2
- confused about Sokol / the renderer -> Section 3
- designing your co-op puzzle game -> Section 4

A lesson always beats a video for *doing*. Use videos/docs for *another angle*.

---

## 1. Learning Odin (the language)

Use these alongside `learn/odin_for_js_devs/`.

- **Official Odin docs — Overview** (the single best reference)
  https://odin-lang.org/docs/overview/
  The whole language in one long page. Bookmark it. Ctrl-F when unsure of syntax.

- **Official Getting Started / Install**
  https://odin-lang.org/docs/install/
  Installing and updating the compiler. Per-platform notes.

- **Official Examples repo** (idiomatic small snippets)
  https://github.com/odin-lang/examples
  How to do specific tasks the Odin way. Read after a concept lesson.

- **Core + vendor package docs** (standard library reference)
  https://pkg.odin-lang.org/
  When you want to know what `core:fmt`, `core:math`, `core:strings` etc offer.

- **Learn Odin in Y Minutes** (fast cheat-sheet skim)
  https://learnxinyminutes.com/odin
  One page, whole language by example. Good for a quick refresher.

- **"Understanding the Odin Programming Language" — Karl Zylinski (book, paid)**
  https://odinbook.com
  The most thorough Odin learning resource. Teaches *why*, not just *how*.
  Worth it if you get serious. Karl ships real Odin games.

- **Karl Zylinski — "Introduction to the Odin Programming Language" (free article)**
  https://zylinski.se/posts/introduction-to-odin/
  Long-form free intro by the book's author. Great second pass after o01-o16.

- **Odin Discord** (live help — the community is small and friendly)
  https://discord.gg/sVBPHEv

- **Odin FAQ**
  https://odin-lang.org/docs/faq/

### Video
- **"Basics of Odin - A Fast, Simple Programming Language" (ThinkWithGames)**
  https://www.youtube.com/watch?v=9cwZWWIV4rY
  ~32 min intro. Assumes some programming experience. Good first watch.

- **gingerBill (Odin's creator) on YouTube/Twitch**
  https://www.youtube.com/channel/UCUSck1dOH7VKmG4lRW7tZXg
  https://www.twitch.tv/ginger_bill

---

## 2. Real Odin Games + No-Engine Gamedev (study how it's actually done)

This is the most valuable section for you. These show a *whole game* structured
the same "just a main loop + libraries" way this repo uses.

- **Karl Zylinski — "No-engine gamedev using Odin + Raylib"**
  https://zylinski.se/posts/no-engine-gamedev-using-odin-and-raylib/
  Exactly your mental model: a game is just a program with a loop. Raylib instead
  of Sokol, but the structure thinking transfers directly.

- **CAT & ONION — a shipped commercial game written in Odin**
  https://store.steampowered.com/app/2781210/CAT__ONION/
  Source code comes with purchase on itch. Real, finished, small-scope Odin game.
  https://zylinski.itch.io/cat-and-onion

- **Solar Storm — Odin + Sokol game (showcase + how it's built)**
  https://odin-lang.org/showcase/solar_storm
  Built on the SAME stack as this repo (Odin + Sokol + sokol-shdc). Read the
  "how it's built" notes: zero runtime allocations, static arrays, temp allocator.
  This is the closest public example to what your repo does.

- **Odin official Showcase (more shipped Odin software)**
  https://odin-lang.org/showcase/

### Useful templates / libraries (for later, not now)
- **Odin + Sokol hot-reload template (Karl Zylinski)**
  https://github.com/karl-zylinski/odin-sokol-hot-reload-template
  Hot reload = change code while the game runs. Big productivity win once you are
  past fundamentals.
- **Karl2D — beginner-friendly 2D Odin library**
  https://github.com/karl-zylinski/karl2d
  An alternative to building everything yourself, if you ever want a simpler base.

---

## 3. Sokol (the graphics layer this repo is built on)

Use these alongside `learn/production_with_sauce/06_what_is_sokol.md` and
`07_sokol_header_map.md`.

- **Sokol main repo + README (what each header does)**
  https://github.com/floooh/sokol
  Read the README sections for `sokol_gfx.h` and `sokol_app.h`. This explains
  exactly what Sokol provides and (importantly) what it does NOT.

- **Official Odin bindings for Sokol** (what your `sauce/sokol/` is based on)
  https://github.com/floooh/sokol-odin

- **sokol-samples (runnable examples, simple -> advanced)**
  https://github.com/floooh/sokol-samples
  Live in-browser versions: https://floooh.github.io/sokol-html5/
  Study the simplest ones (clear, triangle, quad, texture) to understand the
  pass/pipeline/bindings model your repo wraps.

- **"A Tour of sokol_gfx.h" (the author explains the design)**
  https://floooh.github.io/2017/07/29/sokol-gfx-tour.html

- **sokol-shdc (the shader compiler your build uses)**
  https://github.com/floooh/sokol-tools/blob/master/docs/sokol-shdc.md

- **sokol_gp — 2D painter on top of sokol_gfx (concept reference)**
  https://github.com/edubart/sokol_gp
  Not used by this repo, but a clean example of how 2D batching is built on
  Sokol. Good mental model for `sauce/core_render.odin`.

---

## 4. Co-op Puzzle Design (for YOUR game)

Use these alongside `learn/design/coop_lovers_puzzle/`.

Your idea — two separated partners, each sees different information, must talk
to open each other's doors — is a proven, beloved genre. Study what works:

- **We Were Here (series) — the reference for "two players, separate rooms,
  asymmetric info, talk to solve"**
  Series overview: https://en.wikipedia.org/wiki/We_Were_Here_(series)
  First game (free): https://store.steampowered.com/app/582500/We_Were_Here/
  This is almost exactly your concept. Note their core rule: players should
  NEVER see each other's screen — the information gap IS the puzzle.

- **We Were Here Tomorrow — newest entry, explicitly "asymmetric abilities +
  each player holds only part of the info"**
  https://store.steampowered.com/app/2315050/We_Were_Here_Tomorrow/
  Read the key features: "distinct character abilities" + "become each other's
  eyes". That is the "two lovers with different skills" idea you described.

- **Keep Talking and Nobody Explodes — the purest "one sees, one knows" design**
  One player sees the bomb, the other has the manual. Communication only.
  Study how a tiny information asymmetry creates intense co-op.

- **It Takes Two — gold standard for two players with different abilities**
  Each player gets a unique verb; puzzles require combining them. Study how
  every room teaches both verbs then forces cooperation.

- **Reddit: asymmetric co-op game examples (idea bank)**
  https://www.reddit.com/r/CoOpGaming/comments/1f6mnuz/what_asymmetric_coop_games_are_there
  Long list of asymmetric co-op mechanics to steal and adapt.

### Design principle to take from all of these
The fun is NOT both players doing the same thing. The fun is: **each player has
information OR ability the other lacks, so they MUST communicate.** Your "one
sees the keys/pattern and tells the other" is exactly this. Keep it.

---

## 5. General Game Feel + Puzzle Design (timeless talks)

- **"Juice it or lose it" (Martin Jonasson & Petri Purho)** — why game feel
  matters; maps directly to your `t10_particles_screenshake` and `vfx/` lessons.
  Search this title on YouTube (GDC-style talk, widely mirrored).
- **GDC talks on puzzle design** — search "GDC puzzle design" for talks on
  teaching mechanics without text, difficulty curves, and "aha" moments.

(These are widely re-uploaded; pick a current working video. Concepts over any
single link.)

---

## Rule For This Page

Resources are seasoning, not the meal. If you find yourself watching videos
instead of writing `main.odin`, close the browser and go back to the current
lesson. You learn game dev by shipping tiny broken things and fixing them.
