# 05 — Path B: Raw Sockets With core:net (Educational)

This path builds networking from scratch using Odin's standard library
`core:net`. It is the honest way to UNDERSTAND networking. It is NOT the easy way
to ship internet P2P, because you must solve NAT traversal yourself.

> Use this path to learn how it works underneath, or for LAN / direct-IP play.
> For shipping internet co-op to friends, Path A (Steam) is far less work.

---

## What `core:net` Gives You

Odin ships sockets in the standard library — no external dependency:
- TCP and UDP sockets
- DNS resolution
- IPv4 / IPv6 addresses

Docs: https://pkg.odin-lang.org/core/net/
Example: https://github.com/odin-lang/examples/tree/master/net

This is the same level as Berkeley sockets in C: powerful, low-level, and it does
NOT solve "connect through two home routers". That part is on you.

---

## What Works Easily vs What Is Hard

### Easy with core:net
- **Same machine** (two windows, `127.0.0.1`) — great for testing.
- **Same LAN** (you and a friend on the same Wi-Fi, using local IPs) — works with
  basic socket code.
- **Direct IP when one side can port-forward** — works if the host opens a port on
  their router manually.

### Hard with core:net (the NAT wall)
- **Two friends in different homes over the internet** — usually blocked by both
  routers. To fix it yourself you need:
  - a STUN server (to discover your public address),
  - hole-punching (tricky, unreliable across router types), or
  - a TURN/relay server YOU rent and run (reliable, costs money).
- This is exactly the work Steam's relay does for free. Doing it yourself is a
  whole project.

**Honest takeaway:** core:net is excellent for learning and LAN play. For
internet P2P to a friend's house, you will fight NAT — which is why Path A exists.

---

## A Minimal TCP Echo (the "hello world" of sockets)

Start here to feel sockets working, on localhost. Two terminals.

### Server (the host)
```odin
package net_server
import "core:net"
import "core:fmt"

main :: proc() {
    // listen on all interfaces, port 7777
    listen, err := net.listen_tcp(net.Endpoint{
        address = net.IP4_Any,
        port    = 7777,
    })
    if err != nil { fmt.eprintln("listen failed:", err); return }
    fmt.println("listening on :7777")

    // accept ONE client (blocking — fine for this demo, NOT in a game loop)
    client, _, accept_err := net.accept_tcp(listen)
    if accept_err != nil { fmt.eprintln("accept failed:", accept_err); return }
    fmt.println("client connected")

    buf: [1024]u8
    for {
        n, recv_err := net.recv_tcp(client, buf[:])
        if recv_err != nil || n == 0 { break }
        fmt.printf("got: %s", string(buf[:n]))
        net.send_tcp(client, buf[:n])   // echo it back
    }
}
```

### Client (the friend)
```odin
package net_client
import "core:net"
import "core:fmt"

main :: proc() {
    sock, err := net.dial_tcp(net.Endpoint{
        address = net.IP4_Loopback,   // 127.0.0.1
        port    = 7777,
    })
    if err != nil { fmt.eprintln("dial failed:", err); return }

    net.send_tcp(sock, transmute([]u8)string("hello from client\n"))

    buf: [1024]u8
    n, _ := net.recv_tcp(sock, buf[:])
    fmt.printf("server replied: %s", string(buf[:n]))
}
```

Run the server, then the client. You just made two programs talk. That is the
foundation everything else builds on.

---

## The Game-Loop Problem: Non-Blocking Sockets

The demo above BLOCKS on `accept_tcp` and `recv_tcp`. A game loop must never
block (see `02_concepts_for_web_devs.md`). For a real game you need sockets that
return immediately if there is no data. Two options:

1. **Set sockets to non-blocking** and poll them each frame (check the `core:net`
   options for blocking mode), OR
2. **Use `nbio`** — Odin's non-blocking IO example/pattern:
   https://github.com/odin-lang/examples/tree/master/nbio

For a slow co-op puzzle you can also run networking on a **separate thread** that
does the blocking calls and hands messages to the game loop via a queue. That
keeps the main loop clean. (Odin has `core:thread`.)

---

## UDP For Game Traffic (the real choice)

For actual gameplay you would typically use UDP, not TCP, because TCP stalls on
lost packets. With `core:net` you would:
- `net.make_bound_udp_socket(...)` to bind a local port,
- `net.send_udp(...)` to fire an intent at the peer,
- `net.recv_udp(...)` (non-blocking) to poll for incoming intents.

Then YOU add a thin "reliability" layer for the few messages that must arrive
(like "lever pulled"): number your messages, re-send until acknowledged. This is
the layer Steam and Valve's library give you for free. For learning, building a
tiny version of it is genuinely enlightening — see the Gaffer On Games articles in
`RESOURCES.md`.

---

## How It Plugs Into Your Intent System

Identical shape to Path A — only the transport changes:
```odin
net_send_intent :: proc(sock: net.UDP_Socket, peer: net.Endpoint, intent: Player_Intent) {
    bytes := intent_to_bytes(intent)
    net.send_udp(sock, bytes, peer)
}

net_poll_intent :: proc(sock: net.UDP_Socket) -> (Player_Intent, bool) {
    buf: [256]u8
    n, _, err := net.recv_udp(sock, buf[:])   // must be non-blocking
    if err != nil || n == 0 { return {}, false }
    return bytes_to_intent(buf[:n])
}
```

`lover_update` still does not change. The intent abstraction from doc 03 pays off
no matter which path you choose.

---

## When To Actually Use Path B

- You only need **LAN / same-Wi-Fi** play (no NAT problem).
- You want to **learn** how networking works at the socket level.
- You are willing to **rent/run a relay server** for internet play.
- You do not want to depend on Steam.

Otherwise, prefer Path A. There is no shame in letting Valve solve NAT — every
serious indie does.

---

## Next

`RESOURCES.md` — verified links: Odin net docs, the famous Gaffer On Games game
networking series, Valve's open-source networking library, and Steam docs.
