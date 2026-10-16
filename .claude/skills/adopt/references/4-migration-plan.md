# /adopt — Phase 4: Build the Migration Plan

> Part of `/adopt`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 4: Build the Migration Plan

Compose a numbered, ordered action plan. Ordering rules:
1. BLOCKING gaps first (must fix before any pipeline skill runs reliably)
2. HIGH gaps next, infrastructure before spec/ADR content (bootstrapping needs correct formats)
3. MEDIUM gaps ordered: spec gaps before ADR gaps before story gaps (stories depend on specs and ADRs)
4. LOW gaps last

For each gap, produce a plan entry with:
- A clear problem statement (one sentence, no jargon)
- The exact command to fix it, if a skill handles it
- Manual steps if it requires direct editing
- A time estimate (rough: 5 min / 30 min / 1 session)
- A checkbox `- [ ]` for tracking

**Special case — domain-map status values with parentheticals:**
This is always the first item if present. Show the exact values that need changing
and the exact replacement text. Offer to fix this immediately before writing the plan.

**Special case — ADRs missing Status field:**
For each affected ADR, the fix is:
`/architecture-decision retrofit docs/architecture/adr-[NNNN]-[slug].md`
List each ADR as a separate checkable item.

**Special case — specs missing sections:**
For each affected spec, list which sections are missing and the fix:
`/design-spec retrofit design/specs/[filename].md`

**Special case — code with no spec or research note:**
Never rewrite the code. The fix is documentation around it:
`/reverse-document spec <feature>` against the code for a missing spec,
`/reverse-document research <context>` for the choices a bounded context already
made (`/reverse-document brief` and `/reverse-document architecture` for a missing
brief or architecture doc), each a reconstruction that cites file:line and marks
unknown intent `[UNVERIFIED — ask]`. Say plainly that the research note is
written *after* the fact, so it records what was chosen (the why only where the
user states it), keeps `Status: Draft` until the user confirms, and flags anything
that does not match the pinned stack reference — it does not rewrite history and
does not stand in for research before future changes.

**Infrastructure bootstrap ordering** — always present in this sequence:
1. Run `/setup-stack` → records `stack.*`, `deploy`, `distribution`, `tenancy`, `layout.code_roots`, `core.track`, and verifies the stack reference for every configured layer (everything below reads these)
2. Fix ADR formats first (registry depends on reading ADR Status fields)
3. Run `/architecture-review` → bootstraps `tr-registry.yaml`
4. Run `/create-control-manifest` → creates manifest with version stamp
5. Run `/sprint-plan update` → creates `sprint-status.yaml`
6. Run `/gate-check [phase]` (the gate into the phase the project is in; at Discovery there is none — Discovery is the default stage, nothing to run) → writes `project.stage` in `project.yaml` (and an existing legacy `stage.txt`, never creating it) authoritatively

**At `workflow: minimal` the plan prescribes only step 1 of this sequence.** The
rest is not on the minimal path: ADRs are not expected, the brief's build order
is the plan (no `/sprint-plan`), and nothing there runs `/gate-check`. The plan's
Step 3 says so in one line and names the path's next step instead —
`/brainstorm` when there is no brief, `/create-stories` when no stories exist,
else `/dev-story`.

**Existing stories** — note explicitly:
> "Existing stories continue to work with all studio skills — all new format
> checks auto-pass when the fields are absent. They won't benefit from TR-ID
> staleness tracking or manifest version checks until they're regenerated. This
> is intentional: do not regenerate stories that are already in progress."

---
