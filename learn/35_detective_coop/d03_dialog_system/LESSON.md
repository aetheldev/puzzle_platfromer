# D03 — Branching Dialog System

## Goal

Talk to a witness. Build a **data-driven branching dialog tree**: the witness
says something, you pick from a few replies, your choice jumps to another node,
and some choices grant a clue. This is the conversation engine behind every
adventure/RPG.

---

## The Concept

A dialog is a **graph of nodes**. Each node has the speaker's line and a list of
**choices**; each choice has player text and the id of the next node (or "end").
The whole conversation is DATA, not code.

```odin
Node_Id :: enum { start, ask_alibi, ask_weapon, accuse, end }

Choice :: struct {
    text:    string,
    next:    Node_Id,
    gives:   Clue,        // optional clue granted by picking this
}

Node :: struct {
    speaker_line: string,
    choices:      []Choice,
}
```

You keep one piece of runtime state: `current: Node_Id`. Render the current
node's line + its choices. On choosing, grant any clue and set
`current = choice.next`. When you reach `.end`, close the dialog.

### Why data, not `if`-chains

A 200-line conversation is a big table, not 200 lines of branching code. You can
later load it from a file, localize it, or let a designer edit it without
touching Odin. Same lesson as hotspots-as-data (t13) and recipes (d02): **content
is data**.

### Gating choices

Real dialogs hide options until you've earned them ("[Show the photo]" only
appears if you have it). Add a condition:

```odin
Choice :: struct {
    text:      string,
    next:      Node_Id,
    gives:     Clue,
    needs_clue: Clue,   // .none = always shown
}
```

Filter choices whose `needs_clue` you don't yet have.

---

## If You Know JS/React...

A dialog tree is a state machine: `current` is the state, choices are
transitions. Like a multi-step form/wizard where each answer routes to the next
screen. You'd store it as a JSON object of nodes; here it's an Odin array.

---

## Key Concepts

### The node table
```odin
NODES := [Node_Id]Node {
    .start = {
        "Detective. I already told the other officer everything.",
        []Choice{
            {"Where were you at 9pm?", .ask_alibi, .none, .none},
            {"Did you see the weapon?", .ask_weapon, .none, .none},
            {"That's all.", .end, .none, .none},
        },
    },
    // ...
}
```

### Advance on choice
```odin
choose :: proc(c: Choice) {
    if c.gives != .none { grant_clue(c.gives) }
    current = c.next
}
```

### Visible choices (gating)
```odin
for c in NODES[current].choices {
    if c.needs_clue == .none || has_clue(c.needs_clue) {
        // draw + make clickable
    }
}
```

---

## Line-by-Line Breakdown

Open `learn/95_solutions/detective_coop/d03_dialog_system/main.odin`.

- Read `Node_Id`, `Choice`, `Node`, and the `NODES` table — the whole script.
- Read `current` + `choose`: the entire runtime engine is a few lines.
- Read `frame`: draw the speaker line, draw visible choices as clickable rows,
  click a row → `choose`.

---

## Exercises

1. Add a node `ask_motive` reachable from `start`.
2. Add a gated choice "[Show the photo]" that needs `clue_photo` and unlocks an
   accusation branch.
3. Make `accuse` lead to two different `end` lines depending on whether you have
   the `clue_weapon`.
4. Add a "back" choice that returns to `start` from any sub-topic.

---

## Exit Criteria

- [ ] Your dialog is a node table (data), not nested ifs
- [ ] Choices route to the next node via a `Node_Id`
- [ ] A choice can grant a clue
- [ ] Gated choices appear only when their condition is met
- [ ] It builds and runs

---

## Next Lesson

`learn/35_detective_coop/d04_clue_notebook`
