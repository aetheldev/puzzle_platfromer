# 03 — Input For Networked Co-op (Examples)

This is the part you asked for: input helpers, structured so your game is
**network-ready from day one** even while it is still 100% local.

The single most important idea in this whole folder:

> Do not let gameplay read the keyboard directly. Let it read an **input intent**.
> Where that intent comes from (local keys, or a network message) becomes a
> swappable detail. Build this early and networking later is a port, not a rewrite.

All code below is illustrative Odin in the style of this repo's `sauce/`. Adapt
names to match your game.

---

## The Problem With Reading Keys Directly

In `sauce/game.odin` today, the player update reads input directly:

```odin
// from sauce/game.odin — setup_player
e.update_proc = proc(e: ^Entity) {
    input_dir := get_input_vector()         // reads the keyboard NOW
    e.pos += input_dir * 100.0 * ctx.delta_t
    // ...
}
```

This is fine for a single local player. But for co-op — and especially networked
co-op — it is a dead end, because:
- It only knows about ONE input source (the one keyboard mapping).
- A remote player's input does not come from this keyboard at all — it comes from
  the network. There is nowhere to plug that in.

---

## The Fix: An Input Intent Struct

Define what a player WANTS to do this frame, separate from how we found out.

```odin
// One frame of intent for ONE player. This is also exactly what you will
// send over the network later — it is small and serializable.
Player_Intent :: struct {
    move:           Vec2,   // -1..1 on each axis (already normalized)
    pull_lever:     bool,   // pressed interact this frame
    // add more verbs as your game grows: grab, look, etc.
}
```

Now each player entity holds an intent, and the update reads from THAT, not the
keyboard:

```odin
// On your lover entity (add these fields)
Lover :: struct {
    // ... existing fields ...
    is_red:  bool,
    intent:  Player_Intent,   // filled each frame, from SOME source
}

// The update proc only knows about intent. It does NOT know or care
// whether the intent came from a keyboard or the network.
lover_update :: proc(e: ^Entity) {
    in := e.intent

    e.pos += in.move * LOVER_SPEED * ctx.delta_t

    if in.pull_lever {
        try_pull_lever(e)
    }
}
```

That is the whole trick. The gameplay is now **input-source agnostic.**

---

## Filling Intent Locally (two players, one keyboard)

For your local couch co-op, fill each lover's intent from a different key set.
This reuses the repo's `key_down` helpers from `core_input.odin`.

```odin
// Build an intent from a specific key set.
intent_from_keys :: proc(
    up, down, left, right, interact: Key_Code,
) -> Player_Intent {
    intent: Player_Intent

    dir: Vec2
    if key_down(left)  { dir.x -= 1 }
    if key_down(right) { dir.x += 1 }
    if key_down(up)    { dir.y += 1 }
    if key_down(down)  { dir.y -= 1 }

    // normalize so diagonal isn't faster (you learned this in t03_movement)
    if dir != {} {
        dir = linalg.normalize(dir)
    }
    intent.move = dir

    intent.pull_lever = key_pressed(interact)
    return intent
}

// Each frame, BEFORE running lover_update, fill both intents:
fill_local_intents :: proc(red: ^Entity, blue: ^Entity) {
    red.intent  = intent_from_keys(.W, .S, .A, .D, .E)              // red = WASD + E
    blue.intent = intent_from_keys(.UP, .DOWN, .LEFT, .RIGHT, .RIGHT_SHIFT) // blue = arrows + shift
}
```

Note: the repo's existing `action_map` in `game.odin` maps ONE action set. For
two local players you bypass it and map two explicit key sets, exactly as above.
That is the small input task mentioned in the engine review — it lives here.

---

## The Same Code, Now Network-Ready

Here is why the intent struct matters. When you add networking, you change ONLY
where intent comes from. Gameplay (`lover_update`) does not change at all.

```odin
// Pseudocode for the networked version (Path A or B both look like this).
fill_intents_networked :: proc(local: ^Entity, remote: ^Entity) {
    // 1. Local player's intent comes from the keyboard, same as before.
    local.intent = intent_from_keys(.W, .S, .A, .D, .E)

    // 2. Send our intent to the partner over the network.
    net_send_intent(local.intent)

    // 3. The remote player's intent comes from the LAST message we received.
    //    (poll, never block — see 02_concepts_for_web_devs.md)
    if msg, ok := net_poll_intent(); ok {
        remote.intent = msg
    }
    // if no new message arrived, remote keeps its last intent (simple + fine)
}
```

`lover_update` is identical in local and networked builds. THAT is the payoff of
separating input from simulation. You did the hard architectural work early and
for free, while the game was still local.

---

## Serializing Intent For The Wire

When you send intent over the network, you send its bytes. Because
`Player_Intent` is a small plain struct (no pointers, no slices), this is trivial
in Odin:

```odin
import "core:mem"

// Turn an intent into bytes to send.
intent_to_bytes :: proc(intent: Player_Intent) -> []u8 {
    return mem.ptr_to_bytes(&intent)   // raw struct bytes
}

// Turn received bytes back into an intent.
bytes_to_intent :: proc(data: []u8) -> (intent: Player_Intent, ok: bool) {
    if len(data) < size_of(Player_Intent) { return {}, false }
    intent = (cast(^Player_Intent)raw_data(data))^
    return intent, true
}
```

Keep intent small (a few bytes). You send it a handful of times per second, which
is plenty for a co-op puzzle. Do NOT send the whole game state — send intents,
let the host compute the result.

> Caveat for later: sending raw struct bytes works when both machines are the same
> architecture/build. For a shipped cross-platform game you would define an
> explicit byte layout (version it, pick endianness). For two friends on the same
> build, raw bytes are fine to learn with. Note it; don't over-engineer now.

---

## Host Authority In One Picture

For your game (Path A, host authority):

```
RED machine (host)                      BLUE machine (client)
------------------                      ---------------------
read RED keys  -> red.intent            read BLUE keys -> local.intent
receive BLUE intent over net            send local.intent over net
run FULL game (both lovers, levers,     receive authoritative state from host
  doors, win) using both intents          (positions, door_open, won)
send authoritative state to BLUE        draw what host says
draw                                    (optionally predict own movement)
```

The host runs the real simulation. The client mostly sends its intent and draws
the result. This is the simplest correct model and it fits your game perfectly.

---

## Checklist: Make Your Game Network-Ready (do this while LOCAL)

- [ ] Define a `Player_Intent` struct (move + your verbs).
- [ ] Each lover has an `intent` field.
- [ ] `lover_update` reads `e.intent`, never the keyboard directly.
- [ ] A `fill_local_intents` step fills both intents from two key sets each frame.
- [ ] You can serialize an intent to bytes and back.

If all five are true, your local game is already shaped for networking. Adding
Steam or sockets later only changes where intent comes from.

---

## Next

Pick your path:
- `04_steam_lobbies_path.md` — rooms/hosting via the bundled Steamworks (recommended).
- `05_raw_sockets_path.md` — from scratch with Odin `core:net` (educational).
