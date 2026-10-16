# Vite + React SPA Stack Reference — VERSION

Layer: `vite-react` — static SPA product web app. React 19.3, Vite 8, TypeScript 7 (native), TanStack Router and Query, Vitest 5, Playwright, pnpm, ESLint 10.
No Node server in production (static build only). Chosen to avoid the React Server Components / Next.js middleware CVE classes.

Last verified: **2026-10-11**. Every version and date below was fetched this session (official pages, GitHub release pages, npm registry dist-tags). Gaps are marked `NOT SOURCEABLE — <what was searched>`.

## Package table

| Package | Current stable | Release date | Link | Notes |
|---|---|---|---|---|
| **react**, **react-dom** | **19.3.0** | 2026-09-09 | [react.dev/blog/2026/09/09/react-19-3](https://react.dev/blog/2026/09/09/react-19-3), [GitHub v19.3.0](https://github.com/facebook/react/releases) | npm `latest` = 19.3.0. Patch lines: 19.2.8, 19.1.9, 19.0.8 (all 2026-07-21). |
| **vite** | **8.3.4** | 2026-10-08 | [vite.dev/releases](https://vite.dev/releases), [GitHub v8.3.4](https://github.com/vitejs/vite/releases) | Vite 8.0 blog 2026-03-12; Vite 7.0 blog 2025-06-24. npm `previous` = 6.4.4. |
| **typescript** | **7.0.2** | 2026-08-20 (GitHub Latest) | [GitHub TypeScript 7.0.2](https://github.com/microsoft/TypeScript/releases), [TS 7.0 announcement](https://devblogs.microsoft.com/typescript/announcing-typescript-7-0/) | TS 7.0 announced 2026-07-08 (native Go port). **7.0 ships without a programmatic API** (expected in 7.1). TS 6.0.3 released 2026-04-16 (GitHub, year inferred). |
| **@tanstack/react-router** | **1.170.42** | not fetched per version; repo release `release-2026-10-10-0730` marked Latest on 2026-10-10 | [tanstack.com/router](https://tanstack.com/router/latest/docs/framework/react/overview), [GitHub releases](https://github.com/TanStack/router/releases) | npm `latest` tag. `@tanstack/router-plugin` npm `latest` = 1.168.43. |
| **@tanstack/react-query** | **5.104.1** | 2026-10-02 (sibling `@tanstack/vue-query@5.104.1` tagged 2026-10-02 10:04) | [GitHub releases](https://github.com/TanStack/query/releases), [v5 migration](https://tanstack.com/query/latest/docs/framework/react/guides/migrating-to-v5) | npm `previous` = 4.44.0. |
| **vitest** | **5.0.3** | 2026-09-30 (GitHub Latest) | [GitHub releases](https://github.com/vitest-dev/vitest/releases), [v5.0.0 release](https://github.com/vitest-dev/vitest/releases/tag/v5.0.0) | v5.0.0 on 2026-09-03. npm: V4 tag = 4.1.11, V3 tag = 3.2.7. |
| **@playwright/test** (Playwright) | **1.64.0** | 2026-10-07 (year inferred from footer) | [GitHub v1.64.0](https://github.com/microsoft/playwright/releases/tag/v1.64.0), [release notes](https://playwright.dev/docs/release-notes) | npm `next` = 1.65.0-alpha-2026-10-10 (not stable). Bundles Chromium 156.0.8078.4, Firefox 157.0, WebKit 27.2. |
| **pnpm** | **12.11.2** | 12.0.0 on 2026-08-26 (GitHub); 12.11.2 on 2026-10-09 (GitHub Latest) | [GitHub releases](https://github.com/pnpm/pnpm/releases), [pnpm 12.0 blog](https://pnpm.io/blog/releases/12.0) | npm `latest` = `latest-12` = 12.11.2. `latest-11` = 11.28.2. |
| **eslint** | **10.12.0** | 2026-10-02 (GitHub Latest) | [GitHub releases](https://github.com/eslint/eslint/releases), [v10.0.0 release post](https://eslint.org/blog/2026/02/eslint-v10.0.0-released/) | v10.0.0 released 2026-02 (blog URL path; day not read). npm `maintenance` = 9.39.5. |
| **typescript-eslint** | **8.71.1** | not fetched | [npm dist-tags](https://registry.npmjs.org/-/package/typescript-eslint/dist-tags) | Release date NOT SOURCEABLE — no per-version date fetched. Check TS 7 API support before pairing (see below). |
| **Node.js** (runtime, not a package) | Current **v26.11.1** (line v26 first released 2026-05-05); **LTS v24.21.0** ("Latest LTS"); LTS v22 | 26.11.1 date not read | [nodejs.org/en/about/previous-releases](https://nodejs.org/en/about/previous-releases) | Recommend pinning CI to v24 LTS (recommendation, see best-practices). |

## Support policy

| Package | Policy (as fetched) |
|---|---|
| **Vite** | "Regular patches are released for `vite@8.3`." Vite 7.3 and 8.2 get important fixes and security patches. Vite 6.4 and 8.1 get security patches only. Older versions unsupported. No EOL dates for prior majors on the page. Source: [vite.dev/releases](https://vite.dev/releases). |
| **React** | Page states docs are archived per major; "versioning policy" page referenced. Support window for older 19.x lines: **NOT SOURCEABLE — react.dev/versions and its versioning-policy link searched; no window stated on fetched text.** Patch lines in use: 19.3 (current), 19.2.8, 19.1.9, 19.0.8 (security backports from GitHub advisories). |
| **TypeScript** | 6.x end-of-support date: **NOT SOURCEABLE — TS 7.0 post searched; none stated.** |
| **Vitest** | **NOT SOURCEABLE — release notes and migration pages searched; no support window found on fetched text.** |
| **Playwright** | **NOT SOURCEABLE — release notes and intro pages searched; no support window stated.** |
| **pnpm** | Latest dist-tag tracks the newest major (12); 11 remains on `latest-11`. Support window: **NOT SOURCEABLE.** |
| **ESLint** | Maintenance line 9.39.5 exists on npm dist-tags; EOL date **NOT SOURCEABLE.** |
| **Node.js** | Current v26 (not LTS). v24 "Latest LTS" (v24.21.0). v22 LTS listed with a date of 2026-09-23 on nodejs.org (column meaning ambiguous on the fetched page — likely its end-of-life; **NOT SOURCEABLE as EOL without confirmation**). |

## Recommended pins (for a new SPA)

| Package | Pin | Reason |
|---|---|---|
| react, react-dom | `19.3.0` exact | Current stable; advisory-safe (see React CVEs). |
| react-server-dom-* | **Do not install.** If present transitively: `>=19.2.8` (19.x line) | Not needed for SPA. CVE-2026-44907 range ends at 19.2.7. |
| vite | `8.3.4` | Current stable. Needs Node 20.19+ or 22.12+ (see breaking-changes). |
| typescript | `7.0.2` only after confirming your lint/test toolchain runs on TS 7 (7.0 has no programmatic API). Otherwise `6.0.3` | Per TS 7.0 post. |
| @tanstack/react-router | `1.170.42` | npm `latest`. |
| @tanstack/react-query | `5.104.1` | npm `latest`. |
| vitest | `5.0.3` | Current stable. Requires Node 22 and Vite 6.4 (stated as breaking change). |
| @playwright/test | `1.64.0` | npm `latest`. Node requirement: **NOT SOURCEABLE** (page states "latest 22.x, 24.x or 26.x"). |
| pnpm | `12.11.2` (`pnpm self-update latest-12`) | npm `latest`. See the pnpm section in best-practices for the local-install discrepancy. |
| eslint | `10.12.0` flat config only | eslintrc removed in v10. |

## Installed locally (checked 2026-10-11 03:49 EEST)

| Tool | Version | Status |
|---|---|---|
| `node --version` | **v26.11.1** | Current line, **not LTS**. Vite 8 needs 20.19+ / 22.12+ (OK). ESLint 10 needs 20.19.0+ / 22.13.0+ / 24+ (OK). Vitest 5 needs 22+ (OK). |
| `pnpm --version` | **11.28.5** | Installed build is the `next-11` dist-tag. `latest-11` = 11.28.2; `latest` = **12.11.2**. Upgrade to pnpm 12 before pinning `packageManager`. |

## Sources (fetched 2026-10-11)

- Versions: npm registry dist-tags — `react`, `vite`, `typescript`, `vitest`, `@tanstack/react-router`, `@tanstack/react-query`, `@tanstack/router-plugin`, `@playwright/test`, `eslint`, `astro`, `typescript-eslint`, `pnpm` (via `https://registry.npmjs.org/-/package/<name>/dist-tags`); `https://registry.npmjs.org/pnpm/latest`.
- React: [react.dev/blog](https://react.dev/blog), [React 19.3](https://react.dev/blog/2026/09/09/react-19-3), [react.dev/versions](https://react.dev/versions), [GitHub releases](https://github.com/facebook/react/releases).
- React advisories: [Dec 3 2025 post](https://react.dev/blog/2025/12/03/critical-security-vulnerability-in-react-server-components), [Dec 11 2025 post](https://react.dev/blog/2025/12/11/denial-of-service-and-source-code-exposure-in-react-server-components), GHSA-479c-33wc-g2pg, GHSA-wx67-qw84-cm4g, GHSA-83fc-fqcc-2hmg, [CVE-2026-23870 (GitLab advisory DB)](https://advisories.gitlab.com/npm/react-server-dom-webpack/CVE-2026-23870/).
- Vite: [vite.dev/releases](https://vite.dev/releases), [announcing Vite 8](https://vite.dev/blog/announcing-vite8), [announcing Vite 7](https://vite.dev/blog/announcing-vite7).
- TypeScript: [TS 7.0 announcement](https://devblogs.microsoft.com/typescript/announcing-typescript-7-0/), [GitHub releases](https://github.com/microsoft/TypeScript/releases).
- TanStack: [Router overview](https://tanstack.com/router/latest/docs/framework/react/overview), [Query v5 migration](https://tanstack.com/query/latest/docs/framework/react/guides/migrating-to-v5), GitHub releases for Router and Query.
- Vitest: [v5.0.0 release](https://github.com/vitest-dev/vitest/releases/tag/v5.0.0), [releases](https://github.com/vitest-dev/vitest/releases). Migration guide URL `vitest.dev/guide/migration` returned errors.
- Playwright: [v1.64.0 release](https://github.com/microsoft/playwright/releases/tag/v1.64.0), [releases](https://github.com/microsoft/playwright/releases), [intro](https://playwright.dev/docs/intro), [release notes](https://playwright.dev/docs/release-notes).
- pnpm: [pnpm 11.0 notes](https://pnpm.io/blog/releases/11.0), [pnpm 11.3](https://pnpm.io/blog/releases/11.3), [pnpm 11.11–11.14](https://pnpm.io/blog/releases/11.11-11.14), [pnpm 12.0](https://pnpm.io/blog/releases/12.0), [supply-chain security](https://pnpm.io/supply-chain-security), [settings](https://pnpm.io/settings), [releases](https://pnpm.io/releases) (404 at fetch time), [GitHub releases](https://github.com/pnpm/pnpm/releases).
- ESLint: [v10.0.0 release post](https://eslint.org/blog/2026/02/eslint-v10.0.0-released/), [GitHub releases](https://github.com/eslint/eslint/releases), raw [configuration-files.md](https://raw.githubusercontent.com/eslint/eslint/main/docs/src/use/configure/configuration-files.md), raw [migrate-to-10.0.0.md](https://raw.githubusercontent.com/eslint/eslint/main/docs/src/use/migrate-to-10.0.0.md).
- Node.js: [previous releases](https://nodejs.org/en/about/previous-releases).
- Security platform: [MDN CSP](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CSP), [MDN Trusted Types](https://developer.mozilla.org/en-US/docs/Web/API/Trusted_Types_API), [OWASP Session Management (raw markdown)](https://raw.githubusercontent.com/OWASP/CheatSheetSeries/master/cheatsheets/Session_Management_Cheat_Sheet.md).

## Discrepancies noticed

1. **React patch versions.** [react.dev/versions](https://react.dev/versions) lists latest 19.2.7, 19.1.8, 19.0.7. GitHub releases and the GHSA advisory show 19.2.8, 19.1.9, 19.0.8 (2026-07-21). Use the GitHub/advisory values.
2. **pnpm `latest` tag.** The [pnpm 12.0 blog](https://pnpm.io/blog/releases/12.0) says `latest` still points to the pnpm 11 line and recommends `pnpm self-update latest-12`. The npm registry, fetched 2026-10-11, shows `latest` = 12.11.2. Registry value used here.
3. **pnpm 12 Node minimum.** pnpm 12.0 blog and GitHub release state no Node minimum. npm `engines` field reads `>=18.*`. Treat as unverified; pnpm 11 states Node 22+.
4. **Astro/TypeScript dates.** Several GitHub release pages show day/month only; year inferred from footer © 2026. Marked where used.
5. **Vitest 5 Vite requirement.** Changelog text reads "Require Node.js 22 and Vite 6.4", which is lower than Vite 8. Stated as-is; not reconciled.

## Knowledge gap warning

The model's training data predates every release in this file (React 19.3, Vite 8, TypeScript 7, Vitest 5, pnpm 11/12, ESLint 10, Astro 7). Do not write API calls, config keys, or CVE numbers from memory. Re-fetch before each pin change. Known unknowns: React and Vitest support windows, Playwright and Node minimums for Playwright 1.64, typescript-eslint release dates, Vite plugin-react version pairing, TanStack Router SPA-mode specifics.
