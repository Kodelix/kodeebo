# Vite + React SPA — Deprecated and Removed APIs

Layer: `vite-react`. Last verified **2026-10-11**. Each row cites a fetched source. **[secondary]** = from a search-result summary, not the primary page. Do not reintroduce these names. Use the replacement column.

## TypeScript

| Removed / deprecated | Status | Replacement | Source |
|---|---|---|---|
| `target: "es5"` | Removed in TS 7.0 (now error) | ES2015+ target | [TS 7.0 post](https://devblogs.microsoft.com/typescript/announcing-typescript-7-0/) |
| `downlevelIteration` | Removed in TS 7.0 | Not needed on modern targets | same |
| `moduleResolution: "node"` / `"node10"` | Removed in TS 7.0 | `"bundler"` or `"nodenext"` (names not verified in this session; check TS docs) | same |
| `moduleResolution: "classic"` | Removed in TS 7.0 | Module resolution per module kind | same |
| `baseUrl` | Removed in TS 7.0; hard error since 6.0 | `paths` with explicit base, or relative imports | same |
| `module: "amd" \| "umd" \| "systemjs" \| "none"` | Removed in TS 7.0 | ESM | same |
| `alwaysStrict: false` | Now error in TS 7.0 | `true` (or remove) | same |
| `types` default | Changed to `[]` in TS 7.0 | Set `types` explicitly | same |
| `esModuleInterop: false`, `allowSyntheticDefaultImports: false` | Hard error in TS 6.0 | Keep `true` | same |
| `import ... assert {}` | Must use `with` in TS 6.0 | `import ... with {}` | same |
| TypeScript programmatic API | Not present in TS 7.0 (expected 7.1) | Pin 6.0.3 for tools that need it; `@typescript/typescript6` for `tsc6` | same |

## Vite

| Removed / deprecated | Version | Replacement | Source |
|---|---|---|---|
| Node 18 support | Vite 7 | Node 20.19+ or 22.12+ | [Vite 7 blog](https://vite.dev/blog/announcing-vite7) |
| `build.target: 'modules'` (as default) | Default changed in Vite 7 | `'baseline-widely-available'` (default) or set explicitly | same |
| Sass legacy API | Removed in Vite 7 | Sass modern API | same |
| `splitVendorChunkPlugin` | Removed in Vite 7 | Manual `build.rollupOptions` / Rolldown equivalent (not sourced) | same |
| esbuild and Rollup pipeline config | Replaced in Vite 8 by Rolldown + Oxc; compat layer converts `esbuild` and `rollupOptions` | Verify build output after migration | [Vite 8 blog](https://vite.dev/blog/announcing-vite8) |
| `lightningcss` as optional peer | Now a regular dependency in Vite 8 | none needed | same |
| `@vitejs/plugin-react` v5 with Babel | v6 removes Babel dependency; v5 still works in Vite 8 | `@vitejs/plugin-react` v6 | same |
| `buildApp` (Environment API) | Experimental, not deprecated | n/a | Vite 7 blog |

## React

| Removed / deprecated | Status | Replacement | Source |
|---|---|---|---|
| `react-server-dom-webpack`, `-parcel`, `-turbopack` below patched versions | Advisory-affected: CVE-2025-55182, -55183, -55184, -67779, CVE-2026-23864, -23869, -23870, -44907 | `>=19.2.8` / `19.1.9` / `19.0.8`, or remove the packages (SPA needs none) | [react.dev Dec 11 2025](https://react.dev/blog/2025/12/11/denial-of-service-and-source-code-exposure-in-react-server-components), [GHSA-wx67-qw84-cm4g](https://github.com/react/react/security/advisories/GHSA-wx67-qw84-cm4g) |
| React 19.0.1 / 19.1.2 / 19.2.1 as "safe" floor | Superseded by later advisories | Latest patch per line (19.0.8 / 19.1.9 / 19.2.8) | same |
| 19.0.3 / 19.1.4 / 19.2.3 as "safe" | Incomplete DoS fix per React | 19.0.8 / 19.1.9 / 19.2.8 | [react.dev Dec 11 2025](https://react.dev/blog/2025/12/11/denial-of-service-and-source-code-exposure-in-react-server-components) |
| Passing non-string values through `'' + value` | Removed in React 19.3 (no coercion) | Pass Trusted Types objects directly | [React 19.3](https://react.dev/blog/2026/09/09/react-19-3) |
| `useActionState` error text "Form state" | Renamed "action state" in 19.3 | Update any log/alert string matching it | same |
| Create React App | Sunset announced (react.dev blog listing, 2025-02-14, title only) | Vite (this stack) | [react.dev/blog](https://react.dev/blog) |
| `react-dom` `browser()` usage | New API in 19.3 (not deprecated) | n/a | [React 19.3](https://react.dev/blog/2026/09/09/react-19-3) |

Other React deprecations: **NOT SOURCEABLE** — the 19.3 post does not list them and the full React changelog was not read.

## TanStack Query v5

| Removed / deprecated | Replacement | Source |
|---|---|---|
| Positional-argument signatures for `useQuery`, `useMutation`, `useIsFetching`, `queryClient`/`queryCache` methods | Object form only | [v5 migration](https://tanstack.com/query/latest/docs/framework/react/guides/migrating-to-v5) |
| Status `"loading"` | `"pending"` | same |
| `isLoading` (old meaning: pending) | `isPending` (`isLoading` now = pending and fetching) | same |
| `isInitialLoading` | Deprecated; use `isLoading` / `isPending` | same |
| `cacheTime` | `gcTime` | same |
| `onSuccess`, `onError`, `onSettled` on `useQuery` / `QueryObserver` | Remove; use effects or mutation callbacks | same |
| `getQueryData` / `getQueryState` with more than `queryKey` | Pass only `queryKey` | same |
| `hashQueryKey` | `hashKey` | same |
| `suspense` option (experimental flag) | `useSuspenseQuery`, `useSuspenseInfiniteQuery`, `useSuspenseQueries` | same |
| `useErrorBoundary` | `throwOnError` | same |
| Infinite queries without `initialPageParam` / `getNextPageParam` | Pass both explicitly | same |

## Vitest 5 (released 2026-09-03)

| Removed / deprecated | Replacement | Source |
|---|---|---|
| `loupe.inspect` | pretty-format (per release notes) | [v5.0.0](https://github.com/vitest-dev/vitest/releases/tag/v5.0.0) |
| Quotes around string `test.for` / `each` title `$` values | Changed behavior, see release | same |
| `attachmentsDir` default `.vitest-attachements/` | `.vitest/attachments/` | same |
| `sequential` test/suite options | `concurrent` | same |
| Locator as string | Locator as object | same |
| Bundled `expect` package | Inlined | same |
| Deprecated entry points | Removed | same |
| Node < 22, Vite < 6.4 | Required minimums | same |

## Playwright 1.64

| Changed / removed | Notes | Source |
|---|---|---|
| `screen` from device descriptors | Now forwarded; set to `undefined` to opt out | [v1.64.0](https://github.com/microsoft/playwright/releases/tag/v1.64.0) |
| `--update-snapshots=missing` default mode | Run passes; mode renamed `'default'` | same |
| Elements in hidden iframes | Count as hidden for actions and `toBeVisible()` | same |

## ESLint 10

| Removed | Replacement | Source |
|---|---|---|
| eslintrc config format (`.eslintrc.*`) | `eslint.config.*` flat config | [ESLint v10.0.0 post](https://eslint.org/blog/2026/02/eslint-v10.0.0-released/) |
| `.eslintignore` | `ignores` in flat config | ESLint v10 migration (raw markdown; `.eslintignore` ignored per [secondary]) |
| `ESLINT_USE_FLAT_CONFIG` env var | None; no longer honored | [secondary] |
| CLI flags `--no-eslintrc`, `--env`, `--resolve-plugins-relative-to`, `--rulesdir`, `--ignore-path` | Flat config options | [secondary] |
| `/* eslint-env */` comments | Error; use `languageOptions.globals` | [secondary] |
| `Linter` with `configType: "eslintrc"` | Throws | [secondary] |
| `Linter#defineRule()`, `Linter#getRules()` | Removed | [secondary] |
| Node versions below 20.19.0, and Node 21.x and 23.x | Dropped (supported: 20.19.0+, 22.13.0+, 24+) | [ESLint v10 migration (raw)](https://raw.githubusercontent.com/eslint/eslint/main/docs/src/use/migrate-to-10.0.0.md) (version list); the 21.x/23.x wording is [secondary] |

## pnpm 11 and 12

### Removed in pnpm 11.0 (source: [pnpm 11.0](https://pnpm.io/blog/releases/11.0))

| Removed | Replacement |
|---|---|
| `onlyBuiltDependencies` | `allowBuilds` |
| `onlyBuiltDependenciesFile` | `allowBuilds` |
| `neverBuiltDependencies` | `allowBuilds: { pkg: false }` |
| `ignoredBuiltDependencies` | `allowBuilds` |
| `ignoreDepScripts` | `allowBuilds` |
| `allowNonAppliedPatches` | `allowUnusedPatches` |
| `ignorePatchFailures` | None; patch failures throw |
| `auditConfig.ignoreCves` | `auditConfig.ignoreGhsas` |
| `useNodeVersion`, `executionEnv.nodeVersion` | `devEngines.runtime` or `engines.runtime` |
| `managePackageManagerVersions`, `packageManagerStrict`, `packageManagerStrictVersion` | `pmOnFail` |
| `COREPACK_ENABLE_STRICT=0` | `pmOnFail: warn` |
| `@scope:registry=` in `.npmrc` | `registries` in `pnpm-workspace.yaml` |
| Per-project `.npmrc` | `packageConfigs` in `pnpm-workspace.yaml` |
| `npm_config_*` env vars | `pnpm_config_*` |
| `NPM_CONFIG_OTP` | `PNPM_CONFIG_OTP` |
| `node-mirror:<channel>` in `.npmrc` | `nodeDownloadMirrors` in `pnpm-workspace.yaml` |
| `pnpm server` | None named |
| `pnpm link` (no args), `pnpm link --global` | `pnpm add -g .` |
| `pnpm install -g` (no args) | `pnpm add -g <pkg>` |
| `pnpm env use` | `pnpm runtime set` (deprecated, still present) |
| `pnpm` field in `package.json` | Not read in 11.x |
| Commands: `access`, `bugs`, `edit`, `issues`, `owner`, `prefix`, `profile`, `pkg`, `repo`, `set-script`, `team`, `token`, `xmas` | Throw "not implemented" |

### Removed or changed in pnpm 12.0 (source: [pnpm 12.0](https://pnpm.io/blog/releases/12.0))

| Removed / changed | Replacement |
|---|---|
| `pnpm install --frozen-lockfile false` | `--no-frozen-lockfile` |
| SSH git URLs for GitHub/GitLab/Bitbucket in lockfile | HTTPS canonical URLs; use `url.<base>.insteadOf` for SSH |
| Silent unknown keys in `pnpm-workspace.yaml` | Reported; error when pin matches |
| `filterLog` pnpmfile hook | Deprecated |
| `sudo pnpm setup` / `self-update` / global changes | Fails with `ERR_PNPM_SUDO_NOT_SUPPORTED` |

### Removed in pnpm 10 (secondary)
- `onlyBuiltDependencies` in `package.json` `pnpm` field was the pre-11 allowlist. Migrate to `allowBuilds`.

## Vite and framework specifics NOT SOURCEABLE in this session
- TanStack Router deprecated route APIs: overview page did not list any.
- React 19.x patch-line deprecations beyond the 19.3 behavior list.
- typescript-eslint v8.x deprecations (dist-tags only).
