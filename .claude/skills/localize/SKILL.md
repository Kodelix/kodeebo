---
name: localize
description: "Localization pipeline for Arabic and English — hardcoded string scan across web, Android and iOS code roots, extraction, validation, RTL and bidi checks, plurals, number/date/currency formatting (EGP, SAR, AED), pseudo-locale, string freeze, locale QA."
argument-hint: "[scan|extract|validate|status|brief|regional-review|rtl-check|formats|pseudo|freeze|freeze lift|qa]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash(date *), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Agent, AskUserQuestion, Bash(bash "*/.claude/skills/localize/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,qa.level,stack`

# Localization Pipeline

Our products are born bilingual: Arabic (right-to-left) and English from the
first spec. Localization is not translation — it is strings living outside code,
messages that survive plurals and word order, numbers, dates and money that
format for the reader's locale, layouts that mirror, and a translation workflow
that catches a missing or broken string before a customer does. Poor
localization is a defect in the product, not a polish item.

This skill covers the pipeline from the hardcoded-string scan through
extraction, validation, RTL and bidi checks, formatting, pseudo-localization,
string freeze and locale QA. The owner is `localization-lead`; the architecture
per layer (library or platform mechanism, file layout, fallback chain) is
decided in an ADR per layer and a research note `docs/research/i18n.md` — not
in this skill.

**Modes:**
- `scan` — Find hardcoded strings and localization anti-patterns across every code root (read-only)
- `extract` — Extract strings and produce translation-ready entries
- `validate` — Check translations for completeness, placeholders, plurals and length
- `status` — Coverage matrix across all locales and layers
- `brief` — Translator briefing document (glossary, tone, do-not-translate) for a translator or reviewer
- `regional-review` — Flag regional and cultural issues for Egypt, GCC (Saudi Arabia, UAE) and other target markets
- `rtl-check` — Validate RTL layout, mirroring, bidi, fonts and numerals per layer
- `formats` — Check number, date, time and currency (EGP, SAR, AED) formatting
- `pseudo` — Run or set up the pseudo-locales (expanded accented and RTL) and read the findings
- `freeze` — Enforce string freeze; lock source strings before translation begins (`freeze lift` ends it)
- `qa` — Run the full localization QA cycle before release

If no subcommand is provided, output usage and stop. Verdict: **FAIL** — missing required subcommand.
An unrecognised subcommand prints the same usage: Verdict: **FAIL** — unknown subcommand.

**Verdict for every mode.** Each mode ends in one overall word, never only
per-line outcomes: **COMPLETE** (the mode ran over every layer and locale in scope;
findings are reported separately by severity, they do not change this word),
**COMPLETE WITH GAPS** (it ran, but one or more layers, locales, inputs or checks
were `NOT ASSESSED` / `NOT RUN` — name each), **NOT ASSESSED** (nothing could be
assessed: code roots unresolved, no resource files, no locale list for a mode that
needs one), and **BLOCKED — write declined by user** (a mode that writes a file and
the write was declined; the result stays in conversation, marked not recorded).
`qa` keeps its own PASS / PASS WITH CONDITIONS / NOT ASSESSED / FAIL per locale; `pseudo`
and `extract` use COMPLETE / NOT ASSESSED as stated in their sections. `Edit` is
used only to append to or update existing files (`freeze-status.md`, resource files
per the ADR); new files are created with `Write`.

---

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

## Ground rules and inputs

Before any mode runs, establish what exists. Each missing input is reported by
name in the output; none of them is silently defaulted.

| Input | Where | If missing |
|---|---|---|
| Code roots | `resolve_code_root` (`bash .claude/hooks/yaml-helper.sh resolve_code_root`; roots: `backend/`, `web/`, `site/`, `mobile/`, `contracts/`) | `NOT ASSESSED — code roots unresolved`. Zero hits from an unresolved root reads as "nothing to localize", which is exactly the failure this guards. A root that resolved but is absent for a layer (no `mobile/ios/`) is reported `layer not present — not scanned`, not "0 hits" |
| Locale list, glossary, key naming, workflow | `design/localization/` | Say so; `scan` still runs. `extract`, `validate`, `brief`, `qa` need the locale list — offer to create the folder's files with `localization-lead` before continuing |
| i18n mechanism per layer | ADR in `docs/architecture/` and `docs/research/i18n.md` | `NOT SOURCEABLE — the i18n mechanism for [layer] is not covered by docs/research/i18n.md or an ADR`. Do not name a library, resource format or API from memory; the stack reference has no section on web i18n libraries, Android string resources or iOS String Catalogs. Extraction and validation for that layer are `NOT ASSESSED`; `scan` and the RTL/formatting heuristics still run. Next step: `/research` then `/architecture-decision` |
| Specs | `design/specs/<feature>.md` Non-Functional: localization | Note which features declare it |

**Source locale** is `en` unless `design/localization/` says otherwise; **target**
locales default to `ar` (and any regional variant the locale list names, such as
`ar-EG`, `ar-SA`, `ar-AE`). Arabic is a first-class locale, not an afterthought:
a feature with English complete and Arabic missing is not complete.

---

## Phase 2A: Scan Mode

Search every code root for hardcoded user-facing strings and localization
anti-patterns. Patterns per layer are in **`references/scan-patterns.md`** —
read it now and follow it; read it again if the conversation was compacted.

Report **per layer**: `web/`, `site/`, `mobile/android/` (+ `mobile/shared/`),
`mobile/ios/`, `backend/` templates and generated documents. Each layer's line is
`scanned with [patterns]: N hits`, or `NOT ASSESSED — [reason]`. A layer with no
sourceable pattern for its syntax is `NOT ASSESSED`, never zero.

Findings include:

- User-facing string literals not routed through the layer's localization mechanism
- Concatenated strings that should be one message with named placeholders
- Positional placeholders (`%s`, `%d`) instead of named ones
- English-only plural logic (`count == 1 ? … : …`) — Arabic needs six plural categories
- Number, date, time and currency formatting not using locale-aware APIs (hand-built separators, `toFixed`, manual currency symbols)
- Physical direction (`left`/`right`) in CSS, Compose or SwiftUI where `start`/`end`/logical properties belong
- Text embedded in images; punctuation and ordering assumptions
- Backend templates (email, SMS, push, receipts) missing a locale or not selecting the recipient's locale

Report all findings with file paths and line numbers, grouped by layer and
severity (BLOCKING for customer-visible literals on shipped screens; ADVISORY
otherwise). Include the **grep commands run and their raw counts** so the result
can be re-run. This mode is read-only — no files are written. Verdict: **COMPLETE**, or
**COMPLETE WITH GAPS** when a layer was `NOT ASSESSED`, or **NOT ASSESSED** when
every layer was.

---

## Phase 2B: Extract Mode

- Resolve the mechanism for each layer from its ADR (see Ground rules). A layer without one is skipped **and named** in the output.
- Scan the layer's source for keyed references and for hardcoded strings (Phase 2A).
- Compare against the existing resource files (location per ADR).
- Generate entries for strings not yet keyed.
- Key naming from `design/localization/` (default `<feature>.<screen-or-component>.<element>.<purpose>`, lower dot-case, e.g. `billing.invoices.empty.title`). A key never encodes its English text. Renamed keys keep a migration note.
- Each new entry carries a **translator note**:
  - Where it appears (screen, flow, email), and the layer
  - Maximum length if the container is tight
  - Placeholder meaning (`{workspaceName}` = the tenant's workspace name)
  - Plural/gender context; for a counted noun, all six Arabic categories (`zero`, `one`, `two`, `few`, `many`, `other`) are authored, not just two
  - Whether the string includes user-generated text (needs bidi isolation)
- Sentences are single messages; fragments are merged before extraction.
- Flag strings that include secrets, PII or tenant data being logged or sent to telemetry — those do not belong in resource files at all.

Present the diff of new entries to the user. (If the user declines the write:
Verdict **BLOCKED — write declined by user**.) If string freeze is **ACTIVE**
(`production/localization/freeze-status.md`), name that file in the same "May I
write" question, append the new keys to its Post-Freeze Changes on approval, and
warn:
> "String freeze is active. [N] new/modified strings are freeze violations. Notify the translation reviewers before proceeding."

Ask: "May I write these new entries to `[resource files per layer]`?" Write only
the diff, never a full replacement. Verdict: **COMPLETE** — strings extracted and
written (layers skipped for lack of an ADR are listed).

---

## Phase 2C: Validate Mode

Read all resource files per layer for every locale. Check:

- **Completeness** — key exists in source but not in the target locale (per layer and per locale)
- **Key parity** across layers that share keys (web / Android / iOS) — a key that exists on one app and not the other
- **Placeholder mismatches** — source has `{name}` but the translation omits it, renames it or adds extras; placeholders must stay isolated from surrounding RTL text
- **Plural form count** — Arabic requires all six categories for every counted noun; fewer is a defect. English requires its own. A test or fixture renders counts 0, 1, 2, 3, 11, 100 and a decimal in both languages
- **Length violations** — translation exceeds the limit in the note; Arabic often shortens, German-style expansion is simulated by the pseudo-locale, not guessed
- **Orphaned keys** — present in resources, referenced nowhere in the code roots
- **Stale translations** — source changed after the translation was approved (compare per-key status)
- **Approval status** — Arabic strings for shipped features that are `new` or `in review` (a release gate input)
- **Encoding and fonts** — Arabic text present and the font stack supports Arabic glyphs and ligatures (flag if uncertain)
- **Untranslatable terms** — brand and product names against the glossary's do-not-translate list

Report results grouped by locale, layer and severity. A layer whose resource
format could not be read is `NOT ASSESSED — [reason]`. This mode is read-only.
Verdict: **COMPLETE** / **COMPLETE WITH GAPS** (a layer or locale not assessed) /
**NOT ASSESSED** (no resource files or no locale list).

---

## Phase 2D: Status Mode

- Count total localizable strings in the source table, **per layer**
- Per locale and layer: translated, untranslated, stale, in-review, approved
- Generate a coverage matrix:

```markdown
## Localization Status
Generated: [Date]
String freeze: [Active / Not yet called / Lifted]
Layers counted: [web, site, android, ios, backend templates — and those NOT ASSESSED]

