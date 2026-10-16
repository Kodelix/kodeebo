# Astro Marketing Site — Best Practices (static output)

Layer: `astro`. Last verified **2026-10-11**. Each claim cites a fetched page. **[rec]** = project recommendation derived from sources, not a source statement. `NOT SOURCEABLE` = searched, not found on a fetched page.

## 1. Output mode: static

- Default: `output: 'static'`. Allowed values: `'static'`, `'server'`. Source: [configuration reference](https://docs.astro.build/en/reference/configuration-reference/).
- Keep it explicit in `astro.config.mjs` so the static intent is visible. [rec]
- Default `outDir` is `./dist`. `build.format` default is `'directory'` (values: `file`, `directory`, `preserve`). Same source.
- Several i18n features require server output. Do not enable them on the marketing site (see §5).
- Adapters (`@astrojs/vercel`, `@astrojs/netlify`, `@astrojs/node`) are server-side tools. Do not add one unless the site needs on-demand rendering. [rec]

## 2. Islands and client directives

Source: [directives reference](https://docs.astro.build/en/reference/directives-reference/).

- Components render to HTML with no JavaScript unless they carry a `client:*` directive. The page says: "its HTML is rendered onto the page without JavaScript."
- Directives (exact behavior from the page):
  - `client:load`: hydrates immediately on page load.
  - `client:idle`: hydrates once the page finishes initial load and the browser is idle (falls back to the document load event where idle callbacks are unsupported).
  - `client:visible`: hydrates when the component enters the viewport.
  - `client:media="<query>"`: hydrates when the CSS media query matches.
  - `client:only="<framework>"`: skips server HTML; renders on the client only. Must pass the framework name.
- [rec] Default to no directive. Use `client:visible` or `client:idle` for interactive widgets below the fold. Use `client:load` only for above-the-fold interactivity.
- Integrations can add custom directives via `addClientDirective` (since Astro 2.6.0, per page).
- Whether client directives behave differently under static output: **NOT SOURCEABLE** (page does not say; standard static hydration assumed, not verified).

## 3. Content collections

Source: [content collections](https://docs.astro.build/en/guides/content-collections/).

- Config file: `src/content.config.ts` (`.js` and `.mjs` also supported). Export a single `collections` object.
- Imports:
  - `defineCollection`, `getCollection`, `getEntry`, `getEntries`, `render`, `reference` from `astro:content`.
  - `glob`, `file` from `astro/loaders`.
  - `z` from `astro/zod`.
- Each collection needs a `loader` (required). `schema` is optional (Zod).
- Live collections (`src/live.config.ts`, `defineLiveCollection()`, `getLiveCollection()`, `getLiveEntry()`) need an adapter for on-demand rendering. **Do not use them on a static marketing site.** [rec]
- JSON schema files are generated in `.astro/collections/` (since 4.13.0).
- Content Layer as default in Astro 7: **NOT SOURCEABLE**. Use the `loader`-based API shown in the docs.
- Legacy `type: 'content'` collections: **NOT SOURCEABLE** (not mentioned on the page).

## 4. Images

Source: [images guide](https://docs.astro.build/en/guides/images/).

- Components: `<Image />` and `<Picture />` from `astro:assets`. Helper: `getImage()`.
- Default image service: **Sharp**. Set with `image.service`.
- No-op option: `passthroughImageService()` (import from `astro/config`). Astro does not transform images. Useful where Sharp cannot run (e.g. Cloudflare, per page).
- Build-time transformation applies to **prerendered** pages (static output). On-demand pages transform when viewed.
- `image` config keys: `image.domains`, `image.remotePatterns`, `image.layout`, `image.responsiveStyles`, `image.service`. Top-level `cacheDir` defaults to `./node_modules/.astro`.
- [rec] Allow only the remote hosts you control in `image.remotePatterns` and `image.domains`. Keep Sharp current: advisory GHSA-26w7-cxv4-gfx2 requires Astro 7.2.8 with Sharp 0.35.4+ (see `breaking-changes.md`).
- Sharp version requirement on the images page: none stated. Page notes that strict package managers (pnpm) may need Sharp added directly (`pnpm add sharp`). Source: same.

## 5. i18n routing

Source: [internationalization](https://docs.astro.build/en/guides/internationalization/).

- Config keys: `i18n.defaultLocale`, `i18n.locales` (strings or `{ path, codes }` objects), `i18n.routing`, `i18n.fallback`, `i18n.domains`.
- `i18n.routing` accepts an object (`prefixDefaultLocale`, `redirectToDefaultLocale`, `fallbackType`) or the string `"manual"`.
  - `prefixDefaultLocale: false` (default): default-language URLs have no prefix; others do.
  - `prefixDefaultLocale: true`: all URLs prefixed; unprefixed return 404 unless fallback is set.
  - `redirectToDefaultLocale` applies only with `prefixDefaultLocale: true`.
  - `fallbackType`: `"redirect"` (default) or `"rewrite"` (added 4.15.0).
  - `"manual"` disables Astro's i18n middleware. No other routing options may be set.
- Helpers from `astro:i18n`: `getRelativeLocaleUrl`, `getAbsoluteLocaleUrl`, `getAbsoluteLocaleUrlList`, `getLocaleByPath`, `redirectToDefaultLocale`, `redirectToFallback`, `notFound`, `middleware`.
- Static-output constraints from the page:
  - Custom locale `path` values require `site`, `output: 'server'`, and no individually prerendered pages. **Not compatible with static output.** [rec: avoid custom paths]
  - `i18n.domains` requires `site`, `output: 'server'`, and an adapter. **Not compatible with static output.**
  - `Astro.preferredLocale` and `Astro.preferredLocaleList` exist only on on-demand pages. `Astro.currentLocale` works on all pages.
- Middleware order: Astro's i18n middleware runs first and awaits responses from user middleware. Combine with `sequence()` and `middleware()` from `astro:middleware` / `astro:i18n`.
- Static i18n with default routing and `prefixDefaultLocale` on a prerendered site: **NOT SOURCEABLE** as a fully verified recipe (the page lists the constraints above but no static example was read). [rec: build a sample and inspect generated paths before committing]

## 6. HTML output and compression

Source: [Astro 7 upgrade](https://docs.astro.build/en/guides/upgrade-to/v7/).

- `compressHTML` default is now `'jsx'` (was `true`). It can remove spaces between inline elements. Use `{" "}` for intentional spaces, or set `compressHTML: true` for the old behavior.
- Rust compiler is stricter: unclosed tags and invalid nesting now error. Fix markup before upgrade. [rec] Run `astro build` in CI and fail on errors.

## 7. Security

Sources: GitHub advisories listed in `breaking-changes.md`.

- Pin `astro` to `7.3.8` (or at least `>= 7.2.8`). Pin `sharp` `>= 0.35.4` (`0.35.5` latest).
- Request-time advisories (middleware path bypass, Vercel ISR, Node adapter Host header) target server-rendered routes or adapters. A static build without adapters is not in their stated scope. [rec, inference from advisory text] Still upgrade for the image-processing advisory, which the docs tie to build-time transformation for prerendered pages.
- Content-Security-Policy and Trusted Types for the marketing site: apply the same rules as the SPA (`docs/stack-reference/vite-react/best-practices.md` §3-4). [rec]
- Markdown or MDX content is trusted only if authored in-repo. Do not render user-supplied Markdown without sanitization. Sanitizer for Sätteri/remark: **NOT SOURCEABLE**.

## 8. Upgrading

1. Read [upgrade to v7](https://docs.astro.build/en/guides/upgrade-to/v7/) and the release posts for each 7.x minor you skip (blog dates: 7.1 2026-07-16, 7.2 2026-08-06, 7.3 2026-09-03).
2. Run `npx @astrojs/upgrade` to bump Astro and official integrations together. Source: secondary summary of the upgrade page.
3. Confirm Node is 22.12.0 or newer, even-numbered (install page).
4. Move `experimental` flags that became stable into the new top-level keys (`logger`, `cache`, `routeRules`).
5. Set `compressHTML` explicitly and diff static HTML before/after.
6. Rebuild and fix Rust-compiler HTML errors. Compare rendered pages visually with Playwright screenshots (see `vite-react` layer).
