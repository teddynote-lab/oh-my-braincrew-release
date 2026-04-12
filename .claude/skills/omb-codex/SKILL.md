---
name: omb-codex
description: >
  Codex CLI dispatcher — routes codex subcommands (review, adv-review, run, setup)
  to specialized omb-codex-* wrapper skills. Use when the user wants code review by Codex,
  task delegation to Codex, or Codex CLI setup.
user-invocable: true
argument-hint: "<subcommand> [args]"
allowed-tools: Skill, Bash, Read, Grep, Glob
effort: low
---

# Codex CLI Dispatcher

Routes Codex subcommands to specialized wrapper skills.

## Pre-execution Check

!`which codex 2>/dev/null || echo "NOT_FOUND"`

If `codex` is not found **AND** the subcommand is NOT `setup`:
- Stop and tell the user: `Codex CLI is not installed. Run /omb codex setup to install and configure.`

If `codex` is not found **AND** the subcommand IS `setup`:
- Proceed to route to `omb-codex-setup` (which handles installation).

## Arguments

$ARGUMENTS

## Intent Router

Parse `$ARGUMENTS`:
1. Extract the **first word** as the subcommand.
2. Strip the subcommand; the remainder is the arguments to pass to the target skill.

### Subcommand Matching

| Subcommand | Aliases | Target Skill | Purpose |
|------------|---------|-------------|---------|
| `review` | `rev` | `omb-codex-review` | Code review via Codex CLI |
| `adv-review` | `adversarial-review`, `adversarial`, `challenge` | `omb-codex-adv-review` | Adversarial code review — find failure modes |
| `run` | `exec`, `task` | `omb-codex-run` | Delegate a coding task to Codex |
| `setup` | `login`, `auth` | `omb-codex-setup` | Verify CLI installation and authentication |

### Keyword Detection

If no subcommand match, scan for keywords:

| Keywords | Target Skill |
|----------|-------------|
| `review code`, `check changes`, `review diff` | `omb-codex-review` |
| `challenge`, `pressure test`, `find weaknesses`, `adversarial` | `omb-codex-adv-review` |
| `delegate to codex`, `fix this with codex`, `codex task` | `omb-codex-run` |
| `install codex`, `authenticate`, `login` | `omb-codex-setup` |

### No Match

If neither matches, show available commands:

```
Available codex commands:
  review              — Run Codex code review on local changes
  adv-review          — Challenge review: find failure modes and risks
  run                 — Delegate a task to Codex
  setup               — Verify Codex CLI installation and auth
```
