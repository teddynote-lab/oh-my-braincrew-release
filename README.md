# oh-my-braincrew

Multi-agent orchestration harness for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

> Delegate, orchestrate, verify — never implement directly.

## Install

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/teddynote-lab/oh-my-braincrew-release/main/install.sh | sh
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/teddynote-lab/oh-my-braincrew-release/main/install.ps1 | iex
```

### pip / uv (alternative)

```bash
pip install oh-my-braincrew
# or
uv tool install oh-my-braincrew
```

### Manual Download

| Platform | Architecture | Binary |
|----------|-------------|--------|
| macOS | Apple Silicon (arm64) | [`omb-v0.1.2-darwin-arm64`](https://github.com/teddynote-lab/oh-my-braincrew-release/releases/latest) |
| macOS | Intel (amd64) | [`omb-v0.1.2-darwin-amd64`](https://github.com/teddynote-lab/oh-my-braincrew-release/releases/latest) |
| Linux | x86_64 | [`omb-v0.1.2-linux-amd64`](https://github.com/teddynote-lab/oh-my-braincrew-release/releases/latest) |
| Windows | x86_64 | [`omb-v0.1.2-windows-amd64.exe`](https://github.com/teddynote-lab/oh-my-braincrew-release/releases/latest) |

## Getting Started

### 1. Initialize in your project

```bash
cd /path/to/your/project
omb init
```

This will:
- Create the `.omb/` directory structure (plans, sessions, verifications, etc.)
- Download the plugin files from GitHub
- Save the plugin path to `~/.omb/home`

### 2. Start Claude Code with the plugin

```bash
claude --plugin-dir ~/.omb/plugin
```

### 3. Run the setup wizard

Inside Claude Code, run:

```
/omb setup
```

This interactive wizard will:
- Configure your user profile
- Scan your codebase
- Generate `CLAUDE.md` and `PROJECT.md` tailored to your project

### 4. Start using omb workflows

```
/omb plan       # Plan a feature before implementing
/omb exec       # Execute the plan with TDD agents
/omb verify     # Verify with evidence
/omb pr         # Create a PR with plan traceability
```

## Update

```bash
omb update
```

The `omb update` command auto-detects your install method:
- **Binary install** — downloads the latest binary from GitHub Releases
- **pip / uv tool** — runs `pip install --upgrade` or `uv tool upgrade`
- **Source checkout** — advises `git pull && make setup`

## Uninstall

### Binary

```bash
# macOS / Linux
sudo rm /usr/local/bin/omb
rm -rf ~/.omb

# Windows (PowerShell)
Remove-Item "$env:LOCALAPPDATA\omb" -Recurse
```

### pip

```bash
pip uninstall oh-my-braincrew
rm -rf ~/.omb
```

## What is oh-my-braincrew?

oh-my-braincrew is a multi-agent orchestration harness that extends Claude Code with:

- **Specialized agent teams** — executor, reviewer, critic, and 15+ domain specialists
- **Structured workflows** — plan, review, execute (TDD), verify, document, PR
- **Pipeline orchestration** — dependency-aware task scheduling with parallel execution
- **Quality gates** — no completion claims without verification evidence
- **Tech stack awareness** — Python, TypeScript, React, FastAPI, LangChain/LangGraph, and more

## Changelog

See [CHANGELOG.md](./CHANGELOG.md) for release history.

## License

Apache-2.0
