---
name: omb-ast-grep-guide
description: >
  Use when performing structural code search, AST-based refactoring,
  security scanning, or rule-based code analysis with ast-grep (sg CLI).
  Reference guide for pattern syntax, rule composition, and common
  patterns for Python, TypeScript, and Go.
allowed-tools: Read, Grep, Glob
user-invocable: false
metadata:
  version: "1.0.0"
  category: "tool"
  status: "active"
  updated: "2026-03-23"
  tags: "ast, refactoring, code-search, security, structural-search"
  context: "fork"
---

# AST-Grep Reference Guide

ast-grep (`sg` CLI) performs structural code search using Abstract Syntax Trees. It matches code by **structure**, not text — enabling searches that understand nesting, scope, and language grammar.

## When to Use ast-grep

- Searching for function signatures, class definitions, decorator patterns
- Finding code patterns within specific contexts (e.g., `useState` inside components)
- Security scanning for vulnerability patterns (SQL injection, XSS)
- Structural refactoring (rename patterns, update signatures)
- Finding code that is **missing** expected patterns (using `not`)

## Pattern Syntax

| Meta-variable | Captures | Example |
|--------------|----------|---------|
| `$NAME` | Exactly one AST node | `def $NAME($$$):` |
| `$$$ARGS` | Zero or more nodes | `function $F($$$ARGS) { $$$ }` |
| `$$_` | One node (anonymous) | `if ($$_) { $$$ }` |
| `$_` | One node (wildcard) | `$_.$METHOD($$$)` |

## Rule Types

### Atomic Rules
- **`pattern`**: Match a code pattern directly
- **`kind`**: Match by AST node type (e.g., `function_declaration`)
- **`regex`**: Match node text with regex
- **`nthChild`**: Match by position among siblings

### Relational Rules

**Always use `stopBy: end`** for relational rules to ensure full subtree search.

- **`inside`**: Pattern must be within another pattern
- **`has`**: Pattern must contain another pattern
- **`precedes`**: Pattern must come before another pattern
- **`follows`**: Pattern must come after another pattern

```yaml
rule:
  pattern: 'time.sleep($DURATION)'
  inside:
    pattern: 'async def $FUNC($$$): $$$'
    stopBy: end
fix: 'await asyncio.sleep($DURATION)'
```

### Composite Rules
- **`all`**: All sub-rules must match (AND)
- **`any`**: At least one sub-rule must match (OR)
- **`not`**: Sub-rule must NOT match (negation)
- **`matches`**: Reuse a named utility rule

## CLI Commands

```bash
# Simple pattern search
sg -p 'async def $NAME($$$): $$$' -l python /path

# Rule file search
sg scan --rule my_rule.yml /path

# Inline rule (for quick testing)
echo "code" | sg scan --inline-rules 'rule: { pattern: "console.log($$$)" }' --stdin

# Debug AST structure
sg run --pattern 'code' --lang javascript --debug-query=cst
```

## Debugging Tips

1. Start with the simplest pattern, then add complexity
2. Use `--debug-query=cst` to see how the code is parsed
3. Add `stopBy: end` if relational rules miss matches
4. Verify `kind` values match the language's AST node types
5. Test rules against example code before running on the full codebase

## Reference Files

- Rule syntax reference: `${CLAUDE_SKILL_DIR}/references/rule-reference.md`
- Common patterns by tech stack: `${CLAUDE_SKILL_DIR}/references/patterns.md`
