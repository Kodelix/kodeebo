---
name: license-design
description: "Design the self-hosted licence model: signed claims, Ed25519 verification of exact payload bytes (library chosen via /research), key custody, rotation and revocation, online and offline activation, grace and clock-tamper handling, update eligibility, entitlement parity with billing, mandatory threat model (SL-THREAT-MODEL) and ADR (CTO-ADR)."
argument-hint: "[product-slug] [--update] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Skill, Agent, AskUserQuestion, WebFetch, WebSearch, Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(date *), Bash(bash "*/.claude/skills/license-design/../../hooks/yaml-helper.sh" resolve_config *)
model: opus
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,automation_always_ask,stack`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt). **These are never delegated to
a mode**: choosing the signing library, key custody, the offline-expiry bound,
grace and maintenance terms, accepting a residual risk, and moving an ADR to
`Accepted`. They always ask.

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

**`workflow`** does **not** relax this skill. Licensing is ASVS Level 3 code
(`security-baseline.md`, `security-sensitive.md`): the threat model and the
negative tests are required at `minimal`, `standard` and `full`. What a tier
changes is where the decision is recorded (an ADR file, or the brief's decision
log at `minimal`).

# License Design

Self-hosted software cannot be made tamper-proof. The goal is to make honest use
easy, casual copying inconvenient, and misuse detectable and contractually
actionable - **without** a forgeable file, a leaked signing key, or an outage that
locks a paying customer out of their own data. This skill designs the whole
mechanism once, from the standards, before any licensing code exists: the signed
format, the verifier, key lifecycle, activation (online and air-gapped), time and
grace, update eligibility, and parity with the billing entitlements. Owner:
`licensing-specialist`; commercial terms: `pricing-billing-designer`; security
sign-off: `security-lead`.

**It designs; it does not implement and does not hold keys.** It never generates,
requests, stores or prints a signing key, a test private key or any key material.
Implementation is stories (`/create-stories`, Security type) built in
`saas-core-<track>` licensing, not in the product repo.

**Output**
- `docs/research/licensing.md` - library choice and Ed25519 behaviour, via `/research`
- `docs/architecture/licence-model.md` - from `.claude/docs/templates/licence-model.md`
- `docs/architecture/threat-models/licensing.md` - via `/threat-model licensing` (mandatory)
- the ADR - via `/architecture-decision` (a critical ADR), or the decision log of `design/product-brief.md` at `workflow: minimal`
- the Security-type story list for `/create-stories`

> **Verdicts:** `COMPLETE` / `COMPLETE WITH GAPS` / `NOT ASSESSED` / `BLOCKED`.
> Precedence: `BLOCKED`, then `NOT ASSESSED`, then `COMPLETE WITH GAPS`, then
> `COMPLETE`. `NOT ASSESSED` outranks `COMPLETE` and ranks below `BLOCKED`.
> `BLOCKED` = a declined write (`BLOCKED — write declined by user`), or a design that violates a non-negotiable: verification over
> re-serialised bytes; an algorithm field or negotiation; signing key held in the
> repo, CI or a CI variable; a hard lock-out that blocks data export; a default-on
> outbound call or phone-home; hardware-fingerprint binding; a licence-server
> outage that disables a valid unexpired licence; or `SL-THREAT-MODEL` = REJECT.
> `NOT ASSESSED` = the library choice is `NOT SOURCEABLE` or unresearched, the
> commercial terms (term, grace, maintenance, security-patch policy) are not
> decided, `distribution` is unset, the core licensing module list could not be
> read, or a gate could not run. `COMPLETE WITH GAPS` = everything assessed but
> a check is open (named). Every cause is named in the report.

---

## Phase 1: Scope, Inputs, Core-First

**Read `references/1-scope-and-inputs.md` now and follow it.** It confirms
the product ships a self-hosted edition (`distribution.model`; unset is asked,
`hosted` only is `not applicable - hosted only`), records each input as FOUND or
ABSENT, reads the commercial terms (`design/specs/pricing-model.md` "Licence
Terms for Self-Hosted") and the billing entitlement catalogue, and runs the
**core-first check**: licensing is a `saas-core-<track>` module; a product-local
design needs a written reason and an upstream plan (`/core-use`, `/core-extract`).
Read it again if the conversation was compacted or resumed.

## Phase 2: Research (`/research`)

**Read `references/2-research.md` now and follow it.** Spawn `researcher` for
`docs/research/licensing.md`: the Ed25519 verification library per runtime (Go,
JVM/Kotlin, and any other that verifies), its behaviour on non-canonical
signatures and key sizes, key and signature encodings, and the normative
specification - all from official documentation, none from memory. The stack
reference does **not** document Ed25519 library APIs; until the note exists, the
library choice is `NOT SOURCEABLE` and the verdict is at best `NOT ASSESSED`.

## Phase 3: Design Decisions (parallel drafts)

**Read `references/3-design-decisions.md` now and follow it.** Spawn in one turn,
because their inputs are independent after Phase 2:

- `licensing-specialist` - the technical design draft of licence-model sections 1, 3-6 and 8-13 against its Senior Bar.
- `pricing-billing-designer` - the commercial terms (types, term, grace, maintenance, security-patch policy, renewal) and the **entitlement parity table** (billing catalogue keys <-> licence claims).

The skill then walks the decisions with the user section by section
(`AskUserQuestion`), resolving conflicts between the two drafts; the user decides.
It sets no price, plan or term on its own.

## Phase 4: Threat Model (SL-THREAT-MODEL)

**Read `references/4-threat-model-and-adr.md` §1 now and follow it.** Run
`/threat-model licensing` (opus skill, `security-lead` gate). The model must cover
the 12 licensing threats listed there with a mitigation, a story and a named
negative test each, ASVS 5.0.0 Level 3 IDs looked up (never recalled), and the
residual risk (a customer who patches the binary) stated and accepted by a named
person. No licensing code story starts before the gate is APPROVE or CONCERNS.

## Phase 5: Write the Licence Model

Fill `.claude/docs/templates/licence-model.md` with the decisions, section by
section, citing the research note and the threat model. Ask: "May I write the
licence model to `docs/architecture/licence-model.md`?" Write only after approval.
With `--update`, show a diff of changed sections first and keep section numbers.

## Phase 6: ADR (CTO-ADR)

**Read `references/4-threat-model-and-adr.md` §2 now and follow it.** A licensing
ADR is a **critical ADR** (`workflow-modes.md`). At `standard` and `full`, run
`/architecture-decision` with the decision, alternatives and consequences
prepared here; it runs `CTO-ADR`. At `minimal`, record the decision in the decision
log of `design/product-brief.md` (CTO-ADR is not required there) and say so. The
ADR is moved to `Accepted` only by the user (or `cto` on the user's explicit
confirmation).

## Phase 7: Checks, Stories, Report

**Read `references/5-checks-and-report.md` now and follow it.** It runs checks
L1-L17 against the written model and the gate results, derives the verdict, builds
the Security-type story list with a negative test per mitigation, and asks before
writing the report.

---

## Error Recovery Protocol

**First, verify the artifact.** If a spawned agent's return contract named a path,
check it exists before treating the phase as done; a fluent reply with no file is
not a design. If an agent returns BLOCKED or errors, surface it, do not proceed
past what it blocks, and produce a partial report. Full procedure:
`.claude/docs/error-recovery-protocol.md`. A gate or agent that could not run is
recorded `NOT ASSESSED - [what was missing]`.

## Collaborative Protocol

- **Never recall** a cryptographic API, key size, encoding, library version, RFC detail or requirement ID: it comes from the research note, the official document with the URL fetched, or `NOT SOURCEABLE`
- **No key material, ever**: the skill does not generate, request, accept, store or print a private key, a seed or a test key; example values in documents are placeholders marked as such
- **The commercial terms are not this skill's**: term, grace, maintenance, security-patch policy and prices come from `pricing-billing-designer` and the user's decision; an undecided term is `NOT DECIDED` and keeps the verdict at best `NOT ASSESSED`
- **Honest residual risk**: licence enforcement is not DRM. The model states what a determined customer can do and what contract and audit rights cover
- **Degrade, never destroy**: no design in which expiry, revocation or an outage blocks a customer's access to export, login or backup of their own data
- **No default-on outbound traffic** from a self-hosted instance; the only outbound call is the explicit, user-triggered activation or refresh with a documented payload
- **Accepted risk is the user's decision** with an owner and an expiry; this skill, `licensing-specialist` and `security-lead` never accept it on the company's behalf
- Ask "May I write..." naming every path; no commits unless the user asks

## Recommended Next Steps

- `/create-stories` for the Security-type story list; `/story-readiness` checks the threat model and research note before each
- `/team-billing` for pricing -> entitlements -> billing integration -> licence enforcement; `/pricing-check` for loopholes in the plan/licence mapping
- `/core-extract` or `/core-use` per the core-first decision; `/db-migration` for the activation and revocation tables
- `/security-audit selfhosted` and `/pentest` (licence bypass, activation replay, clock rollback) before the first self-hosted release
