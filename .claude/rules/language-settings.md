# Language Settings

## Environment Variables

| Variable | Values | Default | Effect |
|----------|--------|---------|--------|
| `OMB_LANGUAGE` | `en`, `ko` | `en` | Controls interaction language — conversational responses, status messages, AskUserQuestion prompts |
| `OMB_DOC_LANGUAGE` | `en`, `ko` | `en` | Controls document language — plans (.omb/plans/), generated docs, README.md |

These are set during `/omb setup` and stored in `.claude/settings.json` env object.

## Reading Language Settings

[IMPORTANT] Subagents do NOT inherit env vars from settings.json. Skills must read settings via pre-execution context blocks:

```
!cat .claude/settings.json 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('env',{}).get('OMB_LANGUAGE','en'))"
!cat .claude/settings.json 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('env',{}).get('OMB_DOC_LANGUAGE','en'))"
```

Skills that invoke agents must pass the resolved language values in the agent prompt as literal strings.

## Precedence Rules

1. **OMB_LANGUAGE** is the primary signal for interaction language.
2. Agents respond in the language specified by OMB_LANGUAGE.
3. If OMB_LANGUAGE is not set or is `en`, agents respond in English.
4. If OMB_LANGUAGE is `ko`, agents respond in Korean.
5. For document generation, OMB_DOC_LANGUAGE takes priority.
6. Unrecognized values for either variable default to `en`.

## [HARD] Always-English Files

The following files MUST always be written in English, regardless of any language setting:
- `CLAUDE.md` (all scopes: project, user, plugin)
- `PROJECT.md`
- `MEMORY.md` and all files in the memory directory
- `.claude/rules/*.md` (all rule files)
- `.claude/agents/omb/*.md` (agent definitions)
- `.claude/skills/*/SKILL.md` (skill definitions)
- `.claude/hooks/omb/*.sh` (hook scripts)
- Code comments, variable names, and docstrings (per code-conventions.md)
- Git commit messages and PR descriptions
- Security findings and verification reports (always English for auditability)

## Security-Sensitive Agent Exemptions

The following agents MUST always produce output in English, regardless of OMB_LANGUAGE:
- `security-reviewer` — security findings must be English for audit
- `verifier` — verification reports must be English for evidence chain
- `git-master` — commit messages and PR descriptions are always English
