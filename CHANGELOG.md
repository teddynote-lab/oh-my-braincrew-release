# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

