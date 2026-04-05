---
description: "Vite build configuration standards: plugins, env, aliases, optimization"
paths: ["**/vite.config.*"]
---

# Vite Standards

## Configuration

```typescript
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: { '@': path.resolve(__dirname, './src') },
  },
  server: {
    port: 3000,
    proxy: {
      '/api': { target: 'http://localhost:8000', changeOrigin: true },
    },
  },
});
```

## Environment Variables

- Prefix client-side vars with `VITE_` — only these are exposed to the browser.
- Server-side secrets MUST NOT use the `VITE_` prefix.
- Access via `import.meta.env.VITE_API_URL`.
- Validate required env vars at build time.

## Path Aliases

- Use `@/` alias for `src/` to avoid deep relative imports.
- Configure in both `vite.config.ts` and `tsconfig.json` (paths).

## Build Optimization

- Enable code splitting: dynamic `import()` for route-level components.
- Analyze bundle size: `npx vite-bundle-visualizer`.
- Externalize large dependencies that are served via CDN (if applicable).

## Dev Server

- Proxy API calls to backend to avoid CORS in development.
- HMR should work out of the box — if it doesn't, check for side effects in modules.

## Anti-Patterns

- Importing large libraries without tree-shaking awareness.
- Hardcoding API URLs instead of using env vars.
- Circular dependencies between modules (Vite will warn).