| Layer | Locale | Total | Translated | Missing | Stale | Approved | Coverage |
|-------|--------|-------|-----------|---------|-------|----------|----------|
| [layer] | en (source) | [N] | [N] | [N] | [N] | [N] | [N]% |
| [layer] | ar | [N] | [N] | [N] | [N] | [N] | [X]% |

### Issues
- [N] hardcoded strings found in source code (run /localize scan)
- [N] strings exceeding length limits
- [N] placeholder mismatches
- [N] plural entries missing Arabic categories
- [N] orphaned keys
- [N] strings added after freeze (freeze violations)
```

> **Every cell above is a count you must take from the resource files —
> including the source row.** Do not pre-fill the source locale as `100%`: that
> asserts a result before counting. If a layer has no resource files, that
> layer's rows are **`NOT ASSESSED — no resource files found`**, not a row of
> zeros with a confident source line. If every layer is absent, the whole
> status is `NOT ASSESSED`.

This mode is read-only — no files are written. Verdict: **COMPLETE** /
**COMPLETE WITH GAPS** (some layers `NOT ASSESSED`) / **NOT ASSESSED** (all of them).

---

## Phase 2E: Brief Mode

Generate a translator context briefing for a translator or native-speaker
reviewer.

Read:
- `design/product-brief.md` — product, audience, tone
- `PRODUCT.md` / `DESIGN.md` at the repo root — brand voice and numerals policy
- `design/localization/` — existing glossary and style notes
- The source resource files and the extracted keys

Generate `production/localization/translator-brief-[locale]-[date].md`:

```markdown
# Translator Brief — [Product Name] — [Locale]

