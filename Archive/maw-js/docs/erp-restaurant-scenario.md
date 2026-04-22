# 🍽️ maw team erp-restaurant — Scenario Diagram

## Commands (PATH A — CLI)

```bash
# Step 1: Create team
maw team create erp-restaurant --description "Build ERP system for restaurant management"

# Step 2: Spawn 2 agents
maw team spawn erp-restaurant backend-dev \
  --model sonnet \
  --prompt "Build REST APIs for: menu management, order processing, inventory tracking, staff scheduling."

maw team spawn erp-restaurant frontend-dev \
  --model sonnet \
  --prompt "Build React UI: POS terminal, kitchen display, manager dashboard, reservation system."

# Step 3: Verify
maw team ls        # ← sees erp-restaurant NOW (bridge fix!)
maw team status erp-restaurant
maw team shutdown erp-restaurant --force --merge
```

---

## 🖥️ tmux Terminal Layout (After Spawn)

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│  tmux session: maw (your main pane)                                             │
│  ┌─────────────────────────────────────┬───────────────────────────────────────┐
│  │ Pane %501                           │ Pane %502                             │
│  │ maw:0.0                             │ maw:0.1                               │
│  │                                     │                                       │
│  │ $ claude --model sonnet             │ $ claude --model sonnet               │
│  │   --prompt-file "…/backend-dev-     │   --prompt-file "…/frontend-dev-      │
│  │   spawn-prompt.md"                  │   spawn-prompt.md"                    │
│  │                                     │                                       │
│  │ ┌─────────────────────────────────┐ │ ┌───────────────────────────────────┐ │
│  │ │ 🔧 backend-dev                  │ │ │ 🎨 frontend-dev                  │ │
│  │ │                                 │ │ │                                   │ │
│  │ │ Building REST APIs:             │ │ │ Building React UI:               │ │
│  │ │ • /api/menu                     │ │ │ • <POS />                         │ │
│  │ │ • /api/orders                   │ │ │ • <KitchenDisplay />              │ │
│  │ │ • /api/inventory                │ │ │ • <Dashboard />                   │ │
│  │ │ • /api/staff                    │ │ │ • <Reservations />                │ │
│  │ └─────────────────────────────────┘ │ └───────────────────────────────────┘ │
│  └─────────────────────────────────────┴───────────────────────────────────────┘
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 📂 File System State (From Real Test Data)

### VAULT STORE — `ψ/memory/mailbox/teams/erp-restaurant/`

```
ψ/memory/mailbox/teams/erp-restaurant/
├── manifest.json                        ← team metadata
├── backend-dev-spawn-prompt.md          ← 142 bytes — agent prompt
└── frontend-dev-spawn-prompt.md         ← 135 bytes — agent prompt
```

**manifest.json** (actual test output):
```json
{
  "name": "erp-restaurant",
  "createdAt": 1776744310192,
  "members": ["backend-dev", "frontend-dev"],
  "description": "Build ERP system for restaurant management"
}
```

**backend-dev-spawn-prompt.md** (actual):
```
You are 'backend-dev' on team 'erp-restaurant'.

Build REST APIs for: menu management, order processing, inventory tracking, staff scheduling.
```

### TOOL STORE — `~/.claude/teams/erp-restaurant/`

```
~/.claude/teams/erp-restaurant/
├── config.json                          ← what ls/status/shutdown read
└── inboxes/
    ├── backend-dev.json                 ← inbox for messages
    └── frontend-dev.json                ← inbox for messages
```

**config.json** (actual test output — bridge synced!):
```json
{
  "name": "erp-restaurant",
  "description": "Build ERP system for restaurant management",
  "members": [
    {
      "name": "backend-dev",
      "model": "sonnet",
      "tmuxPaneId": "%501"
    },
    {
      "name": "frontend-dev",
      "model": "sonnet",
      "tmuxPaneId": "%502"
    }
  ],
  "createdAt": 1776744310194
}
```

