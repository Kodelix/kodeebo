# project.yaml — Effects Map

> ## READ ONE SECTION, NEVER THIS WHOLE FILE
>
> This document is large, far more than any one lookup needs. It is organised as
> one section per setting, headed `## <key>`, so a reader can take only the
> section it wants.
>
> **So opening it whole costs many times what you need.** To look up a setting:
>
> ```
> Grep pattern="^## modes.review_mode" path=".claude/docs/effects-map.md" -A 40
> ```
>
> Read the section for your key and stop. The same rule the skills already apply
> to their own reference files — `/gate-check` loads only the gate file for the
> target phase and says "never load the others" — applies here.
>
> Cite a section of this document, never the whole file. A pointer such as "see
> effects-map.md for the full schema" invites a full read of a file this size,
> and the cost of accepting that invitation is silent. Name the `## <key>`
> section you need instead.

This document defines what each `project.yaml` setting actually does across
every skill, hook and script that reads it. It is the tracked, authoritative
reference, and it describes the code in `.claude/hooks/yaml-helper.sh` as it is:
where the two could disagree, the helper is the source of truth for **values,
defaults and the local-override whitelist**, and this file is the source of
truth for **what each value changes**.

**Purpose:** When a skill reads a setting, this document says what each value
means for that skill's behaviour. Whoever adds a setting or changes how a skill
responds to one updates this file in the same change.

**Format per setting:**
- Priority chain — which source wins when several are present
- Per-value intent — what the value means in plain terms
- Reader table — exactly which skills, hooks and scripts read it and what changes

**Coverage scope:** 66 studio skills are mapped: the 64 that run
`resolve_config --keys …` as their bootstrap line (including `/gate-check`,
`/skill-test` and `/skill-improve`), plus `/start` (which writes config) and
`/settings` (which reads and writes all of it). The vendored `impeccable` skill
reads no setting. Every reader list below is **derived from
the skills**, not copied from a template: regenerate it with

```
grep -h '^!`.*resolve_config' .claude/skills/*/SKILL.md
grep -rn '<dotted.key>' .claude/skills .claude/hooks .claude/scripts .claude/docs
```

and treat a list as the verified floor, not a ceiling — a skill that reads a
value through a helper function rather than naming the key would not appear.
A key that is not documented in this file is not part of the SaaS schema: an
unknown key in `project.yaml` is simply never read.

**Local override pattern:** `project.yaml` is committed to git as the shared
product config. Per-developer overrides live in `project.local.yaml`
(gitignored). Priority chain across all settings: `project.local.yaml` →
`project.yaml` → legacy plain-text mirror → `modes.rigor` expansion → hardcoded
default. The expansion step applies only to the six knobs `rigor` fronts
(`modes.workflow`, `docs.density`, `qa.level`, `modes.story_granularity`,
`modes.review_mode`, `team.size`), which for that reason have **no** hardcoded
default — see the `modes.rigor` section. The local file is consulted only for
the 15 whitelisted keys below.
**Secrets do NOT belong in either file — use environment variables.** See
"Local Override Pattern" for the full design.

**Reserved settings:** a setting documented here that nothing reads carries a
banner (see "RESERVED banners" below). Today there are three: `testing.strict.visual`,
`core.repo` and `features.token_budget_warn_at`.

---

## Local Override Pattern — `project.local.yaml`

The `project.local.yaml` file lets each developer override specific settings for
their own use without affecting the team. The file is gitignored and never
committed.

### How it works

Priority chain (every setting on the whitelist): `project.local.yaml` →
`project.yaml` → legacy mirror → `modes.rigor` expansion → hardcoded default.

If a whitelisted setting is present in `project.local.yaml` and passes enum
validation, that value wins. If absent (or invalid), the value from
`project.yaml` is used, and so on down the chain. A key that is **not** on the
whitelist is never read from the local file.

> **Read scope equals write whitelist.** Anything `/settings --local` may write
> is also read during resolution (`_yaml_helper_local_read_scope` is the same
> list as `_yaml_helper_locally_overridable`). If the read scope were narrower,
> `/settings --local` would store a value that every skill then ignores.

---

### Deep merge semantics

When both files set a nested value, only the explicitly-set key is overridden.
Sibling keys in the same block are preserved — each leaf is resolved
independently from its own file.

Example:

`project.yaml`:
```yaml
testing:
  strict:
    logic: true
    integration: true
    performance: false
```

`project.local.yaml` (sparse override):
```yaml
testing:
  strict:
    logic: false
```

Effective config seen by skills: `logic: false, integration: true,
performance: false`. Only the explicitly-set `logic` key is overridden; sibling
keys come through from `project.yaml`.

---

### Whitelist — which settings can be locally overridden

Only personal-experience settings can be locally overridden. Project-wide facts
(stack, tenancy, stage, what is required on disk) are locked to `project.yaml`
because divergence between developers would break team coordination.

The rule for deciding which side a setting belongs on:

> **If a setting affects what artifacts exist or what they look like on disk,
> or which stack and agents a story is routed to, it must be locked to
> `project.yaml`. If a setting only changes your personal experience (how much
> AI review you get, whether you get prompts, whether a failing check blocks
> your local work), it can be locally overridden.**

**Locally overridable** — the 15 keys in `_yaml_helper_locally_overridable`:

| Setting | Why local override makes sense |
|---------|-------------------------------|
| `modes.review_mode` | How much director review you personally want |
| `modes.automation` | How often the AI prompts you |
| `modes.automation_always_ask` | Your personal safety categories |
| `team.size` | Which agents are active in your runs (review depth differs, artifacts do not) |
| `testing.strict.logic`, `.integration`, `.contract`, `.security`, `.performance`, `.visual`, `.ui`, `.config` (eight keys) | Whether a failing check blocks your local work (CI still enforces the `project.yaml` values) |
| `performance.enforce` | Whether budget breaches block your local work (CI enforces the project value) |
| `features.session_state` | Your session-tracking preference |
| `features.token_budget_warn_at` | Your personal cost threshold (reserved — see its section) |

**Locked to `project.yaml`** (project-wide — would create artifact or routing
divergence if local):

| Setting | Why it must be project-wide |
|---------|----------------------------|
| `schema_version`, `framework.*` | File metadata, not preferences — **exempt from the report below**: a `project.local.yaml` carrying `schema_version: 1` is correct as written |
| `project.name`, `project.stage` | Product identity and lifecycle position |
| `modes.rigor` | Fronts the six knobs below — locked for the same reason four of them are |
| `modes.workflow` and `workflow_overrides` | Decide which sections and documents are required on disk |
| `modes.story_granularity` | Decides how big stories are in the repo — the team must be consistent |
| `docs.density` | Decides how deep authored docs are — the team must produce consistent docs |
| `qa.level` | Decides what test evidence a story must carry on disk |
| `stack.*`, `deploy.target`, `distribution.model`, `tenancy.model` | Whole team routes to the same leads, references and isolation tests |
| `layout.code_roots` | Decides which directories every hook and skill scans |
| `core.*` | The pinned shared-core track, repo, version and modules |
| `accessibility.target` | A product commitment, project-wide |

> **A locked key written into `project.local.yaml` by hand is reported, not
> swallowed.** `/settings --local` refuses to write one, but the file is meant to
> be hand-edited and that path has no guard: `modes.rigor: full` there is a real
> key with a legal value, so enum validation passes it — and then resolution never
> consults the local file for that path, so the setting vanishes with no error.
> Every value check validated the **value**; nothing validated the **location**.
> `validate_local_scope` in `yaml-helper.sh` names such keys on `resolve_config`'s
> `notes:` line (`local: not locally overridable, ignored — modes.rigor (move to
> project.yaml or delete)`). It **warns and never reconciles**: it does not edit
> the file, does not begin honouring the key, and does not change resolution — a
> locked setting decides which artifacts exist, so applying one quietly would
> produce exactly the divergence this table prevents. A typo'd key in the local
> file is caught by the same check, since it is not on the whitelist. A clean file
> stays silent.

---

### `/settings --local` flag behaviour

```
/settings modes.workflow=minimal              → writes to project.yaml (team-wide)
/settings --local modes.automation=autonomous → writes to project.local.yaml (just you)
```

**Behaviour rules:**

- Default (no flag): writes to `project.yaml`
- `--local` flag: writes to `project.local.yaml` (creates it if absent)
- `--local` on a locked setting → refusal, nothing written:
  > *"`<setting>` cannot be locally overridden — it's a project-wide setting.
  > Use `/settings <setting>=<value>` (no `--local`) to change it for the whole team."*
- Both write paths validate the value first (`validate_enum_value`) and refuse an
  invalid one with `Invalid value '<v>' for '<key>'. Allowed: …`.
- Both write paths, and both view modes, mark a **reserved** key (see below), so a
  setting nothing reads never looks like one that works.
- `/settings --local` with no `project.yaml`: *"Cannot create `project.local.yaml`
  — `project.yaml` is missing. Run `/start` to create one first."*
- Writing a key to `project.yaml` while the same key is overridden in
  `project.local.yaml` shows the override in the view so you can see which one wins.

---

### Schema validation on read

When skills or hooks read either file:

| Issue | Behaviour |
|-------|-----------|
| Unknown key in `project.yaml` (typo or stale setting) | **Not detected.** Resolution never reads it. (Unknown-key detection is not implemented; do not assume a typo is flagged.) |
| Non-whitelisted key in `project.local.yaml` (locked key or typo) | Named on `resolve_config`'s `notes:` line by `validate_local_scope`, and ignored. Does not block. |
| Invalid value for an enum-typed key (e.g. `automation: chaotic`) | The invalid value **does not win**: the chain continues to the next source and ultimately the default, and the rejected value is named on `notes:` (`… is not a valid value (expected: …) — ignored, chain continued`). `session-start.sh` prints the errors for both files. `/settings` refuses to write it. |
| Tab-indented line | Reported with line numbers; those lines are invisible to the parser, so the settings on them fall back to defaults. Replace the tabs with spaces. |
| Value that has no enum (integer, list, free text — e.g. `layout.code_roots`, `core.version`, `stack.messaging`, a `system_overrides` tier) | **Not type-checked.** The value is used as written. |
| Wrong shape (a list where a scalar belongs) or a duplicate key | Resolves to empty (wrong shape) or last-occurrence-wins (duplicate), with **no note**. |

`resolve_config` always exits 0 and always emits a complete block; it never
aborts a skill on a bad config. A skill treats a rejected value as "the default
applies", and `/settings` shows the effective value.

---

### Creation and error handling

| Scenario | Behaviour |
|----------|-----------|
| Fresh checkout of the studio template | `project.yaml` ships with the template. `/start` edits it (or creates a minimal one if it is missing). It does NOT create `project.local.yaml`. |
| `/settings --local <x>=<y>` when the local file does not exist | Creates `project.local.yaml` containing just that setting. |
| `project.local.yaml` exists but `project.yaml` does not | `resolve_config` and `session-start.sh` report on `notes:`: *"project.local.yaml exists but project.yaml is missing — run /start to create one. Local overrides require a base."* Defaults apply. |
| Both files exist | `project.yaml` is read first and `project.local.yaml` merged on top, per leaf, for whitelisted keys. Normal operation. |
| Both files set the same whitelisted key | `project.local.yaml` wins. No prompting. |
| `project.yaml` exists but is empty | Defaults apply; `notes: project.yaml is EMPTY`. Distinct from absent on purpose — a truncated write or an interrupted `/setup-stack` looks like this. |

---

### Two-developer clash scenarios — and why the whitelist prevents them

**File-level conflict (`project.yaml`):** Standard git merge conflict. Each
developer's `project.local.yaml` is gitignored and never collides with
another's. Normal git workflow handles team-wide changes.

**Logical inconsistency (prevented by the whitelist):**

> Sarah sets `modes.workflow: minimal` locally to skip spec sections. She does
> not write the 5 required sections for her feature because her local mode does
> not require them. Mike runs `/gate-check` with the team's `project.yaml`
> value, `standard`; the gate sees the missing sections and fails.

This cannot happen because `modes.workflow` is locked to `project.yaml`. The
same goes for `qa.level`, `docs.density`, `stack.*`, `tenancy.model`,
`layout.code_roots` and every other setting that affects what artifacts exist or
where a story is routed.

Personal-experience settings (`automation`, `review_mode`, `team.size`,
`testing.strict.*`, `performance.enforce`) can diverge freely without affecting
anyone else.

---

### Stricter reviewer reviewing a looser reviewer's work

A common worry: "what if my teammate has stricter review settings than me? Will
their `/gate-check` or `/spec-review` flag things in my work?" The answer depends
on which kind of difference you mean:

**Different review depth, same project requirements (HEALTHY):**

- Teammate A: local `review_mode: full`, `automation: collaborative`, `testing.strict.logic: true`
- Teammate B: local `review_mode: solo`, `automation: autonomous`, `testing.strict.logic: false`
- Both bound by the same `project.yaml`-locked settings (e.g. `workflow: standard`, `qa.level: standard`)

B writes a feature spec that meets `workflow: standard` (all 5 required sections
present). B's `/spec-review` runs at `review_mode: solo` — phases 1–4 only, no
specialists spawned. B moves on. Later A reviews the same spec at `full`, which
adds specialist delegation, and finds polish opportunities and edge cases B's
lighter review missed. A files findings as PR comments or follow-up issues. B
addresses the ones that matter.

**This is normal team collaboration.** The artifacts on disk are the same; only
review depth differs. Nothing here creates project-state divergence.

**Different requirements (PREVENTED by the whitelist):**

If `qa.level` were locally overridable:

- B sets `qa.level: minimal` locally. B's stories carry no test volume.
- B's `/story-done` accepts the story without it. Story marked Complete on disk.
- A pulls. A's `qa.level: standard` requires the evidence; A's `/story-done`
  would have rejected the story.
- A's next `/gate-check` fails because evidence is missing across several of B's
  "Complete" stories.

That is the artifact divergence problem. `qa.level` is locked to `project.yaml`;
the team agrees together on what is required, and individuals override only their
personal experience, never the team's standards.

| Difference type | Outcome |
|----------------|---------|
| Different review depth (`review_mode`, `team.size`) | The stricter reviewer surfaces more findings — healthy. Artifacts unchanged. |
| Different local strictness on failures (`testing.strict.*`, `performance.enforce`) | The stricter developer's local `/story-done` blocks earlier — they fix it locally. CI uses the `project.yaml` values, so the team bar stays. |
| Different artifact requirements (`workflow`, `qa.level`, `docs.density`, …) | **Cannot happen — these are locked.** The team agrees once in `project.yaml`. |

---

### CI behaviour

CI environments have no `project.local.yaml` — the file is gitignored and never
present in a fresh clone. CI therefore always runs against `project.yaml`:
strict project standards, no developer-specific overrides.

| Setting | Local value for fast iteration | CI value (`project.yaml`) |
|---------|--------------------------------|---------------------------|
| `modes.review_mode` (locally overridable) | `solo` for one developer | whatever the project sets, or the `modes.rigor` value |
| `testing.strict.logic` (locally overridable) | `false` for fast WIP commits | `true` (failing tests block) |
| `performance.enforce` (locally overridable) | `warn` locally | `block` when the team sets it — the CI value is the team's |
| `modes.automation` (locally overridable) | `autonomous` for solo flow | mostly a no-op on CI, which asks no questions |

A developer can iterate locally with relaxed gates, but CI enforces the team's
`project.yaml` values regardless of any individual's local config.

---

### Secrets — never in either file

`project.yaml` and `project.local.yaml` are for **preferences and
configuration**, never for **secrets**. API keys, tokens, signing keys and
credentials belong in:

- **Environment variables** (preferred for CI and production)
- **A `.env` file** (gitignored, local dev; `.env.example` documents the names without values)
- **A secret store** (when the platform provides one)

When a skill or story needs a provider credential (a payment, SMS or email
provider), it reads it from the environment, not from `project.yaml`.
`project.yaml` records which **stack** and **edition** the product is, never the
key for any provider it calls.

---

### RESERVED banners

A setting that is documented and settable but that **no skill or hook reads**
carries a banner directly under its `## ` heading. `/settings` (Phase 1b)
derives the reserved set from those banners and marks the key in view-one,
view-all and both write paths. The banner format is exactly this (shown indented
here so the derivation, which matches only a banner at the start of a line,
finds the real ones and not this example):

