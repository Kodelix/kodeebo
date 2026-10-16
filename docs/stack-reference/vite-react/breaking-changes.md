# Vite + React SPA — Breaking Changes (version-pinned)

Layer: `vite-react`. Last verified **2026-10-11**. Every item was read from a fetched page this session unless marked **[secondary]** (search-result summary, not the primary page) or `NOT SOURCEABLE`. Version pins live in `VERSION.md`.

## 1. Security advisories that change pins

### React Server Components packages (`react-server-dom-webpack`, `-parcel`, `-turbopack`)

A pure SPA with no RSC packages is **not affected** (react.dev advisory: apps without a server or without an RSC-capable framework/bundler/plugin are not affected). Any RSC-capable tool pulled in transitively (`next`, `react-router` RSC, `waku`, `@vitejs/plugin-rsc`, `rwsdk`, `@parcel/rsc`) makes the app affected. Source: [react.dev Dec 11 2025](https://react.dev/blog/2025/12/11/denial-of-service-and-source-code-exposure-in-react-server-components), GitHub advisories below.

| CVE / GHSA | Date (published) | Severity | Affected range (all three packages) | Patched |
|---|---|---|---|---|
| CVE-2025-55182 (React2Shell, unauthenticated RCE via Server Function endpoints) | 2025-12-03 | CVSS 10.0 | 19.0, 19.1.0, 19.1.1, 19.2.0 (Dec 3 post) | 19.0.1 / 19.1.2 / 19.2.1 — **superseded** |
| CVE-2025-55184, CVE-2025-67779 (DoS) | 2025-12-11 | 7.5 | 19.0.x–19.2.2 range per secondary sources | 19.0.3 / 19.1.4 / 19.2.3 were **incomplete** per React |
| CVE-2025-55183 (source code exposure) | 2025-12-11 | 5.3 | same family | same family |
| CVE-2026-23864 (DoS, incomplete earlier fixes) | 2026-01-26 | 7.5 | per React post | 19.0.4 / 19.1.5 / 19.2.4 |
| CVE-2026-23869 — [GHSA-479c-33wc-g2pg](https://github.com/react/react/security/advisories/GHSA-479c-33wc-g2pg) | 2026-04-08 | 7.5 (CWE-400, CWE-502) | 19.0.0–19.0.4; 19.1.0–19.1.5; 19.2.0–19.2.4 | 19.0.5 / 19.1.6 / 19.2.5 |
| CVE-2026-23870 — [GitLab DB](https://advisories.gitlab.com/npm/react-server-dom-webpack/CVE-2026-23870/) | 2026-05-11 | 7.5 (CWE-400, CWE-770) | 19.0.0–19.0.5; 19.1.0–19.1.6; 19.2.0–19.2.5 | 19.0.6 / 19.1.7 / 19.2.6 |
| **CVE-2026-44907 — [GHSA-wx67-qw84-cm4g](https://github.com/react/react/security/advisories/GHSA-wx67-qw84-cm4g)** | **2026-07-21** | **7.5** (CWE-400, CWE-770) | 19.0.0–19.0.7; 19.1.0–19.1.8; 19.2.0–19.2.7 | **19.0.8 / 19.1.9 / 19.2.8** (current minimum) |

Rule for this stack: if any `react-server-dom-*` package is in `pnpm-lock.yaml`, it must be `>=19.2.8` (or 19.1.9 / 19.0.8 on those lines). npm audit reportedly flags 19.2.0–19.2.7 for CVE-2026-44907 [secondary: GitHub issue summary].

Note: `react` and `react-dom` 19.3.0 are not in any advisory's affected list fetched.

### Other security-relevant changes

- **React 19.3 Trusted Types integration** ([react.dev 19.3](https://react.dev/blog/2026/09/09/react-19-3)): React previously coerced values with `'' + value` before DOM calls, turning Trusted Types objects into strings the browser rejects. React 19.3 passes them through uncoerced. Effect: under `require-trusted-types-for 'script'`, React's DOM sinks now honor your policies. Raw strings are still rejected.
- **pnpm supply-chain defaults** (pnpm 11 and later) — see section 4.

## 2. React

### React 19.3.0 (2026-09-09)
Source: [react.dev/blog/2026/09/09/react-19-3](https://react.dev/blog/2026/09/09/react-19-3) (changelog items read from the post's linked changelog summary).

- Stable: `<ViewTransition>` and Fragment Refs (`FragmentInstance`).
- Behavior changes (no opt-in):
  - Effects are double-invoked in Strict Mode during hydration, matching client-rendered roots.
  - `defaultValue` for `type="number"` inputs now matches other input types.
  - Updates from `resize` events are batched until the next frame.
  - Transitions render independently instead of being entangled into a single render.
  - "Form state" renamed to "action state" in `useActionState` error messages.
- The post labels no breaking changes or deprecations.
- Server Components can render `<Context>` directly, without an extra Provider wrapper (RSC only; not relevant to SPA).
- `browser()` from `react-dom` (use via `use(browser())`) opts a component out of server rendering.

### React 19.2 (2025-10-01) — prior minor
Adds Activity, `useEffectEvent`, React Performance Tracks [react.dev blog list, title and date only].

## 3. Vite

### Vite 8 (blog 2026-03-12) — current major, 8.3.4 (2026-10-08)
Source: [vite.dev/blog/announcing-vite8](https://vite.dev/blog/announcing-vite8).

- **Bundler replaced**: Rolldown is the single bundler; Oxc is the compiler. Rolldown replaces the esbuild and Rollup pipelines.
- **Config compatibility layer**: converts existing esbuild and `rollupOptions` config to Rolldown/Oxc equivalents. Not a guarantee of identical output — check build artifacts.
- `lightningcss` becomes a regular dependency (was optional peer).
- `@vitejs/plugin-react` **v6** removes Babel as a dependency. v5 still works with Vite 8.
- Install size grows by about 15 MB over Vite 7.
- **Node.js**: Vite 8 requires **Node.js 20.19+ or 22.12+**, "the same requirements as Vite 7".
- Migration: the blog recommends the guide at `vite.dev/guide/migration`. For complex projects it suggests first switching to the `rolldown-vite` package on Vite 7, then upgrading to Vite 8.

### Vite 7 (blog 2025-06-24) — still relevant when upgrading from 6
Source: [vite.dev/blog/announcing-vite7](https://vite.dev/blog/announcing-vite7).

- Node 18 dropped.
- `build.target` default changed from `'modules'` to `'baseline-widely-available'` (Chrome 87→107, Edge 88→107, Firefox 78→104, Safari 14.0→16.0).
- Sass legacy API support removed.
- `splitVendorChunkPlugin` removed.
- New `buildApp` hook (Environment API, experimental).

## 4. pnpm

### pnpm 11.0 (line introduced 2026; release date not stated on the page)
Source: [pnpm.io/blog/releases/11.0](https://pnpm.io/blog/releases/11.0).

**Removed** (use the replacement):
- `onlyBuiltDependencies`, `onlyBuiltDependenciesFile`, `neverBuiltDependencies`, `ignoredBuiltDependencies`, `ignoreDepScripts` → **`allowBuilds`** (map: package pattern → boolean).
- `allowNonAppliedPatches` → `allowUnusedPatches`.
- `ignorePatchFailures` removed; patch failures now throw.
- `auditConfig.ignoreCves` → `auditConfig.ignoreGhsas`.
- `useNodeVersion`, `executionEnv.nodeVersion` → `devEngines.runtime` or `engines.runtime`.
- `managePackageManagerVersions`, `packageManagerStrict`, `packageManagerStrictVersion` → `pmOnFail` (`download`/`ignore`/`warn`/`error`).
- `COREPACK_ENABLE_STRICT=0` → `pmOnFail: warn`.
- `.npmrc` `@scope:registry=` lines → `registries` in `pnpm-workspace.yaml`.
- Per-project `.npmrc` → `packageConfigs` in `pnpm-workspace.yaml`.
- `npm_config_*` env vars → `pnpm_config_*`. `NPM_CONFIG_OTP` → `PNPM_CONFIG_OTP`.
- `pnpm server` removed. `pnpm link` (no args) removed; `pnpm link --global` → `pnpm add -g .`.
- `pnpm env use` deprecated → `pnpm runtime set`.
- Commands now throw "not implemented": `access`, `bugs`, `edit`, `issues`, `owner`, `prefix`, `profile`, `pkg`, `repo`, `set-script`, `team`, `token`, `xmas`.
- The `pnpm` field in `package.json` is no longer read.

**Changed defaults**:
- `strictDepBuilds`: `true`.
- `minimumReleaseAge`: `1440` (minutes; 1 day).
- `minimumReleaseAgeStrict`: `false`.

**Requirements and format**:
- Node.js **22 or newer**. Node 18–21 dropped. Standalone binary needs glibc 2.27+.
- Store v11: JSON-per-package index replaced by SQLite at `$STORE/index.db`; hex digests instead of full integrity strings.
- Lockfile: config-dependency hashes moved from `pnpm-workspace.yaml` into `pnpm-lock.yaml`; old inline hashes migrated automatically.

**[secondary]** Lifecycle scripts for dependencies: official 11.0 page does not state the default; secondary coverage says they are blocked unless allowlisted.

### pnpm 11.3 — `trustLockfile`
Source: [pnpm.io/blog/releases/11.3](https://pnpm.io/blog/releases/11.3). New key `trustLockfile` (default `false`). When `false`, `pnpm install` re-applies `minimumReleaseAge` and `trustPolicy: 'no-downgrade'` checks to every lockfile entry. `true` skips that pass.

### pnpm 11.11–11.14 — `versioning` key, allowBuilds URL matching
Source: [pnpm.io/blog/releases/11.11-11.14](https://pnpm.io/blog/releases/11.11-11.14). New `versioning` block in `pnpm-workspace.yaml` (`changelog.storage` default `registry`). `allowBuilds` git entries can match by repository URL without pinning a commit. Security fixes: scoped-name path traversal fixed in `pnpm install`; crafted lockfile traversal rejected; `pnpm self-update` honors `trustPolicy=no-downgrade`.

### pnpm 12.0 (2026-08-26)
Source: [pnpm.io/blog/releases/12.0](https://pnpm.io/blog/releases/12.0), [GitHub v12.0.0](https://github.com/pnpm/pnpm/releases/tag/v12.0.0).

- `pnpm install --frozen-lockfile false` no longer supported. Use `--no-frozen-lockfile`. `--frozen-lockfile` with no value enables it.
- Git dependencies on GitHub/GitLab/Bitbucket resolve to HTTPS URLs; lockfile never records SSH URLs for those hosts.
- Unknown keys in `pnpm-workspace.yaml` are reported with typo suggestions. If a satisfying pnpm version is pinned, the command fails with `ERR_PNPM_UNRECOGNIZED_WORKSPACE_SETTINGS`; otherwise a warning.
- Cyclic-dependency lockfiles: one-time lockfile diff on first re-resolving install.
- `packageImportMethod: auto` on Linux tries hardlinks before reflinks/clones.
- `engineStrict` now applies to regular `dependencies` edges inside `optionalDependencies` subtrees.
- `pnpm add yarn` records the project's package manager instead of installing the npm `yarn` package. `pnpm add -g yarn` installs Yarn current line, not Classic.
- `sudo` with `pnpm setup`, `self-update`, or global changes fails with `ERR_PNPM_SUDO_NOT_SUPPORTED`.
- `filterLog` pnpmfile hook deprecated.
- `pnpm init` pins the latest pnpm version, not the running one.

Node minimum for pnpm 12: **NOT SOURCEABLE** from the 12.0 post. npm registry `engines` field reads `>=18.*`.

## 5. TypeScript

### TypeScript 7.0 (announced 2026-07-08; GitHub Latest 7.0.2 on 2026-08-20)
Source: [devblogs.microsoft.com/typescript/announcing-typescript-7-0](https://devblogs.microsoft.com/typescript/announcing-typescript-7-0/).

- Native port written in Go, described as "a 10x faster native port of TypeScript".
- **Ships without a programmatic API** (expected in 7.1). Tools that call the compiler API (linters, codegen, editor plugins) cannot run against 7.0 until 7.1 or their own migration.
- Removed options and behaviors (now errors):
  1. `target: es5`
  2. `downlevelIteration`
  3. `moduleResolution: node` and `node10`
  4. `moduleResolution: classic`
  5. `baseUrl`
  6. `module: amd, umd, systemjs, none`
  7. `alwaysStrict: false`
  8. `types` now defaults to `[]`
- Distribution: npm `typescript`. Nightly builds on `typescript@next`. TS 6.x side by side via `@typescript/typescript6`, which provides a `tsc6` executable.
- TypeScript 6.x end-of-support: **NOT SOURCEABLE** (post searched; none stated).

### TypeScript 6.0 hard errors (cited in the 7.0 post)
Source: same post. `esModuleInterop` and `allowSyntheticDefaultImports` cannot be `false`. Import `asserts` must use `with`. `baseUrl` (see 7.0 list).

## 6. TanStack Query v5 (applies to `@tanstack/react-query` 5.104.1)
Source: [TanStack Query v5 migration](https://tanstack.com/query/latest/docs/framework/react/guides/migrating-to-v5).

1. `useQuery`, `useMutation`, `useIsFetching`, and many `queryClient`/`queryCache` methods accept only object signatures; positional keys removed.
2. Status `loading` → `pending`. `isLoading` → `isPending`. New `isLoading` = `isPending && isFetching`. `isInitialLoading` deprecated.
3. `cacheTime` → `gcTime`.
4. `onSuccess`, `onError`, `onSettled` removed from queries and `QueryObserver` (mutations unaffected).
5. `getQueryData` and `getQueryState` accept only a `queryKey`. `hashQueryKey` → `hashKey`.
6. `suspense` experimental flag removed; `useSuspenseQuery`, `useSuspenseInfiniteQuery`, `useSuspenseQueries` added; data no longer typed `undefined`.
7. `useErrorBoundary` → `throwOnError`.
8. Infinite queries require explicit `initialPageParam` and `getNextPageParam`.

## 7. TanStack Router

Router API breaking changes for 1.170.x: **NOT SOURCEABLE** — the overview page fetched (`tanstack.com/router/latest/docs/framework/react/overview`) describes features only. Package names confirmed on npm: `@tanstack/react-router` (latest 1.170.42), `@tanstack/router-plugin` (latest 1.168.43).

## 8. Vitest 5

### Vitest 5.0.0 (2026-09-03)
Source: [GitHub v5.0.0](https://github.com/vitest-dev/vitest/releases/tag/v5.0.0).

- Requires **Node.js 22** and **Vite 6.4** (as stated in the release body).
- Breaking changes (first 8 in release order; list is longer):
  1. Replace `loupe.inspect` with pretty-format.
  2. Remove quotes from string values in `test.for`/`each` title `$` variable.
  3. `attachmentsDir` default changed from `.vitest-attachements/` to `.vitest/attachments/`.
  4. `sequential` test/suite options removed in favor of `concurrent`.
  5. Locator represented as an object instead of a string.
  6. Inline `expect` package.
  7. Remove deprecated entry points.
  8. Require Node.js 22 and Vite 6.4.

## 9. Playwright 1.64.0 (2026-10-07, year inferred)
Source: [GitHub v1.64.0](https://github.com/microsoft/playwright/releases/tag/v1.64.0).

- `screen` property forwarded from device descriptors, so `window.screen` and media queries see the emulated size. Set `screen` to `undefined` to opt out.
- JSX in test files follows `tsconfig.json` JSX options.
- `--update-snapshots=missing` now passes the run; the default mode is renamed `'default'`.
- Elements inside hidden iframes count as hidden for actions, `isVisible()`, and `toBeVisible()`.
- Node minimum for 1.64: **NOT SOURCEABLE** (release body states none; [intro page](https://playwright.dev/docs/intro) says "latest 22.x, 24.x or 26.x").

## 10. ESLint 10

### ESLint 10.0.0 (released 2026-02; GitHub Latest 10.12.0 on 2026-10-02)
Source: [eslint.org/blog/2026/02/eslint-v10.0.0-released](https://eslint.org/blog/2026/02/eslint-v10.0.0-released/); raw [migrate-to-10.0.0.md](https://raw.githubusercontent.com/eslint/eslint/main/docs/src/use/migrate-to-10.0.0.md).

- **eslintrc removed**: "Starting with ESLint v10.0.0, the old configuration format is no longer supported." `.eslintrc.*` and `.eslintignore` are ignored.
- **Node.js**: v20.19.0+, v22.13.0+, v24+. Node 21.x, 23.x and older 20/22 patches dropped.
- Config lookup: flat config file searched from each linted file's folder upward (replaces the CWD-based approach that was previously behind a flag).
- **[secondary, search summary — verify on eslint.org]** `ESLINT_USE_FLAT_CONFIG` no longer honored; CLI flags `--no-eslintrc`, `--env`, `--resolve-plugins-relative-to`, `--rulesdir`, `--ignore-path` removed; `/* eslint-env */` comments error; `Linter` accepts only flat config; `defineRule()` and `getRules()` removed.

## NOT SOURCEABLE in this session

- Vite 8 plugin-react version pairing beyond the v6 Babel note.
- React 19.x support window for older lines.
- typescript-eslint release dates and TS 7 compatibility statement.
- Vitest and Playwright support windows.
- Full ESLint 10 migration item list from the primary eslint.org page (eslint.org fetch failed; the raw migrate file fetch returned only the items above).
