# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.5] - 2026-04-12

### Maintenance
- Release v0.1.5


## [0.1.4] - 2026-04-12

### Maintenance
- Release v0.1.4


## [0.1.3] - 2026-04-13

### Added
- `omb:issue` skill for automated codebase scanning and GitHub issue creation
- `omb:git-setup` skill for git workflow setup with pre-commit hooks and GitHub Actions
- `.gitignore` management integrated into `omb init`
- Documentation language support for PR, issue, and plan skills
- Git hooks and GitHub Actions CI workflows

### Fixed
- Statusline width detection for non-TTY and narrow terminal environments
- PR creation workflow compatibility with worktree environments
- Language environment variable resolution in agents and skills

### Changed
- Updated PR labels and added label sync to git-setup workflow

## [0.1.2] - 2026-04-12

### Changed
- Codex skills renamed for improved consistency
- PR template enhanced with language support and conditional sections
- `omb:document` renamed to `omb:doc` for brevity
- README restructured with usage examples and workflow documentation

### Fixed
- Statusline now uses project root for folder name and displays rate limit reset time

### Maintenance
- Improved worktree cleanup execution flow

## [0.1.1] - 2026-04-12

### Breaking Changes
- Version reset from 0.2.x to 0.1.x — project restructured as a Claude Code harness with new architecture

### Added
- CLI commands: `omb init`, `omb update`, and `omb version` for harness installation and management
- SQLite-based worktree state management with persistent tracking across sessions
- Verification skill (`omb:verify`) with parallel verifier pool
- Codex CLI integration for code review, adversarial review, and task delegation
- Release pipeline for automated version bumping, changelog, and publishing
- Plan review parallelization across multiple reviewer agents
- Evidence-anchored prompt evaluation with binary rubric scoring
- Fullstack AI project template with environment configuration

### Changed
- Renamed CLI binary to `oh-my-braincrew` with `omb` as primary command
- Unified ticket schema for all evaluation, review, and verification workflows
- Standardized agent documentation with scope definitions and execution policies
- TDD practices integrated across all implementation and verification agents

### Fixed
- Git branch name display in statusline
- Hook fallback for manual invocations

### Documentation
- Added README with usage examples and reference documentation
- Added no-attribution rule for PR and commit messages

## [0.2.17] - 2026-04-09

### Fixed
- Codex hooks no longer fail with `${CLAUDE_PLUGIN_ROOT}` errors at session stop
- Plugin manifest path corrected for the Codex companion server

## [0.2.16] - 2026-04-09

### Added
- Codex plugin integration — 7 new `/omb codex-*` commands for delegating code review, adversarial analysis, and rescue tasks to OpenAI Codex
- Driver heartbeat for improved pipeline session health monitoring
- Ruff and ESLint lint checks now run automatically during verification

### Fixed
- Verification output no longer corrupted by ANSI escape sequences
- Type checker warnings resolved in the stop hook engine
- Pipeline lifecycle no longer fails when clearing driver state after archiving

### Improved
- Plan review now uses adversarial review pattern for more thorough and skeptical analysis

## [0.2.15] - 2026-04-07

### Fixed
- Pipeline no longer stalls when the driver process exits unexpectedly mid-task — automatic recovery kicks in
- Late pipeline advance calls are safely ignored, preventing tasks from being skipped
- Status line version display fixed on systems without `pip index` support

### Improved
- Pipeline driver loop is now more resilient with stricter state tracking

## [0.2.14] - 2026-04-06

### Added
- Codex plugin installation — `omb setup` now offers to install the Codex plugin during initial project configuration

### Fixed
- Hook reliability improvements for pipeline ownership and lifecycle tracking
- Statusline now correctly detects active tasks and project root
- CI pipeline stability fixes for Python checks

### Improved
- Skill scripts extracted into standalone files for faster loading and easier debugging

## [0.2.13] - 2026-04-06

### Fixed
- Pipeline no longer stalls when the driving session is interrupted — automatic recovery kicks in after 2 minutes of inactivity

### Improved
- Pipeline debugging: all hook decisions now logged to the pipeline session log file for easy diagnosis
- README updated with quick workflow summary section

## [0.2.12] - 2026-04-06

### Changed
- Installation guide now features "For Claude Code (auto)" and "For Human (manual)" dual-path setup
- Checkpoint setup documented with interactive and JSON editing methods
- Slack setup includes direct link to configuration guide

### Improved
- Language settings can now be changed directly in `.claude/settings.json` after initial setup
- Pipeline templates include Manual mode for custom workflow design

## [0.2.11] - 2026-04-06

### Added
- Language settings support in setup wizard with i18n propagation across agents and skills

### Fixed
- Session advancement stability with driver guard preventing double-advance
- Worktree setup reliability using CLI commands instead of inline scripts

### Improved
- Agent localization now correctly references language settings

## [0.2.10] - 2026-04-06

### Added
- `PROJECT.md` for documenting project architecture and setup

### Fixed
- Slack notification delivery with improved credential handling
- Pipeline session stability — stale state guard and resolver fallback
- Pipeline worktree path propagation for isolated execution
- Statusline display improvements and flicker fix

### Improved
- Pipeline execution now uses deterministic CLI-based generation

## [0.2.9] - 2026-04-05

### Added
- `omb progress` command for viewing pipeline execution status in the terminal
- `omb sync` command to keep plugin files up to date

### Fixed
- Slack notifications now deliver correctly when configured
- Pipeline plan mode no longer stalls on approval steps

### Improved
- Worktree naming uses session IDs for better organization and auto-archive support

## [0.2.8] - 2026-04-05

### Fixed
- Hook no longer incorrectly blocks edits to project configuration directories
- `omb update` now properly syncs plugin files (skills, agents, hooks) alongside the package
- Auto-update works correctly for source-based installations

### Improved
- Pipeline execution now skips unnecessary checkpoint prompts by default, with opt-in interactive selection


## [0.2.7] - 2026-04-05

### Added
- omb init command — initialize oh-my-braincrew in any project with a single command

### Improved
- Renamed pipeline initialization skill for clearer naming


## [0.2.6] - 2026-04-05

### Added
- Cross-platform binary distribution — standalone binaries for macOS (Apple Silicon & Intel), Linux, and Windows
- Self-update for binary installs — `omb update` automatically downloads the latest version
- One-liner installers: `curl | sh` for macOS/Linux, PowerShell for Windows

