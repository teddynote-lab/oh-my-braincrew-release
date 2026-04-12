---
title: Code Block Formatting
impact: MEDIUM-HIGH
tags: format, code, blocks
---

## Code Block Formatting

All code examples in documentation must use fenced code blocks with the correct language tag. Include file path context and keep blocks focused.

### Rules

- Always include a language tag: `python`, `typescript`, `sql`, `json`, `bash`, `yaml`
- Use `json` for request/response examples (not `jsonc`)
- Use `sql` for raw queries and DDL statements
- Include a file path comment on the first line for code snippets: `# src/models/user.py` or `// src/routes/users.ts`
- Keep code blocks under 30 lines. Link to the source file for longer examples.
- Use `bash` for shell commands with `$` prompt prefix

**Incorrect (no language tag, no file context, too long):**

```markdown
```
def create_user(data):
    user = User(**data)
    db.add(user)
    db.commit()
    return user
```
```

**Correct (language tag, file path, focused):**

```markdown
```python
# src/services/user_service.py
async def create_user(data: UserCreate) -> User:
    user = User(**data.model_dump())
    db.add(user)
    await db.commit()
    return user
```
```

For shell commands:

```markdown
```bash
$ docker compose up -d
$ curl -X POST http://localhost:8000/api/v1/users -H "Content-Type: application/json" -d '{"name": "test"}'
```
```
