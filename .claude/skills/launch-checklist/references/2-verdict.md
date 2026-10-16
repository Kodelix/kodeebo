# /launch-checklist — Confirmation, Verdict, Save

> Phases 4a–6 of `SKILL.md`.

## Gates

`/launch-checklist` is a non-PHASE-GATE spawner, so the ordinary per-skill rule
applies (`.claude/docs/director-gates.md`): `full` review mode → spawn;
`lean` / `solo` → skip and record `[GATE-ID] skipped — [mode] mode`. **A skipped
gate waives the director's opinion, never the evidence** — the section 1 items
are still evaluated and reported.

Spawn both in parallel (neither needs the other's output). The `Agent` prompt
tells the agent to read the gate file first; this skill does not read it:

| Gate | Agent | Gate file | Context to pass |
|---|---|---|---|
| **SL-RELEASE-SECURITY** | `security-lead` | `.claude/docs/director-gates/sl-release-security.md` | launch version and commit range; editions shipping; latest `/security-audit` report and per-story security evidence; threat models; scan results on the launch commit; open vulnerability register; SL-TENANT-ISOLATION verdict |
| **SRE-OPERABILITY** | `sre-lead` | `.claude/docs/director-gates/sre-operability.md` | `distribution.model` and `deploy.target`; observability evidence; backup configuration, RPO/RTO and the latest restore-drill record; capacity evidence; rollback plan; runbooks and alert rules |

Record each verdict (READY / CONCERNS / NOT READY / NOT ASSESSED) beside its
section-1 block. NOT READY from either is a Blocking Item.

## Phase 4b — Confirm what only a person can

Most items cannot be settled from the repository — the on-call schedule, terms
approved by counsel, provider live mode, a real payment, press keys, status
page. Left unasked, every one stays unconfirmed and the status can only be
NOT ASSESSED, so ask.

For each of the sections 2–10, collect the items no scan or file settled (the
Phase 3 counts and anything read in Phase 2 are not asked again) and ask **one
`AskUserQuestion` per section**, listing those items numbered. Each item's
answer is **yes / no / not yet / N/A**. Options: `Yes — all of them` /
`Not yet — none of them` / `N/A — this section does not apply` /
`Some differ — I'll answer per item` (the user then gives each numbered item its
answer). Skip a section with nothing left to ask.

- **yes** → ticked `- [x]`, marked `(confirmed by the user)`
- **no** or **not yet** → a failed item: under Blocking Items, or under Conditional Items when the user names a workaround or accepts the risk (and who accepted it)
- **N/A** → written `- N/A — [item]` and left out of the Overall Status
- an item left unanswered stays unconfirmed, and the status names it

Legal, tax and privacy items answered "yes" are recorded with **who confirmed
(counsel/accountant/advisor) and when** where the checklist asks for it — a bare
"yes" from the user is recorded as the user's statement, not as legal approval.

These are questions of fact only the user can answer, so they are asked in
`collaborative` and `guided` alike and never answered on the user's behalf. In
`autonomous` mode and in `dry-run`, skip this phase and say so: the items it
would have asked stay unconfirmed, and the Overall Status is NOT ASSESSED.

## Go / No-Go Decision

**Overall Status**: READY / CONDITIONAL / NOT ASSESSED / NOT READY

First match wins: **NOT READY** if Blocking Items is not empty; else **NOT
ASSESSED** if any item is `- [?]`, any section came out `NOT ASSESSED`, or any
item is still unconfirmed — neither ticked on evidence or on a Phase 4b answer,
nor marked N/A, nor listed below (name each; group by section when there are
many); else **CONDITIONAL** if Conditional Items is not empty; else **READY**.
NOT ASSESSED outranks CONDITIONAL and READY — an item nobody could check is not a
passed one — and ranks below NOT READY, so a known blocker is never buried
behind it.

### Blocking Items
Every FAIL or unresolved finding with no documented workaround and no explicitly
accepted risk: an open S1, an open CRITICAL/HIGH security finding, a failing build
or test, a never-restored backup, no rollback, a gate
that returned NOT READY, live payment not verified, Terms/Privacy not published,
no support channel, no on-call, FIXMEs, debug output, hardcoded dev values.
A scan that did not run is not listed here: it makes the verdict NOT ASSESSED
(never clean, never READY) and is named under Missing inputs.

### Conditional Items
Every shortfall with a documented workaround or an explicitly accepted risk: a
HACK with justification, an S2 with a written exception (below `workflow: full`),
a gate that returned CONCERNS. Name the workaround, or **who accepted the risk
and until when**.

### Not Assessed
Every `[?]` item and unconfirmed item, grouped by section, each with the input
that would close it.

### Sign-offs Required
As listed in section 11 of the checklist. Never signed by this skill.

## Save

Present the completed checklist and summary (Overall Status, total items,
blocking count, conditional count, not-assessed count, sections that are
incomplete, gate verdicts or skips).

If not in dry-run mode, ask: "May I write this to
`production/releases/launch-checklist-[date].md`?" Create nothing before the
answer — not even the `production/releases/` directory. If yes, write the file;
the write creates the directory with it. Keep every `[?]` and NOT ASSESSED line
in the written file. A launch checklist containing customer data, keys, bank or
tax identifiers is a defect: record where those live, never their values.
