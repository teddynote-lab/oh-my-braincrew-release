---
name: omb
description: >
  OMB orchestrator — unified dispatcher for the oh-my-braincrew workflow.
  Routes subcommands (interview, plan, plan-review, run, verify, doc, pr, release,
  prompt-guide, prompt-review, lint-check, brainstorming, mermaid, harness, setup,
  codex) to specialized omb-* sub-skills.
allowed-tools: Skill, AskUserQuestion, Bash, Read, Grep, Glob
argument-hint: "[subcommand] [args] | \"natural language task\""
effort: low
---

# OMB Dispatcher

Unified entry point for the oh-my-braincrew workflow. Routes to specialized sub-skills based on the first word of `$ARGUMENTS`.

## Pre-execution Context

!`git status --short 2>/dev/null | head -5`
!`git branch --show-current 2>/dev/null`

## Arguments

$ARGUMENTS

## Intent Router

Parse `$ARGUMENTS`:
1. Extract the **first word** as the subcommand.
2. Strip the subcommand from the string; the remainder is the arguments to pass to the target skill.
3. Apply routing in priority order: **Priority 1 → Priority 2 → Priority 3**.

---

### Priority 1: Explicit Subcommand Matching

Match the first word (case-insensitive) against the table below. If matched, invoke `Skill("{target}")` with the remaining argument string.

| Subcommand | Aliases | Target Skill | Purpose |
|------------|---------|-------------|---------|
| `interview` | `requirements` | `omb-interview` | Requirements gathering via structured questioning |
| `plan` | — | `omb-plan` | Implementation plan creation with evaluate-improve loop |
| `plan-review` | `review`, `critique` | `omb-plan-review` | Multi-agent plan review and scoring |
| `run` | `exec`, `execute` | `omb-run` | Plan execution with domain agent delegation |
| `verify` | `check-impl`, `validate` | `omb-verify` | Post-implementation verification |
| `doc` | `document`, `docs` | `omb-doc` | Documentation generation and updates |
| `pr` | `ship` | `omb-pr` | GitHub PR creation with lint gate |
| `prompt-guide` | `prompt` | `omb-prompt-guide` | Prompt engineering reference |
| `prompt-review` | — | `omb-prompt-review` | Iterative prompt scoring and improvement |
| `lint-check` | `lint`, `check` | `omb-lint-check` | Stack-aware linter execution |
| `brainstorming` | `brainstorm` | `omb-brainstorming` | Collaborative idea exploration |
| `mermaid` | `diagram` | `omb-mermaid` | Mermaid diagram generation |
| `harness` | `config` | `omb-harness` | Harness configuration management |
| `setup` | `init`, `initialize` | `omb-setup` | Project scaffolding and configuration |
| `release` | — | `omb-release` | Version release with changelog and binary builds |
| `codex` | — | `omb-codex` | Codex CLI code review and task delegation |
| `worktree` | `wt` | `omb-worktree` | Worktree management (create, status, clean, resume) |
| `clean` | — | `omb-clean` | Worktree cleanup and completion |

**Example:**
- `omb interview add OAuth login` → `Skill("omb-interview") "add OAuth login"`
- `omb run 2026-04-11-auth-plan.md` → `Skill("omb-run") "2026-04-11-auth-plan.md"`
- `omb ship` → `Skill("omb-pr")`

---

### Priority 2: Workflow Keyword Detection

If the first word does not match Priority 1, scan the full argument string for workflow keywords.

