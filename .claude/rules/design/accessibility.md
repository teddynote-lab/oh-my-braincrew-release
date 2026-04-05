---
description: "Accessibility standards: WCAG AA, semantic HTML, keyboard navigation, screen readers"
paths: ["**/*.tsx", "**/*.jsx", "**/*.html"]
---

# Accessibility Standards

Target: WCAG 2.1 AA compliance.

## Semantic HTML

- Use semantic elements: `<nav>`, `<main>`, `<article>`, `<section>`, `<header>`, `<footer>`.
- Headings in order: `<h1>` → `<h2>` → `<h3>`. Never skip levels.
- Use `<button>` for actions, `<a>` for navigation. Never `<div onClick>`.
- Lists use `<ul>`/`<ol>`, not styled divs.

## Keyboard Navigation

- All interactive elements MUST be keyboard accessible.
- Tab order follows visual order (avoid positive `tabIndex`).
- Focus indicators must be visible — never `outline: none` without replacement.
- Modal focus trapping: Tab stays within modal while open.
- Keyboard shortcuts: document them, avoid conflicts with browser/OS shortcuts.

## ARIA

- Prefer semantic HTML over ARIA — ARIA is a fallback, not a first choice.
- Required ARIA for custom widgets:
  - Toggle: `aria-pressed` or `aria-checked`.
  - Expandable: `aria-expanded`.
  - Live regions: `aria-live="polite"` for async updates.
  - Dialogs: `role="dialog"` + `aria-modal="true"` + `aria-labelledby`.

## Color and Contrast

- Text contrast: 4.5:1 minimum (AA), 7:1 preferred (AAA).
- Large text (18px+ bold or 24px+): 3:1 minimum.
- Never convey information through color alone — use icons, patterns, or text.

## Forms

- Every input MUST have an associated `<label>` (visible or `aria-label`).
- Error messages linked via `aria-describedby`.
- Required fields marked with `aria-required="true"` and visual indicator.
- Group related fields with `<fieldset>` and `<legend>`.

## Images and Media

- All `<img>` elements MUST have `alt` text (empty `alt=""` for decorative images).
- Complex images (charts, diagrams): provide text description.
- Video: captions and transcripts.

## Testing

- Screen reader testing: VoiceOver (macOS) or NVDA (Windows).
- Keyboard-only navigation test: Tab through the entire page.
- Automated: `axe-core` in vitest or `eslint-plugin-jsx-a11y`.

## Anti-Patterns

- `<div onClick>` instead of `<button>` — not keyboard accessible.
- `outline: none` with no replacement — removes focus indicator.
- Placeholder text as the only label — disappears on input.
- `aria-label` on non-interactive elements — confuses screen readers.
- Duplicate landmark regions without labels.

## Related Rules

- For React component patterns, see `.claude/rules/frontend/react.md`.
- For design system defaults and visual identity, see `.claude/rules/design/web-design-guidelines.md`.
