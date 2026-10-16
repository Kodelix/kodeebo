# /release-checklist — Common Sections, Gates, Confirmation, Verdict

> Phases 4b–5 of `SKILL.md`.

## Common sections (every track)

The checklist file starts from `.claude/docs/templates/release-checklist-template.md`.
Keep its sections *Build & Artifact Verification*, *Quality Gates* (Critical
Bugs, Definition of Done, Test Coverage, Security, Performance & Reliability,
Content & Localization), *Billing & Account Impact*, *Launch Readiness* and
*Sign-offs*; **delete the target sections that do not apply** (do not leave them
unticked) and replace each with a one-line `omitted — [config value]` notice.
Add the track sections from `references/2-hosted.md`, `3-self-hosted.md` and
`4-mobile.md` in place of the template's shorter target blocks. Fill the
template's numbers from the Phase 3 scans; where a value was not found write
`[?]` with the reason.

Template items that need these readings:

- **Definition of Done**: every story in the release has the eight gates met or waived in writing (`/story-done`). List stories whose file lacks a done status or an evidence folder.
- **Contract**: the released `contracts/` version, and the breaking-change check against the previous one.
- **Upgrade tested** from the oldest supported version and from the previous release (hosted data migrations and, for the bundle, the matrix).
- **Localization**: strings externalised, Arabic and English complete, RTL layouts checked on touched screens; emails/notifications/error messages proofread in both locales. Without a `/localize` result: `[?]`.
- **Billing & account impact**: pricing/plan/entitlement changes match `pricing-model.md`; existing subscribers' migration defined; provider products/prices created in **live** mode and webhook endpoints/secrets configured; any price, limit or terms change communicated within the required notice period. Provider live-mode state cannot be read from the repo → ask.
- **Launch readiness** here is the *release-day* slice only (analytics events match `tracking-plan.md` and receive data with consent respected; support briefed; announcements drafted; on-call set). First-launch readiness is `/launch-checklist`.

## Gates

`review_mode` (or `--review`) decides whether the two gates are spawned. These
are spawned by `/release-checklist`, so the ordinary per-skill rule applies
(`.claude/docs/director-gates.md`): `full` → spawn; `lean` and `solo` → skip and
write `[GATE-ID] skipped — [mode] mode`. **A skipped gate waives the director's
opinion, never the evidence** — every checklist item is still evaluated and
reported.

When spawning, the `Agent` prompt tells the agent to read the gate file first
(this skill does **not** read it), and passes only the context fields the gate
lists:

| Gate | Agent | Gate file | Context to pass |
|---|---|---|---|
| **SL-RELEASE-SECURITY** | `security-lead` | `.claude/docs/director-gates/sl-release-security.md` | release identifier and commit range; editions shipping; latest `/security-audit` report and per-story security evidence; threat models for sensitive features; scan results on the release commit (tool, version, scope, result); open vulnerability register; SL-TENANT-ISOLATION verdict for the release |
| **SRE-OPERABILITY** | `sre-lead` | `.claude/docs/director-gates/sre-operability.md` | `distribution.model` and `deploy.target`; editions shipping; observability evidence; backup configuration, RPO/RTO and the latest restore-drill record; capacity evidence (k6 vs budgets, resource limits, pools); this checklist's release/rollback section and migration plan; runbooks and alert rules |

Both return READY / CONCERNS / NOT READY, or NOT ASSESSED naming the missing
input. Record the verdict, its date and its blocker list in the checklist's
Sign-offs section. A gate that returns NOT READY makes the checklist NOT READY.
Spawning a gate never replaces running `/security-audit`: if no audit report
exists, the Security block says so and the gate is told so.

## Phase 4b — Confirm what only a person can

Much of a release cannot be settled from the repository (restore rehearsed,
store form filled, signing done, provider live mode, on-call set). Collect the
items no scan, file or gate settled, per track, and ask **one `AskUserQuestion`
per track** listing them numbered. Each answer: **yes / no / not yet / N/A**.
Options: `Yes — all of them` / `Not yet — none of them` / `N/A — this track does
not apply` / `Some differ — I'll answer per item`.

- **yes** → ticked `- [x]` and marked `(confirmed by the user)`
- **no** / **not yet** → a failed item, under Blocking Items — or Conditional Items when the user names a workaround or accepts the risk (S2 exceptions and gate CONCERNS need a **named approver**)
- **N/A** → written `- N/A — [item]` and left out of the verdict
- unanswered → stays `[?]` and the verdict names it

These are questions of fact only the user can answer: asked in `collaborative`
and `guided` alike, never answered on the user's behalf. In `autonomous` mode,
skip this phase and say so: the items stay `[?]`, the verdict is NOT ASSESSED.

## Verdict — Go / No-Go: READY / CONCERNS / NOT ASSESSED / NOT READY

First match wins:

1. **NOT READY** — any blocking item fails: open S1; open S2 without an approved written exception (or any at `full`); an open S3 without owner/ticket/target (or any at `full`); BLOCKING DoD evidence missing; a never-restored backup; an untested rollback; a LICENCE-rule violation in the bundle; an unsigned bundle; SL-RELEASE-SECURITY or SRE-OPERABILITY returned NOT READY; a dirty release tree; a published tag about to be re-used.
2. **NOT ASSESSED** — any section or item is `[?]`, any track input was absent, a required scan did not run, or a store requirement is `NOT SOURCEABLE`. Name each one. It outranks CONCERNS and READY — an item nobody could check is not a passed one — and ranks below NOT READY, so a known blocker is never buried behind it.
3. **CONCERNS** — no blockers and nothing unassessed, but there are accepted risks or waivers, S3s carried with owners, or a gate returned CONCERNS. List each with its named approver.
4. **READY** — none of the above.

Per-track verdicts are shown in a table (hosted / self-hosted / Android / iOS);
the overall verdict is the worst of them by the order above.

**Rationale**: summary of readiness, the blocking items, and estimated time to
resolve each. **Sign-offs** (never signed by this skill): `qa-lead`, `cto`,
`security-lead`, `sre-lead` / `platform-lead`, `producer`, `product-director`.

## Save

Present the checklist with: total items, blockers, conditional items,
`[?]` items, per-track verdicts, gate verdicts or skips.

Ask: "May I write this to `production/releases/[product]-[version].md`?"
Create nothing before the answer — not even the directory. If yes, write the
file (the write creates the directory). Keep every `[?]` and NOT ASSESSED line in
the written file. If no: `BLOCKED — write declined by user` (the verdict above is
stated in conversation, marked not recorded).
