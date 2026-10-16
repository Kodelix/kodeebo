# Astro Marketing Site Stack Reference — VERSION

Layer: `astro` — marketing site, **static output** (`output: 'static'`). Pinned per `project.yaml` `stack.site: astro`. Product web app is a separate layer (`vite-react`).

Last verified: **2026-10-11**. Every version and date below was fetched this session (npm registry dist-tags, GitHub release pages, Astro docs, Astro blog, GitHub security advisories). Gaps are marked `NOT SOURCEABLE — <what was searched>`.

## Package table

| Package | Current stable | Date | Link | Notes |
|---|---|---|---|---|
| **astro** (major) | **7** | **Astro 7.0: 2026-06-22** (blog) | [Astro blog](https://astro.build/blog/), [upgrade to v7](https://docs.astro.build/en/guides/upgrade-to/v7/) | Major 7 is current. 7.0 → 7.1 (2026-07-16) → 7.2 (2026-08-06) → 7.3 (2026-09-03). |
| **astro** (latest) | **7.3.8** | 2026-10-08 (GitHub, year from footer) | [npm dist-tags](https://registry.npmjs.org/-/package/astro/dist-tags), [GitHub releases](https://github.com/withastro/astro/releases) | npm `latest` = 7.3.8. Beta: `7.4.0-beta.1`. Also 7.3.7 on 2026-10-07. Secondary sources cite 7.3.5 as "stable" in late Sept (superseded). |
| **create-astro** | 5.2.6 | 2026-10-08 (GitHub) | [GitHub releases](https://github.com/withastro/astro/releases) | Scaffolder. Run `npm create astro@latest` or `pnpm create astro@latest`. |
| **@astrojs/vercel** | 11.0.13 | 2026-10-08 (GitHub "Latest") | [GitHub releases](https://github.com/withastro/astro/releases) | Adapter. **Not needed for static output.** Only use if a server adapter is added. |
| **@astrojs/netlify** | 8.2.9 | 2026-10-08 (GitHub) | same | Adapter. Not needed for static output. |
| **@astrojs/markdoc** | 2.0.11 | 2026-10-08 (GitHub) | same | Integration; check if used. |
| **Sharp** (image service dep) | **0.35.5** | not fetched per version | [npm dist-tags](https://registry.npmjs.org/-/package/sharp/dist-tags) | Astro 7.2.8 advisory requires **Sharp 0.35.4 or newer**. npm `next` = 0.35.5-rc.1. |
| **Vite** (inside Astro 7) | Vite **8** | Vite 8.0 blog 2026-03-12 | [upgrade to v7](https://docs.astro.build/en/guides/upgrade-to/v7/) | Astro 7 "moves to Vite 8 for dev and bundling". Vite version pin follows Astro, not the vite-react layer. |

## Support policy

| Item | Policy |
|---|---|
| Astro major lines | **NOT SOURCEABLE** — upgrade guide and blog searched; no support window found on fetched text. Secondary summary says the Node policy is "latest Maintenance LTS and current Active LTS" — not read on a primary page. |
| Node.js requirement | Install page: "v22.12.0 or higher. Odd-numbered versions like v23 are not supported." ([install and setup](https://docs.astro.build/en/install-and-setup/)) |
| Security patch lines | Patches land on 7.x minors (7.0.5, 7.1.0, 7.2.4, 7.2.8 cited by advisories). Maintenance-branch policy: **NOT SOURCEABLE**. |

## Recommended pin

| Package | Pin | Reason |
|---|---|---|
| astro | `7.3.8` exact (update via `npx @astrojs/upgrade`) | npm `latest`. Above 7.2.8 advisory floor. |
| sharp | `>=0.35.5` (npm `latest`) | Advisory floor 0.35.4; latest is 0.35.5. |
| @astrojs/* integrations | Only add when used. Pin to the version that pairs with astro 7.3.8 (version pairing: **NOT SOURCEABLE** per package). | Adapters unused for static output. |
| Node.js (CI and local) | **22.12.0 or newer, even-numbered** (e.g. 24 LTS) | Install page constraint. |

## Installed locally (checked 2026-10-11)

| Check | Result |
|---|---|
| `astro --version` | **Not on PATH.** No `package.json` and no `astro.config.*` in `/home/kiko/saas-studio` yet. Astro is not installed. |
| `node --version` | v26.11.1 (Current line, not LTS; even-numbered and above 22.12.0, so it meets the install-page constraint). |
| `sharp` | Not installed. |

## Sources (fetched 2026-10-11)

- Versions: [npm astro dist-tags](https://registry.npmjs.org/-/package/astro/dist-tags), [npm sharp dist-tags](https://registry.npmjs.org/-/package/sharp/dist-tags), [GitHub withastro/astro releases](https://github.com/withastro/astro/releases).
- Upgrade: [upgrade to v7](https://docs.astro.build/en/guides/upgrade-to/v7/).
- Install: [install and setup](https://docs.astro.build/en/install-and-setup/).
- Config reference: [configuration reference](https://docs.astro.build/en/reference/configuration-reference/).
- Islands: [directives reference](https://docs.astro.build/en/reference/directives-reference/).
- Content: [content collections](https://docs.astro.build/en/guides/content-collections/).
- i18n: [internationalization](https://docs.astro.build/en/guides/internationalization/).
- Images: [images guide](https://docs.astro.build/en/guides/images/).
- Blog: [astro.build/blog](https://astro.build/blog/) (Astro 7.0 on 2026-06-22; 7.1 on 2026-07-16; 7.2 on 2026-08-06; 7.3 on 2026-09-03).
- Security: GitHub advisories on `withastro/astro` (listed in `breaking-changes.md`), read individually.

## Discrepancies noticed

1. **Astro patch version.** Docs/GitHub/npm show 7.3.8. Secondary blogs and an issue cite 7.3.5 as current. Use 7.3.8.
2. **Year on GitHub release pages.** Several pages show day and month only. The year 2026 is inferred from the footer copyright. Marked where used.

## Knowledge gap warning

The model's training data predates Astro 7 entirely. Do not write Astro API names, config keys, or content-collection patterns from memory. Several Astro 7 changes are only in secondary sources (listed in breaking-changes). Re-verify before each upgrade with `npx @astrojs/upgrade` and the upgrade guide. Known unknowns: Astro support windows, Content Layer default status, integration version pairing, and Astro 7.1–7.3 release-note bodies (only titles were read).