## Product Overview
[2–3 paragraphs: what the product does, who uses it (admins, end users), where it is used (Egypt, GCC)]

## Tone and Voice
- **Overall tone**: [e.g. calm, direct, professional; no hype]
- **Address**: [formal vs informal Arabic; dialect for UI voice — Modern Standard Arabic unless `design/localization/` says otherwise]
- **Product terms**: see glossary
- **Humour/idiom**: avoid; translate meaning, not words

## Glossary
| English term | Arabic term | Notes (do not translate / transliterate / approved variant) |
|---|---|---|

## Do Not Translate
- Product and brand names, API field names, code, units where the UI keeps Latin

## Placeholder Reference
| Placeholder | Represents | Example |
|---|---|---|
| `{workspaceName}` | The tenant's workspace name | "Nile Traders" |
| `{count}` | Integer quantity (plural rules apply) | 3 |

## Plurals
Arabic has six categories (zero, one, two, few, many, other). Provide every one for each counted noun.

## Numerals, Dates and Currency
[Numeral policy from `design/localization/`; currency shown as EGP / SAR / AED per the glossary; date format]

## Length Limits
Tight fields are marked in each key's note. Otherwise stay within ±30% of English.

## Delivery
Format: the resource format of each layer (per ADR). Return all six plural forms and keep placeholders unchanged.
```

If `design/localization/` has no glossary, the brief is drafted with
**provisional terms and says so on its first line**.

Ask: "May I write this translator brief to `production/localization/translator-brief-[locale]-[date].md`?"
Verdict: **COMPLETE** (written; **COMPLETE WITH GAPS** if the glossary was absent
and the brief says provisional) / **BLOCKED — write declined by user**.

---

## Phase 2F: Regional Review Mode

Spawn `localization-lead` via `Agent`. Ask them to audit copy, imagery and
formats for the target markets (default Egypt, Saudi Arabia, UAE; add others
from the locale list):

- **Language variant** — Modern Standard vs dialect expectations per market; spelling and vocabulary that differ; terms that read oddly or offensively in a market
- **Calendar and week** — weekend days (Friday–Saturday vs Friday–Sunday vs Saturday–Sunday per market), Hijri versus Gregorian display, week start, Ramadan/Eid considerations for scheduling, billing dates and support hours
- **Currency and pricing display** — EGP, SAR, AED: symbol/code placement, minor units, rounding, tax/VAT presentation (rates come from the pricing decision, not from this review)
- **Imagery and symbols** — gestures, religious or political symbols, people depictions, colours with strong associations
- **Legal and notices** — terms, privacy, cookie and consent text per market (hand legal wording to the owner; flag, do not draft)
- **Names, addresses and phone formats** — name order and length, address fields, mobile number formats and country codes, ID formats

Present findings as a table:

| Finding | Locale(s) / market | Severity | Recommended action |
|---|---|---|---|
| [Description] | [ar-EG / ar-SA / ar-AE] | [BLOCKING / ADVISORY / NOTE] | [Change / Flag for review / Accept] |

BLOCKING = must fix before shipping that locale or market. ADVISORY =
recommend change. NOTE = informational only. A market for which no native
reviewer was available is `NOT ASSESSED — no native review` for that market.

Ask: "May I write this review to `production/localization/regional-review-[date].md`?"
Verdict: **COMPLETE** / **COMPLETE WITH GAPS** (a market `NOT ASSESSED — no native
review`) / **BLOCKED — write declined by user**.

---

## Phase 2G: RTL Check Mode

Right-to-left support is mirroring, bidi and typography, not just translation.
Check per layer present in the product, and state the layers not checked.

**Web (`web/`, `site/`)**
- `lang` and `dir` set on the document and per locale; `dir="auto"` or `<bdi>`/directional isolates on user-generated and mixed Arabic/Latin text
- Logical CSS properties (`margin-inline-start`, `padding-inline-end`, `inset-inline`, `text-align: start`); a grep for physical properties (see `references/scan-patterns.md`) with raw counts
- Directional icons (chevrons, back arrows, progress bars, sliders, swipe/gesture direction) mirror; logos, media controls and numerals do not
- Fonts support Arabic with correct joining and ligatures; line height accommodates Arabic ascenders/diacritics; no letter-spacing on Arabic text
- Tables, charts and exports in RTL; focus order follows the visual order
- Astro site: `hreflang`, canonical and sitemap per locale; locale routes valid under static output

**Android (`mobile/android/`)**
- RTL support enabled in the manifest; `start`/`end` used everywhere; no `Alignment.Left/Right`, `paddingLeft` or `layout_marginLeft`
- Directional icons mirrored with `autoMirrored` where appropriate; per-app language handled per the ADR (not sourced in the stack reference — `NOT SOURCEABLE` without research)

**iOS (`mobile/ios/`)**
- `leading`/`trailing` used; `.left`/`.right` flagged; images that must flip declare it; Dynamic Type at the large sizes with Arabic text

**Strings and bidi (all layers)**
- No concatenation that assumes left-to-right order; placeholders inside translated sentences are isolated so a Latin value does not reorder the sentence
- Phone numbers, IDs, emails, URLs, amounts and codes are isolated as LTR runs inside RTL text
- Numeral policy (Arabic-Indic vs Western digits) is applied uniformly, including inputs, tables, charts and exports — the decision is recorded with `design-director`

**Evidence.** RTL is a run-and-observe obligation (`.claude/docs/run-and-observe.md`):
every screen touched has an Arabic screenshot retained in
`production/qa/evidence/`. A static check alone does not close this mode — say
so in the output and mark layers **NOT RUN (screenshots)** that were not
captured.

Flag BLOCKING (content unreadable or misleading without a fix) vs ADVISORY
(cosmetic). Ask: "May I write this RTL check report to `production/localization/rtl-check-[date].md`?"
Verdict: **COMPLETE** (every layer checked and its Arabic screenshots retained) /
**COMPLETE WITH GAPS** (a layer not present, or marked **NOT RUN (screenshots)**) /
**NOT ASSESSED** (no layer could be checked) / **BLOCKED — write declined by user**.

---

## Phase 2H: Formats Mode

Check number, date, time and currency handling.

- **Mechanism**: web uses the platform `Intl` APIs, Android and iOS use the platform formatters, the backend uses locale data — hand-built separators, `toFixed` for money, string-built dates and manual currency symbols are findings
- **Currency**: EGP, SAR and AED (and any other billed currency) render with the correct symbol/code placement and minor units from the catalogue; **money amounts are never converted client-side**; amounts in invoices and receipts match the billing source of truth; the currency of a tenant is not inferred from the UI locale
- **Numerals**: policy applied uniformly (see RTL mode); amounts are isolated as LTR runs when inside RTL text
- **Dates and times**: stored and transported as UTC ISO-8601, rendered in the user's or tenant's time zone; first day of week, calendar (Gregorian/Hijri) and 12/24-hour from locale data; relative times localized
- **Plurals, lists, ordinals, units** through the CLDR-based mechanism of each layer, not string joins
- **Fixtures**: a test renders sample values (large amounts, zero, negative, decimals, a date across a DST/zone boundary) in `ar` and `en`; its absence is a finding

Report as ADVISORY or BLOCKING (a wrong amount, currency or date on a customer
screen, invoice or receipt is BLOCKING and is routed to `pricing-billing-designer`
and `qa-lead`). This mode is read-only; sample outputs are shown, not written. Verdict:
**COMPLETE** / **COMPLETE WITH GAPS** (a layer or fixture not assessed) /
**NOT ASSESSED** (no layer could be checked).

---

## Phase 2I: Pseudo Mode

Pseudo-localization finds truncation, overlap and hardcoded strings before a
translator is involved.

1. Check each layer for the pseudo-locales: an **accented, ~40% longer** locale and an **RTL pseudo-locale**, wired in CI or as a documented local script. A layer without them: report `no pseudo-locale wired` and offer to specify the setup for `localization-lead`/`dev-tooling-engineer` (mechanism per the layer's ADR — not named from memory).
2. If wired, run it per the product's documented script (never a command written from memory) against the dev stack (`.claude/docs/run-and-observe.md`) and capture screenshots of the main journeys in both pseudo-locales into `production/qa/evidence/`.
3. Findings: text that stays un-accented (a hardcoded string), truncated or overlapping text, clipped buttons, layouts that did not mirror in the RTL pseudo-locale, concatenated fragments that scramble.
4. Verdict: **COMPLETE** with findings, or **NOT ASSESSED** — pseudo-locale not wired / stack would not start / screenshots not captured. An unrun pseudo pass is never reported as "no findings".

Ask before writing the findings: "May I write this to `production/localization/pseudo-[date].md`?"
(Declined: **BLOCKED — write declined by user**.)

---

## Phase 2J: Freeze Mode

String freeze locks the source strings so translation can proceed without the
source changing under the translators.

### freeze call

Check current freeze status in `production/localization/freeze-status.md`.

If already frozen:
> "String freeze is currently ACTIVE (called [date]). [N] strings have been added or modified since freeze. These are freeze violations — they require re-translation or an approved freeze lift."

If not frozen, present the pre-freeze checklist:

```
Pre-Freeze Checklist
[ ] All planned screens and emails for the release are implemented
[ ] Error messages, empty states, onboarding and notification text are complete
[ ] Billing text: invoices, receipts, dunning emails, plan names and limits are final
[ ] /localize scan shows zero hardcoded strings on shipped screens
[ ] /localize validate shows no placeholder or plural-count defects in the source (en)
[ ] Marketing strings (site pages, store listings) are final
[ ] Self-hosted installer and admin-facing messages are final
```

Use `AskUserQuestion`:
- Prompt: "Call string freeze now? This writes `production/localization/freeze-status.md` (Status: ACTIVE) and locks the source strings."
- Options: `[A] Yes — call string freeze now` / `[B] No — I still have strings to add`

On [B], Verdict: **COMPLETE — freeze not called** (the unticked checklist items are
listed; nothing is written). On [A] after the file is written, Verdict:
**COMPLETE — freeze ACTIVE**; if the write is declined, **BLOCKED — write declined
by user**.

If [A]: write `production/localization/freeze-status.md`:

```markdown
# String Freeze Status