```text
  > ### RESERVED - NOT IMPLEMENTED
  >
  > **No skill or hook reads this setting. Setting it has no effect.** …
```

A banner needs its `## <key>` heading within the 14 lines above it, and one
heading may name two keys joined by " and ". Remove the banner in the same change
that gives the key its first reader. Today the reserved settings are
`testing.strict.visual`, `core.repo` and `features.token_budget_warn_at`.

---

## modes.review_mode

**Controls:** How many director and specialist gates are spawned during skill execution
**Values:** `full`, `lean`, `solo`
**Default:** *none* — supplied by `modes.rigor` (`minimal`, the default, yields `solo`; `standard` yields `lean`; `full` yields `full`)
**Set by:** `/settings`. `/start` and `/adopt` never write it — unset, it follows `modes.rigor`. A legacy `production/review-mode.txt` is still read, above the expansion
**Read by:** every skill whose bootstrap requests `review_mode` (current list: `bash .claude/scripts/config-readers.sh review_mode`), plus `session-start.sh`, which prints the resolved value in its banner
**Locally overridable:** yes

**Priority chain (all skills):** inline `--review` flag → `project.local.yaml` → `project.yaml` → `production/review-mode.txt` (legacy mirror) → `modes.rigor` expansion (no terminal default; `minimal`→`solo`, `standard`→`lean`, `full`→`full`)

> **Solo skips opinions, never evidence.** Review mode decides whether a
> *director's opinion* is spawned. It never decides whether a Definition of Done
> gate is checked: `/story-done` checks all eight mechanically in every mode, and
> a skipped director is recorded as `[GATE-ID] skipped — [mode] mode`, never as
> passed (`.claude/docs/director-gates.md`).

> **`hotfix` and `post-release-fix` do not read `review_mode`.** They are
> emergency and release-critical pipelines: every agent they name always runs.

---

### Value intent

