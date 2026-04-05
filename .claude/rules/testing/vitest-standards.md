---
description: "Vitest standards for TypeScript/React testing: RTL, MSW, component testing"
paths: ["**/*.test.ts", "**/*.test.tsx", "**/*.spec.ts", "**/*.spec.tsx"]
---

# Vitest Standards

## Structure

```
src/
├── __tests__/
│   ├── setup.ts                # Global test setup (MSW, RTL config)
│   └── mocks/
│       └── handlers.ts         # MSW request handlers
├── components/
│   └── UserCard/
│       ├── UserCard.tsx
│       └── UserCard.test.tsx   # Co-located component tests
├── hooks/
│   └── useAuth.test.ts         # Hook tests
└── utils/
    └── format.test.ts          # Utility tests
```

## Configuration

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';
export default defineConfig({
  test: {
    environment: 'jsdom',
    setupFiles: ['./src/__tests__/setup.ts'],
    globals: true,
  },
});
```

## React Testing Library

- **Query priority**: `getByRole` > `getByLabelText` > `getByText` > `getByTestId`.
- **User interactions**: `userEvent` over `fireEvent` — simulates real behavior.
- **Async**: use `waitFor` or `findBy*` for async state changes.
- Test what users see and do, not component internals.

```typescript
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

test('submits form with valid data', async () => {
  const user = userEvent.setup();
  render(<LoginForm onSubmit={mockSubmit} />);

  await user.type(screen.getByLabelText('Email'), 'test@example.com');
  await user.click(screen.getByRole('button', { name: 'Sign in' }));

  expect(mockSubmit).toHaveBeenCalledWith({ email: 'test@example.com' });
});
```

## MSW (Mock Service Worker)

- Mock API calls at the network level, not at the fetch level.
- Define handlers in `src/__tests__/mocks/handlers.ts`.
- Override handlers per test for error/edge cases.

## Naming

- `test('<component> <behavior>', ...)` or `describe('<component>')` + `it('<behavior>')`.
- Be specific: "displays error message when API returns 500" > "handles errors".

## Coverage

- Minimum: 80% for new components and hooks.
- Run: `npx vitest run --coverage`.
- Focus on user-facing behavior, not implementation.

## Anti-Patterns

- Testing implementation details (state values, internal methods).
- Snapshot tests as the primary testing strategy.
- Testing third-party library behavior.
- Ignoring accessibility in test queries.

## Related Rules

- This supports Step 3 (Execute TDD). See `.claude/rules/03-execute-tdd.md`.
