# Vite + React SPA — Best Practices (version-pinned)

Layer: `vite-react`. Last verified **2026-10-11**. Claims are tied to fetched sources. Items marked **[rec]** are project recommendations derived from those sources, not statements made by the source. Items marked `NOT SOURCEABLE` were searched for and not found on a fetched page.

## 1. Architecture: static SPA, no Node in production

- Build output is static files. No server-side rendering, no RSC, no framework server functions. This removes the RSC advisory class from production (see breaking-changes §1). [rec]
- Do not add `react-server-dom-*`, `@vitejs/plugin-rsc`, `next`, `waku`, `rwsdk`, or RSC-mode `react-router` to `package.json`. Grep the lockfile in CI:
  `grep -E 'react-server-dom-|plugin-rsc|"next@|waku|rwsdk' pnpm-lock.yaml` must be empty. [rec]
- If a dependency does pull `react-server-dom-*`, it must be `>=19.2.8` on the 19.2 line (`19.1.9` / `19.0.8` on the others). Source: [GHSA-wx67-qw84-cm4g](https://github.com/react/react/security/advisories/GHSA-wx67-qw84-cm4g).

## 2. Authentication token storage

Source: OWASP Session Management Cheat Sheet, read from [raw markdown](https://raw.githubusercontent.com/OWASP/CheatSheetSeries/master/cheatsheets/Session_Management_Cheat_Sheet.md). The `cheatsheetseries.owasp.org` HTML host was blocked for fetch in this session.

- Do not store tokens in web storage. The sheet says: "Do not store authentication tokens, session IDs, JWTs, refresh tokens, or any credential in" `localStorage` / `sessionStorage` (sentence continues).
- Session IDs are exchanged through cookies. Recommended cookie attributes:
  - `HttpOnly`: "mandatory to prevent session ID stealing through XSS attacks."
  - `Secure`: session ID "only exchanged through an encrypted channel."
  - `SameSite=Strict` (preferred) or `SameSite=Lax`. Never `SameSite=None` without `Secure`. SameSite is defense in depth, not a CSRF token replacement.
  - `__Host-` prefix (requires `Secure`, no `Domain`, `Path=/`). Example from sheet: `Set-Cookie: __Host-SessionID=<value>; Secure; HttpOnly; SameSite=Strict; Path=/`.
- Consequence for an SPA: the browser JavaScript never sees the session cookie. The API/auth server sets it with `Set-Cookie`, and the SPA never reads it. [rec] (Fetch-side request options: not sourced in this session.)
- In-memory-only access tokens and refresh-token rotation: **NOT SOURCEABLE from a primary source in this session**. Only secondary blog guidance was found. [rec, unverified]
- Server-side store: the sheet recommends a one-way verifier if read-only store disclosure is in the threat model (summary only; not read in full).

## 3. Content Security Policy for a static SPA

Source: [MDN CSP](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CSP).

- Nonces are "the recommended approach" for `<script>` and `<style>` restriction, but the server must generate a new nonce for every HTTP response. Static HTML generally cannot carry per-response nonces. [rec] For a static host, use hashes or a host-level header that is set per response by the CDN/host config.
- `'strict-dynamic'`: a script with a valid nonce or hash may load further scripts with neither. MDN warns this lowers security, since scripts created from XSS-influenced input are not blocked.
- `default-src` is the fallback for resource types without an explicit directive. `script-src` controls JavaScript.
- Roll out with `Content-Security-Policy-Report-Only` first. MDN: a report-only policy "is not enforced" and "cannot be delivered through a `<meta>` element." Set it as an HTTP header. [rec: keep the enforced header in the host config, not in `index.html`]
- Full directive list for `frame-ancestors`, `connect-src`, `report-to`: **NOT SOURCEABLE** (not read).

## 4. Trusted Types

Sources: [MDN Trusted Types API](https://developer.mozilla.org/en-US/docs/Web/API/Trusted_Types_API), [React 19.3](https://react.dev/blog/2026/09/09/react-19-3).

- Enforce with CSP directives `require-trusted-types-for 'script'` and `trusted-types <policy-names>`. The default policy name is `default`.
- MDN lists Trusted Types as Baseline 2026 ("Since February 2026... latest devices and browser versions").
- React 19.3 integrates with the browser Trusted Types API. React no longer coerces values to strings before DOM calls, so policies apply.
- [rec] Keep the `trusted-types` allowlist minimal (one app policy plus `default` only if needed). Do not use `'allow-duplicates'` unless required; its meaning is not verified in this session (**NOT SOURCEABLE**).
- Any `dangerouslySetInnerHTML` path needs a policy that sanitizes first. Sanitizer choice: **NOT SOURCEABLE** in this session.

## 5. TypeScript 7 adoption

Source: [TS 7.0 announcement](https://devblogs.microsoft.com/typescript/announcing-typescript-7-0/).

- TS 7.0 ships **without a programmatic API** (expected in 7.1). Any tool that imports the `typescript` compiler API (typescript-eslint, codegen, editor plugins) cannot be assumed to work on 7.0.2. [rec] Confirm each tool, or pin `typescript@6.0.3` until 7.1 and the tools are confirmed.
- Side-by-side 6.x: install `@typescript/typescript6` and run its `tsc6` binary. Source: same post.
- Nightly: `typescript@next` (post). Do not pin nightly in production. [rec]
- Recommended tsconfig for TS 7: remove `target: es5`, `downlevelIteration`, `baseUrl`, `moduleResolution: node|node10|classic`, and AMD/UMD/SystemJS module outputs (all removed in 7.0). Set `types` explicitly because the default is now `[]`.

## 6. Vite 8 build

Source: [Vite 8 blog](https://vite.dev/blog/announcing-vite8), [Vite releases](https://vite.dev/releases).

- Node: 20.19+ or 22.12+. Set the CI and local runtime accordingly. [rec: use Node 24 LTS, see §10]
- Migration path for large projects: the blog advises switching to `rolldown-vite` on Vite 7 first, then upgrading to Vite 8. Check build output after the esbuild/`rollupOptions` compat layer.
- `@vitejs/plugin-react` v6 removes Babel as a dependency; v5 still works with Vite 8 (Vite 8 post). Exact plugin-react version pairing: **NOT SOURCEABLE** (npm dist-tags not fetched).
- `build.target` default: `'baseline-widely-available'` (since Vite 7). Set explicitly if you must support older browsers. Source: [Vite 7 blog](https://vite.dev/blog/announcing-vite7).
- Support: pin to `8.3` patch line for regular fixes. Source: Vite releases page.

## 7. TanStack Router and Query

- Router package: `@tanstack/react-router` (npm `latest` 1.170.42). Vite plugin package: `@tanstack/router-plugin` (npm `latest` 1.168.43). Route-generation API: **NOT SOURCEABLE** (overview page only says "generated for you either by the Vite plugin or TanStack Router CLI").
- SPA mode of TanStack Router: **NOT SOURCEABLE** (overview page does not address SPA use).
- Query v5 patterns (from [migration guide](https://tanstack.com/query/latest/docs/framework/react/guides/migrating-to-v5)):
  - Object-form calls only: `useQuery({ queryKey, queryFn })`.
  - Use `isPending` for first load; `isLoading` now means pending and fetching.
  - Use `gcTime`, not `cacheTime`.
  - Do not use query-level `onSuccess`/`onError`/`onSettled`. Use `useEffect` or mutation callbacks.
  - Use `throwOnError` (not `useErrorBoundary`).
  - Infinite queries must pass `initialPageParam` and `getNextPageParam`.

## 8. Testing

### Vitest 5
- Requires Node 22 and Vite 6.4 (as stated in release notes). Source: [v5.0.0](https://github.com/vitest-dev/vitest/releases/tag/v5.0.0). Vite 8 compatibility with that requirement: not stated. [rec: run the test suite in CI on the pinned Vite to confirm]
- Use `concurrent` in place of `sequential` (removed).

### Playwright 1.64.0
- Install: `pnpm install --save-dev @playwright/test@latest`, then `pnpm exec playwright install --with-deps`. Source: [Playwright intro](https://playwright.dev/docs/intro).
- Node: "latest 22.x, 24.x or 26.x" per intro page.
- Test environment: `window.screen` reflects device descriptors. Hidden-iframe elements count as hidden for `toBeVisible()`. Source: 1.64 release.
- Browsers bundled with 1.64.0: Chromium 156.0.8078.4, Firefox 157.0, WebKit 27.2. [rec] Pin the Playwright version so visual baselines stay stable.

## 9. ESLint 10 flat config

Sources: [ESLint v10.0.0 release](https://eslint.org/blog/2026/02/eslint-v10.0.0-released/), raw [configuration-files.md](https://raw.githubusercontent.com/eslint/eslint/main/docs/src/use/configure/configuration-files.md).

- Use `eslint.config.js`, `.mjs`, `.cjs`, `.ts`, `.mts`, or `.cts` at the project root. Discovery runs from each linted file's folder upward (v10).
- The file "export[s] an array of configuration objects." Each object sets rules, plugins, and file patterns.
- Do not create `.eslintrc.*` or `.eslintignore`. They are ignored in v10.
- Node: 20.19.0+, 22.13.0+, or 24+.
- Current: eslint 10.12.0. Maintenance line 9.39.5 (npm dist-tags).
- Plugin-specific config shapes (typescript-eslint, react-hooks): **NOT SOURCEABLE** — typescript-eslint dist-tags fetched (`latest` 8.71.1), per-package docs not read.

## 10. Node.js and CI runtime

Source: [nodejs.org previous releases](https://nodejs.org/en/about/previous-releases).

- Current line v26 (not LTS). LTS: v24 ("Latest LTS", v24.21.0). v22 LTS also listed.
- Minimums across the stack: Vite 8 (20.19+/22.12+), ESLint 10 (20.19+/22.13+/24+), Vitest 5 (22+), pnpm 11 (22+), Playwright (22.x/24.x/26.x per intro).
- [rec] Pin CI and developer `.nvmrc` to Node 24 LTS: satisfies every minimum above and avoids the non-LTS v26 line. Confirm the v22 end-of-life date before dropping v22: NOT SOURCEABLE with confidence (column ambiguous on fetched page).

## 11. pnpm supply-chain hardening

Sources: [pnpm supply-chain security](https://pnpm.io/supply-chain-security), [pnpm settings](https://pnpm.io/settings), [pnpm 11.0](https://pnpm.io/blog/releases/11.0), [pnpm 11.3](https://pnpm.io/blog/releases/11.3).

Setting names are verified against the pnpm.io settings page and release notes. Settings live in `pnpm-workspace.yaml`. The settings page states: "Only auth and registry settings are read from `.npmrc` files."

```yaml
# pnpm-workspace.yaml — verified keys
minimumReleaseAge: 1440          # minutes; default 1440 in pnpm 11; 0 opts out; 10080 = one week (pnpm.io)
minimumReleaseAgeStrict: false   # default false (pnpm 11.0)
minimumReleaseAgeExclude: []     # exists (pnpm.io settings list); add exceptions only with a reason
trustPolicy: no-downgrade        # recommended by pnpm.io supply-chain page
trustLockfile: false             # default false (pnpm 11.3); true skips lockfile re-verification
blockExoticSubdeps: true         # recommended by pnpm.io supply-chain page
strictDepBuilds: true            # default true (pnpm 11.0)
allowBuilds:                     # map: package name -> boolean. Replaces onlyBuiltDependencies (removed in 11.0)
  esbuild: true                  # [rec] allowlist only packages that truly need install scripts
```

- `minimumReleaseAgeIgnoreMissingTime`: exists on the settings page. Default `true` per secondary coverage only; official default not stated on the fetched 11.0 page.
- `ignoreScripts`, `dangerouslyAllowAllBuilds`, `verifyDepsBeforeRun`: names listed on the pnpm.io settings page; behavior and defaults not described there. Do not enable `dangerouslyAllowAllBuilds`. [rec]
- The pnpm.io supply-chain page recommends "explicitly listing only trusted dependencies" for `allowBuilds`.
- Unknown keys in `pnpm-workspace.yaml` are a hard error on pnpm 12 when a matching pnpm version is pinned (catches typos such as `minimumReleaseage`). Source: pnpm 12.0.
- Known bypass report: GHSA-379q-355j-w6rj reports that git dependencies can still run `prepare`, `prepublish`, and `prepack` during fetch under pnpm 10. Current status: **NOT SOURCEABLE** — advisory listed in search, not fetched.
- pnpm 10 behavior: dependency lifecycle scripts blocked by default unless allowlisted. Source: secondary (pnpm discussion and articles). The official pnpm 10 blog returned 404 at fetch.

### pnpm version for this project
- Latest on npm: 12.11.2 (`latest` and `latest-12`). Install with `pnpm self-update latest-12` (pnpm 12.0 post).
- Local install today: 11.28.5 (`next-11` tag). Upgrade before pinning `packageManager` in `package.json`. [rec]

## 12. Dev hygiene checklist [rec]

1. `packageManager` field pins pnpm; CI fails on mismatch.
2. Lockfile committed; CI runs `pnpm install --frozen-lockfile`. In pnpm 12, the flag form is `--frozen-lockfile` (bare) and `--no-frozen-lockfile` to disable. Source: pnpm 12.0.
3. `pnpm audit` in CI. pnpm 11 renamed `auditConfig.ignoreCves` to `auditConfig.ignoreGhsas` (GHSA IDs replace CVE IDs). Source: pnpm 11.0.
4. `minimumReleaseAge` active so brand-new malicious versions are not resolved for 24 hours.
5. Build output inspected for CSP compatibility: no inline scripts unless hashed.
6. Visual verification: Playwright screenshot per changed screen, retained as evidence. [rec]