| Value | Intent |
|-------|--------|
| `full` | Every director gate a skill names is spawned. Best for teams, enterprise or self-hosted products, or anyone who wants thorough AI review of every decision. |
| `lean` | Phase gates only — per-skill director gates are skipped. The `rigor: standard` value. Balances quality with token cost. |
| `solo` | No director gates anywhere (a pipeline's own review steps still run). Fastest. The default, via `rigor: minimal`. |

Gate classes: the four **PHASE-GATEs** (`PD-`, `CTO-`, `PR-`, `DD-PHASE-GATE`) are
spawned only by `/gate-check` and run at `lean` and `full`. At the Hardening →
Release transition `/gate-check` also spawns `SL-RELEASE-SECURITY`,
`SRE-OPERABILITY` and (at `workflow: full`) `SRE-SLO` as phase-gate class: they run
at `lean` and `full`. Spawned by any other skill, the same three follow the
ordinary per-skill rule and run at `full` only. Every other gate is **per-skill**:
`full` only.

---

### Skills that spawn gates (derived from the skills)

| Skill | Gates spawned at `full` (skipped at `lean` and `solo`) |
|-------|--------------------------------------------------------|
| **brainstorm** | `PD-PRODUCT-PRINCIPLES` and `DD-CONCEPT-VISUAL` (visual anchor); `CTO-FEASIBILITY`; `PR-SCOPE` |
| **map-domains** | `CTO-CONTEXT-BOUNDARY`; `PR-SCOPE`; `PD-FEATURES` |
| **design-spec**, **quick-spec** | `PD-SPEC-ALIGN` |
| **spec-review** | Not a gate: `full` adds specialist delegation (Phase 3b); `lean` runs all phases with no specialists; `solo` runs Phases 1–4 only, no delegation and no next-step prompt |
| **architecture-decision** | `CTO-ADR` (and `CTO-STACK-RISK` when the decision rests on an API beyond `docs/stack-reference/`) |
| **create-architecture** | `CTO-ARCHITECTURE` and `PE-FEASIBILITY` |
| **create-control-manifest** | `CTO-MANIFEST` |
| **create-epics** | `PR-EPIC` |
| **create-stories** | `QL-STORY-READY` (once, over every story) |
| **story-readiness** | `QL-STORY-READY`; `SL-THREAT-MODEL` for a sensitive story |
| **sprint-plan** | `PR-SPRINT` (the QA-plan check runs in every mode) |
| **dev-story** | `SL-THREAT-MODEL` (sensitive story); `CTO-STACK-RISK` (high stack risk). Lead routing through `principal-engineer` always runs |
| **code-review** | `PE-CODE-REVIEW` |
| **story-done** | `PE-DOD`, `QL-TEST-COVERAGE`, `SL-TENANT-ISOLATION`, `PE-CODE-REVIEW` — the eight-gate table is checked in every mode |
| **security-audit** | `SL-TENANT-ISOLATION` (the category-3 checks run in every mode) |
| **milestone-review** | `PR-MILESTONE` (without it the Go/No-Go section is presented with no producer verdict) |
| **prototype** | `PD-USABILITY` (a concept prototype written before the brief exists gets `CTO-FEASIBILITY` instead) |
| **usability-report** | `PD-USABILITY` |
| **vertical-slice** | `PD-USABILITY` and `CTO-ARCHITECTURE`, in parallel |
| **propagate-spec-change** | `CTO-CHANGE-IMPACT` |
| **launch-checklist**, **release-checklist** | `SL-RELEASE-SECURITY` and `SRE-OPERABILITY`, in parallel (per-skill rule; `/gate-check release` spawns the same two at `lean` too) |
| **gate-check** | The PHASE-GATE panel runs at `lean` and `full`; `solo` skips the panel and judges on artifacts and evidence only. **Panel width is `modes.workflow`'s axis** (see that section) |

### Team orchestration skills

Team skills are execution pipelines, not review gates. In them `review_mode` sets
only director-gate depth; `team.size` picks the agents (see `## team.size`); a
pipeline's own decision points run in every mode.

| Skill | `full` | `lean` / `solo` |
|-------|--------|-----------------|
| **team-release** | + `SL-RELEASE-SECURITY` (`security-lead`) and `SRE-OPERABILITY` (`sre-lead`) in Phase 3, + `cto` release sign-off before the go/no-go call | Gates not run — recorded `skipped — [mode] mode`; the checklist's security, backup/restore, capacity and rollback items are still checked by `release-manager` and `platform-lead` |
| **team-ui** | + `DD-VISUAL` (only when the feature introduces a new surface type, token or style) and `DD-DESIGN-SYSTEM` (when `PRODUCT.md` / `DESIGN.md` are written or revised) | Skipped; the `/ux-review` verdict, accessibility review and retained screenshots are required at every mode |
| **team-hardening**, **team-qa**, **team-growth** | No director gate at any mode — they read `review_mode` but spawn nothing on it. (`team-hardening` and `team-qa` consume the outputs of `SL-RELEASE-SECURITY` / `SRE-OPERABILITY`; they never spawn them.) | Same |

### Skills that read the value without a gate

`adopt` resolves `review_mode` for its report and **never writes it**: pinning it
would shadow the `modes.rigor` expansion.

### Skills that do not read `modes.review_mode`

These run identically at `full`, `lean` and `solo` and take no `--review` flag:
`architecture-review`, `bug-report`, `bug-triage`, `changelog`,
`consistency-check`, `content-audit`, `estimate`, `help`, `hotfix`, `load-test`,
`localize`, `onboard`, `perf-profile`, `post-release-fix`, `pricing-check`,
`project-stage-detect`, `qa-plan`, `regression-suite`, `release-notes`,
`retrospective`, `review-all-specs`, `scope-check`, `setup-stack`, `smoke-check`,
`sprint-status`, `tech-debt`, `test-evidence-review`, `test-flakiness`,
`test-helpers`, `test-setup`, `ux-design`, `ux-review`.

---

### Special cases and notes

- **`gate-check`** is the one skill where `full` and `lean` behave identically —
  phase gates always run. Only `solo` skips the panel. How many directors run is a
  separate axis: `modes.workflow` sets the width. Width never softens a verdict.
- `hotfix` and `post-release-fix` are exempt — every agent they name always runs.
- When a gate is skipped, skills emit `"[GATE-ID] skipped — [mode] mode."` before
  proceeding. This is consistent across all skills.
- `session-start.sh` resolves the value with `resolve_setting`, so its banner shows
  a rigor-derived value (`solo` for a project that set only `rigor: minimal`) and a
  local override. With nothing configured at all it shows `solo`.

---

## modes.rigor

**Controls:** How much process the product carries overall — the single question `/start` asks that sets the six knobs below
**Values:** `minimal`, `standard`, `full`
**Default:** `minimal` — see the rationale block above `_yaml_helper_defaults` in `.claude/hooks/yaml-helper.sh`. Short version: the heavier tiers cost more to reach working code without producing a better result for a small product
**Set by:** `/start` (Phase 3d), `/settings`
**Read by:** `/launch-checklist` and `/release-checklist` read it directly (at `minimal` they drop items whose only justification is process weight — never a security, evidence, billing-correctness or privacy item). Everything else reads it *through* the six knobs it supplies. `/start` asks for it and `/settings` renders the derived values. `statusline.sh` shows the process posture (and suppresses it when a fronted knob is set explicitly, since no single posture is honest then)

**Priority chain:** `modes.rigor` in `project.yaml` → hardcoded default `minimal`. **Locked** — not overridable from `project.local.yaml`, like the four *on-disk* knobs it fronts (`modes.workflow`, `docs.density`, `qa.level`, `modes.story_granularity`), because those change what artifacts exist on disk. The two personal-experience knobs it also fronts, `modes.review_mode` and `team.size`, stay locally overridable.

---

### Expansion table

| `modes.rigor` | `modes.workflow` | `docs.density` | `qa.level` | `modes.story_granularity` | `modes.review_mode` | `team.size` |
|---|---|---|---|---|---|---|
| `minimal` *(default)* | `minimal` | `terse` | `minimal` | `coarse` | `solo` | `individual` |
| `standard` | `standard` | `balanced` | `standard` | `balanced` | `lean` | `individual` |
| `full` | `full` | `thorough` | `full` | `fine` | `full` | `studio` |

This is `_yaml_helper_rigor_expansion`, verbatim.

**Which to choose:** `minimal` for a validate-fast tool, an internal tool or a solo
first version; `standard` for a product with paying customers and bounded contexts
that affect each other (billing, tenancy, roles); `full` for enterprise or
self-hosted customers, regulated data, several engineers or a firm contractual date.

### It fronts, it does not replace

The expansion sits **below every explicit source and above the terminal default**:

```
project.local.yaml → project.yaml → legacy file → rigor expansion → default
```

That ordering is the back-compat guarantee. Three consequences:

- **An existing `project.yaml` behaves identically.** If it already sets
  `docs.density: terse`, step 2 answers before the expansion is consulted, so the
  value and its reported source (`project.yaml`) are unchanged whether or not
  `rigor` is present.
- **Overrides go both ways.** Unlike the `workflow_overrides` **boolean flags** —
  additive and stricter-only — an explicit knob may be *looser* than the rigor level
  implies. Inheriting the stricter-only rule would make "comprehensive but compact"
  (`rigor: full` + `docs.density: terse`) inexpressible.
  (`workflow_overrides.system_overrides` is also two-directional: it replaces a tier.)
- **`modes.workflow` keeps `workflow_overrides.system_overrides`.** Per-feature tiers
  still beat the rigor-derived project tier. `workflow` was fronted rather than
  folded away because it drives several distinct behaviours and owns the only
  per-feature override mechanism.

The six fronted knobs therefore have **no entry in `_yaml_helper_defaults`**. A
terminal default there would answer before the expansion and make `rigor` a no-op
for anyone who had not also set the sub-knob. The template `project.yaml` does not
seed them for the same reason.

### Provenance

Derived values report their source as `rigor:<level>`, so the vocabulary is
`{project.local.yaml, project.yaml, <legacy path>, rigor:<level>, default, unset}`.
`/settings` renders this as `(derived from rigor: standard)` and force-appends the
seven rigor-family keys to its view-all list — none of them is a leaf of either
YAML file, so enumerating file leaves alone would hide exactly the settings the
user just chose.

> **Under-running is cheap, over-running is not.** The `minimal` default is only
> safe because `/gate-check` keeps its floors (a smoke check, security and
> run-and-observe evidence, and "nothing required → NOT ASSESSED, never PASS").
> `rigor: minimal` expands to `workflow: minimal` + `qa.level: minimal`, which
> together would otherwise leave the Production → Hardening gate with no required
> artifact. `/gate-check` offers a one-time rigor-fit prompt when a product enters
> Production on `minimal`.

---

## modes.workflow

**Controls:** How much product documentation is required before code can begin — the tradeoff between the token/time cost of documentation and the speed of reaching working code
**Values:** `full`, `standard`, `minimal`
**Default:** *none* — supplied by `modes.rigor` (`minimal`, the default, yields `minimal`; `standard` yields `standard`; `full` yields `full`)
**Set by:** `/start` (via `modes.rigor`), `/settings`
**Read by:** every skill whose bootstrap requests `workflow` (current list: `bash .claude/scripts/config-readers.sh workflow`), `detect-gaps.sh` (spec-expected check), `validate-commit.sh` (required spec sections on staged specs, per-feature tier from `system_overrides`), `statusline.sh`
**Locally overridable:** no

**Priority chain:** `workflow_overrides.system_overrides.<feature>` (for a named feature) → `modes.workflow` in `project.yaml` → `modes.rigor` expansion → *(no hardcoded default)*

> **Tiers scale documents, never engineering.** The eight Definition of Done gates
> (`coding-standards.md`) apply at every tier. `minimal` means fewer documents, not
> weaker code: the research note, the threat model for a sensitive story, the
> security negatives, tenant-isolation tests and run-and-observe evidence are
> required at every tier. The only gate a tier changes is *where* the decision is
> recorded (ADR files, or the decision log in the product brief at `minimal`).

> **Permissive, not restrictive:** `workflow` controls what is REQUIRED — not what
> is ALLOWED. Any skill can be run at any tier.

> **`minimal` floor.** Even at `minimal`: a filled `design/product-brief.md` (its
> Build order is the plan, so there is no separate sprint-plan step), a configured
> stack (`/setup-stack`) and a `docs/research/<feature>.md` before each feature's
> code. Everything else can be skipped.

---

### Value intent

| Value | Cost | Required before code | Best for |
|-------|------|---------------------|----------|
| `full` | High | Product brief, domain map, all 8 spec sections per feature, architecture doc, all ADRs, UX spec per screen, threat model per sensitive feature, SLOs | Enterprise or self-hosted customers, regulated data, several engineers |
| `standard` | Balanced | Product brief, domain map, 5 spec sections per feature (+ conditionals), architecture doc, critical ADRs, threat models for sensitive features | Most products once past the first version |
| `minimal` | Low | One-page `design/product-brief.md` + stack configured + a research note per feature | **Default.** New products, internal tools, validated-fast ideas. Raise it when the product grows |

**Spec sections** (8; template `.claude/docs/templates/feature-spec.md`): Overview,
User Value, Detailed Behaviour, Data & Contracts, Edge Cases & Failure Modes,
Dependencies, Non-Functional Requirements, Acceptance Criteria.

**standard required:** Overview, Detailed Behaviour, Data & Contracts,
Non-Functional Requirements, Acceptance Criteria. **Conditional:** Edge Cases &
Failure Modes — required when the feature calls an external provider, moves money,
changes entitlements or runs asynchronously (or `workflow_overrides.edge_cases` is
set). **Optional:** User Value, Dependencies. **minimal:** none — the brief and the
research note cover it; a voluntary spec authors exactly the 5 standard sections.

> **"Critical ADR"**: an ADR governing a foundation concern — tenancy model,
> identity/auth, data store choice, messaging, API style, deployment topology,
> licensing. At `standard` only critical ADRs are required; when in doubt, treat an
> ADR as critical.

---

### Authoring skills

| Skill | full | standard | minimal |
|-------|------|----------|---------|
| **brainstorm** | Full concept flow with the fuller brief sections (market, competitors, personas, pricing hypotheses, risks, roadmap) | Full flow | The lean one-page `design/product-brief.md` |
| **map-domains** | Required before `/design-spec` | Required before `/design-spec` | Not required — the brief's MVP list and build order replace the domain map |
| **design-spec** | All 8 sections | 5 required + conditional Edge Cases; User Value and Dependencies optional | Not required (voluntary run authors the 5 standard sections) |
| **create-architecture** | Every section + a full ADR audit | Context map, data stores and tenancy, deployment topology and the critical-ADR list; the rest one paragraph each | Not required — the brief's decision log carries the rationale |
| **architecture-decision** | All ADRs on the required list | Critical ADRs only | Not required — decisions go in the brief's decision log |
| **create-control-manifest** | Requires Accepted ADRs | Requires the critical Accepted ADRs | Built from the standards and the decision log, with no ADRs; the header says so |
| **ux-design** | A UX spec per screen | Core screens only (sign-up/onboarding, the primary workflow and dashboard, billing and plan management, team/settings) plus any screen that moves money, changes access or deletes data | Not required — the research note and `/impeccable` cover it |

### Review and validation skills

| Skill | full | standard | minimal |
|-------|------|----------|---------|
| **spec-review** | All 8 sections validated; any missing section blocks approval | 5 required sections block if missing (+ Edge Cases where its conditional applies); optional sections warn | Not applicable |
| **review-all-specs** | All 8 sections across all specs | 5 required (+ conditional); optional sections advisory | Not applicable |
| **architecture-review** | Full traceability across all specs and all ADRs | Architecture doc + critical ADRs only; a non-critical gap is listed, not blocking | Not applicable (say so and stop unless the user insists) |
| **consistency-check** | Registry cross-check against all spec sections | Against the required sections only; values outside them are listed as not checked | Not meaningful when no specs exist |
| **content-audit** | All 8 sections, all ADRs, UX spec per screen, threat model per sensitive feature, SLOs | The 5 required sections (+ conditional), critical ADRs, threat models for sensitive features | Brief-level audit |

All of these apply the tier **per spec**, at that feature's effective tier
(`system_overrides` row, else the project value).

### Phase gate enforcement (gate-check)

`/gate-check` is where `workflow` has the most visible impact: each gate file
(`.claude/skills/gate-check/references/gate-<phase>.md`) states the `full` baseline,
then its `standard` and `minimal` reductions. A reduction only ever relaxes
(**drop**, or **→ recommended**: absent is CONCERNS, never a Blocker). Each file
also names its **floors at every tier**, which no reduction touches.

| Gate (into stage) | full | standard | minimal |
|-------------------|------|----------|---------|
| Discovery → Product Design | Brief with required fields, principles (`PD-PRODUCT-PRINCIPLES`), visual anchor (`DD-CONCEPT-VISUAL`), fuller brief sections | Brief required; principles, visual anchor and fuller sections → recommended | The one-page brief with required fields filled |
| Product Design → Architecture | Domain map, MVP specs at 8 sections, cross-spec review, pricing model, entity registry | MVP specs at 5 sections (+ conditional); review and registry → recommended | **Not applicable** — auto-PASS with a note (unless an override pins a feature higher) |
| Architecture → Pre-Production | Stack, architecture doc, all ADRs, traceability, `/architecture-review`, threat models, perf budgets, SLOs, design system, accessibility doc, UX specs started, test framework, CI | Critical ADRs only; design system only when a user-facing layer is configured; most of the rest → recommended; threat models stay required | Stack configured + Foundation decisions in the brief's decision log |
| Pre-Production → Production | Sprint plan, epics, stories, control manifest, UX specs, design system, MVP specs, Accepted ADRs, `QL-STORY-READY`, research notes (vertical slice recommended, not blocking) | Epics, sprint plan, stories, research notes, Accepted Foundation/Core ADRs; the rest → recommended | Brief with build order, stories under `production/epics/`, research notes for the first features; two current-build checks replace the slice (core journey delivers its value; it runs end to end) |
| Production → Hardening | All MVP features, tests per type, smoke, QA sign-off, 3+ usability sessions, per-story eight-gate evidence, no open S1 | QA sign-off → recommended; features, smoke, main journey end to end, 1+ usability session, no open S1, eight-gate evidence for Complete stories | Smoke + main journey end to end + no open S1 + the floors |
| Hardening → Release | All features, strings externalised, localization verification, QA sign-off (+ UAT), smoke PASS, no open S1–S3, SLOs, the floors | Localization, sign-off, UAT, notes → recommended; features, smoke, no open S1, the floors; no SLOs | Smoke + no open S1 + the floors (security audit, scans, tenant isolation, restore drill, rollback plan, licence rules) |
| Release → Live | Release record, launch checklist, post-deploy smoke, observability live, SLOs Active, runbooks, status page, billing live check, analytics, hotfix path | SLOs, analytics, billing check → recommended; release record, post-deploy smoke, observability, backups, incident path, runbooks, no open S1 | Only the floors |

**Director panel width** (`/gate-check` Section 4b) is workflow's second effect.
Directors are Opus-tier, so the panel is sized to the product:

| `workflow` | Panel | Directors |
|---|---|---|
| `full` | 4 | `product-director`, `cto`, `producer`, `design-director` |
| `standard` | 2 | `cto`, `producer` |
| `minimal` | 1 | `producer` |

`review_mode` decides *whether* the panel runs (`solo` skips it); `workflow`
decides how wide it is. Narrowing never softens a verdict, and `/gate-check` names
the perspectives that did not run. At Hardening → Release the release-readiness
gates join the panel: `SL-RELEASE-SECURITY` and `SRE-OPERABILITY` at every tier,
`SRE-SLO` at `full` only (recorded `skipped — not required at workflow: [tier]`,
or `skipped — self-hosted only` for a self-hosted-only product).

`qa.level` and `performance.enforce` relax or enforce independently of the tier —
see their sections. A gate left with **no required artifacts** after both
reductions returns NOT ASSESSED, never PASS (the one exception is the "not
applicable" Product Design → Architecture gate at `minimal`).

---

### Planning and implementation skills

| Skill | full | standard | minimal |
|-------|------|----------|---------|
| **create-epics** | In-scope specs must be Approved at all 8 sections; every TR-ID traced | 5-section specs; critical ADRs suffice; control manifest read if present | Optional and not on the path — `/create-stories` synthesizes the implicit epic from the brief |
| **create-stories** | Requires the epic from `/create-epics` (stops without it) | Same | Reads `design/product-brief.md`, synthesizes the epic, one coarse story per MVP feature per code root; no spec/manifest/TR/ADR reads |
| **dev-story** | TR registry required (blocks without it); a referenced ADR that is missing or not Accepted blocks; missing manifest warns | TR registry optional; ADR blocks only when referenced | No TR registry or ADR required; implements against the brief; a referenced ADR that is missing or not Accepted still blocks |
| **story-readiness** | Full TR + ADR + manifest validation | TR optional; critical ADR check | Acceptance-criteria and design-completeness check, the brief standing in for the spec |
| **story-done** | Full spec traceability + ADR consistency deviation checks | 5-section spec traceability | Acceptance-criteria check; deviation checks that read absent documents drop |
| **qa-plan** | Test plan mined from all 8 spec sections | From the 5 required sections | From acceptance criteria |
| **regression-suite** | Critical journeys mapped from all sections incl. Edge Cases | From required sections | Smoke-only coverage source |
| **propagate-spec-change** | ADR cascade across all ADRs | Critical ADRs and those referencing the spec | ADR cascade not applicable; story, contract, pricing and threat-model checks still run |
| **setup-stack** | — | — | Finish path is `/brainstorm` → `/create-stories` → `/dev-story`; standard/full continue the full pipeline. The tier never changes what the skill validates |

The **research note**, the **threat model for a sensitive story**, contract-first
ordering and the eight DoD gates apply at every tier.

### Support skills

| Skill | full | standard | minimal |
|-------|------|----------|---------|
| **project-stage-detect** | All doc types checked; missing UX specs / threat models flagged as gaps | Optional docs not flagged | Brief + stack present is the normal state |
| **adopt** | Full format-compliance audit | Audit scope reduced to the required docs | Brief format check only |
| **help** | Surfaces all missing docs as next steps | Required docs only | Brief + stack present means the next step is code |
| **security-audit** | Unaffected by the tier — security evidence is required at every tier | same | same |

### Workflow change mid-project

When `workflow` changes via `/settings`, the skill emits an informational note:

> "Workflow changed from [old] to [new]. Run `/content-audit` to see what's now
> required or extra. No automatic migration — existing files stay in place."

No documents are auto-deleted, auto-generated or blocked. The setting only affects
*new* enforcement going forward.

---

## workflow_overrides

**Controls:** Opt-in granular requirements that override the chosen workflow tier
**Location:** **top level of `project.yaml`** — a sibling of `modes:`, *not* a child of it
**Values:** an object with the fields below
**Default:** both flags false, `system_overrides` empty (the flags are validated as `true`/`false`; a tier value under `system_overrides` is **not** validated)
**Set by:** `/settings`
**Read by:** `system_overrides` is delivered through `resolve_config` to every skill whose bootstrap requests it (current list: `bash .claude/scripts/config-readers.sh system_overrides`). The two flags have no `resolve_config` label: `design-spec`, `spec-review` and `gate-check` read them straight from `project.yaml`
**Locally overridable:** no

> **Why the location is called out.** `resolve_config` reads
> `workflow_overrides.system_overrides.*` from the document root, and every
> consuming skill reads the same top-level path. Nested under `modes:` it is still
> valid YAML, so nothing errors — the setting is simply never read. If you copied a
> `workflow_overrides` block from anywhere, check its indentation.

**Priority chain:** the two boolean **flags** (`edge_cases`, `tuning_knobs`) are
*additive* on top of the chosen workflow tier — they make things stricter, never
looser. Neither has a value that opts out of a requirement the tier imposes.

> **`system_overrides` is not a flag and is not additive — it replaces a tier in
> both directions.** On a `full` project, `system_overrides.inventory: minimal`
> really does drop that feature's required sections. Intended — see
> `.claude/docs/workflow-modes.md § workflow_overrides`. Stating the additive rule
> over the whole key is wrong; do not rely on it as a safety net.

---

### Fields

```yaml
workflow_overrides:
  edge_cases: false          # force Edge Cases & Failure Modes required at every tier (no-op at full)
  tuning_knobs: false        # force a "Configuration" subsection (limits, quotas, flags) in Non-Functional Requirements
  system_overrides: {}       # per-feature tier overrides — see below
```

### Per-feature overrides

```yaml
workflow_overrides:
  system_overrides:
    billing: full             # billing's spec requires all 8 sections whatever the project tier
    audit-log: full
    changelog-page: minimal   # that feature needs no spec — the brief and the research note cover it
```

`system_overrides` is a map of `feature: tier`. The key is **the spec filename
stem** (`design/specs/team-invitations.md` → `team-invitations`); a story's
`TR-[feature]-NNN` segment is an alias accepted only as a fallback. The named
feature uses the override; all other features use the project tier. The key name
`system_overrides` is inherited and kept for config compatibility.

**A key that matches no spec is an error, not a no-op** — `/gate-check` reports it
at a phase boundary as CONCERNS, naming the key and the stems that exist. Authoring
skills that *create* the spec do not report it, since before their first run the
key matches nothing by definition. The helper does not validate the tier value:
`billing: ful` is accepted and read as written, so spell tiers carefully.

---

### Affected skills

| Skill | How `workflow_overrides` changes behaviour |
|-------|-------------------------------------------|
| **design-spec**, **spec-review** | Look up `system_overrides[<feature>]` first, else the project tier; apply that tier's section set. `edge_cases` forces Edge Cases & Failure Modes required; `tuning_knobs` adds/requires the Configuration subsection |
| **review-all-specs**, **consistency-check**, **content-audit**, **ux-design**, **ux-review** | Validate each spec / screen at its feature's effective tier |
| **gate-check** | Considers `system_overrides` when validating specs at the Product Design → Architecture, Architecture → Pre-Production and Pre-Production → Production gates: a feature pinned to `full` blocks until all 8 sections exist. An override pinning a feature above `minimal` removes the "not applicable" exception for it. Reports orphan keys. Applies the two flags on top of the tier |
| **create-epics**, **create-stories**, **dev-story**, **story-readiness**, **story-done**, **qa-plan**, **regression-suite**, **propagate-spec-change**, **code-review**, **scope-check** | Resolve the tier per feature rather than for the whole project |

---

## modes.automation

**Controls:** Whether skills ask for decisions and approval before acting, or recommend and proceed — the tradeoff between user control and speed
**Values:** `collaborative`, `guided`, `autonomous`
**Default:** `collaborative` (`_yaml_helper_defaults`)
**Set by:** `/start` (Phase 3e), `/settings`
**Read by:** every skill whose bootstrap requests `automation` (current list: `bash .claude/scripts/config-readers.sh automation`) (`/skill-test` and `/skill-improve` read nothing else); `/settings` resolves it itself. Four skills are exempt (below)
**Locally overridable:** yes

**Priority chain:** `project.local.yaml` → `project.yaml` → hardcoded default `collaborative`

> **Unlike `review_mode` and `workflow`, this setting is not a per-skill table.**
> It defines universal interaction rules that apply across every skill that asks a
> question or writes a file; a per-skill breakdown would repeat one answer 55
> times. `.claude/docs/automation-modes.md` is the implementation pattern and is
> self-sufficient at runtime — do not open this file during a skill run.

> **`guided` and `autonomous` relax the Question → Options → Decision → Draft →
> Approval protocol.** This is opt-in. `collaborative` preserves it exactly.

> **Safety net — `automation_always_ask`:** even in `autonomous` mode, certain
> categories of decision always prompt. See the next section.

---

### Value intent

| Value | Speed | Control | What changes |
|-------|-------|---------|--------------|
| `collaborative` | Slowest | Full — every decision is the user's | Q→O→D→Draft→Approval strictly followed |
| `guided` | Balanced | High — major decisions are the user's | The AI states a recommendation and proceeds on minor decisions; `AskUserQuestion` is reserved for major or irreversible ones |
| `autonomous` | Fastest | Low — the AI decides, logs and proceeds | No `AskUserQuestion` (except `automation_always_ask` categories), no draft review, no write approval; every decision is logged |

### Universal rules per mode

#### collaborative

- `AskUserQuestion` for every multi-option decision, with 2–4 options and pros/cons
- Full draft shown and approved before every file write
- "May I write this to [filepath]?" asked before every write, and before skeleton creation
- Section-by-section approval in multi-section authoring skills
- Multi-file changes require explicit approval of the full changeset

#### guided

- `AskUserQuestion` for **major decisions only** (classification below)
- Minor decisions: the AI states its recommendation inline and proceeds
- Updates to existing files: a brief draft summary, then proceeds without waiting for an explicit "yes"
- "May I write?" for **new files only**, and a new file waits for the answer
- Major decisions still present options but cap at 2 with a clear recommendation
- Multi-section authoring writes each approved section immediately

#### autonomous

- No `AskUserQuestion` **except** categories in `automation_always_ask`
- No draft review, no "May I write?" — writes directly
- Picks the recommended option for every decision
- Every decision is logged by `log_decision` to `production/session-logs/decision-log.md`
- The user audits the log after the session

#### every mode — a question with no answer

- A question that comes back skipped, dismissed or empty is **not an answer**, in
  every mode and on every tool
- Nothing is written, no setting changes and no option is picked on its behalf; the
  question is asked again in plain text, naming what waits on it
- `autonomous`: a question the mode did not require is decided and logged as usual;
  an `automation_always_ask` category or an exempt skill asks again
- Where nobody can answer (CI, headless), the skill stops and reports what is
  waiting rather than choosing

---

### Major vs minor decision classification (guided mode)

**Major — always `AskUserQuestion` in guided mode:**

| Decision type | Example |
|---------------|---------|
| Choosing a feature name or document path | "What should we call this feature?" |
| Mutually exclusive design directions | "Row-level security or schema-per-tenant?" |
| Any choice that gates downstream work | Stack choice, architecture approach |
| Scope changes | "Cut this feature or slip the date?" |
| Any decision that cannot be changed without significant rework | Tenancy model, public API shape |

**Minor — the AI recommends and proceeds in guided mode:**

| Decision type | Example |
|---------------|---------|
| Which section to work on next | "Moving to Edge Cases next" |
| Optional section inclusion | "Adding a Configuration subsection — the feature has tunable limits" |
| Formatting and structure | Heading levels, table vs prose |
| Detail inside an already-decided direction | Sub-options within an approved approach |
| Next-step routing after a phase completes | "Running spec-review now" |

---

### Affected skills by category

**Authoring skills — highest impact.** Each pauses many times per document in
`collaborative`; a few in `guided`; none in `autonomous`.
`brainstorm`, `map-domains`, `design-spec`, `quick-spec`, `ux-design`,
`create-architecture`, `architecture-decision`, `create-control-manifest`,
`create-epics`, `create-stories`, `sprint-plan`, `prototype`

**Review skills — medium impact.** Pause after presenting findings to ask what to do
next. In `guided` routing proceeds automatically; in `autonomous` the recommended
path is taken and logged.
`spec-review`, `review-all-specs`, `architecture-review`, `consistency-check`,
`content-audit`, `story-readiness`, `story-done`, `code-review`,
`milestone-review`, `usability-report`, `test-evidence-review`, `security-audit`

**Team orchestration skills — medium impact.** Pause between phases for check-in.
In `guided` the pipeline advances unless BLOCKED; in `autonomous` it runs end to end.
`team-ui`, `team-qa`, `team-release`, `team-hardening`, `team-growth`

**Implementation skills — lower impact.** Pause for architectural questions before
writing code.
`dev-story`, `vertical-slice`, `test-setup`, `test-helpers`, `localize`, `skill-test`, `skill-improve`

**Setup and utility skills — lowest impact.** Pause for configuration or routing
questions; `guided` applies defaults, `autonomous` takes the recommended ones.
`adopt`, `onboard`, `retrospective`, `propagate-spec-change`, `smoke-check`,
`qa-plan`, `regression-suite`, `perf-profile`, `load-test`, and the remaining
bootstrap skills.

---

### Exemptions — skills that ignore the automation setting

These always behave as `collaborative` regardless of the setting, and do not carry
the automation prelude:

| Skill | Why always collaborative |
|-------|--------------------------|
| **hotfix** | Emergency decisions — the user must approve scope and risk before any action |
| **gate-check** | Results must be reviewed — a gate verdict without acknowledgement defeats the purpose |
| **post-release-fix** | Release-critical — every action needs explicit sign-off |
| **setup-stack** | Stack, distribution and tenancy choices affect the entire product and every agent's routing |

Eight further skills carry no automation prelude because their bootstrap does not
resolve `automation`: `estimate`, `help`, `scope-check`, `sprint-status`,
`ux-review`, `start`, `settings` and `impeccable`.

---

### Decision log format (autonomous mode)

Written to `production/session-logs/decision-log.md` — append-only, created if
absent, never truncated.

```markdown
## [timestamp] — [skill-name]

**Decision point:** [what was being decided]
**Options considered:** [list of options that would have been presented]
**Chosen:** [what was picked]
**Reason:** [one-line rationale]
**Category:** [scope_changes, file_deletions, schema_changes, … or "minor"]
```

Appending facts to a registry or index (`design/registry/entities.yaml`,
`design/specs/domain-map.md`) is `minor`. `schema_changes` means editing the
*structure* of `project.yaml` or a template. When unsure between `minor` and an
always-ask category, prompt — failing safe.

---

## modes.automation_always_ask

**Controls:** Decision categories that ALWAYS trigger `AskUserQuestion` regardless of automation mode
**Values:** a list of category names
**Default:** `[scope_changes, file_deletions, schema_changes]` (`_yaml_helper_always_ask_default`, used when the key is absent from both files)
**Set by:** `/settings`
**Read by:** `/adopt` receives the resolved list in its bootstrap line; every other skill with the automation prelude follows `automation-modes.md`; the helper `is_always_ask_category <category>` answers membership
**Locally overridable:** yes

> **Makes `autonomous` safe.** Without this, `autonomous` is "the AI does literally
> everything, no questions asked." With it, the AI does most things but stops on
> destructive or irreversible decisions you named.

> **Only the categories actually listed prompt.** The table below is the set you
> *may* configure, not the set that always asks. A category the project never
> configured (for example `architecture_decisions`) does nothing until it is listed.

### Recognized categories

| Category | Examples of decisions in this category |
|----------|----------------------------------------|
| `scope_changes` | Cutting a feature, slipping a date, splitting or merging an epic, removing acceptance criteria, adding scope mid-sprint |
| `file_deletions` | Removing a story, deleting a spec, removing a context, removing a test file |
| `schema_changes` | Changes to `project.yaml`, the story template, control manifest, ADR template, spec template |
| `architecture_decisions` | New ADR creation, ADR replacement, context-boundary changes |
| `version_bumps` | A pinned stack version change, `core.version` bump, framework version bump, dependency major version change |
| `external_calls` | Invoking external APIs (payment, SMS, AI services) while in autonomous mode |

The list is a YAML list of these strings, in block form or inline form. Items are
compared exactly; a trailing `# comment` after an unquoted item is stripped.

### Where the categories show up today

| Skill | Categories it names |
|-------|--------------------|
| **story-done** | `scope_changes` (the close-anyway override on a security-sensitive story, and removing a criterion) |
| **sprint-plan** | `scope_changes` (adding scope mid-sprint) |
| **propagate-spec-change** | `schema_changes`, `architecture_decisions` |
| **settings** | `schema_changes` — a write to `project.yaml` is confirmed even in `autonomous` unless the user removed the category |

`version_bumps` and `external_calls` are accepted by the helper but no skill names
them today; the other skills decide per decision whether it falls into a configured
category.

---

## modes.story_granularity

**Controls:** How big each story is and how many stories per epic and sprint
**Values:** `coarse`, `balanced`, `fine`
**Default:** *none* — supplied by `modes.rigor` (`minimal`, the default, yields `coarse`; `standard` yields `balanced`; `full` yields `fine`)
**Set by:** `/start` (via `modes.rigor`), `/settings`
**Read by:** `create-epics`, `create-stories`, `dev-story`, `sprint-plan`, `sprint-status`, `story-done`
**Locally overridable:** no

**Priority chain:** `modes.story_granularity` in `project.yaml` → `modes.rigor` expansion → *(no hardcoded default)*

### Value intent

| Value | Story shape | Stories per sprint | Best for |
|-------|-------------|-------------------|----------|
| `coarse` | One story spans a whole feature slice; multi-day; 5–10 ACs. The default, via `rigor: minimal` | 2–4 | Solo builders, validate-fast products |
| `balanced` | One story is one task; 1–2 days; 2–4 ACs. The `rigor: standard` value | 6–10 | Most products |
| `fine` | One story is one acceptance criterion; hours; easy review; frequent `/story-done` | 15–25 | Teams, fine hand-offs |

### Affected skills

| Skill | coarse | balanced | fine |
|-------|--------|----------|------|
| **create-epics** | 3–5 child stories per epic | 5–10 | 10–20 |
| **create-stories** | 5–10 ACs covering a whole feature slice | 2–4 ACs covering one task | 1 AC; the story name restates it |
| **dev-story** | Expects a multi-day cycle; the lead gets longer working context | 1–2 days | Hours; tighter context |
| **sprint-plan** | Allocates 2–4 stories per sprint, scaled by velocity | 6–10 | 15–25 |
| **story-done** | Fires every 3–5 days on average (cadence expectation only — changes no completion check) | Every 1–2 days | Several times a day |
| **sprint-status** | Burn-down reads in feature-sized chunks | Task-sized | AC-sized |

---

## docs.density

**Controls:** How deep each section in authored docs goes — independent of which sections are required
**Values:** `terse`, `balanced`, `thorough`
**Default:** *none* — supplied by `modes.rigor` (`minimal`, the default, yields `terse`; `standard` yields `balanced`; `full` yields `thorough`)
**Set by:** `/start` (via `modes.rigor`), `/settings`
**Read by:** `architecture-decision`, `brainstorm`, `create-architecture`, `create-epics`, `create-stories`, `design-spec`, `map-domains`, `ux-design`. `release-notes` receives the value in its bootstrap line but does not branch on it
**Locally overridable:** no

**Priority chain:** `docs.density` in `project.yaml` → `modes.rigor` expansion → *(no hardcoded default)*

> **Distinct from `workflow`, but no longer independent by default.** `workflow`
> controls which sections exist; `density` controls how deep each goes.
> `modes.rigor` now sets both together, so the diagonal (`rigor: full` → 8 sections
> *and* thorough prose) is what you get without asking. The off-diagonal stays
> reachable: `rigor: full` + an explicit `docs.density: terse` gives "all sections,
> each compact".

### Value intent

| Value | Per-section output style |
|-------|--------------------------|
| `terse` | Bullet points, 2–5 lines per section; no rationale or narrative framing; just what is needed to implement. The default, via `rigor: minimal` |
| `balanced` | Paragraphs with light rationale; examples where helpful. The `rigor: standard` value |
| `thorough` | Full prose; rationale for every decision; examples, alternatives considered, history |

Structure is never trimmed by density: required sections, traceability fields and
cross-references stay whole at every density.

### Combination matrix with workflow

|  | `terse` | `balanced` | `thorough` |
|---|---|---|---|
| **`workflow: minimal`** | Product brief in bullets *(default)* | Brief in prose | Brief + rationale |
| **`workflow: standard`** | 5 sections, bullets | 5 sections, paragraphs | 5 sections + examples |
| **`workflow: full`** | 8 sections, bullets *(comprehensive but compact)* | 8 sections, paragraphs | 8 sections + rationale + examples |

### Affected skills

| Skill | terse | balanced | thorough |
|-------|-------|----------|----------|
| **design-spec** | Each section 2–5 bullets | Paragraphs with key decisions explained | Full prose, decision history, alternatives considered |
| **architecture-decision** | Decision + alternatives as bullets, one line of rationale each | Short paragraphs of rationale | Full prose per alternative |
| **create-architecture** | Diagrams + decision bullets, no essays | Diagrams + paragraph explanations | Full prose with rationale, trade-offs, alternatives per layer |
| **create-epics** | Scope as bullets, one-line rationale | A scope paragraph | Full scope prose with governing-ADR reasoning |
| **create-stories** | Notes as bullets, no preamble | Short context paragraph + notes | Context, rationale and implementation notes in prose |
| **map-domains** | One-line context and feature descriptions | A paragraph per context + dependency notes | Full context-by-context rationale |
| **ux-design** | Wireframe descriptions + interaction bullets | Wireframes + paragraph flows | Full prose incl. research summaries and alternative flows |
| **brainstorm** | Principle bullets + brief bullets | Principles + brief with short rationale | Principles + brief + extensive rationale + alternatives |

---

## testing.strict

**Controls:** Whether failing or missing test evidence blocks a story from closing, or produces a warning and lets work continue — per story type
**Values:** a map of `{logic, integration, contract, security, performance, visual, ui, config}` → `true` or `false` (each leaf is enum-validated; the scalar shorthand `testing.strict: true` is read as a back-compat form)
**Default:** no central default, on purpose. Each skill applies the per-type default below when the key is unset
**Set by:** `/settings`
**Read by:** every skill whose bootstrap requests `testing.strict` (current list: `bash .claude/scripts/config-readers.sh testing.strict`)
**Locally overridable:** yes (each of the eight leaves)

> **Per-type, not a single boolean.** A global `true`/`false` forces all-or-nothing.
> Per-type matches how teams actually work — strict logic and contract gates, an
> advisory smoke check.

> **Composes with `qa.level`:** `qa.level` controls whether evidence is REQUIRED.
> `testing.strict` controls whether failures BLOCK when evidence exists. At
> `qa.level: minimal` the strict map is effectively ignored for Logic, Integration,
> Contract and Config stories (no test volume is required, so there is nothing to
> be strict about) — but never for the evidence `qa.level` does not waive.

### Value intent per type

| Type | `true` | `false` | Default when unset |
|------|--------|---------|--------------------|
| `logic` (domain rules, pricing, state machines) | Unit-test failures BLOCK the story | WARN; the story can close with a note | `true` |
| `integration` (DB, cache, queue, provider) | Testcontainers failures BLOCK | WARN | `true` |
| `contract` (API shape between backend and clients) | Contract-test failures and breaking changes BLOCK | WARN | `true` |
| `security` (auth, tenancy, billing, uploads, PII) | Missing or failing negative tests / ASVS-MASVS mapping BLOCK | WARN | `true` |
| `performance` (hot paths, list endpoints, jobs) | A missed budget or missing load-test result BLOCKS | WARN | `false` (advisory) — and BLOCKING when `performance.enforce: block` |
| `ui` (web or mobile screens) | Missing screenshot or `/impeccable audit` result BLOCKS | WARN | `true` |
| `config` (limits, flags, prices) | A failing smoke check BLOCKS | WARN | `false` (advisory) |
| `visual` | — | — | none (reserved — next section) |

> **Security evidence on a security-sensitive story is always BLOCKING,** whatever
> this setting says (`pe-dod.md`); a story-level override needs a named owner and an
> expiry and goes to `/tech-debt`.

### Affected skills

| Skill | `true` | `false` |
|-------|--------|---------|
| **story-done** | A story of that type cannot close on a test or evidence failure | The story closes COMPLETE WITH NOTES; the gap is logged in the story file |
| **story-readiness** | Validates that the test requirement exists before implementation — blocks if absent | Validates but does not block |
| **gate-check** | Failures of that type are **Blockers** (verdict FAIL) | Failures are **Concerns** (verdict at least CONCERNS) |
| **smoke-check** | A failing smoke (`config`) blocks QA hand-off | A failing smoke is flagged; hand-off proceeds |
| **dev-story**, **qa-plan**, **test-setup** | The story's evidence table and plan carry the level for each requirement | Same, marked advisory |
| **test-evidence-review** | A gap in that type's evidence is a BLOCKING item (the run ends CONCERNS) | The gap is ADVISORY |
| **code-review**, **team-qa**, **team-hardening**, **team-ui** | Report the level next to each finding; an unmet BLOCKING gate is a blocker | Reported as advisory |

> **Unset-key resolution.** `resolve_config` reads each leaf from
> `project.local.yaml`, then `project.yaml`, then the scalar `testing.strict`
> shorthand, validating each against `true`/`false`; what is left is printed as
> `unset`. A skill then applies the per-type default from the table above
> (`coding-standards.md`). **`smoke-check` is the exception**: it is a build-health
> gate, so an unset `testing.strict.config` defaults to *strict* (a FAIL blocks QA
> hand-off). Only an explicit `testing.strict.config: false` makes a failing smoke
> advisory. An invalid value (`logic: maybe`) is ignored and treated as unset — it
> never silently downgrades a blocking gate.

---

## testing.strict.visual

> ### RESERVED - NOT IMPLEMENTED
>
> **No skill or hook reads this setting. Setting it has no effect.** Everything
> below describes the intended design, not current behaviour.
>
> The value is checked as `true` or `false` when you set it, it can be set locally,
> and it is printed on the `testing.strict:` line of the resolved config — but no
> SaaS story type maps to `visual` (the story types are Logic, Integration,
> Contract, Security, Performance, UI and Config), so nothing branches on it. Set the
> gate level of retained screenshots with `testing.strict.ui`.

**Controls:** The gate level of a visual-fidelity story type, if one is ever added
**Values:** `true`, `false`
**Default:** none (unset)
**Set by:** `/settings`
**Read by:** nothing yet (intended reader: a future Visual story type)
**Locally overridable:** yes

**Priority chain:** `testing.strict.visual` in `project.local.yaml` → `project.yaml` → the `testing.strict` scalar shorthand → unset.

---

## qa.level

**Controls:** How much test evidence beyond the required floor is asked for to mark stories Done
**Values:** `minimal`, `standard`, `full`
**Default:** *none* — supplied by `modes.rigor` (`minimal`, the default, yields `minimal`; `standard` yields `standard`; `full` yields `full`)
**Set by:** `/start` (via `modes.rigor`), `/settings`
**Read by:** every skill whose bootstrap requests `qa.level` (current list: `bash .claude/scripts/config-readers.sh qa.level`)
**Locally overridable:** no

**Priority chain:** `qa.level` in `project.yaml` → `modes.rigor` expansion → *(no hardcoded default)*

> **Different axis from `testing.strict`.** `qa.level` = what evidence is required.
> `testing.strict` = whether failures block.

> **`qa.level` scales extra evidence, never the required floor.** Logic, Integration,
> Contract and Security stories need tests that exist and pass at every level
> (`coding-standards.md`, gate 3). At every level these are also required wherever a story or gate asks for evidence
> (`coding-standards.md`, "A compile is not a run"): the **run-and-observe** record
> for anything a user can see or call, a **UI** story's retained screenshots and
> `/impeccable audit` result, a **Security** story's negative tests and ASVS/MASVS
> mapping, tenant-isolation tests on tenant data, the dependency scan, and the
> **smoke check** at gates that require one (it is build health, not story evidence).

### Value intent

| Aspect | minimal | standard | full |
|--------|---------|----------|------|
| Logic, Integration, Contract stories | Tests exist and pass — BLOCKING (never waived) | Same, plus the per-type evidence detail in `testing-standards.md` | Same + a coverage target (domain and app packages ≥ 85 % lines, `testing-standards.md`) |
| Security stories | Negative tests + ASVS/MASVS mapping required — never waived | Same | Same |
| UI stories | Screenshots + audit required — never waived | Same | Same |
| Config stories | No smoke report required | Smoke check advisory | Smoke check required |
| Performance stories | Load-test evidence per `testing.strict.performance` / `performance.enforce` | Same | Same |
| `/story-done` test gate | Acceptance criteria only, plus the never-waived evidence above | Enforced per story type | Enforced for every story type |
| `/gate-check` test items | Unit/coverage/regression items non-required; smoke check still required | Logic, Integration, Contract and Security tests must pass | Full coverage check + regression suite |
| `/smoke-check` | Optional; a FAIL is advisory and never blocks hand-off; with no tests the stack bring-up and critical-journey checks carry the verdict | Required before a phase transition | Required before every commit |
| Regression suite | Not generated | Generated at Hardening-stage entry | Generated at Production-stage entry |
| Best for | Validate-fast products, internal tools | Most products | Enterprise, regulated data, learning, paranoid teams |

### Affected skills

| Skill | minimal | standard | full |
|-------|---------|----------|------|
| **story-done** | Skips the Logic/Integration/Contract/Config test-presence checks, the >50 %-untested escalation and the QA-coverage gate; criteria and the never-waived evidence still verified | Per-type evidence required | All types require evidence |
| **story-readiness** | The "test evidence requirement is clear" item auto-passes for Logic/Integration/Contract/Config | Per-type requirement validated | + coverage target validated |
| **dev-story** | Brief has no "Test required" line (the run-and-observe line stays) | Per-type test requirement passed to the lead | + coverage target passed |
| **smoke-check** | Optional, advisory (see above) | Required before a phase transition | Required before every commit |
| **gate-check** | No test gates except the smoke floor | Logic/Integration/Contract/Security pass | + coverage + regression suite |
| **qa-plan** | Minimal smoke plan: automated-test rows for Logic/Integration/Contract/Config dropped | Full plan per story type | + per-feature coverage targets |
| **regression-suite** | Not generated (stops early with NOT ASSESSED) | At Hardening entry | At Production entry |
| **team-qa** | Those story types are `WAIVED`; their acceptance-criteria walk is the evidence | The automated test is the evidence | Same |
| **test-evidence-review** | No-evidence stories are `WAIVED`; gaps in existing tests are ADVISORY | Reviewed; BLOCKING/ADVISORY from `testing.strict` | Same |
| **estimate** | Test volume waived; research, security negatives and run-and-observe still itemised | Test effort per type | + coverage effort |
| **retrospective**, **test-setup**, **create-stories** | Notes that test volume is waived and stories carry no test requirement | Per-type test requirements in stories | + coverage targets |
| **launch-checklist**, **release-checklist**, **team-release** | Release items follow the never-waived evidence; test-volume items are dropped | Per-type | Per-type + coverage |

---

## team.size

**Controls:** Which agents are active by default — a solo builder should not get a full-roster pipeline on every change
**Values:** `individual`, `small`, `studio`
**Default:** *none* — supplied by `modes.rigor` (`minimal` and `standard` yield `individual`, `full` yields `studio`)
**Set by:** `/start` (via `modes.rigor`), `/settings`
**Read by:** every skill whose bootstrap requests `team.size` (current list: `bash .claude/scripts/config-readers.sh team.size`)
**Locally overridable:** yes

**Priority chain:** `team.size` in `project.local.yaml` → `project.yaml` → the `modes.rigor` expansion (`full` → `studio`, else `individual`) → no terminal default. Locally overridable — it is a personal-experience knob, not an on-disk artifact.

> **`individual` at `minimal` and `standard`, `studio` at `full`.** Most products
> start with one or two builders, so the two lighter rigor tiers resolve to
> `individual`: one active agent per role. Only `rigor: full` opts into the full
> roster; a smaller team on a bigger product sets `team.size: small` explicitly,
> which wins over the rigor-derived value.

> **Different axis from `workflow`.** `workflow` controls what documents are
> required; `team.size` controls which agents exist to make them. Each `team-*`
> skill names its own set per value and announces, before Phase 1, which agents it
> will and will not spawn — the list in the skill is authoritative and the table
> below mirrors it.

### Affected skills

| Skill | individual | small | studio |
|-------|------|-------|--------|
| **team-ui** | `ux-designer` + the stack lead(s) for the layer(s) in scope; visual design runs through `/impeccable` in the session | + `ui-designer` (drives `/impeccable`) + `accessibility-specialist` | + `design-director` + the layer's framework specialist (`react-specialist`, `compose-ui-specialist` or `swiftui-specialist`) + an adversarial review pass in Phase 4 |
| **team-qa** | `qa-tester` only; `qa-lead` at phase gates only | `qa-lead` + `qa-tester` + `test-automation-engineer` | + per-story `qa-tester` spawn, `uat-coordinator` when UAT is in scope, sign-off |
| **team-release** | `release-manager` only | + `producer`, `platform-lead`, `qa-lead`, `customer-success` | + `localization-lead`, `performance-engineer`, `product-analytics-engineer`, `technical-writer` (self-hosted upgrade guide), and `security-lead` / `sre-lead` for their gates at `review_mode: full` |
| **team-hardening** | `performance-engineer` + `appsec-engineer`; no stack lead is active, so implementation items are handed to `/dev-story` | + `accessibility-specialist`, `qa-tester`, the stack lead(s) for the layer a finding lands in; a scheduled pentest is never spawned here — the user runs `/pentest <scope>` and the report is read if it exists | `small` + an adversarial review pass in Phase 5 |
| **team-growth** | `growth-lifecycle` + `pricing-billing-designer` | + `product-analytics-engineer` + `customer-success` | + `ux-designer`, `localization-lead`, `privacy-compliance-specialist` |
| **architecture-decision** | `cto` (`CTO-ADR`, at `review_mode: full`) + the stack lead for the ADR's layer | Same | Same — no sub-specialist or adversarial reviewer at any size |
| **gate-check** | Never changes how many directors spawn (that is `workflow`'s axis); affects only the specialist depth within each director's review: core set | Standard set | + the stack sub-specialists |

When a non-core agent is needed at `individual`, the skill emits an informational
note and routes through the nearest active agent.

### Special cases

- `team.size` does not decide whether directors run: `/gate-check`'s panel follows
  `review_mode` and `modes.workflow`, and no `team-*` pipeline spawns a PHASE-GATE.
  In a team skill, a "phase gate" is one of the decision points its own pipeline lists.
- `individual` does not disable agents — it only changes which are active by
  default. Any agent can still be invoked by name.
- `business-director` is consulted by `team-growth` only when the initiative changes
  prices, plans, trials, discounts or offers, at any `team.size`.

---

## performance.enforce

**Controls:** Whether performance budget violations warn or block
**Values:** `warn`, `block`, `off`
**Default:** `warn` (`_yaml_helper_defaults`)
**Set by:** `/settings`
**Read by:** every skill whose bootstrap requests `performance.enforce` (current list: `bash .claude/scripts/config-readers.sh performance.enforce`) — and `create-architecture`, `create-control-manifest`, `architecture-review` and `adopt` read it as project config
**Locally overridable:** yes

**Priority chain:** `performance.enforce` in `project.local.yaml` → `project.yaml` → hardcoded default `warn`, resolved by `resolve_config --keys performance.enforce` with its source.

> **Read it from the resolved block, never from `project.yaml` directly.** The key
> is on the `/settings --local` whitelist, so reading the file alone silently drops
> a developer's local override. An invalid value is ignored (the chain continues to
> `warn`) rather than propagated.

> **Budgets live in a document, not in `project.yaml`.** The numbers are in
> `docs/architecture/perf-budgets.md` (starting defaults in
> `.claude/docs/performance-standard.md`), and `performance.enforce` decides what a
> miss *means*. **Unset is not zero:** a budget file that is missing, or a profile
> with placeholder numbers, is not a measurement — `/perf-profile` and `/gate-check`
> report `NOT ASSESSED`, never a pass.

> **Mirrors the `testing.strict` pattern, and is independent of the workflow tier.**
> The performance check in `/gate-check` runs at every tier from Production →
> Hardening on, and `block` makes a breach a Blocker at every tier — a tier reduction
> never suppresses it. `off` is the only thing that makes budgets informational, and
> it is a deliberate choice on the same key.

### Value intent

| Value | Behaviour |
|-------|-----------|
| `warn` | Default. Profile runs flag violations as findings; CI logs them but does not fail; `/gate-check` surfaces them as Concerns, not Blockers; a Performance story's gate is ADVISORY |
| `block` | Violations are Blockers: DoD gate 6 is BLOCKING, `/story-done` and `/gate-check` fail on an over-budget surface from the Hardening gate onward; a Performance story's gate is BLOCKING; `/load-test` FAIL is BLOCKING |
| `off` | Budgets are informational only — measured values are still reported, but violations are not raised as findings and stay out of the verdict |

Only `warn`, `block` and `off` are recognised; a skill that meets anything else
surfaces it and falls back to `warn`.

---

## accessibility.target

**Controls:** The accessibility conformance level the product commits to — scopes the accessibility specialist's review and the contrast, focus and target-size criteria gates judge against
**Values:** `none`, `wcag-a`, `wcag-aa`, `wcag-aaa`
**Default:** `wcag-aa` — both in the template `project.yaml` and in `_yaml_helper_defaults`, so a project that removes the line still resolves `wcag-aa` (provenance `default`)
**Set by:** `/settings`
**Read by:** `accessibility-specialist` (judges every check against it; `none` is reported as a gap, never silently accepted), `ux-designer`, `ui-designer`, `web-lead`; the director gates `DD-PHASE-GATE`, `DD-VISUAL` and `DD-DESIGN-SYSTEM` (contrast, focus and target size meet the level); skills `create-architecture`, `create-control-manifest`, `create-stories` (UI-story criteria), `launch-checklist` (the target is met on the launch journeys), `adopt` (LOW severity: it carries a default), and `gate-check` (passes it to the design director). `resolve_config` emits it as `accessibility.target: <value> (<source>)` under the `accessibility` (or `accessibility.target`) key
**Locally overridable:** no

**Priority chain:** `accessibility.target` in `project.yaml` → default `wcag-aa`.

> **The setting is a default, not the committed document.** The commitment a build
> is gated on is `design/accessibility-requirements.md` (authored by `/ux-design`).
> `/team-ui` reports `Accessibility: NOT ASSESSED — no committed target` when that
> file is absent and never counts the gate as passed on the strength of
> `accessibility.target` alone.

### Value intent

| Value | Meaning | Routing |
|-------|---------|---------|
| `none` | No commitment. Reported as a gap in reviews | `accessibility-specialist` still runs where a pipeline names it |
| `wcag-a` | WCAG conformance level A | `accessibility-specialist` reviews against level A |
| `wcag-aa` | WCAG conformance level AA — the studio's baseline | `accessibility-specialist` reviews against level AA; contrast, focus-state and touch-target criteria in `DD-VISUAL` / `DD-DESIGN-SYSTEM` use the AA criteria |
| `wcag-aaa` | WCAG conformance level AAA | As above at level AAA; audit evidence expected at each phase |

---

## project.stage

**Controls:** The current lifecycle stage — determines which gate `/gate-check` validates next and what artifacts are expected to exist
**Values:** `Discovery`, `Product Design`, `Architecture`, `Pre-Production`, `Production`, `Hardening`, `Release`, `Live`
**Default:** none in the helper; the template ships `Discovery`
**Set by:** `/start` (the initial stage only, never `Hardening`, `Release` or `Live`), then `/gate-check` on a PASS or on a CONCERNS whose risks the user explicitly accepts (the accepted risks are recorded); a FAIL or NOT ASSESSED never advances it. Never write it by hand except to correct a wrong auto-detect
**Read by:** `create-architecture`, `gate-check`, `help`, `hotfix`, `launch-checklist`, `map-domains`, `milestone-review`, `post-release-fix`, `release-checklist`, `team-release` (bootstrap); `project-stage-detect`, `adopt`, `team-qa` (direct); `statusline.sh`, `session-start.sh`, `detect-gaps.sh` (hooks)
**Locally overridable:** no

> **This is a project attribute, not a mode.** It records where the product is in
> its lifecycle.

> **Legacy mirror + dual-write.** Stage is read from `project.stage` in
> `project.yaml` first, then the legacy `production/stage.txt`, then artifact
> auto-detection (`statusline.sh` and `/project-stage-detect`). `/gate-check` and
> `/start` dual-write BOTH `project.yaml` and `production/stage.txt`, so hooks that
> have not migrated still resolve correctly. `session-start.sh` warns — and never
> reconciles — when the two disagree. Resolution order for the helper:
> `project.yaml` → `production/stage.txt` → unset (the key is not locally overridable
> and has no `rigor` expansion or default).

### Stage progression and gate requirements

Each row is the gate that must be passed to enter the next stage; the argument to
`/gate-check` names the stage being entered (`product-design`, `architecture`,
`pre-production`, `production`, `hardening`, `release`, `live`).

| Current stage | Gate checks (full baseline; see `modes.workflow` for reductions) | `gate-check` writes |
|---------------|------------------------------------------------------------------|--------------------|
| **Discovery** | Product brief with required fields, principles, visual identity anchor | `Product Design` |
| **Product Design** | Domain map, MVP feature specs, cross-spec review, pricing model, entity registry | `Architecture` |
| **Architecture** | Stack configured, architecture doc, ADRs, traceability, threat models, budgets, design system, UX specs started, test framework, CI | `Pre-Production` |
| **Pre-Production** | Sprint plan, epics, stories, control manifest, UX specs, Accepted ADRs, research notes (vertical slice recommended) | `Production` |
| **Production** | All MVP features, tests per type, smoke check, QA sign-off, eight-gate evidence, no open S1 | `Hardening` |
| **Hardening** | Localization, security audit, tenant isolation, release-readiness gates (`SL-RELEASE-SECURITY`, `SRE-OPERABILITY`, `SRE-SLO` at `full`), no open S1–S3 at `full` | `Release` |
| **Release** | Release record, post-deploy smoke, observability live, backups, incident path, runbooks, status page | `Live` |
| **Live** | No next gate — `/project-stage-detect` and `/milestone-review` instead | — |

### Affected skills and hooks

| Reader | How it uses stage |
|--------|------------------|
| **gate-check** | Reads the current stage to pick the gate; writes the next stage on a PASS or an accepted CONCERNS |
| **project-stage-detect** | Uses `project.stage` as authoritative when set; falls back to heuristic detection only when absent |
| **help** | Uses stage to place you in the pipeline and surface the right next steps |
| **launch-checklist**, **release-checklist** | Items for stages not yet reached are out of scope and said so; `launch-checklist` runs `/gate-check` for Hardening → Release first when the stage is earlier than `Release` |
| **milestone-review** | SLO-readiness dimension applies at `Hardening` or later (not for a self-hosted-only product) |
| **post-release-fix** | Proceeds only when the stage is `Release` or `Live` |
| **team-release** | Stops before Phase 1 unless the stage is `Release` ("run `/gate-check release` first"); proceeding takes an explicit override recorded in the go/no-go record. Never writes the stage |
| **hotfix**, **create-architecture**, **map-domains**, **team-qa** | Read it for context and scoping |
| **detect-gaps.sh** | At `Hardening`, `Release` or `Live`, flags a missing `docs/architecture/slos.md` and an empty `docs/runbooks/` |
| **statusline.sh** | Shows the stage (heuristic when unset); at `workflow: minimal` shows `Minimal · <done>/<total> stories` instead, since nothing on that path runs `/gate-check` |

---

## Stack profile (overview)

The next six sections (`stack.*`), `deploy.target`, `distribution.model`,
`tenancy.model`, `layout.code_roots` and `core.*` are the **stack profile**: the
product facts every agent routes on. They are written by `/setup-stack` (never by
`/settings` guesses and never by `/start`), validated against `_yaml_helper_enums`,
and **locked** to `project.yaml`.

**The rule for all of them: unset is never defaulted to the permissive reading.**
`resolve_config` prints a layer that is empty as `unset`; routing a Ktor product to
Go agents because a key was missing is the failure that rule prevents. A check
that depends on an unset value reports `NOT ASSESSED` and names `/setup-stack`.

`resolve_config --keys stack` prints one line:

```
stack: backend=go web=vite-react site=astro mobile=kmp+swiftui deploy=compose-vps distribution=hybrid tenancy=shared-schema-rls data=postgres,redis (project.yaml; run /setup-stack if any layer is unset)
```

An enum-invalid value is printed as `INVALID(value)`, never as if configured.
**The line does not include** `stack.messaging`, `layout.code_roots`, `core.*`,
`accessibility.target` or the `workflow_overrides` flags — readers of those read
`project.yaml` directly (`get_yaml_key` / `get_yaml_array`). Every skill whose bootstrap names `stack` receives the
line (current list: `bash .claude/scripts/config-readers.sh stack`).

Pinned versions are **not** in `project.yaml`: they live in
`docs/stack-reference/<layer>/VERSION.md` and `docs/stack-reference/pins.yaml`,
written from sourced research.

**Hooks and scripts that read the profile:**

| Reader | Keys | What it does |
|--------|------|--------------|
| `session-start.sh` | `stack.backend`, `.web`, `.site`, `.mobile`, `.desktop`, `.data` | Prints `STACK REFERENCE MISSING for: …` for every configured layer (compound values split on `+`) that has no `docs/stack-reference/<part>/VERSION.md`; any configured `stack.desktop` needs the `desktop` layer's `VERSION.md` (not written yet: it comes from the first product's desktop `/research`) |
| `detect-gaps.sh` | `stack.backend`, `.web`, `.mobile`, `project.stage`, `modes.workflow`, code roots | Fresh-project banner; "code exists but `stack.backend` unset"; "NOT CHECKED: no code root"; contracts missing; research notes; `PRODUCT.md` when a UI layer is configured; specs expected at the tier |
| `statusline.sh` | `stack.backend` | Stage heuristic: a configured backend means at least `Architecture` |
| `project-coherence.sh` | `stack.backend`, `distribution.model` | `go.mod` presence for a Go backend; the self-hosted bundle check; compares declared versions against `pins.yaml` and emits `LICENCE` lines |

---

## stack.backend

**Controls:** The backend track — which backend lead and specialists a story is routed to
**Values:** `go`, `ktor`, `go+ktor`
**Default:** none — unset stays unset
**Set by:** `/setup-stack`
**Read by:** `dev-story` (lane routing), `code-review`, `create-stories`, `security-audit`, `test-setup`, `onboard`, `adopt`, `setup-stack`, `settings`, `start`; every skill with the `stack` line; the hooks above
**Locally overridable:** no

| Value | Routed to (via `principal-engineer`) | Stack reference |
|-------|-------------------------------------|-----------------|
| `go` | `go-lead` (+ `go-api-specialist`, `go-concurrency-specialist`) | `docs/stack-reference/go/` |
| `ktor` | `ktor-lead` (+ `kotlin-coroutines-specialist`, `kotlin-persistence-specialist`) | `docs/stack-reference/ktor/` |
| `go+ktor` | Both leads; the story's `Owner agent` line says which service. Two backends means two shared cores | `go/` and `ktor/` |
| *(unset)* | `/dev-story` STOPS — a layer with an unset value is a stop, not a default | none |

`core.track` follows the backend (`go` → `go`, `ktor` → `kotlin`). A Go backend with
no `go.mod` is reported `ABSENT` by `project-coherence.sh`.

## stack.web

**Controls:** The product web app — whether a web lane exists and who builds it
**Values:** `vite-react`, `none`
**Default:** none — unset stays unset
**Set by:** `/setup-stack`
**Read by:** `dev-story`, `security-audit`, `team-ui`, `test-setup`, `adopt`, `setup-stack`, `start`; the `stack` line; `detect-gaps.sh`, `session-start.sh`
**Locally overridable:** no

| Value | Effect |
|-------|--------|
| `vite-react` | Code root `web/`; story routed to `web-lead` (+ `react-specialist`); a static single-page app with no Node server in production. `detect-gaps.sh` expects `PRODUCT.md` at the repo root (impeccable's design context) |
| `none` | No web layer: `/dev-story` stops on a web story ("no web layer"); `PRODUCT.md` is not expected on its account |
| *(unset)* | `/dev-story` STOPS on a web story |

## stack.site

**Controls:** The marketing site
**Values:** `astro`, `none`
**Default:** none — unset stays unset
**Set by:** `/setup-stack`
**Read by:** `dev-story`, `security-audit`, `launch-checklist`, `test-setup`, `setup-stack`; the `stack` line; `session-start.sh`
**Locally overridable:** no

`astro` → code root `site/`, routed to `web-lead` (+ `astro-specialist`), static output;
`launch-checklist` adds the site items. `none` → no marketing site; unset → a site story stops.

## stack.mobile

**Controls:** The mobile apps and whether business logic is shared
**Values:** `compose`, `kmp`, `kmp+swiftui`, `swiftui`, `none`
**Default:** none — unset stays unset
**Set by:** `/setup-stack`
**Read by:** `dev-story`, `security-audit`, `launch-checklist`, `release-checklist`, `milestone-review`, `test-setup`, `adopt`, `setup-stack`, `start`; the `stack` line; `detect-gaps.sh`, `session-start.sh`
**Locally overridable:** no

| Value | Lanes |
|-------|-------|
| `compose` | Android (`mobile/android/`) → `android-lead` (+ `compose-ui-specialist`, `android-platform-specialist`) |
| `kmp` | KMP shared module (`mobile/shared/`) → `kmp-specialist` (+ `offline-sync-specialist` when the spec defines offline behaviour); Android → `android-lead` |
| `kmp+swiftui` | KMP shared + Android + iOS (`mobile/ios/`) → `ios-lead` (+ `swiftui-specialist`, `swift-concurrency-specialist`) |
| `swiftui` | iOS only → `ios-lead` |
| `none` | No mobile layer; `release-checklist` and `launch-checklist` read the store items as "not applicable — no mobile edition", stated |

A configured mobile layer also makes `detect-gaps.sh` expect `PRODUCT.md`. A
`kmp`-including value with a `go` backend is valid — the shared Kotlin module and
the backend then share no code.

## stack.data

**Controls:** The data stores the product uses — which data specialists and test fixtures apply
**Values:** a list of any of `postgres`, `mongo`, `redis`, `dragonfly` (written `data: [postgres, redis]` or as a block list)
**Default:** none — an empty list stays unset
**Set by:** `/setup-stack`
**Read by:** `create-architecture` (store choice per context), `test-helpers` (Testcontainers fixtures per member), `adopt`, `setup-stack`, `settings`; the `stack` line (comma-joined); `session-start.sh` (a stack reference per member)
**Locally overridable:** no

The helper does **not** enum-check this list (it is a list, not a scalar);
`/setup-stack` validates each member. `data-lead` routes to `postgres-specialist`,
`mongo-specialist` and `cache-specialist`. `dragonfly` is a **hosted-only** store:
it must not appear in the self-hosted customer bundle (`LICENCE` line from
`project-coherence.sh`, `.claude/rules/deploy.md`). Two stores for one job is a
finding.

## stack.desktop

**Controls:** The desktop client (for example a cashier or point-of-sale app on Windows) and who builds it
**Values:** free text decided by `/research` and an ADR — the chosen desktop runtime — or `none`; **not enum-checked** (the studio has no default desktop runtime)
**Default:** none — unset stays unset
**Set by:** `/setup-stack` (recorded as given; `NOT ASSESSED — stack.desktop has no decision record` when no research note or ADR names it)
**Read by:** `dev-story` (routes `desktop/` to the lead the ADR names; no ADR → STOP), `test-setup`, `setup-stack`, `start`; the `stack` line; `session-start.sh`
**Locally overridable:** no

Any configured value requires the cross-cutting `docs/stack-reference/desktop/`
layer (OS support window, packaging, bundled runtime, signing, auto-update);
`session-start.sh` and `/setup-stack` Phase 5 report it missing. A runtime that has
its own directory under `docs/stack-reference/` is required too.

---

## stack.messaging

**Controls:** The message broker or stream, when the architecture needs one
**Values:** free text decided by `/research` and an ADR — `nats`, `rabbitmq`, `kafka` or `none`; **not enum-checked**
**Default:** none — unset stays unset
**Set by:** `/setup-stack` (recorded as given, with a note that there is no stack reference for it)
**Read by:** `create-architecture` (data-flow: if empty, decides whether any flow needs asynchronous messaging), `setup-stack`; `messaging-specialist` reasons from it
**Locally overridable:** no

Not part of the `stack` line and not checked by `session-start.sh` for a stack
reference, so a broker without one is reported only by `/setup-stack` Phase 5.

---

## deploy.target

**Controls:** How the product is deployed — which topology `create-architecture`, the release skills and the infrastructure agents plan for
**Values:** `compose-vps`, `kubernetes`
**Default:** none — unset stays unset
**Set by:** `/setup-stack`
**Read by:** `create-architecture` (Deployment Topology), `architecture-decision`, `create-control-manifest`, `launch-checklist` and `release-checklist` (inputs to `SRE-OPERABILITY`), `team-release` (editions in play), `project-stage-detect`, `adopt`, `settings`; the `stack` line; the director gates `SRE-OPERABILITY` and `CTO-ARCHITECTURE`
**Locally overridable:** no

| Value | Effect |
|-------|--------|
| `compose-vps` | Docker Compose on a VPS — the studio's deployment rules (`.claude/rules/deploy.md`) and stack reference cover this. The same bundle is the self-hosted installer |
| `kubernetes` | Accepted by the helper, but there is no stack reference for it (`/setup-stack` Phase 5 reports the gap). With `distribution.model` of `self-hosted` or `hybrid`, `/setup-stack` raises a finding: the customer bundle is the Compose bundle |

`adopt` rates an unconfigured `deploy.target` HIGH when ADRs or code exist.

## distribution.model

**Controls:** Which editions the product ships — hosted, a customer-installed bundle, or both. It constrains deployment, tenancy, data-store choice and licence rules
**Values:** `hosted`, `self-hosted`, `hybrid`
**Default:** none — unset stays unset, and **unset is never read as `hosted`**
**Set by:** `/setup-stack` (asked first, because it constrains the rest)
**Read by:** `create-architecture` (hosted topology and self-hosted topology sections), `architecture-decision` (states each alternative's effect on both editions), `architecture-review` (licence check), `create-control-manifest` (self-hosted rules), `design-spec`, `review-all-specs` (edition coherence), `security-audit` (the self-hosted category), `gate-check` (licence rules, `SRE-SLO` skip), `milestone-review`, `launch-checklist`, `release-checklist`, `team-release`, `vertical-slice`, `prototype`, `pricing-check`, `project-stage-detect`, `adopt`; the `stack` line; `project-coherence.sh`
**Locally overridable:** no

| Value | Effect |
|-------|--------|
| `hosted` | Only `deploy/hosted/` applies. Self-hosted sections are written "not in scope — `distribution.model: hosted`", never left blank. Licence rules: "not applicable — hosted only", stated |
| `self-hosted` | The customer bundle in `deploy/self-hosted/` follows the licence rules (cache store Valkey only; MongoDB only as an `image:` reference to the official image; observability is the OTel Collector only; telemetry off by default; signed bundle). `SRE-SLO` is skipped when there is no hosted edition. `security-audit` adds the self-hosted category |
| `hybrid` | Both editions: every store choice and every ADR states its effect on each; both topologies are planned |
| *(unset)* | Licence-dependent checks report `NOT ASSESSED` naming `/setup-stack` |

`project-coherence.sh` reports `ABSENT deploy.self-hosted` when the value is
`self-hosted` or `hybrid` and no Compose file exists under `deploy/self-hosted/`.
Its `LICENCE` lines are driven by the **path** (`/self-hosted/`) of each Compose
file, not by this value.

## tenancy.model

**Controls:** How tenants are isolated — drives the isolation mechanism the architecture, migrations and tests must implement
**Values:** `shared-schema-rls`, `schema-per-tenant`, `db-per-tenant`, `single-tenant`
**Default:** none — unset stays unset; never assumed
**Set by:** `/setup-stack`
**Read by:** `security-audit` (category 3: unset → `NOT ASSESSED — tenancy.model unset`), `story-done` (inputs to `SL-TENANT-ISOLATION`; unset on a tenant-data story is `NOT ASSESSED`), `regression-suite` (tenant-isolation row unless `single-tenant`), `dev-story` and `vertical-slice` (RLS or the chosen mechanism on new tables), `code-review`, `create-architecture`, `create-epics`, `create-control-manifest`, `design-spec`, `review-all-specs` (a spec-versus-spec comparison when unset), `map-domains` (`CTO-CONTEXT-BOUNDARY`), `architecture-decision`, `prototype`, `project-stage-detect`, `adopt`; the `stack` line; the gates `CTO-PHASE-GATE` (agreement with the architecture doc and `deploy/`) and `CTO-ARCHITECTURE`
**Locally overridable:** no

| Value | Isolation |
|-------|-----------|
| `shared-schema-rls` | One schema, `tenant_id` on tenant-owned tables, app-layer scoping **and** Row-Level Security — the model the studio's tenant-isolation checks are written around |
| `schema-per-tenant` | A schema per tenant; isolation tested per schema |
| `db-per-tenant` | A database per tenant; strongest data separation, highest operational cost |
| `single-tenant` | One customer per deployment (natural with a self-hosted-only product); the tenant-isolation test row is not generated |

`migration-lint.sh` does not read this key: its "tenant-owned table without ENABLE
ROW LEVEL SECURITY" warning fires on any migration that creates a `tenant_id` table,
whatever the model.

## layout.code_roots

**Controls:** Which directories hold source — every hook and skill that scans, counts or writes source iterates this list
**Values:** a list of relative directory names (e.g. `[backend, web, mobile, contracts]`)
**Default:** none. **Unset does not default**: `resolve_code_root` falls back to detecting the conventional directories that exist on disk (`backend`, `web`, `site`, `mobile`, `desktop`, `contracts`, `core`); if none exist the result is empty and the caller must announce that its check did not run
**Set by:** `/setup-stack` (it records existing directories; it never scaffolds one). The helper does not validate the entries; `/setup-stack` reports a root that does not exist
**Read by:** `resolve_code_root` (prints the roots and a source of `layout.code_roots`, `detected` or `unset`) — called by `session-start.sh` (TODO/FIXME scan), `detect-gaps.sh` (checks 3–7), `validate-commit.sh` (source scans), `statusline.sh`, and the skills that scan source, including `dev-story`, `code-review`, `gate-check`, `security-audit`, `story-done`, `smoke-check`, `perf-profile`, `regression-suite`, `localize`, `test-setup` and `create-architecture`
**Locally overridable:** no

| State | Behaviour |
|-------|-----------|
| Set | Exactly those roots are scanned |
| Unset, conventional directories exist | Those directories are scanned; `source: detected` |
| Unset, none exist | Empty. `detect-gaps.sh` reports "NOT CHECKED: no code root resolved"; `validate-commit.sh` reports `SKIPPED` for the gofmt, debug-output, hardcoded-value, SQL-string and TODO-owner scans; `/gate-check` reports `NOT ASSESSED — code roots unresolved`. **Never reported as zero hits** |

`validate-commit.sh` scans staged source files under the resolved roots only, and
treats test and fixture paths as non-production. Code that lives outside the
resolved roots (`app/`, `services/`) is invisible to every one of these checks —
list it here.

---

## core.track

**Controls:** Which shared-core repository the product consumes. There is one core per backend track — `saas-core-go` and `saas-core-kotlin` — and a product uses the core of its track. The four `core.*` keys describe that dependency: `core.track` picks the core, `core.repo` locates it, `core.version` pins a released tag, `core.modules` lists the modules this product uses. Products pin a released version and never edit core code in place; the cores are built after the studio itself is finished
**Values:** `go`, `kotlin`
**Default:** none — unset stays unset
**Set by:** `/setup-stack` (follows `stack.backend`: `go` → `go`, `ktor` → `kotlin`; for `go+ktor` the user chooses, and the other backend then has no shared core yet)
**Read by:** `create-architecture`, `map-domains` (unset or no released version: record the context as built in the product, not "in core"), `dev-story`, `review-all-specs`, `spec-review`, `project-stage-detect`, `adopt` (MEDIUM when `stack.backend` is set and the track does not follow it), `setup-stack`; the `auth-identity-specialist` agent reads the identity module docs for the product's track. `resolve_config` does not print it
**Locally overridable:** no

`/setup-stack` raises a finding for a track that does not follow the backend, or a
track set while `stack.backend` is unset.

| Value | Core repository | Follows | What it changes |
|-------|-----------------|---------|-----------------|
| `go` | `saas-core-go` | `stack.backend: go` | Specs and architecture may claim a capability is "in core" only when a released module of this track covers it; `/map-domains` and `/create-architecture` record contexts that rely on an unreleased module as built in the product |
| `kotlin` | `saas-core-kotlin` | `stack.backend: ktor` | Same rule against the Kotlin core; the KMP and Android clients consume this track's client pieces |
| *(unset)* | none | — | Every "belongs in core" claim is reported as unconfirmed; nothing is defaulted from `stack.backend` |

The mapping is a convention checked by `/setup-stack` (a cross-field finding) and
`/adopt` (MEDIUM severity), not by the helper: `core.track` is enum-checked on its own
(`go` or `kotlin`) but not against `stack.backend`. For `go+ktor` there is no single
track, so the user chooses which backend the shared core serves.

## core.repo

> ### RESERVED - NOT IMPLEMENTED
>
> **No skill or hook reads this setting. Setting it has no effect.** Everything
> below describes the intended design, not current behaviour.
>
> The value is not checked when you set it, and nothing reads it. `/setup-stack`
> writes it when the user supplies a released core to pin. The skills that will
> read it (`/core-use`, `/core-extract`, `/core-upgrade`, `/core-release`) are not
> built yet.

**Controls:** Where the track's core repository lives
**Values:** a git URL or a local path (free text, not validated)
**Default:** none (unset)
**Set by:** `/setup-stack`, only when the user has a released core to pin
**Read by:** nothing yet (intended readers: the core-consumption skills)
**Locally overridable:** no

## core.version

**Controls:** The released core tag the product pins (e.g. `v0.4.2`)
**Values:** a release tag (free text, not validated)
**Default:** none — unset means the pin cannot be read
**Set by:** `/setup-stack` when supplied; bumped by the core-upgrade flow once it exists
**Read by:** `create-architecture` (shared-core modules used, at this version), `create-control-manifest` ("capabilities come from `saas-core` modules at the pinned version"), `create-epics` (the epic's shared-core module row), `design-spec` and `review-all-specs` (a capability is "in core" only if a released module covers it; otherwise `core pin not readable`), `spec-review` (`⚠ core: <module> — pin not readable (core.version unset)`), `launch-checklist` and `release-checklist` (product and pinned core version in the release record)
**Locally overridable:** no

An unset pin is reported by name wherever a claim "belongs in core" would rest on
it — never silently accepted. A `version_bumps` decision (see
`modes.automation_always_ask`).

## core.modules

**Controls:** The core modules this product consumes (identity, observability, OTP, notifications, storage, billing, licensing, tenancy, audit, rate-limiting, …)
**Values:** a list of module names (not validated)
**Default:** none — an empty list stays unset
**Set by:** `/setup-stack` when supplied
**Read by:** `create-architecture` (for each module in use, whether it adds a deployable or a data store), `create-control-manifest` (approved modules @ version), `test-helpers` (a port that comes from a core module is faked from the module's contract, not re-derived), `setup-stack`
**Locally overridable:** no

---

## features.session_state

**Controls:** Whether the harness runs the full session-tracking pipeline (hooks, log files, the `active.md` checkpoint preview) or relies on skeleton-first output files for recovery
**Values:** `on`, `off`
**Default:** `on`
**Set by:** `/settings`
**Read by:** six hooks — `session-start.sh` (its recovery preview only), `pre-compact.sh`, `post-compact.sh`, `session-stop.sh`, `log-agent.sh` and `log-agent-stop.sh`. No skill reads it, and neither does `statusline.sh`
**Locally overridable:** yes

> **`on` is the recommended setting.** Long-form skills write self-describing
> skeleton files upfront, which covers much of mid-task recovery on its own; the
> pipeline adds the checkpoint preview at session start, the session archive and the
> subagent tally. Turn it `off` only to save that preview's tokens.

> **Priority chain:** `features.session_state` in `project.local.yaml` →
> `project.yaml` → hardcoded default **`on`**. Hooks read it via
> `session_state_enabled()` in `yaml-helper.sh` and exit early when `off`. The
> function disables only on the literal `off`: writing `false` there means
> *enabled*, which is why the key is enum-checked (`on`/`off`). Skills do not read
> it: `/dev-story` and `/story-done` update the checkpoint in `active.md` whatever
> its value.

> **The default is `on`, deliberately.** `.claude/docs/context-management.md` tells
> you to rely on `production/session-state/active.md` as your crash-recovery
> checkpoint, so defaulting it off would quietly remove recovery, the session
> archive and the subagent tally. What `off` saves — the checkpoint preview, at most
> ~750 tokens per session start — is an explicit opt-out
> (`/settings features.session_state=off`), never a silent default.

> **`session-start.sh` is gated per block, not at the top.** Its sprint, milestone,
> git, stack-reference and schema-validation context is not part of the session-state
> pipeline; only the `active.md` recovery preview is gated. Its check fails OPEN:
> that hook sources `yaml-helper.sh` conditionally, and an undefined function is
> falsey, which would suppress the recovery checkpoint invisibly.

### Value intent

| Value | Intent |
|-------|--------|
| `off` | Recovery via skeleton-first output files. The six hooks do nothing, so no logs; skills still update the checkpoint in `active.md`, but session start does not show it |
| `on` | Full session tracking: session-stop archival, compaction log and agent audit log all active. Adds the checkpoint preview to each session start, capped at 25 lines or 3,000 characters (at most ~750 tokens). Compaction hooks log to disk and add nothing to Claude's context |

### Hook behaviour

The check lives inside each hook script, not at the harness level: every
session-state-aware hook calls `session_state_enabled()` at its top and exits
silently on `off` (except `session-start.sh`, which skips only its recovery
preview), so the harness always fires the hook and the hook decides whether to act.

| Hook | session_state: off | session_state: on |
|------|--------------------|-------------------|
| **session-start.sh** | Runs normally (git, sprint, stack-reference and schema context); skips the `active.md` checkpoint preview | Runs fully, including the checkpoint preview |
| **pre-compact.sh** | No-op | Writes the checkpoint block, changed/untracked file names and WIP markers to the debug log and appends to the compaction log |
| **post-compact.sh** | No-op | Prints a re-read reminder to the debug log (`session-start.sh` restores context) |
| **session-stop.sh** | No-op | Archives `active.md` to `session-log.md` when it changed, appends commits and uncommitted file names, writes the subagent tally to `session-cost.md` |
| **log-agent.sh**, **log-agent-stop.sh** | No-op | Append spawn and completion events to `agent-audit.log` |
| **detect-gaps.sh**, **log-instructions.sh**, validation hooks | Unchanged — independent of session state | Unchanged |

| File | off | on |
|------|-----|----|
| `production/session-state/active.md` | Still written by skills; session start does not show it | Written by skills; session start shows its checkpoint |
| `production/session-logs/session-log.md` | Not written | Append-only archive of each session's `active.md` |
| `production/session-logs/compaction-log.txt` | Not written | Append-only timestamp log of compaction events |
| `production/session-logs/agent-audit.log` | Not written | Append-only log of agent spawn and completion |
| `production/session-logs/session-cost.md` | Not written | Subagent spawn tally |

### Skeleton-first pattern (the `off` recovery mechanism)

Long-form skills write a skeleton file as their first action — all section headers
with empty bodies and a placeholder per section — before any section discussion.
As each section is approved the placeholder is replaced. On recovery (after
`/clear` or compaction) the agent reads the skeleton, finds the unfinished sections,
reads the relevant ADRs and the domain map, and resumes at the first one.

| Skill | Output file |
|-------|-------------|
| **design-spec** | `design/specs/[feature].md` — skeleton created after a "May I create the skeleton?" ask, before section discussion |
| **ux-design** | `design/ux/[screen].md` (and the app-shell, pattern-library and accessibility modes) — skeleton mirrors the template |
| **map-domains** | `design/specs/domain-map.md` — file skeleton created immediately |

`architecture-decision` emits the ADR skeleton from its template when it generates;
the other long-form skills (`create-architecture`, `create-epics`, `create-stories`)
write once, after their ask, and keep their progress in `active.md` as they go.

### Skills and `active.md` (not gated by this setting)

Skills read `active.md` to fill in a missing argument and write a checkpoint or
extract when they finish; neither depends on `session_state`.

| Skill | Reads from `active.md` | Writes to `active.md` |
|-------|------------------------|----------------------|
| **dev-story** | The active story path when no argument is given | Checkpoint: story, next step, blockers, files, run result |
| **story-done** | The in-progress story path | Checkpoint: verdict, story, next story |
| **team-release** | The target version | — |
| **team-qa** | The active sprint | QA phase comment, blocking issues |
| **code-review** | `Files in progress` for the active story | — |
| **help** | The STATUS and CHECKPOINT blocks, for context-aware suggestions | — |
| **map-domains**, **create-architecture**, **vertical-slice**, **prototype** | — | Task record and decisions as they are made |
| **qa-plan**, **consistency-check** | — | A silent session extract on completion |

### Token cost summary

| Scenario | off | on |
|----------|-----|----|
| Per session start | ~500 tokens (git, sprint, stack context only) | ~500–1,250 tokens (+ the checkpoint preview, at most ~750) |
| Per compaction event | 0 | 0 (logged to disk only) |
| Per session end | 0 | File I/O only |
| Recovery after `/clear` | Read the skeleton + 2–3 docs (~1,000–3,000 tokens) | Read `active.md` (~200–500 tokens) |

---

## features.token_budget_warn_at

> ### RESERVED - NOT IMPLEMENTED
>
> **No skill or hook reads this setting. Setting it has no effect.** Everything
> below describes the intended design, not current behaviour.
>
> The value is not checked when you set it (it is not enum-typed), and nothing reads
> it. Nothing warns at any threshold. It is on the local-override whitelist, so
> `/settings --local` stores it, and stores it silently unless the banner is heeded.

**Controls:** Context-usage threshold at which session warnings fire
**Values:** a float between 0.0 and 1.0
**Default:** `0.7` (warn at 70 %) — documented intent only; nothing applies it
**Set by:** `/settings`
**Read by:** nothing yet (intended readers: `statusline.sh`, `session-start.sh`, `pre-compact.sh`)
**Locally overridable:** yes

**Priority chain:** `features.token_budget_warn_at` in `project.local.yaml` → `project.yaml` → documented default `0.7`.

> Intended behaviour: surface a warning when session context usage exceeds the
> threshold, to help cost-conscious users `/clear` before runaway sessions; `1.0`
> disables it. Today `statusline.sh` shows context usage without a threshold.

---

## schema_version and framework

**Controls:** Which schema version `project.yaml` conforms to (`schema_version`) and which studio template the product was created from (`framework.name`, `framework.version`, `framework.derived_from`)
**Values:** `schema_version`: an integer; `framework.*`: strings
**Default:** `schema_version: 1`; `framework` is stamped in the template's `project.yaml`
**Set by:** the template; `/start` writes both blocks when it has to create a minimal `project.yaml`
**Read by:** no skill branches on either — they are file metadata, not behavioural settings. `/adopt` prints `framework.version` in its report header. `schema_version` and `framework.*` are exempt from the local-scope check: a `project.local.yaml` that carries `schema_version: 1` is correct as written
**Locally overridable:** no

```yaml
schema_version: 1
framework:
  name: saas-studio
  version: 0.1.0
  derived_from: "<template name and version>"
```

`schema_version` lets a future studio version detect and migrate an old
`project.yaml`. No migration tooling exists yet, and no value of
`schema_version` changes behaviour today.

---

## Complete example `project.yaml`

A full `project.yaml` showing every setting. The six knobs `modes.rigor` fronts are
**commented out on purpose**: seeding any of them pins that value and shadows the
rigor expansion. Uncomment one only to vary it from the rigor level.

```yaml
schema_version: 1

framework:
  name: saas-studio
  version: 0.1.0
  derived_from: "<template name and version>"

project:
  name: "Acme Invoicing"
  stage: Pre-Production      # Discovery | Product Design | Architecture | Pre-Production | Production | Hardening | Release | Live

modes:
  rigor: standard            # minimal | standard | full — supplies the six knobs below
  automation: collaborative  # collaborative | guided | autonomous
  automation_always_ask:     # decision categories that always prompt regardless of mode
    - scope_changes
    - file_deletions
    - schema_changes
  # review_mode: lean        # full | lean | solo           (fronted by rigor)
  # workflow: standard       # minimal | standard | full    (fronted by rigor)
  # story_granularity: balanced  # coarse | balanced | fine (fronted by rigor)

# TOP-LEVEL, not nested under `modes:` — resolve_config reads
# `workflow_overrides.system_overrides.*` from the document root, and every skill
# reads the same top-level path. Nesting it under `modes:` parses as valid YAML and
# is silently never read.
workflow_overrides:
  edge_cases: false          # force Edge Cases & Failure Modes required at every tier
  tuning_knobs: false        # force a Configuration subsection in Non-Functional Requirements
  system_overrides: {}       # { billing: full, changelog-page: minimal } — key = spec filename stem

docs:
  # density: balanced        # terse | balanced | thorough  (fronted by rigor)

qa:
  # level: standard          # minimal | standard | full    (fronted by rigor)

team:
  # size: individual         # individual | small | studio  (fronted by rigor)

testing:
  strict:
    logic: true              # unit-test failures BLOCK story closure
    integration: true        # Testcontainers failures BLOCK
    contract: true           # contract-test failures BLOCK
    security: true           # missing negative tests / ASVS-MASVS mapping BLOCK
    performance: false       # advisory; BLOCKING when performance.enforce: block
    ui: true                 # missing screenshot / audit BLOCKS
    config: false            # advisory only
    # visual: —              # RESERVED, nothing reads it

# --- Stack profile (written by /setup-stack) --------------------------------
stack:
  backend: go                # go | ktor | go+ktor
  web: vite-react            # vite-react | none
  site: astro                # astro | none
  mobile: kmp+swiftui        # compose | kmp | kmp+swiftui | swiftui | none
  desktop: none              # decided by /research + ADR | none
  data: [postgres, redis]    # any of: postgres, mongo, redis, dragonfly
  messaging: ""              # decided by /research + ADR (nats | rabbitmq | kafka | none)

deploy:
  target: compose-vps        # compose-vps | kubernetes

distribution:
  model: hybrid              # hosted | self-hosted | hybrid

tenancy:
  model: shared-schema-rls   # shared-schema-rls | schema-per-tenant | db-per-tenant | single-tenant

layout:
  code_roots: [backend, web, site, mobile, contracts]

core:
  track: go                  # go | kotlin — follows stack.backend
  repo: ""                   # RESERVED: git URL or local path of the track's core repo
  version: v0.4.2            # pinned release tag
  modules: [identity, billing, licensing]

performance:
  enforce: warn              # warn | block | off — budgets live in docs/architecture/perf-budgets.md

accessibility:
  target: wcag-aa            # none | wcag-a | wcag-aa | wcag-aaa

features:
  session_state: on          # off | on
  # token_budget_warn_at: 0.7  # RESERVED, nothing reads it
```

And a minimal sparse `project.local.yaml` — a single developer who wants
autonomous mode and an advisory performance gate locally:

```yaml
modes:
  automation: autonomous
testing:
  strict:
    performance: false
features:
  session_state: on
```

Only the overridden keys are present; everything else cascades from
`project.yaml`. Any key outside the 15 on the whitelist would be ignored and named
on the `notes:` line. See "Local Override Pattern" for the full whitelist.
