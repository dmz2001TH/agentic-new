# Chapter 9: Deployment — Production Server Setup

> "The forest needs roots in the ground, not just in the air."

## Prerequisites

| Tool | Install | Version |
|------|---------|---------|
| Bun | `curl -fsSL https://bun.sh/install \| bash` | 1.3+ |
| Node | `nvm install 24` | 24+ |
| ghq | `go install github.com/x-motemen/ghq@latest` | 1.9+ |
| gh | `apt install gh` / `brew install gh` | 2.45+ |
| Claude Code | `npm install -g @anthropic-ai/claude-code` | 2.1+ |
| direnv | `apt install direnv` / from binary | 2.37+ |
| pm2 | `npm install -g pm2` | 5+ |
| tmux | `apt install tmux` | 3.3+ |

## Step 1: Install maw-js

```bash
ghq get https://github.com/Soul-Brews-Studio/maw-js
cd $(ghq root)/github.com/Soul-Brews-Studio/maw-js
bun install
```

## Step 2: Symlink Everything

```bash
# Make tools available for ALL users and non-login shells
sudo ln -sf ~/.bun/bin/bun /usr/local/bin/bun
sudo ln -sf ~/.bun/bin/maw /usr/local/bin/maw
sudo ln -sf ~/go/bin/ghq /usr/local/bin/ghq
sudo ln -sf ~/.local/bin/claude /usr/local/bin/claude
sudo ln -sf ~/bin/direnv /usr/local/bin/direnv
```

**Why symlinks?** Non-login shells (tmux, cron, GH Actions) don't source `.bashrc`. Symlinks in `/usr/local/bin/` work everywhere.

Also add to `.bashrc` / `.zshrc`:
```bash
export PATH="$HOME/go/bin:$HOME/.bun/bin:$HOME/.local/bin:$PATH"
```

## Step 3: Configure maw

```bash
mkdir -p ~/.config/maw/fleet

# Main config
cat > ~/.config/maw/maw.config.json << 'EOF'
{
  "host": "local",
  "port": 3457,
  "node": "my-server",
  "federationToken": "<run: openssl rand -base64 32>",
  "peers": [],
  "namedPeers": [],
  "agents": {}
}
EOF
```

## Step 4: Create Fleet Configs

```bash
# One file per oracle
cat > ~/.config/maw/fleet/01-myoracle.json << 'EOF'
{
  "name": "myoracle",
  "windows": [
    {"name": "myoracle-main", "repo": "my-org/my-oracle-repo"}
  ]
}
EOF
```

## Step 5: Start maw with pm2

```bash
cd $(ghq root)/github.com/Soul-Brews-Studio/maw-js
pm2 start src/server.ts --name maw --interpreter bun
pm2 save
pm2 startup  # auto-start on reboot
```

Verify:
```bash
curl -s http://localhost:3457/api/sessions | jq '.[].name'
maw ls
```

## Step 6: Claude Token (direnv)

```bash
# In your oracle repo directory
echo 'export CLAUDE_TOKEN=<your-oauth-token>' > .envrc
direnv allow .
```

zshrc wrapper function (handles token + --continue fallback):
```bash
claude() {
  CLAUDE_CODE_OAUTH_TOKEN=$CLAUDE_TOKEN command claude "$@"
  if [[ $? -ne 0 ]] && [[ " $* " == *" --continue "* || " $* " == *" -c "* ]]; then
    echo "⚠ No session — starting fresh"
    CLAUDE_CODE_OAUTH_TOKEN=$CLAUDE_TOKEN command claude "${@/--continue/}"
  fi
}
```

## Step 7: Security (UFW + SSH)

```bash
# Disable root login + password auth
sudo sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# Firewall — only allow SSH + maw on VPN
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 3456/tcp  # maw port 1
sudo ufw allow 3457/tcp  # maw port 2
sudo ufw enable
```

## Step 8: Wake Fleet

```bash
maw wake myoracle
# Then in tmux:
tmux send-keys -t myoracle:myoracle-main "cd /path/to/repo && direnv allow . && claude --continue" Enter
```

## Step 9: GitHub Actions Workflows

### Oracle Notify (issue/PR events → maw hey)
```yaml
on:
  issues:
    types: [opened, closed]
  pull_request:
    types: [opened, closed]

jobs:
  notify:
    runs-on: [self-hosted, my-runner]
    steps:
      - run: |
          maw hey myoracle "Event: ${{ github.event.action }} on #${{ github.event.issue.number || github.event.pull_request.number }}" --force
```

### Oracle PR Review (Claude Code reviews PRs)
```yaml
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  review:
    runs-on: [self-hosted, my-runner]
    steps:
      - uses: actions/checkout@v4
      - run: |
          DIFF=$(gh pr diff ${{ github.event.pull_request.number }})
          REVIEW=$(echo "$DIFF" | claude --print "Review this PR for security issues. Under 200 words.")
          echo "$REVIEW" | gh pr comment ${{ github.event.pull_request.number }} --body-file -
```

### Fleet Sync (daily maw hey reminder)
```yaml
on:
  schedule:
    - cron: '0 17 * * *'  # Daily UTC

jobs:
  sync:
    runs-on: [self-hosted, my-runner]
    steps:
      - run: |
          maw hey myoracle "Daily sync reminder — git pull && commit" --force
```

## Known Gotchas

| Issue | Fix |
|-------|-----|
| `maw: command not found` in tmux | Symlink to `/usr/local/bin/` |
| `bun: No such file or directory` | Symlink bun too |
| `ghq: Permission denied` | Symlink or add `~/go/bin` to PATH |
| `.envrc` not loading in tmux | Run `direnv allow .` inside tmux |
| `maw wake --continue` creates worktree | Use `maw wake` then `tmux send-keys "claude --continue"` |
| Double `github.com/github.com` path | ghq root mismatch — check `ghq root` vs actual repo location |
| `peers: []` must be empty | Exponential session duplication if not |

---

🍄 *Plant once. Grow forever.*
