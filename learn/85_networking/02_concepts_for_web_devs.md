# 02 — Networking Concepts For Web Developers

You already know more networking than you think. You have used HTTP, fetch,
maybe WebSockets. This page maps that knowledge onto game networking so the
terms are not scary.

---

## What Transfers From Web Dev

| You know (web) | Game networking equivalent |
|---|---|
| HTTP request/response | A reliable message (sent, confirmed delivered) |
| `fetch()` / `await` | Sending a message and waiting — but games can't block! |
| WebSocket (persistent connection) | A game "connection" — open the whole session |
| Client / server | Same idea: one authority, many clients |
| JSON payload | Your "packet" — the bytes you send each update |
| `localhost` vs production server | `localhost` vs the real internet (NAT, latency) |

---

## What Is Different (and why it matters for games)

### 1. You cannot `await` in a game loop
In web code you write `const data = await fetch(...)`. The code pauses until the
response arrives. **A game loop must NEVER pause** — it runs 60 times a second.
If you wait for the network, the game freezes.

Instead, networking in games is **polled**, exactly like input:
```
every frame:
    poll for any messages that arrived  (non-blocking)
    process them
    maybe send some messages
    continue the frame — never wait
```
You already learned this mindset in `learn/20_game_thinking_for_web_devs/
g04_no_async_in_game_loop`. Networking is that lesson applied for real.

### 2. TCP vs UDP (reliable vs fast)
- **TCP** = like HTTP. Guaranteed delivery, in order. But if a packet is lost it
  STALLS everything waiting to resend. Bad for real-time games.
- **UDP** = fire and forget. Fast, no guarantees. Packets can vanish or arrive
  out of order. Games prefer UDP and add their own "make this one reliable" layer
  on top, only for messages that need it.

For your slow co-op puzzle, you can honestly start with the simpler reliable
option and not worry about UDP tuning. Steam's networking gives you BOTH reliable
and unreliable messages on one connection — you just pick per message.

### 3. There is no server you rent (for P2P)
In web dev, there is always a server somewhere. In peer-to-peer games, one
player's machine acts as the "host" (the server). The other connects to it. The
hard part is letting them connect THROUGH home routers — that is what Steam's
relay or a TURN server does for you.

---

## The Three Networking Models (pick the simplest that works)

### A. Peer-to-peer, host authority (recommended for you)
- One player hosts (is the authority). The other connects to them.
- Host runs the real game. Client sends inputs, draws what host reports.
- Simple. Perfect for 2-player co-op. No server to rent (with Steam relay).

### B. Dedicated server
- A separate always-on computer runs the game; both players connect to it.
- Overkill for a 2-player co-op puzzle. Skip.

### C. Lockstep / deterministic
- Both machines run the SAME simulation, only exchange inputs.
- Elegant and low-bandwidth, but requires your game to be perfectly deterministic
  (same inputs always give identical results on both machines — surprisingly hard
  with floats). Mention it so you know it exists. Not your first choice.

**Use model A.** One host, one client, host is the truth.

---

## Vocabulary You Will See (decoded)

- **Latency / ping / RTT** — round-trip time for a message. Lower is better.
- **Packet loss** — messages that never arrive. The network's fault, not yours.
- **Authority** — whose version of the game is "correct". You pick the host.
- **Replication** — copying game state from host to client.
- **Prediction** — client guesses its own movement immediately so it feels
  responsive, instead of waiting for the host to confirm.
- **Reconciliation** — when the host's truth differs from the client's guess, the
  client corrects. (For slow co-op, this is rarely visible.)
- **NAT traversal / hole punching** — the dark art of connecting through home
  routers. Let Steam do it.
- **Lobby / matchmaking** — the "room" system: create, list, join. Steam gives
  you this for free.

---

## How Small Your Game's Networking Can Be

For your two-lovers puzzle, an honest minimum:
- A connection between two players (Steam or sockets).
- A few times per second, each player sends: "my position is X,Y" and "I pulled
  lever 3".
- The host decides door/win state and sends it back.

That is genuinely most of it. You are not building Fortnite. Keep it that small.

---

## Next

`03_input_for_networked_coop.md` — the input examples you asked for, structured so
this whole thing becomes a port instead of a rewrite.
