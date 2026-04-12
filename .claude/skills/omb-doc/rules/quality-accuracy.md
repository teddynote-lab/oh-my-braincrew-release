---
title: Accuracy Verification
impact: MEDIUM
tags: quality, accuracy, verification
---

## Accuracy Verification

Every claim in documentation must be verifiable. Code examples must compile, commands must run, and file paths must exist.

### What to Verify

| Claim Type | Verification Method |
|-----------|-------------------|
| File path in `relates-to` | Glob for the path |
| Code example | Read the source file to confirm syntax matches |
| Shell command | Run the command (or dry-run with `--help`) |
| API endpoint URL | Check route definitions in source code |
| Environment variable | Grep for usage in codebase |
| Configuration value | Read the config file |

### Rules

- Never document a file path without confirming it exists
- Code examples must match the actual implementation (or be clearly marked as pseudocode)
- Shell commands must use correct flags and arguments
- API response examples must match the actual Pydantic/Zod schema
- When unsure about accuracy, add a `> **UNVERIFIED:** ...` banner

**Incorrect (unverified claims):**

```markdown
Run `python manage.py migrate` to apply changes.
The config is at `src/config/settings.yaml`.
```

```
# But the project uses Alembic, not Django migrations
# And the config file is actually at src/config/settings.py
```

**Correct (verified claims):**

```markdown
Run `alembic upgrade head` to apply the latest migration.
The config is at `src/config/settings.py` (verified via `Glob src/config/settings.*`).
```
