---
title: Create vs Update Decision
impact: HIGH
tags: lifecycle, create, update
---

## Create vs Update Decision

Before writing documentation, determine whether to create a new document or update an existing one. The wrong choice leads to duplicated content or lost context.

### Decision Matrix

| Scenario | Action |
|----------|--------|
| No document exists for the topic | Create new from template |
| Document exists and topic matches | Update existing document |
| Document exists but scope expanded significantly | Update existing + split if over 400 lines |
| API version changed (v1 to v2) | Create new (`resource-v2.md`), deprecate old |
| ADR is accepted and needs change | Create new ADR that supersedes the old one |
| Feature was removed | Update existing to `status: deprecated` |

### Create Protocol

1. Determine the correct category folder using `foundation-category-structure` rules
2. Choose a filename following `foundation-naming-convention` rules
3. Glob for `docs/{category}/{topic}*.md` to confirm no document exists
4. Copy the category template from `template-{category}.md`
5. Fill in the frontmatter with today's date for both `created` and `updated`
6. Set `status: draft` until content is reviewed

### Update Protocol

1. Read the existing document fully before making changes
2. Follow the steps in `foundation-update-protocol`
3. Set `status: active` if promoting from draft

**Incorrect (creating a duplicate):**

```markdown
# Creating docs/api/user-endpoints.md when docs/api/users.md already exists
# Now there are two documents covering the same API resource
```

**Correct (updating the existing document):**

```markdown
# Found docs/api/users.md already exists via: Glob docs/api/user*.md
# Reading existing content, then updating with new endpoint information
# Updated frontmatter: updated: 2026-04-10
```
