---
name: design-spec
description: "Section-by-section feature spec authoring for one feature at the effective tier — walks through each required section, cross-references dependencies, prompts the NFRs."
argument-hint: "<feature-name> [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, TaskCreate, TaskGet, TaskList, TaskUpdate, Bash(date *), Bash(bash .claude/hooks/yaml-helper.sh log_decision *), Bash(bash .claude/scripts/spec-structure-check.sh), Bash(bash .claude/scripts/spec-structure-check.sh *), Bash(bash "*/.claude/skills/design-spec/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,docs.density,system_overrides,stack`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

# Design Spec

When this skill is invoked:

## 1. Parse Arguments & Validate

**Read `references/1-parse-arguments.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 2. Gather Context (Read Phase)

**Read `references/2-gather-context.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 3. Create File Skeleton

**Read `references/3-file-skeleton.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 4. Section-by-Section Design

**Read `references/4-section-design.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 5. Post-Design Validation

**Read `references/5-post-design.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 6. Specialist Agent Routing

This skill delegates to specialist agents for domain expertise. The main session
orchestrates the overall flow; agents provide expert content. Only agents in
`.claude/docs/agent-roster.md` are spawned.

**Rows here are finer-grained than the eight `Category` values on purpose** — the
right specialist for sign-in is not the right specialist for invoices, and
both could sit under different categories. Resolve in two steps: take the
feature's `Category` from `domain-map.md`, then pick the row within it that
matches what the feature actually does. Every category has at least one row, so
nothing falls through.

| `Category` | Rows below to choose from |
|---|---|
| `Platform` | Identity/access · Tenancy/organisation · Platform foundations |
| `Core domain` | Core domain workflow |
| `Billing & Licensing` | Billing/plans/entitlements · Licensing (self-hosted) |
| `Integrations` | External integration · Public API/webhooks |
| `Admin & Support` | Admin/support tooling · Privacy/data lifecycle |
| `Growth` | Growth/lifecycle |
| `Insights` | Analytics/reporting |
| `Client surfaces` | App shell/UI surfaces · Mobile surfaces |

If two rows fit, spawn the union of their Primary agents and say why.

| Feature type | Primary Agent | Supporting Agent(s) |
|---|---|---|
| **Platform foundations** (config, audit log, jobs, settings) | `domain-architect` | `principal-engineer` (feasibility, clean-architecture fit), `data-lead` (stores) |
| Identity/access (sign-in, roles, MFA, SSO, invitations) | `product-manager` | `auth-identity-specialist` (authN/authZ model), `security-lead` (threat-model trigger), `ux-designer` (flows) |
| Tenancy/organisation (workspaces, membership, isolation) | `domain-architect` | `multitenancy-specialist` (isolation model), `security-lead`, `data-lead` |
| Core domain workflow | `product-manager` | `domain-architect` (aggregates, invariants), `ux-designer` (flows), `api-designer` (contract shape) |
| Billing/plans/entitlements/quotas | `pricing-billing-designer` | `product-manager`, `integrations-engineer` (payment provider), `security-lead`, `privacy-compliance-specialist` (tax/VAT records) |
| Licensing (signed licences, activation, offline grace) | `licensing-specialist` | `pricing-billing-designer`, `security-lead`, `infra-engineer` (self-hosted bundle) |
| External integration (email, SMS/OTP, payments, storage, push, OAuth) | `integrations-engineer` | `api-designer`, `security-lead`, `researcher` (provider docs) |
| Public API/webhooks | `api-designer` | `integrations-engineer`, `appsec-engineer` (abuse, SSRF), `technical-writer` (docs) |
| Admin/support tooling (console, impersonation) | `product-manager` | `security-lead` (impersonation is a threat-model trigger), `customer-success` (support workflows), `ux-designer` |
| Privacy/data lifecycle (export, delete, retention) | `privacy-compliance-specialist` | `domain-architect` (ownership), `data-lead` (retention mechanics), `security-lead` |
| Growth/lifecycle (onboarding, trials, dunning, referrals) | `growth-lifecycle` | `pricing-billing-designer`, `product-analytics-engineer` (events), `ux-designer` |
| Analytics/reporting | `product-analytics-engineer` | `product-manager`, `data-lead` (aggregation, retention), `privacy-compliance-specialist` |
| App shell/UI surfaces | `product-manager` | `ux-designer` (flows), `design-director` (visual direction via impeccable), `accessibility-specialist`, `web-lead` (feasibility) |
| Mobile surfaces | `product-manager` | `ux-designer`, `android-lead` / `ios-lead` (platform feasibility), `offline-sync-specialist` (offline), `accessibility-specialist` |

