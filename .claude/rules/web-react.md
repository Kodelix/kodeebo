---
paths:
  - "web/**/*.ts"
  - "web/**/*.tsx"
  - "web/**/*.css"
  - "web/package.json"
---

# Web App Rules (Vite + React SPA)

The SPA is static files only. All authority — auth, authz, pricing, limits — lives in the backend.

- **Design**: every new or changed screen goes through `/impeccable` (`craft` for new, `audit` + `polish` before Done). Tokens from the design system; no ad-hoc colors, spacing or fonts.
- **Structure**: `src/features/<feature>/{ui,model,api}`, `src/shared/`; features never import each other's internals.
- **Data**: server state via TanStack Query with typed query keys and explicit `staleTime`; mutations invalidate exactly what they change. No `fetch` in components — use the generated client from `contracts/`.
- **Routing**: TanStack Router with typed routes and route-level code splitting; loaders prefetch, they do not authorize.
- **TypeScript**: `strict` on, no `any` (use `unknown` + narrowing), no non-null `!` without a comment.
- **Security**: no tokens in `localStorage`/`sessionStorage`; cookies are `HttpOnly`. No `dangerouslySetInnerHTML` without a vetted sanitizer and review. No secrets in env vars bundled into the client (`VITE_*` is public). CSP-compatible: no inline scripts/styles, no `eval`.
- **Accessibility**: WCAG level from `accessibility.target`; semantic HTML first, labelled controls, focus management on route change and dialogs, keyboard paths tested.
- **i18n**: no hardcoded user-facing strings; Arabic + English with RTL via logical CSS properties (`margin-inline-start`, not `margin-left`).
- **Performance**: route chunks within the budget; images sized and lazy; lists virtualized past ~100 rows; no layout shift from late-loading content.
- **Dependencies**: added only via `pnpm add` with a reason in the PR. `pnpm-workspace.yaml` keeps the verified supply-chain settings (`strictDepBuilds`, explicit `allowBuilds`, `minimumReleaseAge`, `trustPolicy: no-downgrade`, `blockExoticSubdeps`) — see `docs/stack-reference/vite-react/best-practices.md` §11. No `react-server-dom-*` in the lockfile.
- **Toolchain**: `packageManager` pins pnpm; CI runs the even-numbered Node LTS from `docs/stack-reference/pins.yaml`.
- **Tests**: Vitest + Testing Library for components and hooks; Playwright for journeys, with screenshots retained as evidence.
