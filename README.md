# oh-my-braincrew

Multi-agent orchestration harness for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

> Delegate, orchestrate, verify — never implement directly.

## Install

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/teddynote-lab/oh-my-braincrew-release/main/install.sh | bash
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/teddynote-lab/oh-my-braincrew-release/main/install.ps1 | iex
```

### Manual Download

| Platform | Architecture | Binary |
|----------|-------------|--------|
| macOS | Apple Silicon (arm64) | [`oh-my-braincrew-v0.1.5-darwin-arm64`](https://github.com/teddynote-lab/oh-my-braincrew-release/releases/latest) |
| Linux | x86_64 | [`oh-my-braincrew-v0.1.5-linux-amd64`](https://github.com/teddynote-lab/oh-my-braincrew-release/releases/latest) |
| Windows | x86_64 | [`oh-my-braincrew-v0.1.5-windows-amd64.exe`](https://github.com/teddynote-lab/oh-my-braincrew-release/releases/latest) |

## Getting Started

### 1. Initialize in your project

```bash
cd /path/to/your/project
omb init
```

This installs the harness files:
- `.claude/` — agents, skills, rules, hooks, statusline
- `.omb/` — working directories (plans, todo, interviews)
- `CLAUDE.md` — project instructions for Claude Code
- `.claude/settings.json` — hook and permission configuration

### 2. Start Claude Code

```bash
claude
```

The harness activates automatically via `settings.json` hooks.

### 3. Use omb workflows

```
/omb plan       # Generate an implementation plan
/omb run        # Execute the plan with TDD agents
/omb verify     # Post-implementation verification
/omb pr         # Create a GitHub PR with lint gate
```

Full workflow: `interview → plan → plan-review → run → verify → doc → pr → release`

## Update

```bash
omb update
```

## Uninstall

```bash
rm ~/.local/bin/oh-my-braincrew ~/.local/bin/omb
```

Remove harness files from your project:

```bash
rm -rf .claude/agents/omb .claude/skills .claude/rules .claude/hooks/omb .claude/statusline-omb.sh .omb/
```

## What is oh-my-braincrew?

A multi-agent orchestration harness that extends Claude Code with:

- **20+ specialized agents** — design, implement, verify, review across 10 domains
- **Structured workflows** — plan → review → execute (TDD) → verify → document → PR
- **Quality gates** — automated lint, type check, and test verification
- **Domain routing** — API, DB, UI, AI/ML, Infra, Security, Electron, Harness
- **Worktree isolation** — parallel feature development with SQLite state tracking

## Changelog

See [CHANGELOG.md](./CHANGELOG.md) for release history.

## License

Apache-2.0
