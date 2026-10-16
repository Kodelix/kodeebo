---
name: release-notes
description: "Customer-facing release notes per product and version, in English and Arabic, from changelogs and git history. Covers hosted and self-hosted editions, upgrade notes and breaking changes for self-hosted admins, and responsible wording for security fixes."
argument-hint: "[version] [--edition hosted|self-hosted|android|ios|web|all] [--style brief|detailed|full]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit(production/session-state/active.md), AskUserQuestion, Bash(date *), Bash(git log *), Bash(git tag --list), Bash(git tag --list *), Bash(git tag --sort=*), Bash(git for-each-ref *), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Bash(bash "*/.claude/skills/release-notes/../../hooks/yaml-helper.sh" resolve_config *), Bash(git log)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,docs.density,stack`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Release Notes

Customer-facing notes for one product version: what changed, in the customer's
words, in **English and Arabic**, for every edition that ships it. The
developer changelog (`/changelog`) is the input; this skill is the translation
into customer language. Structure comes from
`.claude/docs/templates/release-notes.md`.

The reader is a customer admin or end user, never an engineer. Two readers need
extra care: the **self-hosted admin**, who must decide whether and how to
upgrade, and the **customer who is exposed by a security fix**, who must be told
enough to act and not enough to attack.

---

## Provenance check — before reading any history

**Confirm the history you are about to read belongs to THIS product.** Run this
before Phase 2 and stop if it fails.

1. Sample the recent log: `git log --oneline -20`. **If it is empty or git is
   unavailable, skip this check** — there is nothing to classify, and Phase 2's
   no-changelog-data branch is the right stop.
2. **Classify every commit in the range, one at a time**, into exactly one of:
   - **Product** — changes what a customer experiences or integrates with:
     features, plan or limit changes, UI, API and webhook behaviour, the
     self-hosted bundle, a bug in any of those.
   - **Studio / maintenance** — changes the studio itself or internal tooling:
     subjects naming skills, hooks, agents, CI configuration, test plans, the
     studio's own docs, dependency bumps with no customer effect. **Excluded
     from customer notes, but not a reason to stop.**
   - **Unclear** — treat as maintenance. A commit you cannot confidently place
     is not one to write customer copy from.
3. Then decide from the counts:
   - **At least one Product commit** → proceed, using **only** those. Say how
     many of how many you used, so the reader can see the filter ran.
   - **Zero Product commits** → stop with the message below, giving the count
     (0 of how many).

> **Filter per commit; do not stop on a repo that merely contains maintenance
> work.** Every product repo built with the studio accumulates commits touching
> hooks, CI and skills. The danger is not that they exist; it is that they get
> **rendered as customer-facing copy**. Excluding them addresses that exactly.

Corroborate cheaply: the Product commits should name features that appear in
`design/specs/`, `design/product-brief.md` or the code roots
(`resolve_code_root`). If they name a product those never mention, that is the
real wrong-history signal — stop.

> "The git history in this repo does not appear to belong to [product]: 0 of the
> [N] recent commits are Product commits. The recent commits describe [what they
> actually describe]. I cannot generate release notes from it — point me at the
> right history, or supply the change list directly."

Verdict: **BLOCKED** — stop here without generating notes.

**Why this is a hard stop.** A batch of studio-internal commits once produced
customer copy reading *"Fixed an issue where your session could be lost on
login"* — a hook timeout rendered as a product fix for a product with no such
bug. It was fluent, plausible and entirely false. Only this check catches it.

---

## Phase 1: Parse Arguments

- `version`: the release version to write notes for (e.g. `2.4.0`). If none is
  given, ask before proceeding.
- `--edition`: `hosted`, `self-hosted`, `android`, `ios`, `web` or `all`.
  Default: every edition the version actually shipped to. Read that from
  `project.yaml` (`distribution`, `deploy`, `stack`) and the release checklist
  `production/releases/[product]-[version].md` (what `/release-checklist` writes) if
  present; the previous release tag comes from `git tag --list --sort=-v:refname`. **If you
  cannot tell which editions shipped, ask — never assume "all".**
