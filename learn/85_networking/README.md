# Networking — Online Rooms & Remote Co-op (Read Last)

You want your two-lovers co-op game to support **creating a room, hosting, and a
remote friend connecting over the internet.** This folder is for that.

> **Read this folder LAST.** Do not touch networking until your game is fully
> playable LOCALLY (two players, one keyboard, all puzzles working). Networking
> is the single hardest thing in your whole plan. Adding it before the game is
> fun will sink the project. This is not caution for its own sake — it is the
> #1 reason solo multiplayer games never ship.

This folder is reading + examples, not lessons to grind. Skim it now so you know
what is coming. Come back and work through it only when local co-op is done.

---

## The Honest Big Picture

There are two realistic ways to make "host a room, friend joins over internet":

| | **Path A: Steam** (recommended) | **Path B: Raw sockets** (hard mode) |
|---|---|---|
| What you use | The Steamworks SDK **already in this repo** (`sauce/steamworks/`) | Odin's `core:net` + your own protocol |
| Who handles NAT/firewalls | Valve (relay network) — it "just works" | YOU. This is brutal and the real reason P2P is hard. |
| Rooms / lobbies | Built in (`ISteamMatchmaking` lobbies) | You build a lobby system from scratch |
| Cost | Free SDK; $100 one-time to ship on Steam | Free, but you may need to rent a relay server |
| Effort for your game | Medium | Very high |
| Best for | Actually shipping a co-op game to players | Learning how networking works underneath |

**Recommendation:** Use **Path A (Steam)**. The repo already bundles Steamworks
with full Lobby + P2P + Relay support — Valve solves the NAT-punchthrough problem
that makes internet P2P genuinely hard. Path B is here so you understand what is
happening underneath, and as a fallback if you do not want Steam.

---

## What Lives In This Folder

Read in order:

1. `01_networking_reality_check.md`
   The hard truth about scope, latency, and why "just sync the two players" is
   not simple. Read this BEFORE you decide to add networking.

2. `02_concepts_for_web_devs.md`
   Networking concepts mapped from what you already know (HTTP, fetch, WebSocket,
   client/server). Bridges your web brain to game networking.

3. `03_input_for_networked_coop.md`
   The input helper examples you asked for. The key idea: structure input so it
   is **network-ready from day one**, even while your game is still local. This
   is the one thing worth doing EARLY.

4. `04_steam_lobbies_path.md`
   Path A. How to use the bundled Steamworks for rooms/hosting/connecting.

5. `05_raw_sockets_path.md`
   Path B. From-scratch networking with Odin's `core:net`. Educational.

6. `RESOURCES.md`
   Verified external links: Odin net docs, Steam docs, Valve's open-source
   networking library, and the famous Gaffer On Games networking articles.

---

## The One Thing To Do Early (everything else waits)

You do NOT write networking code early. But you DO structure your game so it is
ready for it. One rule, applied from the start of your `sauce/` game:

**Separate "input" from "what the input does."**

Instead of the player update reading the keyboard directly, it reads an *input
intent* ("move left", "pull lever"). Where that intent comes from — local
keyboard OR a network message from your partner — becomes a detail you can swap
later. Do this from day one and adding networking later is a port, not a rewrite.

`03_input_for_networked_coop.md` shows exactly how. That is the only networking-
shaped work worth doing before the game is fun.

---

## Where This Sits In Your Path

```
... 30_fundamentals -> 70_co_op (LOCAL co-op working) -> 80_design (your game)
    -> build it in sauce/ as LOCAL two-player -> ship/playtest local
    -> THEN: 85_networking (this folder) -> add online rooms
```

Local first. Always. Networking is the last layer, not the foundation.
