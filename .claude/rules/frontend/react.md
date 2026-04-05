---
description: "React component standards: hooks, composition, state management, TypeScript patterns"
paths: ["**/*.tsx", "**/*.jsx"]
---

# React Standards

## Component Design

- Functional components only — no class components.
- One component per file for top-level components.
- Co-locate tests, styles, and types with the component.
- Push state down — lift only when two+ siblings need the same data.

## Hooks Rules

- Never call hooks conditionally or inside loops.
- Custom hooks for reusable stateful logic — prefix with `use`.
- `useEffect` cleanup: always return cleanup function for subscriptions, timers, AbortControllers.
- `useMemo` / `useCallback`: only when profiling shows a performance issue, not by default.

## TypeScript

- Define props with `interface` (not `type`) for component props — better error messages.
- Export prop interfaces for reusable components.
- Use `React.FC` sparingly — prefer explicit return type or inference.
- No `any` — use `unknown` and narrow. See `.claude/rules/code-conventions.md` for type safety rules.

## State Management

- Local state (`useState`) for component-scoped data.
- Context for global data needed by many components (theme, auth, locale).
- Avoid prop drilling beyond 2 levels — use context or composition.
- Server state: use a data-fetching library (SWR, TanStack Query) — don't manage in local state.

## Patterns

```tsx
interface UserCardProps {
  user: User;
  onEdit: (id: string) => void;
}

export function UserCard({ user, onEdit }: UserCardProps) {
  return (
    <div className="rounded-lg border p-4">
      <h3 className="text-lg font-medium">{user.name}</h3>
      <button onClick={() => onEdit(user.id)}>Edit</button>
    </div>
  );
}
```

## Error Boundaries

- Wrap major sections in error boundaries.
- Show user-friendly fallback, not stack traces.
- Log errors to monitoring service in `componentDidCatch` equivalent.

## Performance

- Avoid creating new objects/arrays in render (causes unnecessary re-renders of children).
- Use `key` prop correctly — stable, unique identifiers, never array index for dynamic lists.
- Lazy load heavy components: `React.lazy()` + `Suspense`.

## Anti-Patterns

- Direct DOM manipulation (use refs sparingly, never `document.querySelector`).
- Derived state in `useState` — compute during render instead.
- Overusing context for frequently changing values (causes widespread re-renders).
- Ignoring cleanup in effects — leads to memory leaks and stale closures.

## Project Structure

```
src/
├── components/        # Reusable UI components
├── hooks/             # Custom React hooks
├── pages/             # Route-level page components
├── contexts/          # React context providers
├── lib/               # Utilities (cn(), api client)
└── __tests__/         # Test setup and global mocks
```

## React 19 Composition Patterns

### Universal (Vite SPA + Framework)

- `use()` hook: read promises and context inside render. Replaces some `useEffect` + `useState` data-fetching patterns.
- `useOptimistic`: optimistic UI during async operations. Show expected result immediately, reconcile on server response.
- `ref` as a regular prop: no `forwardRef()` wrapper needed in React 19. Pass `ref` directly to function components.
- React Compiler (experimental): automatic memoization — `useMemo`, `useCallback`, and `React.memo` become unnecessary when the compiler is active. Continue manual memoization until the compiler is stable in the project.
- Compound components: group related components under a namespace (`Tabs.Root`, `Tabs.List`, `Tabs.Trigger`, `Tabs.Content`).
- Render slots: accept named children via props for flexible layout customization.
- Children composition: prefer `{children}` props over render props for simple content projection.

### Framework-Required (Next.js, Remix — NOT Vite SPA)

These patterns require a framework with server runtime support. Do not use in Vite SPA projects.

- Server Components: default rendering with zero client JS. Only available with a framework that supports RSC.
- Client Components (`'use client'`): push the directive as far down the tree as possible — only the interactive leaf needs it.
- Server Actions (`'use server'`): mutations from client components. Requires a server runtime to handle the action.
- `useActionState`: form state from Server Actions. Returns `[state, action, isPending]`.
- `useFormStatus`: read submission status of a parent `<form>`. Requires Server Actions.
- Streaming SSR with `<Suspense>`: progressive rendering via `renderToPipeableStream`. Requires a server rendering pipeline.

## Related Rules

- For accessibility requirements, see `.claude/rules/design/accessibility.md`.
- For mandatory quality checklist, see `.claude/rules/frontend/react-best-practices.md`.
- For design system defaults, see `.claude/rules/design/web-design-guidelines.md`.