**Status**: ACTIVE
**Called**: [date]
**Called by**: [user]
**Total strings at freeze**: [N per layer]

## Post-Freeze Changes
[Any strings added or modified after freeze are listed here by /localize extract]
```

### freeze lift

If the argument includes `lift` (`/localize freeze lift`): ask "May I update
`freeze-status.md` to LIFTED?", then (with `Edit`) set its Status to `LIFTED` and
record the reason and date. Warn: "Lifting the freeze requires re-translation and
re-review of all modified strings." Verdict: **COMPLETE — freeze LIFTED**; no
`freeze-status.md` or a status that is not ACTIVE: **NOT ASSESSED — no active
freeze to lift**; declined: **BLOCKED — write declined by user**.

Freeze does not apply to a `/hotfix`, where an Arabic and English string pair
may be added together and recorded in the hotfix record.

---

## Phase 2K: QA Mode

Localization QA runs after translations are delivered and before any locale
ships. It is not `validate` (completeness) — it is a structured, in-product
quality check on the running stack.

Spawn `localization-lead` via `Agent` with: the target locale(s), the list of
screens/flows (from `design/specs/` or `/content-audit`), the current
`/localize validate` report, and the regional review and RTL check reports if
they exist. Where a UI is touched, `accessibility-specialist` reviews screen
reader and reading-order behaviour in Arabic.

The plan covers:

1. **Functional string check** — every string displays without truncation, placeholder errors or encoding corruption, on web, Android and iOS, and in emails/SMS/push/receipts
2. **UI overflow and mirroring check** — Arabic and the pseudo-locales on the main journeys; screenshots retained
3. **Contextual accuracy** — a sample of at least 10% of strings reviewed in-product by a **native Arabic speaker**
4. **Formats check** — amounts, dates, numerals, plurals on real screens and in a generated invoice
5. **Regional review items** — all BLOCKING items resolved or accepted
6. **Store and legal text** — Play Console / App Store listings, privacy and terms in each shipped locale
7. **Self-hosted** — the bundle contains every locale resource and the installer/admin messages display in Arabic and English

Output a QA verdict per locale:

```
## Localization QA Verdict — [Locale]