**When delegating via the `Agent` tool**:
- Provide: feature name, product brief summary, dependency spec excerpts, the specific
  section being worked on, and what question needs expert input
- The agent returns analysis/proposals to the main session
- The main session presents the agent's output to the user via `AskUserQuestion`
- The user decides; the main session writes to file
- Agents do NOT write to files directly — the main session owns all file writes

---

## 7. Recovery & Resume

If the session is interrupted (compaction, crash, new session):

1. Read `production/session-state/active.md` — it records the current feature and
   which sections are complete
2. Read `design/specs/[feature-name].md` — sections with real content are done;
   sections with `[To be designed]` still need work
3. Resume from the next incomplete section — no need to re-discuss completed ones

This is why incremental writing matters: every approved section survives any
disruption.

---

## Collaborative Protocol

**In `collaborative` mode (the default).** For `guided` and `autonomous`
modes, see the per-mode rules in `.claude/docs/automation-modes.md` — the
"Never" lines below describe what collaborative mode requires, not what
applies universally.

This skill follows the collaborative design principle at every step:

1. **Question -> Options -> Decision -> Draft -> Approval** for every section
2. **AskUserQuestion** at every decision point (Explain -> Capture pattern):
   - Phase 2: "Ready to start, or need more context?"
   - Phase 3: "May I create the skeleton?"
   - Phase 4 (each section): Design questions, approach options, draft approval
   - Phase 5: "May I update the entity registry? May I update the domain
     map? What's next?" — **not** "Run spec review?": §5c forbids offering
     `/spec-review` inline, because the reviewing agent must not inherit this
     session's design history. Phase 5c presents the hand-off; it never asks.
3. **"May I write to [filepath]?"** before the skeleton and before each section write
4. **Incremental writing**: Each section is written to file immediately after approval
5. **Session state updates**: After every section write
6. **Cross-referencing**: Every section checks existing specs for conflicts
7. **Specialist routing**: Complex sections get expert agent input, presented to
   the user for decision — never written silently
8. **A check that did not run is reported as not run**: a skipped specialist, a
   skipped gate, an unread stack reference and an unresolvable standard ID are
   each named in the spec output, never silently omitted.

**Never** auto-generate the full spec and present it as a fait accompli.
**Never** write a section without user approval.
**Never** contradict an existing approved spec without flagging the conflict.
**Never** restate a price: plan and pricing effects link to the pricing model
(`.claude/rules/specs.md`).
**Always** show where decisions come from (dependency specs, principles, user choices).

## Context Window Awareness

This is a long-running skill. After writing each section, check if the status line
shows context at or above 70%. If so, append this notice to the response:

> **Context is approaching the limit (≥70%).** Your progress is saved — all approved
> sections are written to `design/specs/[feature-name].md`. When you're ready to continue,
> open a fresh Claude Code session and run `/design-spec [feature-name]` — it will
> detect which sections are complete and resume from the next one.

---

## Recommended Next Steps

- Run `/spec-review design/specs/[feature-name].md` in a **fresh session** to validate the completed spec independently
- Run `/threat-model [feature-name]` when the spec's Non-Functional Requirements flagged a sensitive area
- Run `/consistency-check` to verify this spec's values don't conflict with other specs
- Run `/map-domains next` to move to the next highest-priority unspecified feature
- Run `/gate-check` when all MVP specs are authored and reviewed
