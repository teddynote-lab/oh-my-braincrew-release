# Sections

This file defines all sections, their ordering, impact levels, and descriptions.
The section ID (in parentheses) is the filename prefix used to group rules.

---

## 1. Foundation (foundation)

**Impact:** CRITICAL
**Description:** The structural backbone of the documentation system. Category structure, naming conventions, frontmatter schema, and update protocols must be followed for every document. Without these, documents become unfindable and unmaintainable.

## 2. Templates (template)

**Impact:** HIGH
**Description:** Category-specific document templates ensure consistency and completeness. Each template defines the required sections, diagram types, and table formats for its category. Using templates prevents blank-page paralysis and guarantees minimum quality.

## 3. Format (format)

**Impact:** MEDIUM-HIGH
**Description:** Formatting rules for diagrams, code blocks, tables, and changelogs. Consistent formatting enables automated tooling, improves readability, and ensures documents render correctly on GitHub.

## 4. Lifecycle (lifecycle)

**Impact:** HIGH
**Description:** Rules governing document creation, updates, staleness detection, deprecation, and cross-referencing. Living documentation requires active lifecycle management to prevent drift between code and docs.

## 5. Quality (quality)

**Impact:** MEDIUM
**Description:** Quality gates for accuracy, completeness, and conciseness. Every document must pass these checks before being marked as active. Quality rules prevent documentation debt.
