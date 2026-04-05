# Common AST-Grep Patterns

Patterns organized by the omb tech stack: Python/FastAPI, TypeScript/React, Go, and security.

## Python / FastAPI

### Route Handlers

```yaml
# Find all FastAPI route handlers
id: fastapi-routes
language: python
rule:
  pattern: '@router.$METHOD($PATH)'
```

```
# CLI pattern
sg -p '@router.$METHOD($PATH)' -l python
```

### Pydantic Models

```yaml
# Find Pydantic model definitions
id: pydantic-models
language: python
rule:
  pattern: 'class $MODEL(BaseModel): $$$BODY'
```

### Async Functions

```yaml
# Find async functions
id: async-functions
language: python
rule:
  pattern: 'async def $NAME($$$ARGS): $$$'
```

### Dependency Injection

```yaml
# Find FastAPI Depends() usage
id: fastapi-depends
language: python
rule:
  pattern: '$VAR: $TYPE = Depends($FACTORY)'
```

### Blocking I/O in Async

```yaml
# Detect blocking calls inside async functions
id: blocking-in-async
language: python
rule:
  any:
    - pattern: 'time.sleep($DURATION)'
    - pattern: 'open($PATH)'
    - pattern: 'requests.get($URL)'
  inside:
    pattern: 'async def $FUNC($$$): $$$'
    stopBy: end
message: 'Blocking I/O in async function'
```

### Exception Handling

```yaml
# Find bare except clauses
id: bare-except
language: python
rule:
  pattern: |
    except:
        $$$BODY
message: 'Avoid bare except — catch specific exceptions'
```

## TypeScript / React

### Component Exports

```yaml
# Find exported React components
id: react-components
language: typescriptreact
rule:
  any:
    - pattern: 'export function $NAME($PROPS) { $$$ }'
    - pattern: 'export default function $NAME($PROPS) { $$$ }'
    - pattern: 'export const $NAME = ($PROPS) => { $$$ }'
```

### Hook Usage

```yaml
# Find useState calls
id: use-state
language: typescriptreact
rule:
  pattern: 'const [$STATE, $SETTER] = useState($INIT)'
```

```yaml
# Find useEffect with dependencies
id: use-effect
language: typescriptreact
rule:
  pattern: 'useEffect(() => { $$$BODY }, [$$$DEPS])'
```

### Custom Hooks

```yaml
# Find custom hook definitions
id: custom-hooks
language: typescript
rule:
  kind: function_declaration
  has:
    kind: identifier
    regex: '^use[A-Z]'
    field: name
```

### Type Assertions

```yaml
# Find type assertions (potential type safety issues)
id: type-assertions
language: typescript
rule:
  any:
    - pattern: '$EXPR as any'
    - pattern: '$EXPR as unknown'
```

## Go

### Function Definitions

```yaml
# Find all Go function definitions
id: go-functions
language: go
rule:
  pattern: 'func $NAME($$$PARAMS) $$$RETURNS { $$$ }'
```

### Method Definitions

```yaml
# Find methods on a specific type
id: go-methods
language: go
rule:
  pattern: 'func ($RECV $TYPE) $NAME($$$PARAMS) $$$RETURNS { $$$ }'
```

### Error Handling

```yaml
# Find error handling blocks
id: error-handling
language: go
rule:
  pattern: 'if err != nil { $$$ }'
```

```yaml
# Find ignored errors
id: ignored-errors
language: go
rule:
  pattern: '$VAR, _ := $FUNC($$$)'
message: 'Error return value ignored'
```

### Context Propagation

```yaml
# Find functions that should accept context but don't
id: missing-context
language: go
rule:
  all:
    - kind: function_declaration
    - has:
        any:
          - pattern: '$DB.Query($$$)'
          - pattern: 'http.Get($$$)'
        stopBy: end
    - not:
        has:
          pattern: 'ctx context.Context'
          field: parameters
message: 'Function with I/O should accept context.Context'
```

## Node.js (Express/Fastify)

### Route Handlers

```yaml
# Express route handlers
id: express-routes
language: javascript
rule:
  any:
    - pattern: 'app.$METHOD($PATH, $$$HANDLERS)'
    - pattern: 'router.$METHOD($PATH, $$$HANDLERS)'
```

### Middleware

```yaml
# Express middleware definitions
id: express-middleware
language: javascript
rule:
  pattern: 'app.use($$$ARGS)'
```

## Security Patterns

### SQL Injection

```yaml
id: sql-injection
language: python
severity: error
rule:
  any:
    - pattern: 'cursor.execute(f"$$$SQL")'
    - pattern: 'cursor.execute($QUERY % $ARGS)'
    - pattern: 'cursor.execute($QUERY.format($$$))'
message: 'Potential SQL injection — use parameterized queries'
```

```yaml
id: sql-injection-js
language: javascript
severity: error
rule:
  any:
    - pattern: '$DB.query(`$$$SQL ${$VAR} $$$`)'
    - pattern: '$DB.query($SQL + $VAR)'
message: 'Potential SQL injection — use parameterized queries'
```

### XSS

```yaml
id: xss-danger
language: typescriptreact
severity: warning
rule:
  pattern: 'dangerouslySetInnerHTML={{ __html: $CONTENT }}'
message: 'XSS risk — sanitize content before using dangerouslySetInnerHTML'
```

### Hardcoded Credentials

```yaml
# Detect hardcoded password or secret assignments
id: hardcoded-credentials
language: python
severity: error
rule:
  any:
    - pattern: 'password = "$$$VALUE"'
    - pattern: 'secret = "$$$VALUE"'
    - pattern: 'token = "$$$VALUE"'
message: 'Hardcoded credential — use environment variables'
```

### Command Injection

```yaml
id: command-injection
language: python
severity: error
rule:
  any:
    - pattern: 'os.system($CMD)'
    - pattern: 'subprocess.call($CMD, shell=True)'
    - pattern: 'subprocess.run($CMD, shell=True)'
message: 'Potential command injection — avoid shell=True with untrusted input'
```
