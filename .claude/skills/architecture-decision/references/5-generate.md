# /architecture-decision — Step 5: Generate the ADR

> Part of `/architecture-decision`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 5. Generate the ADR

**In this file:**

- The ADR skeleton (the template, and what each section must contain)
- 5.5 Stack Lead Validation
- 5.6 CTO Strategic Review (CTO-ADR, CTO-STACK-RISK), with the review mode check
- 5.7 Spec Sync Check: found, none found, could not check
- Write approval
- Update Architecture Registry, and the registry append logic

Fill `.claude/docs/templates/architecture-decision-record.md` — that template is the
skeleton and the single source of section order. Its sections are all emitted
(none dropped at any `docs.density`). What each must contain beyond the template's
own prompts:

- **Status** — `Proposed`. The ownership note in the template (user, or `cto` on the user's explicit confirmation) stays in the file.
- **Date / Last Verified** — today's date for both on creation.
- **Summary** — 2 specific sentences naming the bounded context, the problem and the chosen approach (used for tiered loading).
- **Stack Compatibility** — layers, domain, `Layer` (Foundation / Core / Feature / Presentation — the ADR's own layer, and `Foundation` for every critical ADR), Knowledge Risk, References Consulted, pinned versions (must match `pins.yaml`), post-cutoff APIs used, verification required. Add a line `Critical ADR: yes | no — [reason]` directly beneath the table.
- **ADR Dependencies** — never `None` unless confirmed; never `UNKNOWN` in the file.
- **Context** — problem, current state, constraints, requirements, and a line `Research note: [docs/research/<feature>.md | NOT FOUND — required before Accepted]`.
- **Decision** — with diagram-as-code, key interfaces (link `contracts/`), and **Implementation Guidelines** written as "must / must never" so `/create-control-manifest` and `/dev-story` extract them cleanly, naming the layer (`domain` / `app` / `adapters`) and context each rule applies to.
- **Alternatives Considered** — at least two rejected alternatives, each with **Cost, Risk, Performance, Operability** (hosted and self-hosted) and a rejection reason specific to this product. A generic reason ("less popular") fails CTO-ADR.
- **Consequences / Risks** — what becomes harder, what it costs, what must be revisited and when.
- **Cross-Cutting Impact** — one line each for security/tenancy, observability, caching, self-hosted, cost. "None" is valid; blank is not. Security-sensitive: ASVS/MASVS refs and the threat-model link (`docs/architecture/threat-models/<feature>.md`).
- **Performance Implications** — against `docs/architecture/perf-budgets.md`; if the budget file is missing say `budget not yet set`, never invent numbers.
- **Migration Plan / Validation Criteria** — forward-only production migrations, the self-hosted upgrade path, rollback; measurable criteria including a negative/security criterion.
- **Spec Requirements Addressed** — the table with TR-IDs, or "Foundational — no spec requirement. Enables: ...".
- **Related** — related ADRs (supersedes/contradicts/depends on), research note, threat model, runbook, code paths once built.

Superseding an ADR: write the new ADR, mark the old one `Superseded by ADR-NNNN`
by appending to its Status only — never edit the old decision text
(`.claude/rules/architecture-docs.md`).

5.5. **Stack Lead Validation** — Before saving, spawn the **stack lead for the ADR's layer** via `Agent` to validate the drafted ADR:
   - Resolve the lead: Go backend → `go-lead`; Ktor → `ktor-lead`; Web/Marketing → `web-lead`; Android → `android-lead`; iOS → `ios-lead`; KMP → `kmp-specialist`; Data/messaging/cache → `data-lead`; Deploy → `platform-lead`; API contract → `api-designer`. A decision spanning layers asks `principal-engineer` to route.
   - If `stack` has no layer configured for the decision, skip this step **and record `Stack validation: NOT ASSESSED — no stack layer configured for this decision`** in this run's output. A skipped check that says nothing is indistinguishable from a check that passed; the reader cannot tell stack guidance was never sought.
   - Spawn with: the ADR's Stack Compatibility section, Decision section, Key Interfaces, and the stack-reference paths. Ask them to:
     1. Confirm the proposed approach is idiomatic for the pinned stack versions
     2. Flag any APIs or patterns that are deprecated or changed (`deprecated-apis.md`, `breaking-changes.md`)
     3. Identify stack-specific risks or gotchas not captured in the ADR draft
   - If the lead identifies a **blocking issue** (wrong API, deprecated approach, version incompatibility, licence conflict for the customer bundle): revise the Decision and Stack Compatibility sections accordingly, then confirm the changes with the user before proceeding
   - If the lead finds **minor notes** only: incorporate them into the ADR's Risks table

**Review mode check** — apply before spawning CTO-ADR:
- `solo` → skip. Note: "CTO-ADR skipped — Solo mode." Proceed to Step 5.7 (spec sync check).
- `lean` → skip (not a PHASE-GATE). Note: "CTO-ADR skipped — Lean mode." Proceed to Step 5.7 (spec sync check).
- `full` → spawn as normal.

5.6. **CTO Strategic Review** — After the stack lead validation, spawn `cto` via `Agent` using gate **CTO-ADR** (`.claude/docs/director-gates/cto-adr.md`):
   - Pass: the ADR file path (or draft content), the stack versions for the touched layers (`pins.yaml`), related ADRs with statuses, the research note path, the TR-IDs claimed
   - The CTO validates architectural coherence (is this decision consistent with the whole system, both editions, and the licence rules?) — distinct from the stack lead's API-level check
   - If the decision depends on an API or behaviour beyond `docs/stack-reference/` (Step 1 flagged it, or the lead's review did), also spawn `cto` for **CTO-STACK-RISK** (`.claude/docs/director-gates/cto-stack-risk.md`) with the API/feature and the reference paths. The same review modes apply.
   - On CONCERNS: show them to the user verbatim and ask with the standard options from `director-gates.md` — `Revise flagged items` / `Accept and proceed` / `Discuss further`. Revise the flagged Decision or Alternatives sections only on `Revise flagged items`.
   - On REJECT: show the blockers verbatim and revise the Decision or Alternatives sections before proceeding.
   - If `cto` authored the decision, the gate requires a recorded second review by `principal-engineer`.
   - A revised draft still reaches the user through the write approval below; nothing is written before it. A `NOT ASSESSED` answer is not an approval — name the missing input (`director-gates.md`). Record the verdict (or the skip and its mode) in the ADR's Decision Makers / Related section.

5.7. **Spec Sync Check** — Before presenting the write approval, scan all specs
referenced in the "Spec Requirements Addressed" section for naming inconsistencies
with the ADR's Key Interfaces and Decision sections (renamed endpoints, events,
fields or entities). If any are found, surface them as a **prominent warning block**
immediately before the write approval — not as a footnote:

```
⚠️ SPEC SYNC REQUIRED
[spec-filename].md uses names this ADR has renamed:
  [old_name] → [new_name_from_adr]
  [old_name_2] → [new_name_2_from_adr]
The spec (and the contract in contracts/) must be updated before or alongside
writing this ADR to prevent developers implementing the wrong interface.
```

**This check has three outcomes, not two.** The two above are "found" and "none
found"; the third is **could not check**, and it must not fall through the
silent branch and render exactly like a clean result.

- **None found** — print one line, do not stay silent:
  `Spec sync: checked [N] referenced spec(s), no naming inconsistencies.`
  A silent pass is indistinguishable from a check that never ran.
- **Could not check** — the ADR has no `Spec Requirements Addressed` section,
  it names no specs (a foundational ADR), or a named spec does not exist on disk. Print:
  `Spec sync: NOT ASSESSED — [which reason, and which files]`
  Do **not** treat an ADR that references no specs as one whose specs are
  consistent. Nothing was compared.

Only the warning block itself is conditional; the check always reports.

5. **Write approval** — Use `AskUserQuestion`:

If spec sync issues were found:
- "ADR draft is complete. How would you like to proceed?"
  - [A] Write ADR + update the spec in the same pass
  - [B] Write ADR only — I'll update the spec manually
  - [C] Not yet — I need to review further

If no spec sync issues:
- "ADR draft is complete. May I write it?"
  - [A] Write ADR to `docs/architecture/adr-[NNNN]-[slug].md`
  - [B] Not yet — I need to review further

If yes to any write option, write the file, creating the directory if needed.
For option [A] with spec update: also update the spec file(s) to use the new names.

6. **Update Architecture Registry**

Scan the written ADR for new architectural stances that should be registered:
- Data it claims ownership of (context → store → tables/collections)
- Tenancy rules it sets
- Interface contracts it defines (port signatures, event names, `contracts/` files)
- Performance budget it claims
- Technology choices it makes explicitly (store, broker, library at a pinned version)
- Patterns it bans (Consequences → Negative or explicit "do not use X")

Present candidates:
```
Registry candidates from this ADR:
  NEW data ownership:       invoices → billing context (postgres)
  NEW tenancy rule:         every query scoped by TenantContext; RLS on all tables
  NEW interface contract:   InvoicePaid event via outbox
  NEW performance budget:   invoice list endpoint p95 150 ms
  NEW forbidden pattern:    cross-context table reads
  EXISTING (referenced_by update only): plan_changed already registered
```

**Registry append logic**: When writing to `docs/registry/architecture.yaml`, do NOT assume sections are empty. The file may already have entries from previous ADRs written in this session. If the file does not exist, create it with the sections `data_ownership`, `tenancy_rules`, `interface_contracts`, `performance_budgets`, `api_decisions`, `forbidden_patterns` (after the user's approval below). Before each Edit call:
1. Read the current state of `docs/registry/architecture.yaml`
2. Find the correct section
3. Append the new entry AFTER the last existing entry in that section — do not try to replace a `[]` placeholder that may no longer exist
4. If the section has entries already, use the closing content of the last entry as the `old_string` anchor, and append the new entry after it

**BLOCKING — do not write to `docs/registry/architecture.yaml` without explicit user approval.**

Ask using `AskUserQuestion`:
- "May I update `docs/registry/architecture.yaml` with these [N] new stances?"
  - Options: "Yes — update the registry", "Not yet — I want to review the candidates", "Skip registry update"

Only proceed if the user selects yes. If yes: append new entries. Never modify existing entries — if a stance is
changing, set the old entry to `status: superseded_by: ADR-[NNNN]` and add the new entry.

---