- `--style`: `brief` (bullets), `detailed` (with context), `full` (with the
  team's commentary). Default: `detailed`.

Editions are different audiences: hosted customers get the change the moment it
deploys; self-hosted admins choose when to upgrade; store users see only the
store "What's new" text. One version can need several outputs (Phase 4).

---

## Phase 2: Gather Change Data

- Read the product `CHANGELOG.md` entry for the version (the internal changelog
  `/changelog` writes) and, if present, the customer-facing draft
  `production/releases/whats-new-[version].md` (its other output) — these are the
  inputs, since `/changelog` writes nothing under `production/releases/[version]/`.
- Run `git log` between the previous release tag and this one as the fallback.
- Read sprint plans/retros in `production/sprints/` for context.
- Read the pricing changes in `design/specs/` or `business/pricing/` **only for
  what was approved** — never announce a plan or price change that is not
  approved and effective-dated.
- Read QA bug-fix records and any `production/hotfixes/` entries for this version.
- Read `docs/architecture/` ADRs and `contracts/` diffs for API changes
  (deprecations carry a `Sunset` date; see `.claude/docs/api-standards.md`).
- For self-hosted: read migration files and `deploy/self-hosted/` changes
  (new/renamed/removed settings, minimum upgrade-from version, licence format).

**If no changelog data is available** (no `CHANGELOG.md` entry, no
`production/releases/whats-new-[version].md`, and git log is empty or unavailable):

> "No changelog data found for [version]. Run `/changelog [version]` first to
> generate the internal changelog, then re-run `/release-notes [version]`."

Verdict: **BLOCKED** — stop here without generating notes.

---

## Phase 2b: Detect Tone Guide, Glossary and Template

**Tone guide** — before drafting, check for voice guidance in this order:
`PRODUCT.md` (repo root, brand voice), `design/localization/` (glossary and
style notes), `docs/RELEASE-NOTES-STYLE.md` if it exists. Extract and apply
any tone instructions. If none is found, default to: plain, calm, specific,
confident without hype; what the customer can now do, not what the team changed.

**Glossary** — read `design/localization/` for the approved Arabic product
terms (plan names, feature names). **If the glossary is absent, the Arabic
text is drafted with provisional terms and the report says so** (see Phase 5).

**Template** — use `.claude/docs/templates/release-notes.md` as the structure.
Omit a section that has no entries rather than leaving it empty, **except**
Security and Upgrade Notes, which are omitted only after the Phase 3 checks
confirm there is nothing to say (and the report states that).

---

## Phase 3: Categorize and Translate

Categorise every change into:

- **What's New** — features customers can do something with
- **Plan & Pricing Changes** — plans, limits, quotas, prices, effective dates
- **Behaviour Changes** — existing things that now work differently
- **Improvements**, **Bug Fixes** (critical, functional, UI, platform-specific)
- **Security** — see below
- **Performance Improvements** — only what a customer would notice
- **API & Integration Changes** — added, deprecated (with `Sunset` date),
  removed/breaking (with migration steps)
- **Upgrade Notes (Self-Hosted)** — see below
- **Known Issues**

Translate developer language into customer language:

- "Refactored invoice aggregation" → "Invoices for annual plans now generate faster"
- "Fixed null deref in the webhook retry worker" → "Fixed an issue where some webhook deliveries were not retried"
- "Added index on tenant_id, created_at" → "Reports load faster on large workspaces"
- Remove purely internal changes (refactors, test-only, CI, dependency bumps with no customer effect).
- Preserve specific numbers for limits and prices (seats: 5 → 10; EGP 499 → EGP 549), always with **who is affected** and **from when**.
- Never expose ticket IDs, sprint numbers, internal service names, table names or stack-trace text.

### Security entries — responsible disclosure

Security fixes are described so that customers can act and attackers cannot
learn the weakness. Rules:

1. **Read the security record first** (`docs/architecture/` threat model,
   `production/hotfixes/` entry, appsec advisory draft). If a fix is
   security-related but **no advisory or `security-lead` clearance exists, do
   not write the entry** — list it in the report as *held pending security-lead
   clearance* and mark the Security section `NOT ASSESSED`.
2. **Never publish before the fix is available to every edition that is
   affected.** A hosted fix is live the moment it deploys; a self-hosted fix is
   live only when the signed bundle is downloadable and upgrade notes exist. If
   self-hosted customers are affected and their patch is not yet released,
   hold the entry — publishing it advises attackers about instances customers
   cannot yet fix.
3. State: **severity, who is affected (editions/versions), the action required,
   and the fixed version.** Reference the advisory/CVE ID once the fix is
   available to all.
4. Do **not** include: exploit steps, vulnerable endpoint paths or parameter
   names, payload examples, internal component names, or how it was found.
   "Fixed an issue that could let a signed-in user view another workspace's
   data" is acceptable once fixed everywhere; "the `/v1/exports/{id}` endpoint
   did not check the tenant" is not.
5. Cross-tenant data exposure, credential exposure or a licence-bypass fix is
   always routed to `security-lead` for wording sign-off (gate
   `SL-RELEASE-SECURITY` is the release-level check; this is the wording check).
6. Credit reporters only with their permission.

### Self-hosted upgrade notes and breaking changes

Self-hosted admins upgrade on their schedule, offline, often across several
versions. For every self-hosted release write the Upgrade Notes block with:

- **Minimum upgrade-from version** and the upgrade path if a version must be
  skipped through (read the upgrade matrix from `release-manager`'s artefacts).
- **Migrations and downtime**: automatic or manual, estimated downtime,
  whether a backup is required first (it always is; say so).
- **Config changes**: new, renamed, removed settings (from `.env.example` /
  `deploy/self-hosted/` diffs), with defaults.
- **Licence**: any change to licence format, update-eligibility window or
  activation behaviour.
- **Rollback**: supported or not, and exactly what to restore.
- **Breaking changes**: each with who is affected, the migration steps, and the
  deprecation history.
- **Component changes** only as they affect the admin (for example "the bundled
  cache is Valkey") — never mention components excluded from the customer
  bundle by `docs/ROADMAP.md` licence decisions L1–L4 as if they ship.

**If the self-hosted edition shipped this version and migration/config/licence
information cannot be sourced from the repo, do not guess.** Write the
Upgrade Notes heading with `NOT SOURCEABLE — [what] is not covered by
[path]`, mark that section `NOT ASSESSED`, and let it set the verdict to
**NOT ASSESSED** (Phase 7): notes for an edition whose upgrade path nobody could
source are not final.

Apply the same clarity to **hosted**: if a change needs customer action (new
webhook IP range, API field removal, SSO config), it is an *Action required*
line, not an improvement bullet.

---

## Phase 4: Generate the Notes

Produce, for the requested editions:

| Output | Audience | Shape |
|---|---|---|
| Full notes (`all` editions) | Website / in-app announcement / email | Template sections at the chosen `--style` |
| Self-hosted notes | Customer admins | Full notes + Upgrade Notes block + checksums/signature note |
| Store "What's new" (Android, iOS) | Store users | Within store limits; no promises of unreleased work; reviewed against the store listing language |
| In-app headline | All users | One sentence, the `Headline` block |

Styles:

- **Brief** — Headline + bullets under New / Changes / Fixes / Security / Known Issues.
- **Detailed** — the template sections with 2–4 sentences per major feature.
- **Full** — Detailed plus a short team commentary (first-person team voice, no
  internal names; ask the user which decisions they want explained).

### Languages

Every output exists in **English and Arabic** unless the user explicitly limits
it. Arabic is **written for Arabic readers, not translated word for word**:

- Modern Standard Arabic by default unless `design/localization/` sets a dialect for UI voice.
- Right-to-left document: write the Arabic file as its own file with `dir="rtl"`
  guidance for HTML delivery; keep Latin product names, version numbers, code
  and units as left-to-right runs and do not break them across lines.
- Numerals follow the locale decision in `design/localization/`; default to the
  convention the product UI uses so the notes match what customers see.
- Currency and dates: EGP / SAR / AED amounts with the currency code placed per
  the glossary; dates in the locale's calendar format; state the timezone for
  effective dates.
- Plural forms follow Arabic's six categories — avoid constructions that need
  counted nouns where a number-free phrasing works.
- UI labels are quoted exactly as they appear in the Arabic UI, not re-translated.
- Mark the Arabic as **draft pending native review** until `localization-lead`
  (or a named native reviewer) has signed it off. Never ship unreviewed Arabic
  as final.

---

## Phase 5: Review the Output

Check the generated notes for:

- No internal jargon, ticket IDs, sprint numbers, service or table names
- Plan/limit/price changes: before → after, who is affected, effective date, what to do
- Bug fixes describe what the customer experienced and what is correct now, not the technical cause
- Security entries pass every rule in Phase 3; none include exploit detail
- Self-hosted Upgrade Notes complete, or `NOT SOURCEABLE` stated
- Hosted/self-hosted/store statements are true for the editions listed — a
  feature that exists only on hosted is labelled so
- No commitments in "Coming Next" (no dates, no unapproved plans)
- English and Arabic carry the same facts (diff the lists of changes, numbers and dates between the two)
- Tone matches the brand voice

For wording that needs a second reader, name the agents: `customer-success`
reviews customer clarity and tone; `localization-lead` reviews Arabic;
`technical-writer` reviews the self-hosted upgrade steps; `security-lead`
clears security entries. A review that was not requested is reported as **not
run**, never as passed.

---

## Phase 6: Save

Present the completed notes with: change counts by category, the commits
excluded (for the user to review), the security entries held (if any), and the
review status of each language.

Ask: "May I write these release notes to
`docs/release-notes/[version].en.md` and `docs/release-notes/[version].ar.md`,
with archive copies in `production/releases/[version]/release-notes.*.md`?"
(Self-hosted: also `production/releases/[version]/upgrade-notes.*.md` if kept separately.)

If yes, write the files, creating directories as needed. If no, write nothing and
close with `BLOCKED — write declined by user` (the drafts stay in conversation,
marked not saved).

---

## Phase 7: Verdict and Next Steps

Verdicts:

- **COMPLETE** — notes generated and saved; every section either filled or confirmed empty
- **CONCERNS** — generated and saved, but one or more of: Arabic not natively reviewed, edition scope unconfirmed, a requested reviewer not run
- **NOT ASSESSED** — a section could not be assessed (Security entries held for clearance, Upgrade Notes `NOT SOURCEABLE` for a shipped self-hosted edition); say which section and why
- **BLOCKED** — wrong history, no change data, or `write declined by user`

Precedence: `BLOCKED`, then `NOT ASSESSED`, then `CONCERNS`, then `COMPLETE`.
`NOT ASSESSED` outranks `CONCERNS` and `COMPLETE`: notes with an unassessed Security
or Upgrade Notes section are not final.

**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/release-notes <version> —
<verdict>`, Next step = the first next step below, plus Blocked on / Files in
progress / Open questions; append the Notes line. NOT ASSESSED, BLOCKED or a
declined write still updates the checkpoint with the blocker.

Next steps:

- `/release-checklist` — verify the other release gates before publishing
- Publish only after `release-manager` confirms the artifacts exist for every edition named in the notes
- Share the drafts with `customer-success` for tone review before sending
- Security entries: confirm advisory publication timing with `security-lead`

## Collaborative Protocol

Question → Options → Decision → Draft → Approval. Notes are shown in full and
approved before any write; the user decides what is excluded, the style, and
the security wording. Nothing is published by this skill — it writes drafts to
disk only.