| Keywords | Target Skill |
|----------|-------------|
| `requirements`, `gather`, `questions`, `scope`, `define feature` | `omb-interview` |
| `implement plan`, `execute plan`, `run plan`, `start implementation` | `omb-run` |
| `verify implementation`, `check implementation`, `validate code`, `post-implementation check` | `omb-verify` |
| `create plan`, `write plan`, `planning` | `omb-plan` |
| `score plan`, `evaluate plan`, `review plan`, `critique plan` | `omb-plan-review` |
| `update docs`, `write docs`, `generate documentation`, `document` | `omb-doc` |
| `create pr`, `open pr`, `submit pr`, `pull request`, `push changes` | `omb-pr` |
| `prompt tips`, `prompt best practices`, `how to prompt` | `omb-prompt-guide` |
| `improve prompt`, `score prompt`, `review prompt` | `omb-prompt-review` |
| `lint`, `check code`, `run linter` | `omb-lint-check` |
| `brainstorm`, `explore idea`, `think through`, `ideate` | `omb-brainstorming` |
| `diagram`, `flowchart`, `sequence diagram`, `mermaid` | `omb-mermaid` |
| `configure harness`, `update agents`, `update hooks`, `update rules`, `update settings` | `omb-harness` |
| `initialize`, `scaffold`, `first run`, `set up project`, `configure project` | `omb-setup` |
| `release`, `publish`, `ship version`, `bump version and release` | `omb-release` |
| `codex review`, `adversarial review`, `code review with codex`, `delegate to codex` | `omb-codex` |
| `worktree`, `switch worktree`, `create worktree`, `worktree status` | `omb-worktree` |
| `clean worktree`, `remove worktree`, `cleanup` | `omb-clean` |

If a keyword match is found, invoke `Skill("{target}")` passing the full original `$ARGUMENTS` string.

---

### Priority 3: Ambiguous — Ask the User

If neither Priority 1 nor Priority 2 produces a match, use `AskUserQuestion` to let the user pick:

```
AskUserQuestion:
  question: "Which omb workflow should I run for this request?"
  header: "Workflow selection"
  options:
    - label: "interview — gather requirements"
      description: "Ask structured questions to define scope, tech stack, and constraints."
    - label: "plan — create implementation plan"
      description: "Author a multi-phase plan with agent delegation."
    - label: "run — execute a plan"
      description: "Run an existing .omb/plans/ file through domain agents."
    - label: "brainstorming — explore the idea first"
      description: "Open-ended collaborative dialogue before committing to a direction."
```

Show only the 2-3 most likely workflows based on the original argument string. After the user selects, invoke the corresponding skill with the original `$ARGUMENTS`.

---

## Routing Logic Summary

```
First word of $ARGUMENTS
  ├── Matches Priority 1 subcommand/alias?
  │     YES → Skill("{target}") with remaining args
  │
  └── No match
        ├── Full string matches Priority 2 keyword?
        │     YES → Skill("{target}") with full $ARGUMENTS
        │
        └── No match
              → AskUserQuestion (Priority 3): present top 2-3 workflows
                → Skill("{chosen target}") with $ARGUMENTS
```

---

## Workflow Quick Reference

Recommended execution order for a complete development cycle:

| # | Subcommand | Description | Supports --worktree |
|---|-----------|-------------|---------------------|
| 1 | `interview` | Requirements gathering | Yes |
| 2 | `plan` | Implementation plan | Yes |
| 3 | `plan-review` | Review and score plan | No |
| 4 | `run` | Execute plan | Yes |
| 5 | `verify` | Post-implementation verification | Yes |
| 6 | `document` | Generate/update docs | Yes |
| 7 | `pr` | Create GitHub PR | Yes |
| 8 | `release` | Version release with changelog and binary builds | No |

### Utility subcommands (invoke anytime):

| Subcommand | Description |
|-----------|-------------|
| `prompt-guide` | Prompt engineering reference |
| `prompt-review` | Iterative prompt scoring |
| `lint-check` | Stack-aware linter (required before PR) |
| `brainstorming` | Collaborative idea exploration |
| `mermaid` | Mermaid diagram generation |
| `harness` | Harness configuration management |
| `setup` | Project scaffolding and configuration |
| `worktree` | Worktree management (create, status, clean, resume) |
| `clean` | Worktree cleanup and completion |

---

## Output Contract

On successful routing (skill invoked):

<omb>DONE</omb>

```result
summary: "Routed to {target-skill} with args: {args}"
artifacts:
  - "{target-skill}"
changed_files: []
concerns: []
blockers: []
retryable: false
next_step_hint: "Check the output of {target-skill} for next steps"
```

On ambiguous input where the user declined to choose:

<omb>BLOCKED</omb>

```result
summary: "Could not determine target workflow from input: {$ARGUMENTS}"
artifacts: []
changed_files: []
concerns: []
blockers:
  - "No matching subcommand or keyword found and user declined to select"
retryable: true
next_step_hint: "Re-invoke with an explicit subcommand, e.g.: omb interview, omb plan, omb run"
```
