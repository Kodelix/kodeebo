---
name: pricing-check
description: "Sanity-check plans, entitlements and quotas — loopholes, dominated or unreachable tiers, margin vs infra cost, server-side enforcement, licence terms. 'Check the pricing.'"
argument-hint: "[plan-name | entitlement-key | path-to-pricing-file]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit(production/session-state/active.md), AskUserQuestion, Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(date *), Bash(bash "*/.claude/skills/pricing-check/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,stack,distribution`

Resolved above — use as-is. No block → defaults in `.claude/docs/config-resolution.md`.

# Pricing Check

Reviews the product's plans, entitlements, quotas, trials, coupons and licence
terms for loopholes, incoherent tiers, unprofitable usage and limits that are not
actually enforced. Reads the artifacts written from
`.claude/docs/templates/pricing-model.md`. Domain owner: `pricing-billing-designer`
— findings are routed to that agent; this skill does not edit the pricing model.

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

## Insufficient input — check this before producing any report

**If the inputs this skill needs do not exist, the answer is "could not run" —
not a filled-in report.** Check first, and stop if the check fails.

1. List the inputs this skill reads: the pricing model (`design/specs/pricing-model.md` — the canonical path
   written by `/team-billing` — else `Glob design/**/pricing-model*.md`), the entity registry
   (`design/registry/entities.yaml`), feature specs that cite entitlement keys,
   `contracts/`, the backend code root, the architecture doc and
   `docs/architecture/perf-budgets.md` (cost drivers), the licence model
   (`licence-model.md` artifact) for self-hosted products, and `project.yaml`
   `distribution`.
2. For each, record `FOUND` or `ABSENT` — not "assumed present".
3. If any input required for a section is ABSENT, that section is
   **`NOT ASSESSED — NO DATA`**. Do not estimate it, do not infer it from an
   adjacent artifact, and do not leave a mandated cell to be filled by whoever
   reads the template next.
4. If **every** required input is ABSENT, stop and report
   **`NOT ASSESSED — NO DATA`** as the whole verdict, naming what was missing and
   which skill or agent produces it (`pricing-billing-designer` writes the pricing
   model; `/brainstorm` records the pricing model choice in the brief).

**A verdict of `NOT ASSESSED` is a success.** It is the correct, useful answer
when there is no data. The failure mode this prevents: a report whose verdict
enum has no "could not run" state produces **false clean passes** — a margin
check returning HEALTHY with no infrastructure cost figures, or an enforcement
check passing because no backend code exists to inspect.

**Absence of evidence is never evidence of absence.** A grep that finds no
loophole because the rule it would test is undocumented has verified nothing. Say
which of the two happened.

**Never fill cost or price facts from memory.** Provider fees, tax rates and
infrastructure unit costs are external facts: take them from the pricing model,
the architecture doc or a research note (`docs/research/`), or write
`NOT SOURCEABLE — <fact> is not stated in <path>` and let the margin section
read NOT ASSESSED.

---

## Phase 1: Identify the Scope

From `$ARGUMENTS` (the whole string — a path may contain spaces):

- **No argument** → the whole model: all plans, entitlements, quotas, trials,
  coupons, billing mechanics and licence terms
- **Plan name** → that plan, plus every comparison that involves it (neighbours,
  upgrade and downgrade paths)
- **Entitlement key or quota name** → that key across every plan, spec and the
  enforcement code
- **File path** → load that file directly and infer the scope from content

If the scope is ambiguous, ask the user which to check.

---

## Phase 2: Read the Pricing Artifacts

Read the pricing model. Note every file read — they appear in the Data Sources
section of the report. Extract:

- Plans (audience, price per period, billing periods, trial) — **values quoted
  from the model, never from memory**
- Entitlement table (key, type, value per plan, *Enforced where*, source spec)
- Limits & quotas (unit, period, per-plan values, hard/soft, on-exceed behaviour)
- Metering (meter, source, aggregation, idempotency key, late-event window)
- Trials, coupons, referral/credit rules and their abuse controls
- Billing mechanics: proration, dunning, refunds, tax
- Licence terms for self-hosted
- Price targets & unit economics (margin, conversion, churn targets)

**Registry and specs.** If `design/registry/entities.yaml` exists, read its
`plans`, `quotas`, `roles` and `permissions` entries for cross-spec values; then
`Grep` the feature specs for each entitlement key (`design/specs/*.md`) to confirm
every gated behaviour names its key and no spec restates a price or limit inline.

If the pricing model is FOUND but a section the checks need is empty or still
template placeholder text, that section's checks are `NOT ASSESSED — NO DATA`,
naming the section and `pricing-billing-designer`.

---

## Phase 3: Read the Enforcement Surface

For each entitlement key and quota, find where it is actually enforced. Resolve
the code roots from `layout.code_roots` in `project.yaml`, else the conventional
`backend/`, `web/`, `mobile/`, `contracts/` on disk (as `resolve_code_root` does).
**If none resolves, Phase 4 check 5 (enforcement) is `NOT ASSESSED — code roots
unresolved`** — not clean.

- `Grep` the key (and its constant/identifier form) in the backend: a
  use-case-level check (`can(tenant, "key")`, entitlement guard) is **server-side**.
- `Grep` the same key in `web/`, `mobile/`: a check present *only* there is a
  client-side gate — a loophole by construction.
- `Grep` `contracts/` for the error that signals the limit (e.g. `plan_limit_reached`,
  429 with `Retry-After`) — the contract must document it.
- For metered quotas, find the meter's idempotency key and the reconciliation job.
- Plan **names** hardcoded in code (`if plan == "team"`) instead of entitlement
  keys violate the model's own rule — count them.

---

## Phase 4: Perform Analysis

**Every domain: compare each value with its stated intent.** Take the intended
value from the pricing model (and the registry for cross-spec constants); a spec
or code constant that differs is a finding. A value with no stated rationale is
`no stated rationale — not judged`.

Run these checks; each one reports `PASS`, a finding, or `NOT ASSESSED — NO DATA`
(name the missing input):

1. **Reachability and dominance.** Is every plan chosen by some customer profile?
   A plan is *dominated* when another plan is at least as good on every
   entitlement and quota and no more expensive for the same usage; *unreachable*
   when no realistic usage profile makes it the cheapest sufficient plan (e.g.
   a per-seat price at which Team costs less per seat than Starter, or a quota
   gap too small to justify the price step). Tabulate price vs entitlements across
   plans, with annual vs monthly.
2. **Seat and role abuse.** Shared logins to avoid seat counts (is a seat a
   *membership* or a *login*?); viewer/guest roles that bypass paid seats; a
   seat removed and re-added within the proration window to dodge billing; role
   downgrades that keep paid capabilities; invitations that create seats before
   acceptance.
3. **Trial cycling.** One trial per what — email, email domain, payment
   fingerprint, tenant, device? Disposable-email blocking? Does trial data and
   quota reset on a new trial? What happens at expiry (downgrade, read-only,
   suspend) — and is it enforced, or does expiry leave full access?
4. **Coupon and credit stacking.** Stackable with trials, annual discounts,
   other coupons, referral credit? Duration (once / N months / forever), max
   redemptions, expiry, applicable plans, audit. A forever-100% stack or a coupon
   that applies to a plan it was not meant for is a finding.
5. **Server-side enforcement.** Every entitlement and quota has an *Enforced where*
   cell, and Phase 3 found it enforced in the backend, not only in a UI gate.
   A limit with no enforcement point, enforced only client-side, or enforced on
   some routes but not others (list/export/API/webhook/background job paths) is a
   finding. Over-quota behaviour matches the model (block vs allow-and-bill vs
   grace) and notices exist at 80%/100%.
6. **Proration and cycling.** Upgrade then downgrade inside a period to use a
   higher plan for free; mid-period seat changes; refunds vs credits; annual →
   monthly switches; rounding rule stated.
7. **Margin vs cost drivers.** For each plan, compare price per period against the
   cost drivers the architecture names (compute, storage, egress, database,
   email/SMS/notification volume, third-party API calls, payment-provider fees,
   support) at the plan's quota ceiling and at P90 usage. Costs come from the
   architecture doc, `perf-budgets.md`, a research note or the model's
   unit-economics section — **if none states a cost figure the check is
   `NOT ASSESSED — NO DATA`** and names which figure is missing; it is never
   estimated here. A plan negative at P90 usage, or a free plan with unbounded
   cost drivers (storage, outbound messages, AI calls), is a finding.
8. **Metering integrity** (usage-based components). Idempotency key present, late
   events handled, customer-visible usage matches the invoice, dispute and credit
   path defined.
9. **Dunning and access.** Failed-payment steps lead to a defined access state;
   suspended tenants keep data for the stated period and can export.
10. **Self-hosted licence terms** (when `distribution` includes self-hosted).
    Unit of licensing and what a tenant/instance count means in a multi-tenant
    self-host; **one-time licence vs maintenance**: updates released before expiry
    remain usable, grace period then read-only (never data loss), offline
    activation path, renewal/reinstatement price; whether an expired licence on a
    perpetual+maintenance model can still run the last eligible version; no phone-
    home dependency that bricks an air-gapped customer. Cross-check
    `.claude/rules/deploy.md` licence rules. If `distribution` is hosted only,
    report this check `skipped — hosted only`.
11. **Ethical guardrails.** Cancellation as easy as sign-up; renewal reminders;
    prices and taxes shown before purchase; data export after cancellation.
12. **Consistency.** Prices or limits restated in specs, marketing copy or code
    that differ from the model; plan names in code; currency stored as float.

---

## Phase 5: Output the Analysis

```
## Pricing Check: [Scope]

### Data Sources Analyzed
- [List of files read, and inputs recorded ABSENT]

### Health Summary: [NOT ASSESSED / HEALTHY / CONCERNS / CRITICAL ISSUES]

### Checks run
| # | Check | Result | Evidence (file:line) |
|---|-------|--------|----------------------|
(one row per check 1–12; a check that did not run reads `NOT ASSESSED — <input>` or `skipped — <reason>`, never blank)

### Plan / Entitlement Matrix
[Table of plans × key entitlements and quotas as read from the model, with a
dominated/unreachable flag per plan]

### Loopholes Found
- [Loophole, exploit steps, who is affected, severity]

### Unenforced or Client-Only Limits
| Key / quota | Declared where | Enforced where | Gap |

### Margin vs Cost Drivers
[Per plan at quota ceiling and P90, or `NOT ASSESSED — NO DATA` naming the missing cost figure]

### Recommendations
| Priority | Issue | Suggested Fix | Owner | Impact |
|----------|-------|--------------|-------|--------|

### Values That Need Attention
[Specific values with suggested adjustments and rationale; values with no stated rationale]
```

Choose the Health Summary by the worst finding, first match wins:
- **CRITICAL ISSUES** — a loophole that gives paid capability for free or at will
  (trial cycling, stackable forever-discount, seat/role bypass), a quota or
  entitlement enforced only client-side, a plan with negative margin at its quota
  ceiling, or a licence term that can destroy a customer's data on expiry
- **CONCERNS** — dominated or unreachable tiers, unenforced-on-some-paths limits,
  missing over-quota notices, margin below target, stale restated values; a
  tuning pass fixes them
- **NOT ASSESSED** — nothing to analyze (the no-data path above), a check that
  needs an input is `NOT ASSESSED — NO DATA`, code roots unresolved, or a value
  had no stated rationale to judge it against; name which. It ranks below the two
  finding verdicts (a measured problem is more actionable than a gap) and above
  HEALTHY
- **HEALTHY** — all 12 checks ran or were legitimately skipped with a stated
  reason, no loopholes, every limit enforced server-side, margin positive at P90

---

## Phase 6: Fix & Verify Cycle

After presenting the report, use `AskUserQuestion`:
- Prompt: "Pricing check complete. What would you like to do next?"
- Options:
  - `[A] Fix highest-priority issue now — walk me through it`
  - `[B] Save report to docs/pricing-check-[date].md`
  - `[C] Stop here — I'll review the findings manually`

If [A]:
- Ask which issue to address first (refer to the Recommendations table by priority row)
- Route it: price/plan/limit changes go to `pricing-billing-designer` (data change in the pricing model with an audit-log entry, not a deploy); enforcement gaps become a story (`/create-stories`) with a **Security** or **Logic** story type and negative tests (wrong plan, over quota, other tenant); billing-flow threats go to `/threat-model billing`.
- After each fix, offer to re-run the relevant checks to verify nothing new appears.
- If the fix changes a plan, entitlement or quota that a feature spec cites, remind the user:
  > "This value is referenced by a feature spec. Run `/propagate-spec-change [path]` on the affected spec to find downstream impacts (ADRs, stories, contracts, the tracking plan) before committing."

If [B]:
- Ask: "May I write the report to `docs/pricing-check-[date].md`?" On yes, write it (create the directory if needed) using the current date in YYYY-MM-DD format, confirm, and end with: "Re-run `/pricing-check` after fixes to verify."

If [C]:
- Summarize open issues and end with: "Re-run `/pricing-check` after fixes to verify."

**Checkpoint.** Whichever option was chosen, update
`production/session-state/active.md` per `.claude/docs/checkpoint-handoff.md`
before the closing message: Current task `/pricing-check <scope> — <Health
Summary>`, Next step = the highest-priority Recommendation (or "re-run
`/pricing-check` after fixes"), plus Blocked on / Files in progress (the report
path, or `none`) / Open questions; append the Notes line. CRITICAL ISSUES or NOT
ASSESSED still update the checkpoint with the blocker.

---

## Collaborative Protocol

1. **Read silently, report fully** — run every check before presenting
2. **Say what did not run** — a check without input is NOT ASSESSED by name, not blank
3. **Never edit the pricing model** — it belongs to `pricing-billing-designer`; this skill reports and routes
4. **Ask before writing** — the report file needs approval like any other write
