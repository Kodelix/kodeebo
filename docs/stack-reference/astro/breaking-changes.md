# Astro Marketing Site — Breaking Changes and Security Advisories

Layer: `astro`. Last verified **2026-10-11**. Items are from fetched pages unless marked **[secondary]** (search-result summary) or `NOT SOURCEABLE`.

## 1. Security advisories (withastro/astro GitHub advisories)

Read individually this session. Severity and CVSS as shown on the advisory page. Static-output relevance is stated only where the advisory says so.

| GHSA | CVE | Published | Severity | Affected | Patched | Static-output relevance (as stated) |
|---|---|---|---|---|---|---|
| [GHSA-26w7-cxv4-gfx2](https://github.com/withastro/astro/security/advisories/GHSA-26w7-cxv4-gfx2) — Remote code execution through AVIF image optimization | No CVE listed | 2026-08-27 | **Critical**, CVSS 9.8 (CWE-125, CWE-787) | `astro` < 7.2.8 | **7.2.8** (requires **Sharp 0.35.4**) | Advisory does not distinguish static, SSR, or image endpoints. Trigger: Astro processing untrusted AVIF input. Root cause in `libheif` via the default Sharp service. No workaround listed. |
| [GHSA-376h-93r7-7g6f](https://github.com/withastro/astro/security/advisories/GHSA-376h-93r7-7g6f) — Authorization bypass, missing path-segment boundary check when stripping configured base | CVE-2026-84376 | 2026-08-27 | Moderate | `astro` <= 7.2.3 | **7.2.4** | Advisory does not mention static output. Involves a non-root `base` and middleware checking `context.url.pathname`. |
| [GHSA-4233-jc72-56c5](https://github.com/withastro/astro/security/advisories/GHSA-4233-jc72-56c5) — Netlify Image CDN allowlist bypass enables SSRF | not read | 2026-08-27 | Moderate | not read | not read | Netlify adapter/image CDN. Fix version: **NOT SOURCEABLE** (listing only). |
| [GHSA-qh8j-hqjv-7m4x](https://github.com/withastro/astro/security/advisories/GHSA-qh8j-hqjv-7m4x) — Malformed port in Host header can crash Node adapter | not read | 2026-08-27 | Low | not read | not read | Node adapter. Not relevant to pure static output. Fix version: **NOT SOURCEABLE**. |
| [GHSA-4g3v-8h47-v7g6](https://github.com/withastro/astro/security/advisories/GHSA-4g3v-8h47-v7g6) — Reflected XSS via unescaped View Transition animation properties | CVE-2026-73422 | 2026-07-17 | Moderate (no CVSS shown) | `astro` >= 2.9.0, <= 7.0.9 | **7.1.0** | Advisory describes on-demand, server-rendered routes, including `output: "server"` projects. Static-output impact not stated. |
| [GHSA-x27w-589x-frm2](https://github.com/withastro/astro/security/advisories/GHSA-x27w-589x-frm2) — Unauthenticated path override in `@astrojs/vercel` ISR function | CVE-2026-73424 | 2026-07-17 | Moderate | `@astrojs/vercel` >= 10.0.3 | **11.0.3** | Applies to `isr: true` with `@astrojs/vercel`. PoC uses `output: 'server'`. Not relevant to static deploys on other hosts. |
| [GHSA-8mv7-9c27-98vc](https://github.com/withastro/astro/security/advisories/GHSA-8mv7-9c27-98vc) — `astro/hono` pipeline bypasses `security.checkOrigin` when `middleware()` absent or misordered | not read | 2026-07-17 | Low | not read | not read | Hono integration. Not relevant to static output. |
| [GHSA-f48w-9m4c-m7f5](https://github.com/withastro/astro/security/advisories/GHSA-f48w-9m4c-m7f5) — XSS via unescaped spread attribute names in custom element rendering | CVE-2026-59729 | 2026-07-17 | Low | `astro` <= 7.0.3 | **7.0.5** | Runs only when a global `HTMLElement` exists at SSR time. Not default Node SSR. Static build relevance not addressed. |
| [GHSA-hp3v-mfqw-h74c](https://github.com/withastro/astro/security/advisories/GHSA-hp3v-mfqw-h74c) | not read | 2026-07-15 | not read | not read | not read | Listed by advisory index; not read. |

Project rule [rec]: keep `astro` on **7.3.8** (the current `latest`, which is above every patched version in the table) and `sharp` on **>= 0.35.5**. Build-time image processing invokes the Sharp service on any AVIF input. The docs state build-time transformation applies to prerendered pages (see `best-practices.md`), so the critical AVIF advisory is not limited to server output. This inference is ours, not the advisory's.

## 2. Astro 7.0 breaking changes
Source: [upgrade to v7](https://docs.astro.build/en/guides/upgrade-to/v7/) (fetched).

- **Vite 8**: Astro 7 uses Vite 8 for dev and bundling. Most users need no project changes. Mainly affects integrations and plugins that use Vite internals.
- **Experimental flags now stable or default**: `logger` (now top-level `logger` field), `queuedRendering` (now default), `rustCompiler`, `advancedRouting`, `cache`. `cache` and `routeRules` move out of the `experimental` block.
- **Rust compiler** replaces the Go-based compiler. It is "stricter about invalid HTML syntax": unclosed tags error, and invalid nesting is no longer auto-corrected. CSS output may serialize colors and `url()` values differently. Run a build and diff the static HTML.
- **`src/fetch.ts`** is a reserved filename for advanced routing. Rename it or change the `fetchFile` option.
- **Markdown processor**: Sätteri is the default. `@astrojs/markdown-remark` is no longer installed by default. To keep remark/rehype plugins, set `unified()` as the processor.
- **`compressHTML` default changed from `true` to `'jsx'`**. This can remove spaces between inline elements. Add `{" "}` where needed, or set `compressHTML: true`. This is the change most likely to alter marketing-page markup.
- **Deprecated**: `getContainerRenderer()` imported from integration package roots. Import from each integration's `container-renderer` entrypoint.
- **Removed**: `@astrojs/db` (alternatives named on page: Node's built-in `node:sqlite`, Drizzle ORM, or another DB library). Several `astro:transitions` internals: `TRANSITION_*` constants, `isTransitionBeforePreparationEvent()`, `isTransitionBeforeSwapEvent()`, `createAnimationScope()`.

### Secondary-only items (verify on the official guide before relying on them)
**[secondary]** These came from third-party write-ups in search results. The official page fetched did not list them:
- `Astro.glob()` removed (use `import.meta.glob()`).
- `ViewTransitions` renamed to `ClientRouter`.
- Node 18 and 20 dropped (the install page's 22.12.0+ requirement is primary; the drop list is secondary).
- Markdown pipeline and "no auto-correction" wording are partly primary (above) and partly secondary.

## 3. Install and runtime
Source: [install and setup](https://docs.astro.build/en/install-and-setup/).
- Node: **v22.12.0 or higher**. Odd-numbered versions such as v23 are not supported.
- Install locally, not globally ("Astro must be installed locally, not globally").
- Scaffold: `npm create astro@latest`, `pnpm create astro@latest`, or `yarn create astro`.

## 4. Astro 7.1, 7.2, 7.3 (minor releases)
Blog titles and dates only: 7.1 (2026-07-16), 7.2 (2026-08-06), 7.3 (2026-09-03). **Bodies not read.** Breaking changes in these minors: **NOT SOURCEABLE**. Check each release post before upgrading across them.

## NOT SOURCEABLE in this session
- Full CHANGELOG for 7.1–7.3.
- Support window and LTS policy for Astro majors.
- Patched versions for GHSA-4233-jc72-56c5, GHSA-qh8j-hqjv-7m4x, GHSA-8mv7-9c27-98vc, GHSA-hp3v-mfqw-h74c (listing read, advisory body not read).
- Content Layer as default status in Astro 7 (not stated on the content-collections page).
- Legacy `type: 'content'` collection status (not mentioned on the page).