**Status**: PASS / PASS WITH CONDITIONS / NOT ASSESSED / FAIL
**Reviewed by**: localization-lead (+ native reviewer: [name or NOT PROVIDED])
**Date**: [date]
**Checks not run**: [each, with reason — or "None"]

### Findings
| ID | Area | Description | Severity | Status |
|----|------|-------------|----------|--------|
| LOC-001 | UI Overflow | "Settings" button text overflows on [Screen] | BLOCKING | Open |
| LOC-002 | Translation | [Key] is literal — sounds unnatural | ADVISORY | Open |

### Conditions (if PASS WITH CONDITIONS)
- [Condition — must resolve before ship]

### Sign-Off
[ ] All BLOCKING findings resolved
[ ] producer approves shipping [Locale]
```

First match wins: **FAIL** if any BLOCKING finding is open; else **NOT
ASSESSED** if a check could not run — the checks are in-product, so a locale
nobody has exercised on the running stack, with no native reviewer, or whose
translations were not delivered cannot pass on resource files alone; name each
check that did not run; else **PASS WITH CONDITIONS** if conditions remain; else
**PASS**. NOT ASSESSED outranks both pass values — an unexercised locale has not
passed — and ranks below FAIL, so an open BLOCKING finding is never buried
behind it.

Ask: "May I write this localization QA report to `production/localization/loc-qa-[locale]-[date].md`?"

**Gate integration**: at `workflow: full`, the Hardening → Release gate requires
PASS or PASS WITH CONDITIONS for every locale being shipped (recommended at
`standard`; dropped at `minimal`, though Arabic and English remain required for
a bilingual product). A FAIL blocks release for that locale only. A NOT ASSESSED
locale has not passed — its QA did not run.

---

## Phase 3: Rules and Next Steps

**Checkpoint.** When the mode wrote a file or ended in a QA verdict
(PASS / PASS WITH CONDITIONS / FAIL / NOT ASSESSED), update
`production/session-state/active.md` per `.claude/docs/checkpoint-handoff.md`:
Current task `/localize <mode> <target> — <verdict>`, Next step = the next
command in the Recommended Workflow below, plus Blocked on / Files in progress /
Open questions; append the Notes line. A declined write still updates the
checkpoint with the blocker.

### Rules
- English (`en`) is the source locale unless the locale list says otherwise; Arabic is a required target for every customer-facing feature
- Every resource entry carries a translator note; sentences are single messages with named placeholders
- Never modify translation files directly in a mode that is read-only; generate diffs for review
- Machine translation is a draft at most; a native Arabic speaker approves before ship
- String freeze is called before strings go for translation — never translate a moving target
- RTL is designed in from the first screen — retrofitting is expensive
- Backend responses carry stable error `type`/`code` and structured parameters; sentences are composed on the client
- No user-facing text, PII or tenant data is placed in telemetry; no translations are fetched from a hosted service by a self-hosted install
- Never name a library, resource format, flag or version from memory — the ADR and `docs/research/i18n.md` decide; a layer without them is `NOT ASSESSED`

### Recommended Workflow

```
/localize scan            → find hardcoded strings per layer
/localize extract         → build resource entries
/localize pseudo          → expose truncation and hardcoded text early
/localize freeze          → lock source before translation
/localize brief           → translator briefing and glossary
[Translate + native review]
/localize validate        → check returned translations
/localize formats         → numbers, dates, currency
/localize regional-review → Egypt / GCC issues
/localize rtl-check       → mirroring, bidi, fonts, screenshots
/localize qa              → full localization QA pass
```

After `qa` returns PASS or PASS WITH CONDITIONS for every locale you ship,
include the QA report paths when running `/gate-check release`.

## Collaborative Protocol

Question → Options → Decision → Draft → Approval. Read-only modes write
nothing. Every file written is named in a "May I write" question. A layer,
locale, check or reviewer that did not run is named in the output as not run —
it is never folded into "no findings".
