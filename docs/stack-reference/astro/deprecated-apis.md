# Astro Marketing Site — Deprecated and Removed APIs

Layer: `astro`. Last verified **2026-10-11**. Primary = fetched official Astro page or advisory. **[secondary]** = search-result summary only.

| Removed / deprecated | Status | Replacement | Source |
|---|---|---|---|
| `getContainerRenderer()` imported from an integration package root | Deprecated in Astro 7 | Import from that integration's `container-renderer` entrypoint | [upgrade to v7](https://docs.astro.build/en/guides/upgrade-to/v7/) |
| `@astrojs/db` | Removed in Astro 7 | `node:sqlite`, Drizzle ORM, or another DB library (page names these) | same |
| `astro:transitions` internals: `TRANSITION_*` constants | Removed in Astro 7 | Public View Transitions API surface (see Astro docs for the current names; not read) | same |
| `isTransitionBeforePreparationEvent()` | Removed in Astro 7 | Not named on page | same |
| `isTransitionBeforeSwapEvent()` | Removed in Astro 7 | Not named on page | same |
| `createAnimationScope()` | Removed in Astro 7 | Not named on page | same |
| `experimental.logger` | Stable in Astro 7 | Top-level `logger` config field | same |
| `experimental.queuedRendering` | Default in Astro 7 | Remove the flag | same |
| `experimental.rustCompiler` | Stable/default in Astro 7 | Remove the flag | same |
| `experimental.advancedRouting` | Stable/default in Astro 7 | Remove the flag; rename `src/fetch.ts` (reserved) or set `fetchFile` | same |
| `experimental.cache`, `experimental.routeRules` | Moved out of `experimental` | Top-level `cache` and `routeRules` | same |
| Go-based compiler | Replaced by Rust compiler in Astro 7 | n/a. Stricter HTML: unclosed tags error | same |
| `@astrojs/markdown-remark` as default | Not installed by default in Astro 7 | Sätteri is default; keep remark/rehype with `unified()` processor | same |
| `compressHTML: true` as default | Default is `'jsx'` in Astro 7 | Set `compressHTML: true` to restore old behavior, or add `{" "}` | same |
| `src/fetch.ts` as a normal route file | Reserved in advanced routing | Rename, or set `fetchFile` | same |
| `Astro.glob()` | **[secondary]** removed | `import.meta.glob()` | search summary of third-party write-ups |
| `ViewTransitions` component | **[secondary]** renamed | `ClientRouter` | search summary of third-party write-ups |
| Node.js 18 and 20 | **[secondary]** dropped | Node 22.12.0+ (primary, install page) | search summary |
| `remark` / `rehype` as default markdown pipeline | Replaced by Sätteri default (primary); `unified()` opt-in keeps plugins | see above | upgrade page |
| Custom locale `path` and `i18n.domains` in static output | Require `output: 'server'` (and an adapter for domains) | Avoid on the marketing site | [i18n guide](https://docs.astro.build/en/guides/internationalization/) |
| Live content collections on static site | Require an adapter for on-demand rendering | Use build-time `defineCollection` with `loader` | [content collections](https://docs.astro.build/en/guides/content-collections/) |
| Default Sharp image service on targets without Sharp (page names Cloudflare as an example) | `passthroughImageService()` from `astro/config` | Disables transformation | [images guide](https://docs.astro.build/en/guides/images/) |

## Security-related deprecations and superseded patches

| Item | Replacement | Source |
|---|---|---|
| `astro` below 7.2.8 with default Sharp service | `astro` 7.2.8+ with Sharp 0.35.4+ | [GHSA-26w7-cxv4-gfx2](https://github.com/withastro/astro/security/advisories/GHSA-26w7-cxv4-gfx2) |
| `astro` <= 7.2.3 (non-root `base` path-segment bypass) | 7.2.4+ | [GHSA-376h-93r7-7g6f](https://github.com/withastro/astro/security/advisories/GHSA-376h-93r7-7g6f) |
| `astro` <= 7.0.9 (View Transition animation property XSS) | 7.1.0+ | [GHSA-4g3v-8h47-v7g6](https://github.com/withastro/astro/security/advisories/GHSA-4g3v-8h47-v7g6) |
| `astro` <= 7.0.3 (spread attribute XSS) | 7.0.5+ | [GHSA-f48w-9m4c-m7f5](https://github.com/withastro/astro/security/advisories/GHSA-f48w-9m4c-m7f5) |
| `@astrojs/vercel` >= 10.0.3 with `isr: true` | 11.0.3+ | [GHSA-x27w-589x-frm2](https://github.com/withastro/astro/security/advisories/GHSA-x27w-589x-frm2) |

## NOT SOURCEABLE in this session
- Exact replacements for `astro:transitions` removed internals.
- Full list of Astro 7.1–7.3 deprecations (release bodies not read).
- Whether `Astro.glob()` removal and `ViewTransitions` → `ClientRouter` are accurate for Astro 7.0 (secondary only).
