---
description: "Tailwind CSS standards: utility usage, theming, responsive design, dark mode"
paths: ["**/tailwind.config.*", "**/*.tsx", "**/*.css"]
---

# Tailwind CSS Standards

## Usage

- Use utility classes directly — avoid `@apply` except for base element styles.
- Use `cn()` helper (clsx + tailwind-merge) for conditional classes.
- Responsive: mobile-first (`sm:`, `md:`, `lg:`) — default styles are for mobile.

```tsx
import { cn } from '@/lib/utils';

function Button({ variant, className, ...props }: ButtonProps) {
  return (
    <button
      className={cn(
        'rounded-md px-4 py-2 font-medium transition-colors',
        variant === 'primary' && 'bg-blue-600 text-white hover:bg-blue-700',
        variant === 'secondary' && 'bg-gray-200 text-gray-900 hover:bg-gray-300',
        className,
      )}
      {...props}
    />
  );
}
```

## Theming

- Use CSS variables for colors that change with theme (dark mode).
- Define design tokens in `tailwind.config.ts` `extend` section.
- Dark mode via `class` strategy (not `media`) for user toggle support.

## Class Ordering

Follow consistent ordering: layout → sizing → spacing → typography → colors → effects → states.

Example: `flex items-center gap-2 w-full p-4 text-sm text-gray-700 bg-white rounded-lg shadow hover:bg-gray-50`.

## Responsive Design

- Mobile-first: write base styles for mobile, add breakpoint prefixes for larger screens.
- Common breakpoints: `sm` (640px), `md` (768px), `lg` (1024px), `xl` (1280px).
- Test at each breakpoint — don't assume intermediate sizes work.

## Anti-Patterns

- Overly long class strings without `cn()` for variants.
- Using `@apply` for complex component styles (defeats Tailwind's purpose).
- Hardcoded pixel values instead of Tailwind spacing scale.
- Mixing Tailwind with inline `style` props (except for truly dynamic values).
