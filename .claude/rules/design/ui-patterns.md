---
description: "UI design patterns: layout composition, component hierarchy, loading/error/empty states"
paths: ["**/*.tsx", "**/*.jsx", "**/*.css"]
---

# UI Patterns

## Layout Composition

- Use consistent layout shells: sidebar + main content area.
- Page structure: header → content → footer (each as separate components).
- Use CSS Grid for page-level layout, Flexbox for component-level alignment.

## Component Hierarchy

- **Page**: top-level route component. Fetches data, composes sections.
- **Section**: logical grouping (e.g., UserList, ActivityFeed). Receives data as props.
- **Widget**: reusable UI unit (e.g., Card, Table, Modal). Pure presentation.
- **Primitive**: atomic elements (Button, Input, Badge). No business logic.

## States

Every data-driven component MUST handle all four states:

| State | What to Show |
|-------|-------------|
| Loading | Skeleton or spinner — match the shape of the content |
| Empty | Helpful message + action (e.g., "No users yet. Invite your team.") |
| Error | User-friendly message + retry action. Never raw error strings. |
| Success | The actual content |

## Forms

- Label every input (visible label or `aria-label`).
- Validate on blur, show errors inline below the field.
- Disable submit button while submitting — show loading state.
- Show success/error feedback after submission.

## Modals and Dialogs

- Use for confirmations and focused tasks — not for navigation.
- Trap focus inside the modal when open.
- Close on Escape key and backdrop click.
- Destructive actions require explicit confirmation (AlertDialog pattern).

## Responsive

- Design mobile-first, enhance for larger screens.
- Side navigation → bottom tabs or hamburger on mobile.
- Tables → card lists on small screens.
- Test at 320px (minimum), 768px (tablet), 1280px (desktop).

## Color and Typography

- Use design tokens (Tailwind theme) — not hardcoded hex values.
- Sufficient contrast (WCAG AA minimum: 4.5:1 for text).
- Consistent type scale — don't invent sizes.
