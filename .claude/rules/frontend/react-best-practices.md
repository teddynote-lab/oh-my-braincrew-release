---
description: "React best practices checklist: component structure, hooks discipline, state management, accessibility, performance, TypeScript, design system"
paths: ["**/*.tsx", "**/*.jsx"]
---

# React Best Practices Checklist

This is a **mandatory** quality checklist for all React code. The `frontend-engineer` agent MUST verify each applicable section before completing any task.

## Component Structure

- **One component per file** — co-locate helpers only if they are private to that component.
- **Named exports** over default exports for better refactoring and tree-shaking.
- **Props interface** defined inline or co-located, not in a separate `types.ts` unless shared across multiple components.
- **Destructure props** in the function signature: `function Card({ title, children }: CardProps)`.
- **Avoid barrel files** (`index.ts` re-exports) in large projects — they defeat tree-shaking and create circular dependency risk.
- **Keep components under 150 lines**. Extract sub-components or custom hooks when approaching the limit.

## Hooks Discipline

- **Rules of Hooks** — never call hooks conditionally, inside loops, or in nested functions.
- **Custom hooks** — prefix with `use`, extract when logic is reused by two+ components OR when a component's hooks section exceeds ~10 lines.
- **Dependency arrays** — list every value from the component scope that the effect/callback/memo reads. Never suppress the `react-hooks/exhaustive-deps` lint rule.
- **`useCallback` / `useMemo`** — use only when profiling shows a performance issue or when passing callbacks to memoized children. Do not memoize by default.
- **`useEffect` cleanup** — always return a cleanup function for subscriptions, timers, AbortControllers, and event listeners.

## State Management

- **Colocate state** — keep state in the lowest component that needs it. Lift only when siblings share state.
- **Derive, don't sync** — compute values during render instead of syncing with `useEffect` + `useState`.
- **Avoid prop drilling** past 2–3 levels — use React context, composition (children), or a state library.
- **Server state** — use a data-fetching library (SWR, TanStack Query). Never manage server-fetched data in `useState` + `useEffect`.

## Accessibility

- **Semantic HTML first** — use `<button>` for actions, `<a>` for navigation, `<nav>`, `<main>`, `<section>` before reaching for `<div onClick>`.
- **`alt` on every `<img>`** — decorative images get `alt=""`.
- **Keyboard navigation** — interactive elements must be focusable and operable via keyboard (Tab, Enter, Space, Escape).
- **`aria-*` attributes** — only when native semantics are insufficient. Do not redundantly label elements that already have semantic meaning.
- See `.claude/rules/design/accessibility.md` for full WCAG requirements.

## Performance

- **`React.memo()`** — wrap components that receive the same props frequently and are expensive to render. Do not wrap everything by default.
- **Lazy loading** — use `React.lazy()` + `<Suspense>` for route-level code splitting.
- **List keys** — use stable, unique identifiers. Never use array index as key for dynamic or reorderable lists.
- **Avoid inline object/array literals** in JSX props — they create new references every render, defeating memoization.
- **Image optimization** — use appropriate formats (WebP/AVIF), explicit width/height, lazy loading for below-fold images.

## TypeScript Patterns

- **`React.FC` is optional** — prefer plain function declarations with typed props interface.
- **`React.PropsWithChildren<Props>`** — use when a component accepts children but has no other custom props.
- **Event handlers** — type explicitly: `React.MouseEventHandler<HTMLButtonElement>`, `React.ChangeEventHandler<HTMLInputElement>`.
- **Generics for reusable components** — e.g., `function List<T>({ items, renderItem }: ListProps<T>)`.
- **`as const`** for constant arrays and objects that feed into type inference and discriminated unions.

## Design System Consistency

- Prefer shadcn/ui primitives (Button, Dialog, Card, Table, Tabs, Sheet, AlertDialog) over building ad-hoc equivalents when available.
- Reject container soup: no repeated `<div className="rounded-xl border p-6">` blocks — use composition primitives instead.
- Typography consistency: use the project's type scale consistently. Geist Sans for interface text, Geist Mono for code/metrics/IDs.
- See `.claude/rules/design/web-design-guidelines.md` for full design system defaults.

## Related Rules

- For React component standards and project structure, see `.claude/rules/frontend/react.md`.
- For Tailwind CSS usage patterns, see `.claude/rules/frontend/tailwind.md`.
- For design system defaults and visual identity, see `.claude/rules/design/web-design-guidelines.md`.
- For accessibility standards, see `.claude/rules/design/accessibility.md`.
