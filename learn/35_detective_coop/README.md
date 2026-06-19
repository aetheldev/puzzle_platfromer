# Detective Co-op — Two Detectives, One Case

[DO] track. Open this AFTER `30_fundamentals/t13_point_and_click`. That lesson
taught the genre's core tech (hit-testing, hotspots-as-data, state flags). This
track grows it into a real **two-detective co-op investigation game**:

> One detective examines the crime scene (clicks objects, collects evidence).
> The other combines clues, takes notes, and runs deductions. Together they
> solve a puzzle neither could alone.

This is YOUR milestone game. Each lesson adds one system, step by step, with a
runnable Odin + sokol_gl program you build yourself.

## Why this design

Strong co-op = **asymmetric information + asymmetric ability**. A weak co-op
game has both players doing the same thing. Here:

- Detective A (the **Field** agent): mouse. Searches the scene, picks up and
  inspects evidence, talks to a witness.
- Detective B (the **Desk** agent): keyboard. Reads the shared notebook,
  combines clues, proposes the deduction that opens the next step.

Neither can finish alone. That forces communication — the heart of co-op.

## The systems you build (in order)

| #   | Folder                  | System | Builds on |
|-----|-------------------------|--------|-----------|
| d01 | `d01_multi_inventory`   | multi-slot inventory: collect many items, select one | t13 one-slot |
| d02 | `d02_inspect_combine`   | inspect an item up close; combine two items into a new one | d01 |
| d03 | `d03_dialog_system`     | branching dialog with a witness; choices reveal clues | d01 |
| d04 | `d04_clue_notebook`     | a shared notebook: clues get logged, browsable, pinned | d02 + d03 |
| d05 | `d05_clues_deduction`   | combine clues into a deduction (A + B => conclusion) | d04 |
| d06 | `d06_two_detective_coop`| put it together: split-role two-detective case, one screen | all of the above |

## Co-op model (this track)

**Single screen, local, split-role. No networking.** Detective A uses the
mouse on the left scene; Detective B uses keyboard on the right notebook/deduction
panel. This is the formalized version of t13's "describe, partner solves"
exercise. Online two-window co-op comes LAST, only after this works:
`learn/85_networking/06_two_windows_local_to_network.md`. The whole design is
networking-ready because every action is a small intent
(`{who, action, target}`), trivial to serialize later.

## How to use this folder

Same loop as all of `learn/`:

1. Read the `LESSON.md`.
2. Read only the marked block(s) of the solution under
   `learn/95_solutions/detective_coop/<folder>/main.odin`.
3. Write your own `main.odin` in the lesson folder, then `zsh build.sh`.
4. Finish rule: run it, change one thing, break one thing, fix it, add one tweak.

## Where this goes next

- Add a `45_shaders_postfx` mood (fog/darkness/grading) to the crime scene.
- Pre-render props in Blender (`47_graphics_programming/gp14`) for real art.
- Promote the case into the real engine:
  `learn/90_production_with_sauce/` (and `learn/80_design/coop_lovers_puzzle/`
  for your wider co-op design).
