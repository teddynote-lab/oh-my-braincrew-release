---
title: Table Formatting
impact: MEDIUM-HIGH
tags: format, tables, markdown
---

## Table Formatting

Use markdown tables for structured data with consistent columns. Tables are preferred over lists when data has 2+ attributes per item.

### When to Use Tables vs Lists

| Use Tables When | Use Lists When |
|----------------|---------------|
| Data has 2+ attributes per item | Items have a single attribute |
| Comparing items across dimensions | Items are sequential steps |
| Referencing data by lookup (e.g., error codes) | Items are hierarchical |

### Rules

- Left-align text columns, right-align numeric columns
- Use `|` separators consistently with spaces
- Header row describes what the column contains, not just a label
- Keep cells concise — one line per cell. Use a note below the table for details.
- Use `—` for empty/not-applicable cells (not blank)
- Sort rows logically: alphabetical, by severity, or by frequency

**Incorrect (inconsistent, blank cells, no alignment):**

```markdown
|name|type|desc|
|-|-|-|
|id|UUID||
|name|VARCHAR|the name|
```

**Correct (consistent spacing, descriptive headers, no blank cells):**

```markdown
| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| id | UUID | NO | gen_random_uuid() | Primary key |
| name | VARCHAR(255) | NO | — | User display name |
| email | VARCHAR(320) | NO | — | Unique email address |
| created_at | TIMESTAMPTZ | NO | now() | Row creation timestamp |
```
