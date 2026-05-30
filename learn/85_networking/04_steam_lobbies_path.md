# 04 — Path A: Steam Lobbies (Recommended)

This is the realistic path for "create a room, host, friend connects over the
internet." The repo **already bundles Steamworks** — Valve does the hard part
(NAT traversal, relay) for you.

> Use this path if you want to actually ship a co-op game to players. It is far
> less work than building NAT traversal yourself.

---

## What The Repo Already Has

```
sauce/steamworks/steamworks.odin   <- ~6000 lines of Steamworks bindings
```

It already exposes the networking interfaces you need (verified present in the
binding):
- **ISteamMatchmaking** — Lobbies = your "rooms". Create, list, join, leave.
- **ISteamNetworkingSockets** — the modern connection API (reliable + unreliable
  messages, P2P).
- **Steam Datagram Relay (SDR)** — routes traffic through Valve's network so you
  never expose IPs or fight home routers.

You do not need to add a networking library. It is in the repo.

---

## Mental Model: Lobby vs Connection

Two separate Steam systems, used together:

1. **Lobby (ISteamMatchmaking)** = the room.
   - Host calls `CreateLobby` -> gets a lobby ID.
   - Friend calls `JoinLobby(id)` (or finds it via invite / friend list).
   - The lobby is where players gather and agree to start. Think "waiting room".
   - A lobby can hold metadata (level name, ready state) as key/value pairs.

2. **Networking connection (ISteamNetworkingSockets)** = the gameplay pipe.
   - Once both are in the lobby and ready, you open a P2P connection between them.
   - This is what carries your `Player_Intent` messages every frame.
   - Valve's relay handles getting through firewalls.

Lobby = "find each other". Connection = "play together". Both are in the SDK.

---

## The Flow For Your Two-Lovers Game

```
HOST                                    FRIEND
----                                    ------
CreateLobby(friends-only, max 2)        (sees invite / friend's lobby)
  -> get lobby_id                       JoinLobby(lobby_id)
wait for friend to join                 -> now in the lobby
both press "Ready"                      both press "Ready"
host: CreateListenSocketP2P(0)          friend: ConnectP2P(host_identity, 0)
  -> connection established  <------------>  connection established
LEAVE lobby (no longer needed)          LEAVE lobby

-- gameplay loop (every frame) --
send red.intent  ------------------->   receive red.intent (remote lover)
receive blue.intent <----------------   send blue.intent
run authoritative game                  draw host's authoritative state
send state ------------------------->   apply state
```

The lobby is only for finding each other and agreeing to start. The actual game
runs over the P2P connection. After connecting, you can leave the lobby.

---

## The Pieces You Will Use (names to look up)

In `sauce/steamworks/steamworks.odin`, search for these (exact names may have a
prefix like `I` or `Steam`):

Lobby / rooms:
- `CreateLobby` — make a room (pick `k_ELobbyTypeFriendsOnly`, max members 2)
- `RequestLobbyList` / `JoinLobby` — find and join a room
- `SetLobbyData` / `GetLobbyData` — store level name, ready flags
- Callbacks: `LobbyCreated_t`, `LobbyEnter_t`, `LobbyChatUpdate_t`

Connection / gameplay:
- `InitRelayNetworkAccess` — call at startup so the relay is ready
- `CreateListenSocketP2P` — host listens for the friend
- `ConnectP2P` — friend connects to the host
- `AcceptConnection` — host accepts the incoming friend
- `SendMessageToConnection` — send your intent bytes
- `ReceiveMessagesOnConnection` — poll for the partner's intent (never block)
- Callback: `SteamNetConnectionStatusChangedCallback_t` — connection up/down

You poll Steam callbacks each frame with `SteamAPI_RunCallbacks` (the binding has
an equivalent). This fits the game loop exactly like input polling.

---

## How This Plugs Into Your Intent System (from doc 03)

You already structured input as `Player_Intent`. Steam networking just becomes the
transport:

```odin
// send (each frame, host and client both send their own intent)
net_send_intent :: proc(conn: HSteamNetConnection, intent: Player_Intent) {
    bytes := intent_to_bytes(intent)
    // reliable send is fine for a slow co-op puzzle
    SendMessageToConnection(conn, raw_data(bytes), u32(len(bytes)),
                            k_nSteamNetworkingSend_Reliable, nil)
}

// poll (each frame, never block)
net_poll_intent :: proc(conn: HSteamNetConnection) -> (Player_Intent, bool) {
    msgs: [1]^SteamNetworkingMessage_t
    n := ReceiveMessagesOnConnection(conn, &msgs[0], 1)
    if n <= 0 { return {}, false }
    defer msgs[0]->Release()
    data := mem.byte_slice(msgs[0].m_pData, int(msgs[0].m_cbSize))
    return bytes_to_intent(data)
}
```

(Exact struct/func names follow the binding; this shows the SHAPE.) Notice
`lover_update` from doc 03 still does not change. Networking is just the source.

---

## Practical Notes / Gotchas

- **You need a Steam App ID to ship**, which means a Steamworks account ($100
  one-time). For DEVELOPMENT and testing you can use the Spacewar test App ID
  (480) that Valve provides — many devs prototype Steam networking with it.
- **Steam must be running** on both machines (it is the relay client).
- **Test over real internet early-ish** (not just two windows on one PC). Relay
  behavior only shows with two real machines.
- **macOS**: Steamworks supports Mac. The repo bundles the redistributables. You
  are on the harder platform generally, but Steam networking itself is
  cross-platform.
- Start with **reliable** messages everywhere. Optimize to unreliable later only
  if you ever need to — a co-op puzzle almost never does.

---

## Honest Effort Estimate

For someone who has finished the local game and understands the intent system:
- Lobby create/join + ready flow: a few days of focused work.
- P2P connection + sending intents: a few more days.
- Debugging real-internet edge cases (disconnects, reconnects): the long tail.

It is a real project, but a bounded one, because Valve handles the genuinely hard
part (NAT). This is why Path A is recommended over Path B.

---

## Next

- Alternative: `05_raw_sockets_path.md` (from scratch, educational).
- Links: `RESOURCES.md` (Steam docs, examples).
