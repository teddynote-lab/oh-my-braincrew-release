---
description: Start Claude Code with the Slack channel enabled
argument-hint: ""
---

## Slack Channel Startup

To start Claude Code with the Slack channel bridge enabled, run this command in your terminal:

```bash
claude --dangerously-load-development-channels server:slack-channel
```

### Prerequisites

Before starting, ensure:
1. **Bun is installed**: `bun --version` (install from https://bun.sh if missing)
2. **Slack credentials configured**: Run `/omb slack-configure` first
3. **ngrok running** (if using webhooks): `ngrok http 3789` in a separate terminal
4. **Slack App configured**: See `docs/guides/slack-channel-setup.md`

### What happens on start

1. Claude Code spawns the Slack channel MCP server as a subprocess
2. The server connects to Slack via webhook and starts listening for events
3. Pipeline watcher begins monitoring `.omb/sessions/` for state changes
4. Messages from Slack arrive as `<channel source="slack-channel" ...>` events

### Verify it works

Send a message in your configured Slack channel. You should see the message arrive in your Claude Code session.
