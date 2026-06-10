# 06 — Two Windows: From One Screen To The Network

> The question this file answers: *"All the co-op lessons show ONE
> window with two characters (blue + green). How do I get TWO windows,
> one per player? How does local become network?"*

Short answer: **you never make one app with two windows. You run the
game TWICE.** Two processes, two windows — first on the same machine,
later on two machines. That is not a workaround; that IS how networked
games work.

---

## Why Not One App With Two Windows?

Technical reason: `sokol_app` (this repo's windowing layer) gives you
**one window per process**. There is no second-window API. This is
true of most game frameworks — a game is one window owning one
swapchain, one input stream, one main loop.

But the deeper reason: two windows on one machine is a dead end
anyway. Your real goal is two PLAYERS on two MACHINES. Each machine
runs its own copy of the game = its own process = its own window.
So the thing you actually need to learn is not "second window" — it is
**"two copies of my game agreeing on one shared game state."**

One mouse per machine also matters for YOUR game: a point-and-click
cannot share a single mouse between two couch players. So for the
detective game, the two-process model is not optional polish — it is
the natural shape of the game.

---

## The Ladder: Local → Two Windows → Internet

Each rung is small. Do them in order. You are at rung 1 today.

```
rung 1   ONE window, two players, one keyboard (WASD + arrows)
         <- all current co-op lessons live here. CORRECT place to start.

rung 2   ONE window, but input goes through Player_Intent structs
         <- Ticket 075. No visible change. Everything changes.

rung 3   TWO windows, SAME machine: run the game twice in two
         terminals. Process A = host, process B = client.
         They talk over localhost (127.0.0.1). Each window draws
         the SAME shared world; each sends only its own intents.
         <- two terminals, two `zsh build.sh` runs, zero internet.

rung 4   TWO machines, same wifi (LAN). Same code as rung 3 —
         only the IP address changes.

rung 5   TWO machines, anywhere on earth. NAT/firewalls now bite.
         Steam's relay (Path A, doc 04) solves this for you.
```

The magic insight: **rung 3 is rung 5.** Code that works over
localhost between two processes is already network code. localhost is
just a network with zero latency and zero packet loss. Steam later
replaces "which address do I send to" — not your game logic.

---

## What Each Process Does (Host-Authoritative Model)

The model every doc in this folder assumes:

```
HOST process (player 1)                 CLIENT process (player 2)
========================                =========================
owns the REAL game state                has a COPY of game state
                                        
reads own keyboard/mouse                reads own keyboard/mouse
  -> Player_Intent A                      -> Player_Intent B
                                        
                    <---- intent B ----  sends intent B to host
                                        
applies intent A + intent B            
to the real state                       
(one update proc, both players)         
                                        
sends state snapshot ---->              overwrites its copy
                                        
draws its window from state             draws its window from state
```

Both windows run the same executable. A flag decides the role:

```
./game host
./game join 127.0.0.1
```

Key consequences:

- **Game logic runs ONCE** (on the host). The client is a fancy
  remote control with a screen. No desyncs possible.
- The client never moves its own player directly — it sends the
  intent and waits for the snapshot. (On localhost the wait is
  invisible. Over internet you add prediction LATER, if ever. For a
  slow puzzle game: probably never. This is why your genre choice is
  lucky — see doc 01.)
- This is why Ticket 075 exists: if your gameplay already reads
  `e.intent` instead of the keyboard, rung 3 is mostly plumbing.

---

## What Goes Over The Wire (Your Detective Game)

A point-and-click co-op is the EASIEST genre to network:

```odin
// client -> host, on click (a few bytes, not 60/sec!)
Click_Intent :: struct {
    player: u8,
    target: Hotspot_Id,      // from t13 — already an enum
    held:   Held_Item,
}

// host -> clients, after each state change
Room_State :: struct {
    flags:        bit_set[Room_Flag; u8],   // o19 — one byte
    door_open:    bool,
    code_progress: u8,
}
```

Compare a shooter syncing 20 positions at 60Hz. You sync a few enums
per CLICK. Turn-based-grade traffic. Doc 01's scariest warnings mostly
do not apply to you — but read it anyway.

The asymmetric twist ("each detective sees different things") is
client-side: same `Room_State` arrives, each window DRAWS it through
its own player's view — exactly the parallel-worlds trick
(`learn/70_co_op/parallel_worlds_puzzle/`), one world drawn two ways,
now in two processes instead of split-screen.

---

## How To Practice Rung 3 (when you get there)

Not yet — finish local first. But so you know the shape:

1. `05_raw_sockets_path.md` step 1 has the two-terminal localhost
   echo example. Two processes talking on one machine in ~40 lines.
2. Wrap it: host listens, client connects, exchange one
   `Player_Intent` per frame, print it.
3. Bolt onto your t13 room: client clicks drawer -> host applies ->
   both windows show it open. That moment is the whole concept proven.
4. Then doc 04 (Steam lobbies) to replace localhost with the internet.

On macOS, note: run the two instances from two terminals with the
binary directly is fine for the HOST (no keyboard focus issue if it is
mouse-only!), but use the `.app` wrapper trick from
`learn/run_graphics.sh` when keyboard input matters.

---

## Summary

- Two windows = two processes = run the game twice. No two-window API
  exists and you do not want one.
- Local one-window co-op is NOT wasted work — it is rung 1, and the
  game logic you write there runs unchanged on the host later.
- Ticket 075 (intents) is the hinge. Do it while local.
- localhost between two processes IS networking. Steam just swaps the
  address book.
- Your genre clicks-not-positions traffic makes you the easy case.

Next: `04_steam_lobbies_path.md` when local co-op is fun and tested.
