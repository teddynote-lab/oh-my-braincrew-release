---
paths: "**/*.py,**/*.ts,**/*.tsx,**/*.js,**/*.jsx,**/*.go"
---

# AST-Grep Usage Rules

## When to Use `ast_grep_search` vs `Grep`

| Use `ast_grep_search` | Use `Grep` |
|----------------------|------------|
| Function/method signatures | Import statements |
| Class/type definitions | String literals, log messages |
| Decorator/attribute patterns | Comments, TODOs |
| Structural refactoring targets | Config values, env vars |
| Hook/component patterns | File path references |

Rule of thumb: if the match depends on code **structure** (nesting, scope, parent-child), use ast-grep. If it depends on **text content**, use Grep.

## Pattern Syntax Quick Reference

| Meta-variable | Meaning | Example |
|--------------|---------|---------|
| `$NAME` | Single AST node | `def $NAME($$$):` |
| `$$$ARGS` | Zero or more nodes (variadic) | `function $F($$$ARGS)` |
| `$$_` | Anonymous single match | `if ($$_) { $$$BODY }` |
| `$_` | Wildcard single node | `$_.$METHOD($$$)` |

## Common Patterns by Tech Stack

### Python / FastAPI

```
# FastAPI route handlers
@router.$METHOD($PATH)
async def $HANDLER($$$PARAMS): $$$

# Pydantic models
class $MODEL(BaseModel): $$$

# Async function definitions
async def $NAME($$$ARGS): $$$

# Dependency injection
$VAR: $TYPE = Depends($FACTORY)
```

### TypeScript / React

```
# React component exports
export function $NAME($PROPS) { $$$ }

# Hook usage
const [$STATE, $SETTER] = useState($INIT)

# useEffect patterns
useEffect(() => { $$$ }, [$$$DEPS])

# Named exports
export const $NAME: $TYPE = $VALUE
```

### Go

```
# Function definitions
func $NAME($$$PARAMS) $$$RETURNS { $$$ }

# Method definitions
func ($RECV $TYPE) $NAME($$$PARAMS) $$$RETURNS { $$$ }

# Error handling pattern
if err != nil { $$$ }

# Interface definitions
type $NAME interface { $$$ }
```

## Relational Rules

Always use `stopBy: end` in relational rules (`inside`, `has`, `follows`, `precedes`) to ensure complete subtree traversal:

```yaml
rule:
  pattern: 'useState($INIT)'
  inside:
    pattern: 'function $COMPONENT($$$) { $$$ }'
    stopBy: end
```

## Security Scanning Patterns

Use ast-grep for structural security checks:

- **SQL injection**: `cursor.execute(f"$$$SQL")` or `$DB.query($SQL + $VAR)`
- **XSS**: `dangerouslySetInnerHTML={{ __html: $CONTENT }}`
- **Hardcoded secrets**: `password = "$$$VALUE"` and similar credential patterns
- **Bare except**: `except: $$$BODY` (should catch specific exceptions)

For the full rule reference, load `Skill("omb-ast-grep-guide")`.

## `ast_grep_replace` (T3 Code-Modifying Agents Only)

Use for structural refactoring — rename patterns, update function signatures, transform decorators. Never use for simple text replacements (use `Edit` instead).

## CLI Usage

When running `sg` via Bash:

```bash
# Pattern search
sg -p 'async def $NAME($$$): $$$' -l python /path/to/dir

# Rule-based search
sg scan --rule rule.yml /path/to/dir

# Inline rule
sg scan --inline-rules 'rule: { pattern: "console.log($$$)" }' --stdin

# Debug AST structure
sg run --pattern 'code' --lang javascript --debug-query=cst
```