---

## 🔄 Data Flow (Bridge Fix)

```
 User runs: maw team create erp-restaurant
              │
              ▼
 ┌──────────────────────────────────────────────────────────────┐
 │                    cmdTeamCreate()                            │
 │                                                              │
 │  1. Write manifest.json ──────────────────► VAULT STORE      │
 │     ψ/memory/mailbox/teams/erp-restaurant/   ✅ written      │
 │                                                              │
 │  2. syncToToolStore() ────────────────────► TOOL STORE       │
 │     ~/.claude/teams/erp-restaurant/          ✅ written      │
 └──────────────────────────────────────────────────────────────┘

 User runs: maw team spawn erp-restaurant backend-dev --model sonnet --prompt "..."
              │
              ▼
 ┌──────────────────────────────────────────────────────────────┐
 │                    cmdTeamSpawn()                             │
 │                                                              │
 │  1. Write spawn prompt ───────────────────► VAULT STORE      │
 │     backend-dev-spawn-prompt.md              ✅ written      │
 │                                                              │
 │  2. Update manifest members ──────────────► VAULT STORE      │
 │     members: ["backend-dev"]                 ✅ updated      │
 │                                                              │
 │  3. syncToToolStore(member + paneId) ────► TOOL STORE        │
 │     members: [{name, model, tmuxPaneId}]     ✅ updated      │
 └──────────────────────────────────────────────────────────────┘

 User runs: maw team ls
              │
              ▼
 ┌──────────────────────────────────────────────────────────────┐
 │                    cmdTeamList()                              │
 │                                                              │
 │  Reads ~/.claude/teams/ ─────────────────► TOOL STORE        │
 │  Finds: erp-restaurant (2 members)           ✅ FOUND!       │
 │                                                              │
 │  Also scans vault for vault-only teams                       │
 │  (erp-restaurant already in tool store → skipped)            │
 └──────────────────────────────────────────────────────────────┘

 User runs: maw team shutdown erp-restaurant --force --merge
              │
              ▼
 ┌──────────────────────────────────────────────────────────────┐
 │                    cmdTeamShutdown()                          │
 │                                                              │
 │  1. loadTeam() reads ────────────────────► TOOL STORE        │
 │     Finds team + pane IDs (%501, %502)       ✅ found       │
 │                                                              │
 │  2. Send shutdown_request ───────────────► INBOX FILES       │
 │     to backend-dev.json + frontend-dev.json  ✅ sent         │
 │                                                              │
 │  3. tmux kill-pane %501, %502 ──────────► TMUX               │
 │     Agents terminated                        ✅ killed       │
 │                                                              │
 │  4. mergeTeamKnowledge() ────────────────► VAULT MAILBOX     │
 │     Copy findings → ψ/memory/mailbox/<agent>/  ✅ merged     │
 │                                                              │
 │  5. cleanupTeamDir({ vault: true }) ─────► BOTH STORES       │
 │     ~/.claude/teams/erp-restaurant/          ✅ deleted      │
 │     ψ/memory/mailbox/teams/erp-restaurant/   ✅ deleted      │
 └──────────────────────────────────────────────────────────────┘
```

---

## ✅ Test Evidence Summary

| Step | Command | Vault | Tool Store | Status |
|---|---|---|---|---|
| 1 | `create` | manifest.json ✅ | config.json ✅ | **Bridge works** |
| 2 | `spawn backend-dev` | prompt.md ✅ | member+paneId ✅ | **Synced** |
| 3 | `spawn frontend-dev` | prompt.md ✅ | member+paneId ✅ | **Synced** |
| 4 | `team ls` | — | reads config.json ✅ | **Team visible!** |
| 5 | `team status` | — | reads members ✅ | **Pane IDs present** |
| 6 | `team shutdown` | deleted ✅ | deleted ✅ | **Clean exit** |
