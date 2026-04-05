# Skill-Command Parity Rule

## [HARD] Every user-invocable skill MUST have a command file

When creating a new skill in `.claude/skills/<name>/SKILL.md` that has `user-invocable: true` (or omits the field, defaulting to true):

1. Create `.claude/commands/omb/<name>.md` — thin wrapper for plugin-mode discovery
2. Create `internal/template/templates/.claude/commands/omb/<name>.md` — same content, for `omb init` deployment
3. Run `make sync-templates` to verify both directories are in sync
4. Update the dispatcher routing table in `.claude/skills/omb/SKILL.md`

### Exceptions

- `lc-*` reference skills (`disable-model-invocation: true`) — skill-only is fine
- Skills with `user-invocable: false` — intentionally hidden from menu

### Why

Without a command file, the skill is invisible in Claude Code's `/` autocomplete menu. Users cannot discover it. The skill still works programmatically (via `Skill()` calls or hooks), but no one can find it. This caused the `omb:interview`, `omb:loop`, and `omb:release` visibility bugs.

### Command file format (thin wrapper)

```markdown
---
description: <one-line description matching the skill>
argument-hint: "<usage hint>"
---

Use Skill("omb-<skill-name>") with arguments: $ARGUMENTS
```

### Verification checklist for new skills

- [ ] `.claude/skills/<name>/SKILL.md` exists with proper frontmatter
- [ ] `.claude/commands/omb/<name>.md` exists
- [ ] `internal/template/templates/.claude/commands/omb/<name>.md` exists
- [ ] `.claude/skills/omb/SKILL.md` dispatcher has a routing entry
- [ ] `make sync-templates` shows no diff
- [ ] CLAUDE.md skill list updated (if applicable)

### Reference

- `docs/plugin-dev-docs/10-commands-vs-skills-critical-distinction.md`
- `docs/plugin-dev-docs/15-common-mistakes-gotchas.md`
