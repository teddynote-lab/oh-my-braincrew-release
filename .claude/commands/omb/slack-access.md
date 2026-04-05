---
description: Manage Slack channel access (pair users, set policies and tiers)
argument-hint: "pair <code> | policy allowlist | tier <user-id> admin|standard|read-only"
---


Manage the Slack channel sender allowlist at `~/.claude/channels/slack/access.json`.

Subcommands:
- `pair <code>` — Validate a pairing code and add the user to the allowlist
- `policy allowlist` — Lock down to allowlisted users only (recommended)
- `policy open` — Allow all Slack users (development only)
- `tier <user-id> admin|standard|read-only` — Change a user's permission tier
- `list` — Show all paired users and their tiers
