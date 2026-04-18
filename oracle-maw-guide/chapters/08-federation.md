# Chapter 8: Federation — Cross-Node Oracle Communication

> "One mushroom, one forest. But what happens when the forests connect?"

## What is Federation?

Federation lets maw instances on different machines talk to each other. Each machine is a **node**. Each node runs its own maw server with its own oracles. Federation connects them.

```
Node A (laptop)          Node B (server)
├── oracle-1             ├── oracle-3
├── oracle-2             └── oracle-4
└── maw :3457            └── maw :3457
         ↕ HTTP + HMAC-SHA256 ↕
```

## Setup

### 1. Generate Federation Token

Both nodes share the same token:
```bash
openssl rand -base64 32
# Example: 2QHmsYh-1UamE10V8mec0t5w0bGNHEZJ
```

### 2. Configure Node A (`~/.config/maw/maw.config.json`)

```json
{
  "host": "local",
  "port": 3457,
  "node": "laptop",
  "federationToken": "YOUR_SHARED_TOKEN",
  "peers": [],
  "namedPeers": [
    {"name": "server", "url": "http://10.20.0.1:3457"}
  ],
  "agents": {
    "oracle-1": "laptop",
    "oracle-2": "laptop",
    "oracle-3": "server",
    "oracle-4": "server"
  }
}
```

### 3. Configure Node B (same structure, reversed)

```json
{
  "host": "local",
  "port": 3457,
  "node": "server",
  "federationToken": "YOUR_SHARED_TOKEN",
  "peers": [],
  "namedPeers": [
    {"name": "laptop", "url": "http://10.20.0.3:3457"}
  ],
  "agents": {
    "oracle-1": "laptop",
    "oracle-2": "laptop",
    "oracle-3": "server",
    "oracle-4": "server"
  }
}
```

### 4. Critical: `peers: []` Must Be Empty

**NEVER put URLs in `peers`**. This causes exponential session duplication (each node re-broadcasts to all peers, creating loops). Use `namedPeers` for explicit routing.

## Sending Messages

```bash
# Local oracle (same node)
maw hey oracle-1 "hello"

# Remote oracle (cross-node)
maw hey server:oracle-3 "hello from laptop"

# The node prefix tells maw to route via federation
```

## How It Works

1. `maw hey server:oracle-3 "msg"` → maw looks up "server" in namedPeers
2. Sends HTTP POST to `http://10.20.0.1:3457/api/federation/message`
3. Body signed with HMAC-SHA256 using shared federationToken
4. Remote maw verifies signature, delivers to oracle-3's tmux session

## Transport Security

Federation uses plain HTTP. For production:
- **WireGuard VPN** — encrypt the tunnel, restrict access to VPN IPs only
- **UFW firewall** — only allow maw ports (3456, 3457) on VPN interface
- **Never expose maw to public internet**

```
[Laptop] ──WireGuard──▶ [Server:3457]
  10.20.0.3                10.20.0.1
```

## Agent Routing

The `agents` map tells maw where each oracle lives:

```json
"agents": {
  "mycelium": "server",
  "glyph": "laptop"
}
```

When you `maw hey mycelium "msg"`, maw checks:
1. Is "mycelium" local? → deliver to tmux
2. Is "mycelium" in agents map? → route to that node via namedPeers
3. Not found? → error

## Multi-Node Fleet

```
Node: laptop (MBA)     Node: clinic       Node: white
├── homekeeper         ├── mycelium       ├── pulse
├── hermes             └── mother         ├── hermes
├── volt                                  ├── neo
└── glyph                                 └── 13 more...
```

All connected via federation. Any oracle can talk to any other:
```bash
maw hey clinic:mycelium "sync please"
maw hey white:pulse "status check"
```

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| "send failed" | Node unreachable | Check VPN, ping the IP |
| Exponential sessions | `peers` not empty | Set `peers: []` |
| "agent not found" | Missing from agents map | Add to both configs |
| HMAC rejected | Token mismatch | Same token on both nodes |
| One-way only | Firewall blocking | Open maw port on receiver |

## Production Checklist

- [ ] Both nodes have same `federationToken`
- [ ] `peers: []` on ALL nodes
- [ ] `namedPeers` has correct IPs/ports
- [ ] `agents` map is consistent across nodes
- [ ] WireGuard VPN running
- [ ] UFW allows maw port on VPN only
- [ ] Test: `maw hey remote:oracle "test"` works both directions

---

🍄 *The underground connects forests without anyone seeing the roots.*
