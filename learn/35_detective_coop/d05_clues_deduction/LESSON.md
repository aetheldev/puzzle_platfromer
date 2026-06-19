# D05 — Clues & Deduction

## Goal

Turn clues into conclusions. Build a **deduction system**: the player picks a
set of pinned clues and proposes a conclusion; if the right clues are selected,
the deduction "locks in" and unlocks the next step. This is the puzzle layer —
and the thing two detectives solve together.

---

## The Concept

A deduction is a **rule**: "these required clues ⇒ this conclusion". Same
data-driven shape as recipes (d02) and dialog (d03):

```odin
Conclusion :: enum { none, suspect_lied, weapon_is_knife, killer_identified }

Deduction :: struct {
    needs:      bit_set[Clue],   // the clues that must all be selected
    yields:     Conclusion,
    forbids:    bit_set[Clue],   // (optional) clues that must NOT be selected
}
DEDUCTIONS := []Deduction{ ... }
```

The player's working set is `selected: bit_set[Clue]` (from pinned notebook
clues, d04). To resolve: find a deduction whose `needs` are all in `selected`
and whose `forbids` are absent. If found, mark the conclusion reached.

```odin
try_deduce :: proc(sel: bit_set[Clue]) -> (Conclusion, bool) {
    for d in DEDUCTIONS {
        if (d.needs & sel) == d.needs && (d.forbids & sel) == {} {
            return d.yields, true
        }
    }
    return .none, false
}
```

### Why `bit_set`?

This is exactly what `o19_bit_set` taught: a set of enum values packed into one
integer. `&` (intersection), `==` (subset check), `+`/`-` (add/remove). A
deduction rule is set algebra — clean and fast, no loops over arrays.

### The detective fantasy

Wrong clue combos give a "that doesn't add up" — the same satisfying loop as
Return of the Obra Dinn or Phoenix Wright: gather, hypothesize, confirm. The
DESIGN (which clues prove what) is the game; the code is small.

---

## If You Know JS/React...

`selected` is a `Set`. A deduction check is `needs.every(c => selected.has(c))`.
The `bit_set` version is the same idea but as bitwise ops on one number —
faster and the natural Odin tool.

---

## Key Concepts

### Toggle a clue into the working set
```odin
if clue in selected { selected -= {clue} } else { selected += {clue} }
```

### Subset test = "all required clues present"
```odin
(d.needs & selected) == d.needs   // true if every needed clue is selected
```

### Lock in a conclusion
```odin
if concl, ok := try_deduce(selected); ok {
    reached[concl] = true
}
```

---

## Line-by-Line Breakdown

Open `learn/95_solutions/detective_coop/d05_clues_deduction/main.odin`.

- Read `Conclusion`, `Deduction`, `DEDUCTIONS` — the rules as data.
- Read `selected: bit_set[Clue]` and the toggle logic.
- Read `try_deduce` — the set-algebra check (the whole engine).
- Read `frame`: clue chips you click to toggle, a "Deduce" button, and the
  reached-conclusions list.

---

## Exercises

1. Add a deduction that needs two clues AND forbids a third (a red herring).
2. Show a live "X of N clues selected match a known deduction" hint.
3. Make `killer_identified` require a conclusion from an earlier deduction (a
   two-step chain): add reached conclusions into the selectable set.
4. Add a wrong-guess counter and a snarky message at 3 wrong deductions.

---

## Exit Criteria

- [ ] Deductions are data: `needs`/`forbids` as `bit_set[Clue]`
- [ ] You toggle clues into a `selected` set
- [ ] `try_deduce` uses subset/intersection set algebra
- [ ] A correct set locks in a conclusion; a wrong set is rejected
- [ ] It builds and runs

---

## Next Lesson

`learn/35_detective_coop/d06_two_detective_coop`
