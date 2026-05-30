# Networking — External Resources

Verified links for building online co-op. Read these when you reach this folder,
not before. Grouped by what you need.

---

## Game Networking Theory (read first — genre-independent)

- **Gaffer On Games — Game Networking series** (the canonical resource)
  https://gafferongames.com/categories/game-networking/
  Glenn Fiedler's articles are THE reference for game networking. Start with:
- **"What Every Programmer Needs To Know About Game Networking"**
  https://gafferongames.com/post/what_every_programmer_needs_to_know_about_game_networking/
  Explains client/server, lockstep, authority, prediction — exactly the concepts
  in `02_concepts_for_web_devs.md`, in depth.
- **"Reliable Ordered Messages"** (how to add reliability on top of UDP)
  https://gafferongames.com/post/reliable_ordered_messages/
  If you go Path B (raw sockets) and need some messages guaranteed, this is how.

---

## Odin Networking (Path B: from scratch)

- **`core:net` package docs** (Odin's standard-library sockets)
  https://pkg.odin-lang.org/core/net/
  TCP, UDP, DNS, addresses. Your toolkit for raw networking.

- **Odin net example**
  https://github.com/odin-lang/examples/tree/master/net
  Idiomatic socket usage in real Odin.

- **Odin nbio example** (non-blocking IO — needed for a game loop)
  https://github.com/odin-lang/examples/tree/master/nbio
  How to do networking without blocking your 60fps loop.

- **core:thread** (run blocking network calls off the main loop)
  https://pkg.odin-lang.org/core/thread/

---

## Steam Networking (Path A: recommended for shipping)

- **Steam Matchmaking & Lobbies** (your "rooms" system)
  https://partner.steamgames.com/doc/features/multiplayer/matchmaking
  How lobbies work: create, search, join, lobby data, the host/owner concept.
  Read this to understand your room-creation flow.

- **ISteamMatchmaking API reference** (the lobby functions)
  https://partner.steamgames.com/doc/api/ISteamMatchmaking

- **Steam Networking overview**
  https://partner.steamgames.com/doc/features/multiplayer/networking

- **ISteamNetworkingSockets API reference** (the modern connection API)
  https://partner.steamgames.com/doc/api/ISteamNetworkingSockets
  CreateListenSocketP2P, ConnectP2P, SendMessageToConnection,
  ReceiveMessagesOnConnection — the functions you call from the repo's binding.

- **Steam Datagram Relay** (why Steam solves NAT for you)
  https://partner.steamgames.com/doc/features/multiplayer/steamdatagramrelay

> The repo already bundles these bindings at `sauce/steamworks/steamworks.odin`.
> The Steam docs above describe the C interface; the Odin binding mirrors it.

---

## Valve's Open-Source Networking Library (deep reference)

- **GameNetworkingSockets** (the actual library behind Steam networking)
  https://github.com/ValveSoftware/GameNetworkingSockets
  Reliable+unreliable messages over UDP, fragmentation, encryption, P2P/NAT.
- **README_P2P** (peer-to-peer specifics)
  https://github.com/ValveSoftware/GameNetworkingSockets/blob/master/README_P2P.md
  You can use this open-source version WITHOUT Steam if you run your own relay —
  advanced, but it is the same tech.

---

## Engine / Repo Context

- **Sokol** (your render/app layer — does NOT do networking; that's separate)
  https://github.com/floooh/sokol
- **Sokol Odin bindings**
  https://github.com/floooh/sokol-odin

---

## Suggested Reading Order When You Get Here

1. `01_networking_reality_check.md` (in this folder) — scope honesty.
2. Gaffer "What Every Programmer Needs To Know About Game Networking" — theory.
3. `02_concepts_for_web_devs.md` — map it to what you know.
4. `03_input_for_networked_coop.md` — structure your input (do this EARLY).
5. Pick a path: Steam matchmaking docs (Path A) OR `core:net` docs (Path B).
6. `04_steam_lobbies_path.md` or `05_raw_sockets_path.md`.

---

## Reminder

Networking is the LAST layer. Finish and playtest your LOCAL co-op game first.
Then come here. Everything in this folder assumes the game already works offline.
