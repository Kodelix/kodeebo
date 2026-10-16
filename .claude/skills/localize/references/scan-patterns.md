# Scan patterns per layer

Heuristics for `/localize scan`. They are **patterns, not proof**: a hit is a
candidate to classify, and an empty result from a pattern that cannot match the
layer's syntax is not a clean result. Every layer reports its own line:
`scanned <root> with <patterns>: N hits` or `NOT ASSESSED — <reason>`.

Exclude from every scan: locale resource files themselves, tests and fixtures,
generated code (`contracts/` codegen output, build directories, `node_modules`),
log/telemetry messages (operators read these, not customers) and developer-only
error text that never reaches a UI or a message.

## Web (`web/`, and `site/` for the marketing site)

- JSX/Astro text children that are literal words: lines where `>` is followed by letters and `<` closes (`>Save<`, `>Delete workspace<`)
- User-facing attributes with literals: `placeholder="…"`, `title="…"`, `aria-label="…"`, `alt="…"`, `label="…"`, `aria-description`
- String literals passed to toast/dialog/notification helpers; literals in `throw new Error("…")` that surface to the UI
- `toLocaleString()`, `toFixed(`, `Intl` calls without an explicit locale; manual thousands separators; `new Date(…).toString()`; hand-built currency (`"EGP " +`, `"$" +`)
- Physical CSS properties (RTL blockers): `margin-left`, `margin-right`, `padding-left`, `padding-right`, `left:`, `right:`, `text-align: left|right`, `float: left|right`, `border-left`, `border-right`, Tailwind `ml-`/`mr-`/`pl-`/`pr-`/`text-left`/`text-right`/`left-`/`right-` (logical equivalents exist: `ms-`/`me-`/`ps-`/`pe-`/`start`/`end`)
- Missing `lang` / `dir` on the document root; text in images (list `*.png|jpg|svg` assets that contain words — flag for manual check)
- Astro: `hreflang`/canonical/sitemap entries per locale present in built output; locale routing options valid under static output (stack reference `astro/best-practices.md` §5, `deprecated-apis.md`)

## Android (`mobile/android/`, `mobile/shared/`)

- Compose `Text("literal")`, `Text(text = "literal")`, `contentDescription = "literal"`, `label = { Text("literal") }`
- Literals passed to snackbar, dialog, notification builders; literals in `Toast.makeText`
- `String.format(` / template strings holding user-facing sentences; concatenated fragments (`"…" + x + "…"`) in UI code
- Resources: keys in `res/values/strings.xml` missing from `res/values-ar/strings.xml` (or the locale folders the ADR sets); `<plurals>` entries lacking Arabic quantity items `zero|one|two|few|many|other`; non-translatable strings not marked
- RTL blockers: `Alignment.Left`, `Alignment.Right`, `Modifier.padding(left =`, `paddingLeft`, `marginLeft`, `Arrangement.Start` where mirroring is wrong, `android:layout_marginLeft`; manifest `android:supportsRtl` setting
- KMP shared code: user-facing strings in `commonMain` (should come from resources/keys, not literals)

## iOS (`mobile/ios/`)

- SwiftUI `Text("literal")` is localizable by default but only if the key exists in the catalog — a `Text(verbatim:)` or `Text(someStringVar)` with a literal source is the candidate; `Label("…", …)`, `Button("…")`, `.navigationTitle("…")`, `.accessibilityLabel("…")` literals must resolve to catalog keys
- `String(format:)`, `NSLocalizedString` with no comment/context, string interpolation holding sentences
- Catalog completeness: keys in the source language's String Catalog with no Arabic entry, entries in state "new"/"needs review", plural variations missing Arabic categories
- RTL blockers: `.padding(.left`, `.padding(.right`, `Alignment.left`, `.leading`/`.trailing` are correct — `.left`/`.right` are not; hard-coded `HStack` order in directional sequences; images needing `flipsForRightToLeftLayoutDirection`

## Backend-originated text (`backend/`)

- Templates for email, SMS, push, receipts/PDF/invoices: each exists in `ar` and `en`, selects the recipient's locale, and falls back per the documented chain
- API error bodies: stable `type`/`code` plus structured parameters; sentences are composed on the client (`contracts/` problem-details shapes). Flag human-readable `detail` strings that clients are expected to show verbatim
- Money, dates and numbers in generated documents: formatted from locale data, not by hand; currency code/symbol and minor units from the catalogue; dates stored and sent as UTC ISO-8601
- Self-hosted: every locale resource ships in the bundle; no runtime fetch of translations from a hosted service

## Every layer

- Concatenated sentence fragments; counts hard-coded as `count == 1 ? "item" : "items"` (English-only plural logic)
- Positional placeholders (`%s`, `%d`, `{0}`) in sentences where named placeholders are possible
- Hardcoded punctuation or quote characters inside strings; hardcoded ordering assumptions
- Text-in-image assets; numerals rendered by custom code instead of the formatter
- Gender or title assumptions baked into logic
