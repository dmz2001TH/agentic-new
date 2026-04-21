# WSL to Windows Chrome Bridge (Port 9222)
## 2026-04-21 — Network Bridging Pattern

- **Context**: WSL2 networking is isolated from the Windows host. Chrome running on Windows with `--remote-debugging-port=9222` listens on the Windows host's loopback/IP, but not directly accessible via `localhost:9222` from inside WSL.
- **Learned**: A simple Python socket bridge can transparently forward WSL's `localhost:9222` to the Windows Host IP (detected via `ip route` or `resolv.conf`).
- **Solution**: 
  1. Detect Windows Host IP using `ip route show default | awk '{print $3}'`.
  2. Start a Python TCP server on `127.0.0.1:9222` inside WSL.
  3. For every connection, open a socket to `<Windows_IP>:9222` and tunnel data bidirectionally.
- **Implementation**: Created `oracle-cowork/src/bridge-chrome.py` and integrated into `scripts/oracle-tools.sh` as `ot-hack-chrome`.
- **Usage**: `ot-hack-chrome` starts the bridge, runs the Playwright connector, and cleans up after completion.
- **Tags**: #networking #wsl #chrome #bridge #python
