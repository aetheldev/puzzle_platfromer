# 01 — Networking Reality Check (Read Before You Commit)

Honest talk. Networking is not "add multiplayer." It is a different discipline.
This page exists so you go in with eyes open, not to scare you off.

---

## Why Networking Is Hard (the real reasons)

### 1. The internet is not your localhost
On your machine, two players share the same memory. Data is instant and always
correct. Over the internet:
- Messages take time (latency — 20ms to 300ms).
- Messages arrive out of order, or not at all (packet loss).
- The two machines drift out of sync unless you constantly correct them.

### 2. NAT / firewalls block direct connections
Your friend's router does not, by default, let a stranger's computer connect in.
This is "NAT traversal" and it is the single biggest reason hobby P2P games fail.
Solving it yourself means STUN/TURN servers, hole-punching, relays — a project on
its own. **This is the problem Steam solves for you** (see `04_steam_lobbies_path.md`).

### 3. Two sources of truth fight
If both players' games decide "the door is open" independently, they will
disagree. You need a rule for who is right (usually: one player is the "host" /
authority, the other obeys). Designing that rule is most of networking.

### 4. Cheating and trust
Less relevant for a co-op puzzle with a friend, but: never trust the other
machine blindly. For your game this is low risk (you are co-operating), which is
one more reason a co-op puzzle is a GOOD first networked game.

---

## Good News: Your Game Is The Easy Case

Co-op turn-ish puzzle games are the FRIENDLIEST genre to network. Why:
- **No twitch timing.** A 100ms delay on "I pulled the lever" is fine. Compare to
  a fighting game where 100ms ruins it.
- **Few moving objects.** Two players, some levers, some doors. Not 200 bullets.
- **Cooperative, not competitive.** No cheating pressure, no need for an
  authoritative anti-cheat server.
- **Low update rate is OK.** You can send "player moved to tile X" a few times a
  second, not 60 times a second.

So: networking is hard in general, but YOUR specific game is near the easy end.
That is a real, honest reason to be optimistic — once the local game works.

---

## The Trap That Kills Projects

> "I'll build it multiplayer from the start so I don't have to add it later."

This is the most common way solo multiplayer games die. What actually happens:
- You spend weeks on connection code with nothing fun to play.
- Every gameplay change now has to be tested across two machines.
- You burn out before the game is ever fun.

### Do this instead
1. Build the WHOLE game local (two players, one keyboard). Make it fun.
2. Playtest it on a couch with a real friend. Fix the design.
3. ONLY THEN add networking, by swapping the input source (see `03_...`).

Because you separated input from simulation early (the one early task), step 3 is
a port, not a rewrite.

---

## What "Adding Networking" Will Actually Involve

When the time comes, roughly:
1. Pick host authority: one player's game is the truth, the other mirrors it.
2. On the host: run the real simulation (levers, doors, win state).
3. Send the other player your inputs/intents over the network.
4. The host applies both players' inputs, then sends back the resulting state.
5. The non-host draws what the host says, and predicts its own movement locally so
   it feels responsive.

That is the shape of it. Each step has depth, but for a slow co-op puzzle, the
simplest version of each is enough. You do not need rollback netcode or
prediction-heavy systems that action games require.

---

## Decision Checklist Before You Start Networking

Only begin when you can tick ALL of these:
- [ ] The game is fully playable LOCAL, two players, one keyboard.
- [ ] You have playtested it with a real second person and it is fun.
- [ ] Your player update reads an *input intent*, not the keyboard directly
      (see `03_input_for_networked_coop.md`).
- [ ] You have decided: Steam (Path A) or raw sockets (Path B).
- [ ] You accept this will take real time and is its own learning project.

If any box is empty, you are not ready. Go finish that first. That is not a
delay — it is the fastest route to a finished networked game.

---

## Next

`02_concepts_for_web_devs.md` — networking concepts mapped from your web
background, so the terms stop being scary.
