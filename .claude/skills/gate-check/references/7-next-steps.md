# /gate-check — Sections 7 and 8: Next Step and Follow-Up

> Part of `/gate-check`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 7. Closing Next-Step Widget

**In this file:**

- 7. Closing Next-Step Widget: per gate, and the `workflow: minimal` route
- 8. Follow-Up Actions

**Checkpoint.** Before the widget, update `production/session-state/active.md`
per `.claude/docs/checkpoint-handoff.md` (the Gate Outcomes line of 6.5 is a
separate record and stays): Current task `/gate-check <stage> — <PASS | CONCERNS
| FAIL | NOT ASSESSED>`, Next step = the first step of the stage that follows
(option [A] of the gate's widget below; on FAIL / CONCERNS / NOT ASSESSED the
first blocker's closing skill from section 8), plus Blocked on / Files in
progress (the gate report, `project.yaml` if the stage moved) / Open questions;
append the Notes line. Still updated when the stage write was declined (record
that the stage did not move and why).

After the verdict is presented and any stage update is complete (`project.yaml`, plus `stage.txt` only if it already existed), close with a structured next-step prompt using `AskUserQuestion`.

**Tailor the options to the gate that just ran.** The argument names the stage
being entered, so `/gate-check product-design` is the Discovery → Product Design
gate.

**At `workflow: minimal`, skip the menus below.** They walk the stage ladder, and
the minimal route is not the ladder: offer the first incomplete step of
`paths.minimal` instead (the `--path minimal` rows from Section 3):
`/setup-stack`, then `/brainstorm`, then `/create-stories`, then `/dev-story`
on the next story — the route `/help` gives.

For **Discovery → Product Design** (`/gate-check product-design`) PASS — option [A] is
`/map-domains` when `design/specs/domain-map.md` does not exist yet, otherwise
`/design-spec [first feature in the domain map's design order]`:
```
Gate passed. What would you like to do next?
[A] Run /map-domains — decompose the product into bounded contexts and features, with a design order (recommended next step)
    — or, when the domain map already exists: Run /design-spec [first feature] — author its spec
[B] Revisit the product brief first — return here when it is settled
[C] Stop here for this session
```

For **Product Design → Architecture** (`/gate-check architecture`) PASS:
```
Gate passed. What would you like to do next?
[A] Run /create-architecture — produce the architecture blueprint and the ADR work plan (recommended next step; needs the stack — /setup-stack first if it is not configured)
[B] Run /threat-model [sensitive feature] — threat models are written before the architecture is accepted
[C] Specify more features first — return here when all MVP features are specified
[D] Stop here for this session
```

> **Note for the Product Design → Architecture PASS**: `/create-architecture` is the required next step before writing any ADRs. It produces the architecture document and a prioritized list of ADRs to write. Running `/architecture-decision` without this step means writing ADRs without a blueprint — skip it at your own risk.

For **Architecture → Pre-Production** (`/gate-check pre-production`) PASS:
```
Gate passed. What would you like to do next?
[A] Run /create-control-manifest — generate the must/never rules per context and layer from your Accepted ADRs (first, if docs/architecture/control-manifest.md does not exist yet)
[B] Run /vertical-slice — build the vertical slice (do this before writing epics — prove the architecture and the core journey first)
[C] Write more ADRs first — run /architecture-decision [next-decision]
[D] Stop here for this session
```

> **Note for the Architecture → Pre-Production PASS**: The Pre-Production sequence is deliberately ordered
> to prove the architecture and the core journey before committing to detailed planning:
>
> 1. `/create-control-manifest` — extract the technical rules from Accepted ADRs, if not done yet (`/create-epics` requires it at `full`)
> 2. `/vertical-slice` — build the vertical slice **FIRST**, before writing epics or stories: a thin end-to-end path (database → API → web or mobile → deploy) on the real stack
> 3. Usability session → `/usability-report` — at least 1 documented unguided session with someone from the ICP, 3+ better before committing the full team. `/gate-check production` treats the slice as recommended: skipped → CONCERNS, unused → NOT ASSESSED
> 4. `/ux-design [screen]` — UX specs for the app shell and the key screens (if not done)
> 5. `/create-epics` for the Foundation contexts, then the Core contexts — plan after the slice has validated the architecture
> 6. `/create-stories [epic-slug]` for each epic
> 7. `/sprint-plan new`
>
> **Why a slice before epics?** If the slice shows that tenancy, auth, deployment
> or the core journey needs to change, epics written before that discovery will
> be partially wrong. Prove it cheaply first, then plan in detail.

For **Pre-Production → Production** (`/gate-check production`) PASS:
```
Gate passed. What would you like to do next?
[A] Run /sprint-plan new — plan the first sprint (or /story-readiness on the first story at minimal)
[B] Run /dev-story [first story] — start implementing
[C] Stop here for this session
```

For **Production → Hardening** (`/gate-check hardening`) PASS:
```
Gate passed. What would you like to do next?
[A] Run /team-hardening — performance, security, accessibility and QA pass before release (recommended next step)
[B] Run /security-audit full — the audit /gate-check release requires
[C] Run /load-test — measure the hot paths against the budgets
[D] Stop here for this session
```

For **Hardening → Release** (`/gate-check release`) PASS:
```
Gate passed. What would you like to do next?
[A] Run /launch-checklist — first-launch readiness across every function (recommended for a first release)
[B] Run /team-release — coordinate the release: hosted deploy, self-hosted bundle, store submissions
[C] Run /release-checklist — the per-release checklist
[D] Stop here for this session
```

For **Release → Live** (`/gate-check live`) PASS:
```
Gate passed. The product is Live. What would you like to do next?
[A] Run /team-growth — activation, retention and lifecycle for the first customers
[B] Run /retrospective — capture what the release taught the team
[C] Stop here for this session
```
Mention `/incident` for the first production incident and `/hotfix` for an
emergency fix; there is no further gate after Live.

For any other situation, offer the two most logical next steps for that stage plus "Stop here".

---

## 8. Follow-Up Actions

Based on the verdict, suggest specific next steps. Always name the skill that
closes the gap; never create the missing artifact from here.

**Discovery / Product Design**
- **No product brief?** → `/brainstorm` to create one
- **Brief has unfilled fields?** → `/brainstorm` again, or fill the REQUIRED fields by hand from `.claude/docs/templates/product-brief.md`
- **No stack configured?** → `/setup-stack`
- **No market or competitor evidence?** → `/market-research`, `/competitor-analysis` (sourced and dated)
- **No domain map?** → `/map-domains` to decompose the product into bounded contexts and features
- **Missing feature specs?** → `/design-spec [feature]`, or delegate to `product-manager`
- **Small change needed?** → `/quick-spec` for changes under about one week of implementation (bypasses the full spec pipeline)
- **Spec not reviewed?** → `/spec-review [doc]`
- **Specs not cross-reviewed?** → `/review-all-specs` (run after all MVP specs are individually approved)
- **Cross-spec consistency issues?** → fix the flagged specs, then re-run `/review-all-specs`
- **Pricing, plans or entitlements unclear?** → `/pricing-strategy`, `/pricing-check`
- **Self-hosted or hybrid but no licence model?** → `/license-design`

**Architecture / Pre-Production**
- **No master architecture doc?** → `/create-architecture` for the full blueprint
- **Missing ADRs?** → `/architecture-decision` for individual decisions
- **ADRs missing a stack-version stamp or spec linkage?** → re-run `/architecture-decision` or add the sections by hand
- **No architecture review?** → `/architecture-review`
- **Sensitive feature without a threat model?** → `/threat-model [feature]`
- **Missing control manifest?** → `/create-control-manifest` (requires Accepted ADRs)
- **Missing epics?** → `/create-epics` (requires the control manifest at `full`)
- **Missing stories for an epic?** → `/create-stories [epic-slug]` (run after each epic is created)
- **Stories not implementation-ready?** → `/story-readiness`
- **No research note for a feature?** → `/research [feature]` before any code
- **No UX specs?** → `/ux-design [screen name]`, or `/team-ui [feature]` for the full pipeline
- **UX specs not reviewed?** → `/ux-review [file]` or `/ux-review all`
- **No design system (`PRODUCT.md` / `DESIGN.md`)?** → `/impeccable` (init / document), driven by `design-director`
- **No accessibility requirements doc or interaction pattern library?** → `/ux-design` creates both
- **No test framework?** → `/test-setup` to scaffold the frameworks and CI per layer
- **No vertical slice?** → `/vertical-slice`; **no usability session on it?** → `/usability-report`
- **Need a quick sprint check?** → `/sprint-status`

**Production / Hardening**
- **No QA plan for the current sprint?** → `/qa-plan sprint`
- **No smoke check?** → `/smoke-check sprint`
- **Tests failing?** → delegate to `principal-engineer` (or `/debug`) and `qa-tester`
- **Coverage gaps against critical journeys?** → `/regression-suite`
- **Evidence missing for closed stories?** → `/test-evidence-review`
- **Performance unknown?** → `/perf-profile`, `/load-test`
- **No security audit, or open CRITICAL/HIGH findings?** → `/security-audit full` (after fixes, `/security-audit quick` to confirm)
- **Tenant isolation unproven?** → `/tenant-check`
- **Dependencies unscanned?** → `/dependency-audit`
- **Open bugs?** → `/bug-triage`
- **Not localized (Arabic/English, RTL)?** → `/localize`
- **No QA sign-off?** → `/team-qa`

**Release / Live**
- **No release checklist?** → `/release-checklist`
- **First launch?** → `/launch-checklist`
- **No changelog or release notes?** → `/changelog`, `/release-notes`
- **No SLOs, alerts or runbooks?** → `/observability-plan`
- **No restore drill or rollback plan?** → delegate to `platform-lead` / `infra-engineer`, record under `production/qa/evidence/`
- **Self-hosted bundle failing the licence rules?** → fix `deploy/self-hosted/` per `.claude/rules/deploy.md`, then re-run `bash .claude/scripts/project-coherence.sh`
- **Emergency fix needed?** → `/hotfix`
- **Incident?** → `/incident`, then `/postmortem`

---
