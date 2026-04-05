# AST-Grep Rule Reference

Complete reference for ast-grep rule syntax. Rules are YAML objects with optional fields — at least one "positive" key is required. Multiple fields at the same level are combined with implicit AND.

## Atomic Rules

### pattern

Match code by structure. Supports string or object form.

```yaml
# String form — direct pattern
rule:
  pattern: 'console.log($ARG)'

# Object form — with selector and context
rule:
  pattern:
    context: 'function $F() { return $V }'
    selector: return_statement
```

**Strictness levels**: `cst` (exact whitespace), `smart` (default, normalized), `signature` (ignore body), `relaxed` (most flexible).

### kind

Match by AST node type name.

```yaml
rule:
  kind: function_declaration
```

Use `--debug-query=cst` to discover node kind names for a language.

### regex

Match node text content with a regular expression.

```yaml
rule:
  kind: identifier
  regex: '^use[A-Z]'  # React hooks
```

### nthChild

Match by position among sibling nodes.

```yaml
# Match first child
rule:
  nthChild: 1

# Match using An+B syntax (like CSS)
rule:
  nthChild: '2n+1'  # Odd children

# Object form with reverse
rule:
  nthChild:
    position: 1
    reverse: true  # Last child
```

### range

Match by source position (line/column).

```yaml
rule:
  range:
    start: { line: 10, column: 0 }
    end: { line: 20, column: 0 }
```

## Relational Rules

All relational rules accept `stopBy` and `field` options.

### stopBy Options

| Value | Behavior |
|-------|----------|
| `neighbor` | Only check immediate children (default) |
| `end` | Search entire subtree (**recommended**) |
| `{rule}` | Stop when the rule matches |

### inside

Pattern must appear within another pattern.

```yaml
rule:
  pattern: 'await $EXPR'
  inside:
    kind: function_declaration
    stopBy: end
```

### has

Pattern must contain another pattern.

```yaml
rule:
  kind: class_declaration
  has:
    pattern: 'constructor($$$) { $$$ }'
    stopBy: end
```

### precedes

Pattern must appear before another pattern at the same level.

```yaml
rule:
  pattern: 'const $CONFIG = $VALUE'
  precedes:
    pattern: 'export default $CONFIG'
```

### follows

Pattern must appear after another pattern at the same level.

```yaml
rule:
  pattern: 'return $VALUE'
  follows:
    pattern: 'if ($COND) { $$$ }'
```

### field

Restrict relational search to a specific named AST field.

```yaml
rule:
  kind: if_statement
  has:
    pattern: '$A && $B'
    field: condition
```

## Composite Rules

### all (AND)

All sub-rules must match.

```yaml
rule:
  all:
    - pattern: 'def $FUNC($$$):'
    - not:
        pattern: 'def $FUNC($$$) -> $TYPE:'
```

### any (OR)

At least one sub-rule must match.

```yaml
rule:
  any:
    - pattern: 'console.log($$$)'
    - pattern: 'console.warn($$$)'
    - pattern: 'console.error($$$)'
```

### not (negation)

Sub-rule must NOT match.

```yaml
rule:
  pattern: 'fetch($URL)'
  not:
    inside:
      pattern: 'try { $$$ } catch ($$$) { $$$ }'
      stopBy: end
```

### matches (reuse)

Reference a named utility rule defined in `utils`.

```yaml
utils:
  is-async:
    kind: function_declaration
    has:
      kind: async

rule:
  matches: is-async
  has:
    pattern: 'await $$$'
    stopBy: end
```

## Constraints

Add constraints on captured meta-variables.

```yaml
rule:
  pattern: '$FUNC($$$ARGS)'
constraints:
  FUNC:
    regex: '^(eval|exec)$'
  ARGS:
    not:
      regex: '^$'  # Must have arguments
```

## Fix / Rewrite

Define automatic fixes for matched patterns.

```yaml
rule:
  pattern: 'console.log($MSG)'
fix: 'logger.info($MSG)'
```

For complex transformations, use `rewriters`:

```yaml
rule:
  pattern: '$A == null'
fix: '$A === null'

rewriters:
  convert-to-strict:
    rule:
      pattern: '$A == $B'
    fix: '$A === $B'
```

## YAML Rule File Format

```yaml
id: rule-identifier
language: python  # or javascript, typescript, go, etc.
severity: error   # error, warning, hint, off
rule:
  # rule definition (atomic, relational, or composite)
message: 'Human-readable description of the issue'
note: 'Additional context or fix suggestion'
fix: 'auto-fix pattern (optional)'
constraints:
  # meta-variable constraints (optional)
utils:
  # reusable sub-rules (optional)
```
