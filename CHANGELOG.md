# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.5] - 2026-04-13

### Fixed
- Install script now always updates `omb` symlink even when an older binary exists
- PyInstaller binary bundles certifi CA certificates to fix SSL errors on macOS
- HTTP downloader uses certifi SSL context for reliable HTTPS connections

## [0.1.4] - 2026-04-13

### Fixed
- Fixed release pipeline that caused all previous releases (v0.1.1-v0.1.3) to ship with zero assets
- CI publish job now tolerates partial build failures across platforms
- Install script URL corrected (no longer returns 404)
- Binary download asset naming aligned with CI output format
- Hooks and statusline script now properly included in harness distribution
- Eliminated race condition between manual release skill and CI pipeline

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

## [0.1.1] - 2026-04-12

### Added
- CLI commands: `omb init`, `omb update`, and `omb version` for harness installation and management
- SQLite-based worktree state management with persistent tracking across sessions
- Verification skill (`omb:verify`) with parallel verifier pool
- Codex CLI integration for code review, adversarial review, and task delegation
- Release pipeline for automated version bumping, changelog, and publishing
- Plan review parallelization across multiple reviewer agents
- Evidence-anchored prompt evaluation with binary rubric scoring

### Changed
- Renamed CLI binary to `oh-my-braincrew` with `omb` as primary command
- Unified ticket schema for all evaluation, review, and verification workflows
- TDD practices integrated across all implementation and verification agents

### Fixed
- Git branch name display in statusline
- Hook fallback for manual invocations

---

## Legacy (v0.2.x)

> The v0.2.x series used a plugin-based architecture that has been replaced by the current harness architecture in v0.1.x. These versions are no longer supported.

<details>
<summary>v0.2.6 — v0.2.17 (2026-04-05 to 2026-04-09)</summary>

- v0.2.17: Fixed Codex hooks and plugin manifest path
- v0.2.16: Added Codex plugin integration, lint checks during verification
- v0.2.15: Pipeline recovery and resilience improvements
- v0.2.14: Codex plugin installation, hook reliability fixes
- v0.2.13: Pipeline stall recovery, hook decision logging
- v0.2.12: Dual-path installation guide, checkpoint setup docs
- v0.2.11: Language settings in setup wizard
- v0.2.10: PROJECT.md, Slack notifications, pipeline stability
- v0.2.9: `omb progress` and `omb sync` commands
- v0.2.8: Hook and auto-update fixes
- v0.2.7: `omb init` command
- v0.2.6: Cross-platform binary distribution, one-liner installers

</details>
