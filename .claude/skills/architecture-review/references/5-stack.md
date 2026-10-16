# /architecture-review — Phases 5 and 5b: Stack and Licence Cross-Check, Spec Revision Flags

> Part of `/architecture-review`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 5: Stack Version and Licence Cross-Check

**In this file:**

- Version Consistency
- Post-Cutoff API Consistency
- Deprecated API Check
- Licence Conflicts with Customer Bundles
- Missing Stack Compatibility Sections
- Stack Lead Consultation

Across all ADRs, check for stack consistency:

### Version Consistency
- Do all ADRs that name a version agree with `docs/stack-reference/pins.yaml` and with each other?
- If any ADR was written against an older pin, or `Last Verified` predates the
  `VERSION.md` verification date of a layer it names, flag it as potentially stale
- A pin below a security floor recorded in `VERSION.md` (for example a framework patch floor) is a finding, not a note

### Post-Cutoff API Consistency
- Collect all "Post-Cutoff APIs Used" fields from all ADRs
- For each, verify against the relevant stack-reference page (`best-practices.md`, `breaking-changes.md`)
- Check that no two ADRs make contradictory assumptions about the same API
- Any API with no stack-reference page is `NOT SOURCEABLE` — report it by name

### Deprecated API Check
- For each layer in use, read `docs/stack-reference/<layer>/deprecated-apis.md`
  and Grep all ADRs for the API/pattern names it lists
- Flag any ADR whose Decision, Key Interfaces or Implementation Guidelines
  reference a deprecated API or pattern
- **A layer whose `deprecated-apis.md` could not be read is reported as not checked**
  (`Deprecated API check: NOT ASSESSED for <layer>`), never as clean

### Licence Conflicts with Customer Bundles
*Runs when `distribution.model` is `hybrid` or `self-hosted`. Otherwise record
`Licence check: not applicable — distribution.model is hosted`.*

Check every ADR and, if present, `deploy/self-hosted/` against the rules in
`.claude/rules/deploy.md` and `docs/ROADMAP.md`:

| Rule | Conflict if an ADR or bundle file ... |
|---|---|
| Cache = Valkey only | selects Dragonfly or Redis >= 7.4 for a component that ships in the bundle, or depends on a command outside the portable subset |
| MongoDB = reference the official image | ships a Mongo binary, tarball or derived image |
| Observability = OTel Collector only, exporters off | bundles Grafana/Loki/Tempo/Mimir or enables telemetry by default |
| Signed licences, offline-capable | requires an online licence check with no offline grace |
| Upgrade path | requires a migration that cannot run offline or across skipped versions |

Hosted-only choices (Dragonfly, Redis 8.2, a hosted observability backend) are
fine **when the ADR says hosted-only** and nothing in the bundle depends on them.
A conflict found here is an **Edition** conflict (Phase 4 table) and **blocks the
verdict** — it is a blocking finding, not a note.

### Missing Stack Compatibility Sections
- List all ADRs that are missing the Stack Compatibility section entirely
- These are blind spots — their stack assumptions are unknown

Output format:
```
### Stack Audit Results
Stack: [layers + pinned versions]
ADRs with Stack Compatibility section: X / Y total

Deprecated API References:
  - ADR-0002: uses [deprecated API] — deprecated since [version]; see docs/stack-reference/<layer>/deprecated-apis.md

Stale Version References:
  - ADR-0001: written for [older pin] — current pin is [version]

Post-Cutoff API Conflicts:
  - ADR-0004 and ADR-0007 both use [API] with incompatible assumptions

Licence Conflicts (customer bundle):
  - ADR-0006: selects [component] — breaks [rule]; hosted-only if re-scoped

NOT SOURCEABLE / not checked:
  - [layer or API] — not covered by docs/stack-reference/
```

---

### Stack Lead Consultation

After completing the stack audit above, spawn the relevant **stack lead(s)** via `Agent` for a domain-expert second opinion:
- Resolve leads from the layers present in the audit: `go-lead` / `ktor-lead` (backend), `web-lead`, `android-lead`, `ios-lead`, `kmp-specialist`, `data-lead` (stores, cache, messaging), `platform-lead` (deploy). When more than two layers are present, ask `principal-engineer` to route.
- If no stack layer is configured, skip this consultation **and record `Stack validation: NOT ASSESSED — no stack configured` in this run's output.** A skipped check that says nothing is indistinguishable from a check that passed; the reader cannot tell stack guidance was never sought.
- Spawn each lead with: all ADRs that contain stack-specific decisions or `Post-Cutoff APIs Used` fields, the stack reference paths, and the Phase 5 audit findings. Ask them to:
  1. Confirm or challenge each audit finding — leads may know of nuances not captured in the reference docs
  2. Identify stack-specific anti-patterns in the ADRs that the audit may have missed (blocking calls on coroutine dispatchers, thread-per-request assumptions, SPA state that the contract should own, ORM leakage into `domain`)
  3. Flag ADRs that make assumptions about behaviour that differ from the actual pinned version

Incorporate additional findings under `### Stack Lead Findings` in the Phase 5 output. These feed into the final verdict — lead-identified issues carry the same weight as audit-identified issues.

---

## Phase 5b: Spec Revision Flags (Architecture → Spec Feedback)

For each **HIGH RISK stack finding** or licence conflict from Phase 5, check
whether any spec makes an assumption that the verified stack reality contradicts.

Specific cases to check:

1. **Post-cutoff API behaviour differs from training-data assumptions**: If an ADR
   records a verified behaviour that differs from the default model assumption,
   check all specs that reference the related feature. Look for rules written
   around the old (assumed) behaviour.

2. **Known stack limitations in ADRs**: If an ADR records a known limitation
   (e.g. "the Valkey bundle lacks a module the hosted cache uses", "RLS is bypassed
   by table owners"), check specs that design behaviour around the affected feature.

3. **Deprecated API conflicts**: If Phase 5 flagged a deprecated API used in an ADR,
   check whether any spec contains behaviour that assumes the deprecated API.

4. **Edition promises**: a spec that promises a feature in the self-hosted edition
   that a licence conflict makes impossible.

For each conflict found, record it in the Spec Revision Flags table:

```
### Spec Revision Flags (Architecture → Spec Feedback)
These spec assumptions conflict with verified stack behaviour, licence rules or accepted ADRs.
The spec should be revised before its feature enters implementation.

| Spec | Assumption | Reality (from ADR/stack-reference) | Action |
|------|-----------|------------------------------------|--------|
| reports.md | "Use a Dragonfly-only command for ranking" | Bundle uses Valkey — ADR-0006 | Revise spec |
```

If no revision flags are found, write: "No spec revision flags — all spec assumptions
are consistent with verified stack behaviour and licence rules."

Before asking, display the proposed change inline — show the current domain-map row for each flagged spec and the proposed updated row side by side so the user can see exactly what will change.

Then use `AskUserQuestion`:
- "I found [N] spec revision flag(s). May I update the domain map?"
  - [A] Yes — apply all [N] updates to the domain map now
  - [B] Show me the full diff first, then ask again
  - [C] No — leave the domain map unchanged for now

If [A]: apply the updates. Status field must be exactly `Needs Revision` — no parentheticals
(other skills match that exact string and parentheticals break the match).
If [B]: display the complete proposed domain-map section, then re-ask with `AskUserQuestion`.

---
