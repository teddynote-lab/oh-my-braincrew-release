# oh-my-braincrew (omb)

[![Release](https://img.shields.io/github/v/release/teddynote-lab/oh-my-braincrew-release?style=flat-square)](https://github.com/teddynote-lab/oh-my-braincrew-release/releases/latest)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-blue?style=flat-square)](https://github.com/teddynote-lab/oh-my-braincrew-release/releases/latest)
[![Python](https://img.shields.io/badge/python-%3E%3D3.12-3776AB?style=flat-square&logo=python&logoColor=white)](https://python.org)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-harness-cc785c?style=flat-square&logo=anthropic&logoColor=white)](https://docs.anthropic.com/en/docs/claude-code)
[![License](https://img.shields.io/badge/license-Apache--2.0-green?style=flat-square)](LICENSE)

**[English](README.md)** | **[한국어](README-ko.md)**

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
| macOS | Apple Silicon (arm64) | [`oh-my-braincrew-v0.2.11-darwin-arm64`](https://github.com/teddynote-lab/oh-my-braincrew-release/releases/latest) |
| Linux | x86_64 | [`oh-my-braincrew-v0.2.11-linux-amd64`](https://github.com/teddynote-lab/oh-my-braincrew-release/releases/latest) |
| Windows | x86_64 | [`oh-my-braincrew-v0.2.11-windows-amd64.exe`](https://github.com/teddynote-lab/oh-my-braincrew-release/releases/latest) |

### Update / Uninstall

```bash
omb update                    # update binary and harness files
omb init                      # re-install harness files only
```

```bash
rm ~/.local/bin/oh-my-braincrew ~/.local/bin/omb   # uninstall binary
```

### CLI Commands

| Command | Description |
|---------|-------------|
| `omb init [path]` | Download and install harness files from latest release |
| `omb update [path]` | Update binary and refresh harness files |
| `omb version` | Print installed version |

## Setup

After installing, initialize in your project and run the setup wizard:

```bash
cd /path/to/your/project
omb init
```

```
> /omb:setup
```

This will:
- Scaffold `.omb/` directory structure (plans, todo, interviews)
- Generate `CLAUDE.md` tailored to your project
- Configure `.claude/settings.json` with hooks and permissions

## Recommended Workflow

Run step-by-step for a complete development cycle, or invoke individually.

```
# 1. Gather requirements through structured interview
> /omb:interview

# 2. Generate an implementation plan
> /omb:plan

# 3. Review and score the plan with multiple agents
> /omb:plan-review

# 4. Execute the plan with TDD agents
> /omb:run

# 5. Verify the implementation
> /omb:verify

# 6. Generate documentation
> /omb:doc

# 7. Create a pull request
> /omb:pr

# 8. Cut a release
> /omb:release patch
```

| # | Command | Description |
|---|---------|-------------|
| 1 | `/omb:interview` | Requirements interview. Saves to `.omb/interviews/` |
| 2 | `/omb:plan` | Generate implementation plan. Saves to `.omb/plans/` |
| 3 | `/omb:plan-review` | Multi-agent plan review with quantitative scoring |
| 4 | `/omb:run [plan]` | Execute plan with TDD agents. Tracks in `.omb/todo/` |
| 5 | `/omb:verify [plan]` | Post-implementation verification with parallel verifiers |
| 6 | `/omb:doc` | Generate or update documentation |
| 7 | `/omb:pr` | Create GitHub PR with lint gate |
| 8 | `/omb:release` | Version release with changelog and binary builds |

## Commands

### Workflow Commands

#### `/omb:interview` — Requirements Interview

Asks up to 15 multi-dimensional questions covering tech stack, implementation choices, and design preferences. Saves summary to `.omb/interviews/`.

```
> /omb:interview
# Interviewer asks structured questions about your feature requirements
# Output: .omb/interviews/2026-04-13-user-auth.md
```

#### `/omb:plan` — Implementation Plan

Generates a detailed plan with domain decomposition, agent delegation, TDD strategy, and risk analysis. Runs an evaluate-improve loop until the plan passes quality gates.

```
> /omb:plan
# Explores codebase → writes plan → evaluates with rubric → improves → delivers
# Output: .omb/plans/2026-04-13-user-auth-flow.md
```

#### `/omb:plan-review` — Plan Review

Assembles 3-12 domain reviewers in parallel, runs quantitative evaluation, and synthesizes consensus with P0-P3 issue tracking.

```
> /omb:plan-review
# Multiple agents review the plan independently → consensus synthesis → improvement
```

#### `/omb:run` — Execute Plan

Parses the TODO checklist from a plan, delegates to domain agents, enforces TDD, and tracks progress.

```
> /omb:run
# Reads plan → spawns agents per task → RED-GREEN-IMPROVE cycle → marks done
# Progress: .omb/todo/
```

#### `/omb:verify` — Post-Implementation Verification

Assembles parallel verifiers (type check, lint, test, domain-specific agents), runs static analysis, and delivers DONE/RETRY/BLOCKED verdict.

```
> /omb:verify
# Runs tsc, ruff, pytest, eslint → domain agents review → consensus verdict
```

#### `/omb:doc` — Documentation

Generates or updates service documentation following category structure and naming conventions.

```
> /omb:doc
# Scans changes → generates docs in docs/ folder → follows template conventions
```

#### `/omb:pr` — Pull Request

Validates branch, runs lint check, creates commit, pushes, and opens a GitHub PR with structured template.

```
> /omb:pr
# Lint gate → commit → push → gh pr create with Summary/Changes/Test Plan
```

#### `/omb:release` — Release

Handles version bump, AI-summarized changelog, git tagging, GitHub Release creation, and CI-triggered binary builds.

```
> /omb:release patch
> /omb:release minor
> /omb:release 2.0.0
```

#### `/omb:harness` — Harness Configuration

Create, update, verify, or design agents, skills, hooks, rules, and settings.json.

```
> /omb:harness --verify    # check configuration health
> /omb:harness --fix       # auto-fix issues
```

### Utilities

#### `/omb:setup` — Project Setup

Scaffolds directory structure, generates `CLAUDE.md`, and configures `settings.json` with hooks and env vars.

```
> /omb:setup
# Interactive wizard: scans codebase → generates CLAUDE.md → configures hooks
```

#### `/omb:lint-check` — Lint Check

Auto-detects tech stack from changed files and runs appropriate linters. Must pass before PR.

```
> /omb:lint-check
# Detects Python → ruff, TypeScript → eslint, Dockerfile → hadolint
```

#### `/omb:prompt-guide` — Prompt Engineering Reference

Loads comprehensive prompt engineering guide (52 rules across 11 categories) for writing system prompts, agent instructions, and skill descriptions.

```
> /omb:prompt-guide
```

#### `/omb:prompt-review` — Prompt Review

Iterative prompt scoring and improvement loop. Evaluates against rubric, fixes P0/P1 issues, re-evaluates until resolved.

```
> /omb:prompt-review
# Scores prompt → identifies issues → fixes → re-scores until passing
```

#### `/omb:brainstorming` — Idea Exploration

Collaborative dialogue that asks one question at a time to refine intent, constraints, and approach.

```
> /omb:brainstorming
# Interactive Q&A to explore ideas before committing to a design
```

#### `/omb:mermaid` — Diagram Generation

Generates Mermaid diagrams across 22 types including flowcharts, sequence diagrams, ER diagrams, and LangGraph visualizations.

```
> /omb:mermaid
# Analyzes context → selects diagram type → generates validated Mermaid syntax
```

#### `/omb:worktree` — Worktree Management

Manages isolated git worktrees with persistent SQLite state tracking.

```
> /omb:worktree create feat/add-auth   # create isolated worktree
> /omb:worktree status                 # show all worktree states
> /omb:worktree resume feat/add-auth   # switch to existing worktree
```

#### `/omb:clean` — Worktree Cleanup

Removes completed worktrees, marks DONE in DB, optionally deletes branches.

```
> /omb:clean feat/add-auth             # remove worktree and mark done
```

#### `/omb:issue` — Issue Scanner

Scans codebase for issues, dispatches parallel explorer agents, and creates GitHub issues with structured templates.

```
> /omb:issue
# Builds checklist → parallel scan → consensus → gh issue create
```

#### `/omb:git-setup` — Git Workflow Setup

Sets up pre-commit hooks (ruff, eslint), reviews `.gitignore`, and configures GitHub Actions CI.

```
> /omb:git-setup
# Installs pre-commit hooks → reviews .gitignore → generates CI workflows
```

### Codex Integration

Integrate with [OpenAI Codex CLI](https://github.com/openai/codex) for code review and task delegation.

#### `/omb:codex` — Codex Dispatcher

Routes to the appropriate Codex subcommand.

```
> /omb:codex review       # code review
> /omb:codex adv-review   # adversarial review
> /omb:codex run           # delegate task
> /omb:codex setup         # check installation
```

#### `/omb:codex-review` — Code Review

Runs Codex code review on local git state and reports findings.

```
> /omb:codex-review
# Analyzes staged/unstaged changes → reports issues and suggestions
```

#### `/omb:codex-adv-review` — Adversarial Review

Challenges assumptions, finds failure modes, and pressure-tests implementation choices.

```
> /omb:codex-adv-review
# Deep analysis: edge cases, failure modes, security concerns, scalability
```

#### `/omb:codex-run` — Task Delegation

Delegates a coding task to Codex CLI for investigation, bug fixes, or implementation.

```
> /omb:codex-run fix the flaky test in tests/test_auth.py
> /omb:codex-run add input validation to the /api/users endpoint
```

#### `/omb:codex-setup` — Setup Verification

Verifies Codex CLI installation, authentication status, and runs a connectivity test.

```
> /omb:codex-setup
# Checks: codex binary → auth status → connectivity test
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
