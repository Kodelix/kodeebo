# /dev-story — Phase 2: Load Context and Pass the Prerequisite Gates

> Part of `/dev-story`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 2: Load Context and Pass the Prerequisite Gates

**In this file:**

- Required files by tier
- The story file
- Gate A — research note (DoD gate 1)
- Gate B — threat model (sensitive stories)
- Gate C — contract first
- The TR registry
- The governing ADR
- The control manifest
- Dependency validation
- Stack reference
- Mark Story In Progress

**Before loading any context, resolve the workflow tier for this story's feature**
(see the Workflow tier note in `SKILL.md`), then **verify required files exist.**
Extract the ADR path from the story's `ADR Governing Implementation` field. The
"If missing — `full`" column is the baseline; the tier columns relax it:

| File | Path | If missing — `full` | `standard` | `minimal` |
|------|------|---------------------|-----------|-----------|
| TR registry | `docs/architecture/tr-registry.yaml` | **STOP** — "TR registry not found at `docs/architecture/tr-registry.yaml`. Run `/architecture-review` to bootstrap the registry from your specs and ADRs." | optional — proceed without it | not expected — proceed |
| Governing ADR | path from story's ADR field | **STOP** — "ADR file [path] not found. Run `/architecture-decision` to create it, or correct the filename in the story's ADR field." Also STOP if its `## Status` is `Proposed` — "ADR [path] is still Proposed. Accept it with `/architecture-decision accept [ADR-id]` before implementing." A story whose ADR field reads `N/A` (`N/A — [reason]`) references none — proceed. | **STOP only if the story references an ADR** and its file is missing/Proposed/Deprecated/Superseded; if it references none, proceed | no ADR required — proceed; **STOP only if the story references an ADR** whose file is missing/Proposed/Deprecated/Superseded |
| Control manifest | `docs/architecture/control-manifest.md` | **WARN and continue** — "Control manifest not found — layer rules cannot be checked. Run `/create-control-manifest`." | WARN and continue | skip — not expected |
| Research note | `docs/research/<feature>.md` or a documented exemption | **STOP** (Gate A) | **STOP** (Gate A) | **STOP** (Gate A) — not relaxed at any tier |
| Threat model | `docs/architecture/threat-models/<feature>.md` | **STOP** for a sensitive story (Gate B) | **STOP** (Gate B) | **STOP** (Gate B) — not relaxed at any tier |

At `full`, if the TR registry is missing, or a referenced governing ADR is missing
or `Proposed`, set the story status to **BLOCKED** in the session state and do not
spawn any agent. At `standard`/`minimal`, only a story that references an ADR whose
file is **missing, `Proposed`, `Deprecated` or `Superseded`** is set BLOCKED; a
missing TR registry, or an absent-by-design ADR, does **not** block — implement
against the story's acceptance criteria + the spec (or `design/product-brief.md`).

Read the story file and the TR registry simultaneously — these two are genuinely
independent, unconditional reads. **The governing ADR is not part of this batch —
do not include it in the same parallel tool-call group as these two.** Its own
section below is a gate, not a read: whether the ADR gets opened at all depends
on a freshness check that itself depends on the story file already being read.
Do not start implementation until this phase is fully resolved:

### The story file
Extract and hold:
- **Story title, ID, layer, code root, type** (Logic / Integration / Contract / Security / Performance / UI / Config)
- **Owner agent** line and **Editions** line (hosted / self-hosted — and the licence rule that binds the story)
- **TR-ID** — the spec requirement identifier
- **Research note** and **Threat model** lines (path, `exempt — [row]`, `not required — [reason]`, or MISSING)
- **Contract** line (which contract story/file this story consumes or authors)
- **Governing ADR** reference
- **ADR Version** stamp embedded in story header (absent on pre-stamp stories)
- **ADR Decision Summary** and **Implementation Notes** — the distilled ADR guidance; the primary source for what the ADR decided
- **Manifest Version** embedded in story header
- **Acceptance Criteria** — every checkbox item, verbatim (including the negative / cross-tenant criteria)
- **Out of Scope** boundaries
- **QA Test Cases** and **Test Evidence** — the required test paths
- **Definition of Done Evidence** table (the eight gates plus run-and-observe) with its current statuses
- **Dependencies** — what must be DONE before this story

### Gate A — Research note (DoD gate 1) — refuse to start without it

Source: `.claude/docs/research-protocol.md` → "When research is required". **No feature is built
from memory.** Check, in this order:

1. The story's `Research note:` path exists on disk (Glob). Read its section
   headings and its `Versions`, `Decision`, `Security notes`, `Performance &
   caching notes`, `Observability notes` and `Open questions` sections — the
   lead will need them; this phase confirms they are present and filled.
2. **Else**, the story carries a documented exemption — `Research: exempt —
   [row of the research-protocol.md table]` (bug fix inside already-researched
   code, citing the existing note's path; or copy, styling, config value change).
   **Check the claim against the story's content**: a story that introduces a
   new endpoint, dependency, provider, schema or sensitive area (auth, billing,
   licensing, crypto, file upload, PII) is **not** exempt, whatever it says.
3. **Else STOP.** Report: `Research note missing for [feature] — no feature is
   implemented from memory (DoD gate 1). Run /research [feature] (or the researcher
   agent), then re-run /dev-story.` Set the session-state `Blocked on:` line. Do
   not spawn any agent and do not offer to research inline.

If the note exists, also check:
- **The note is `Status: Complete`.** Read its `Status:` header line
  (`.claude/docs/templates/research-note.md`). `/research` writes `Complete` only
  for verdict COMPLETE; a note written with gaps is `Draft`
  (verdict COMPLETE WITH GAPS), and `Stale (re-verify)` is stale.
  - `Complete` → pass.
  - `Draft` → the note's gaps are open. Name them (its `Open questions` and every
    `NOT SOURCEABLE` line) and ask via `AskUserQuestion`: `[A] Finish the note
    first with /research (Recommended)` / `[B] Accept the gaps for this story —
    I state that I accept them` / `[C] Stop`. [B] is the user's explicit
    acceptance. Record it in two places that need no further ask: the Phase 7
    summary and the session-state checkpoint (`active.md`, `Open questions:` line — the
    one write made without an ask). Then also write it to the story file as
    `Research gap accepted: <gaps> — accepted by <user> on <date>` as part of the
    "Mark Story In Progress" ask below. If that ask is declined the story file is
    not edited, but the acceptance is already on record in the summary and the
    checkpoint — it is never lost with the declined write. Never infer acceptance
    from silence or a general "go ahead".
  - `Stale (re-verify)` → handled by the stale-versions check that follows.
  - No readable `Status:` line → **NOT ASSESSED** for this check: name the file;
    do not treat it as `Complete`, and **stop before any agent is spawned**. Ask via
    `AskUserQuestion`: `[A] I will fix the note's header (or re-run /research) and
    re-run /dev-story` / `[B] Stop`. Either way this run ends here with
    `Research status: NOT ASSESSED — <file>` in the summary; nothing is implemented
    on an unreadable note.
- **Versions are current**: every library/service version in the note's `Versions`
  section matches `docs/stack-reference/pins.yaml` (Grep the pin keys). A note
  that cites older versions than the pinned ones is **stale** — ask via
  `AskUserQuestion`: `[A] Re-verify the note first with /research (Recommended)` /
  `[B] Proceed — I accept the staleness risk (recorded in the Phase 7 summary)` /
  `[C] Stop`.
- **No blocking open question**: an `Open questions` entry that blocks
  implementation and has no resolution means BLOCKED — name it.
- **A `NOT SOURCEABLE` finding** in the note for something the story needs is
  carried into the lead's brief: the lead must not fill that gap from memory.
- Whether the note contains a **cache decision** (or a written "no cache" reason)
  and performance and observability notes — missing ones are carried into the
  Phase 4 evidence plan as items the plan must create, not silently skipped.

### Gate B — Threat model (security-sensitive stories)

Trigger list: `.claude/docs/security-baseline.md` → "Threat modelling" — authentication, the authorization
model, billing, licensing, file upload, webhooks, PII export/delete, admin or
impersonation, a new external integration. Borderline cases lean to "trigger
applies"; say which way you judged and why in the Phase 7 summary.

If the story (or its feature) hits a trigger:

1. The model at `docs/architecture/threat-models/<feature>.md` must exist.
   **Missing → STOP**: `Sensitive story with no threat model — run /threat-model
   [feature]; the story stays BLOCKED until SL-THREAT-MODEL has a model to review.`
   No agent is spawned.
2. **Residual risk is accepted by name.** Read the model's section 7
   (*Residual Risk — Accepted by Name*) and its `Status:` header.
   - Every residual-risk row needs a named acceptor (name, role), an acceptance
     date and a review-by date; the model must also say so explicitly if there is
     **no** residual risk. A row with no named acceptor, a section that is empty
     without that statement, or `Status: Needs update` → **STOP**:
     `Threat model for [feature] has no recorded residual-risk acceptance — the
     accountable person records it with /threat-model [feature] --update; the
     story stays BLOCKED.` This model never accepts risk on anyone's behalf, and
     neither does this skill — acceptance cannot be drafted here.
   - `Status: Draft` with every residual-risk row accepted by name → proceed, but
     print `Threat model is Draft — accepted residual risk only` in the Phase 7
     summary so the reviewer sees it. `Reviewed` / `Accepted` → proceed.
   - These checks are mechanical file reads: they run in every review mode,
     including `solo` and `lean`, where only the SL-THREAT-MODEL director opinion
     (step 3) is skipped.
3. Read the model's threat table and extract the rows this story owns: each
   mitigation, its ASVS / MASVS / API Top 10 requirement ID, and the **negative
   test** it names. These become mandatory rows of the Phase 4 evidence plan and
   mandatory test cases in the lead's brief.
4. **SL-THREAT-MODEL gate** (review mode from the resolved block):
   - `solo` or `lean` → skip. Note: "SL-THREAT-MODEL skipped — [mode] mode." The file-exists, status and residual-risk-acceptance checks above still stand.
   - `full` → spawn `security-lead` via `Agent` using gate **SL-THREAT-MODEL** (`.claude/docs/director-gates/sl-threat-model.md`), passing the model path, the spec path, this story and the architecture data-flow. The gate file is read by the spawned agent, not here.
   - Verdicts: **APPROVE** → proceed. **CONCERNS [gaps]** → the gaps become tasks in this story's evidence plan; user chooses via `AskUserQuestion`: `Update the plan` / `Accept and proceed anyway` / `Discuss further`. **REJECT** → STOP; the model must be revised. **NOT ASSESSED [missing input]** → name the input; do not proceed as if approved.
5. If the story does **not** hit a trigger, record `Threat model: not required — [reason]` for the Phase 7 summary. Never leave the line out.

### Gate C — Contract first

Applies when the story's code root is `web/`, `site/`, `mobile/**` or `backend/`
and it consumes or exposes an API operation.

1. Find the **Contract** line in the story and the `Type: Contract` stories in the
   same epic (one Grep of `Type:` across `production/epics/<epic>/story-*.md`).
2. A client story (web, mobile) or a backend story that implements an operation
   requires: the operation exists in `contracts/` (Glob the named file; Grep the
   operation id/path) **and** the contract story is `Complete`. A contract story
   that is Ready/In Progress/missing → **BLOCKED**: `Contract story [ID] is not
   Complete — finish the contract first (api-designer, /api-contract).`
3. A story that authors the contract (`Type: Contract`) is routed to `api-designer`
   first and everything downstream waits for its merge — see Phase 3.
4. If the story says `Contract: n/a — [reason]` (no API surface), accept the
   reason only if the story's criteria really touch no endpoint; otherwise ask.

### The TR registry
Grep the story's TR-ID from `docs/architecture/tr-registry.yaml`
(`Grep pattern="id: <TR-ID>\s*$" path="docs/architecture/tr-registry.yaml" output_mode="content" -A 6`)
rather than reading the whole cross-feature registry. Read the matched entry's
current `requirement` text — this is the source of truth for what the spec
requires now. Do not rely on any inline text in the story file (may be stale).

### The governing ADR

**Do not open the ADR by default.** `/create-stories` already distilled it into
this story's `**ADR Decision Summary**` + `## Implementation Notes`, and its
template states the contract outright: *"This is what the engineer reads instead
of the ADR."* Re-reading the source here discards that work and, on an ADR past
the 25k `Read` cap, costs a failed read plus offset/limit retries before
implementation even starts.

**Check status and freshness with one line, not one file.** Resolve the ADR path
from the story, then:

```
Grep pattern="^## (Status|Last Verified|Date)" path="docs/architecture/[adr-file].md" output_mode="content" -A 2
```

The `## Status` line decides first: if it reads `Proposed`, the story is BLOCKED
per the file-check table above — stop here, before any freshness comparison.
`Deprecated` or `Superseded by ADR-XXXX` blocks the same way, at every tier:
"ADR [path] is [status]; point the story at [successor] (edit its ADR field —
`/create-stories` never rewrites an existing story) before implementing."

Then resolve the ADR's **current version** the way `/create-stories` stamped it:
its `## Last Verified` date, else its `## Date`, else `unversioned`. Compare that
value against the story's `**ADR Version**` field:

| Result | Meaning | Action |
|---|---|---|
| Versions **match** (a date on both sides) | The summary was distilled from the ADR as it stands. | **Trust the story.** Do not read the ADR. |
| Story has **no `ADR Version`** field | A story written before the stamp existed — *not* evidence of staleness. | **Trust the story**, and note in the Phase 7 summary: "Story predates the ADR Version stamp; summary trusted unverified." |
| Both read `unversioned` | The ADR has neither `## Last Verified` nor `## Date`. Consistent, not stale — but nothing to compare. | **Trust the story**; note "ADR carries no date; summary trusted unverified." in the Phase 7 summary, and recommend `/architecture-decision retrofit [file]`. |
| The ADR resolves to `unversioned` but the story names a date | Ambiguous — the ADR lost the field the story was stamped from. | Treat as **mismatch** (below). |
| Versions **differ** | The ADR changed after this story was written. | **Mismatch** — resolve below. |

**Never treat an absent stamp as a stale one.** A missing field means "unknown",
and the fallback for unknown is the story, not a 35k-token re-read — the two
staleness gates that already exist (`/story-readiness` on Manifest Version,
`/code-review` post-implementation) are what make that safe.

**On mismatch**, use `AskUserQuestion`:
- Prompt: "Story was written against ADR v[story-date]. The ADR is now
  v[current-date]. Its decision may have changed. How do you want to proceed?"
- Options:
  - `[A] Re-read the changed ADR sections, implement against current guidance, and refresh this story's ADR summary and ADR Version (Recommended)`
  - `[B] Implement from the story's summary — I accept the drift risk`
  - `[C] Stop — I want to review the ADR diff first`

If **[A]**: first check the ADR's size — `Bash: wc -c "docs/architecture/[adr-file].md"`:

- **Under ~50KB** — read the whole file with one `Read` call.
- **~50KB or larger** — read *only* the sections that govern implementation:
  ```
  Grep pattern="^## (Decision|Stack Compatibility|ADR Dependencies)" path="docs/architecture/[adr-file].md" output_mode="content" -A 40
  ```
  Escalate to a bounded `Read(offset, limit)` on one section only if a scanned
  section cross-references material outside itself.

Then make the story edit that option [A] names: set its `ADR Version` to the ADR's
current version resolved above — not today's date, or the next run mismatches
again — and replace its `**ADR Decision Summary**` and `## Implementation Notes`
with the guidance you just read.
If **[B]**: proceed on the summary; record it in the Phase 7 "Deviations" summary.
If **[C]**: stop. Do not spawn any agent.

### The control manifest
Read only this story's layer from `docs/architecture/control-manifest.md` — grep that
one section (`Grep pattern="^## <layer> Layer Rules" path="docs/architecture/control-manifest.md" output_mode="content" -A 40`)
rather than a full read of every layer. Extract the rules for this story's layer
and context: required patterns, forbidden patterns, performance guardrails.

Check: does the story's embedded Manifest Version match the current manifest
header date? If they differ, use `AskUserQuestion` before proceeding:
- Prompt: "Story was written against manifest v[story-date]. Current manifest is v[current-date]. New rules may apply. How do you want to proceed?"
- Options:
  - `[A] Update story manifest version and implement with current rules (Recommended)`
  - `[B] Implement with old rules — I accept the risk of non-compliance (the story records the current Manifest Version and a Manifest-Note)`
  - `[C] Stop here — I want to review the manifest diff first`

If [A]: edit the story file's `Manifest Version:` field to the current manifest date before spawning anything. Then read the manifest carefully for new rules.
If [B]: edit the story file's `Manifest Version:` field to the current manifest date AND add a `Manifest-Note: Proceeded with old manifest rules on [date] — non-compliance risk accepted.` line to the story header. Read the manifest for new rules anyway. Note the decision in the Phase 7 summary under "Deviations". `/story-done` will include the Manifest-Note in its deviations section without re-checking staleness.
If [C]: stop. Do not spawn any agent. Let the user review and re-run `/dev-story`.

### Dependency validation

After extracting the **Dependencies** list from the story file, validate each:

1. Glob `production/epics/**/*.md` to find each dependency story file.
2. Read its `Status:` field.
3. If any dependency has Status other than `Complete` or `Done`:
   - Use `AskUserQuestion`:
     - Prompt: "Story '[current story]' depends on '[dependency title]' which is currently [status], not Complete. How do you want to proceed?"
     - Options:
       - `[A] Proceed anyway — I accept the dependency risk`
       - `[B] Stop — I'll complete the dependency first`
       - `[C] The dependency is done but status wasn't updated — mark it Complete and continue`
   - If [B]: set story status to **BLOCKED** in session state and stop. Do not spawn any agent.
   - If [C]: ask "May I update [dependency path] Status to Complete?" before continuing.
   - If [A]: note in Phase 7 summary under "Deviations": "Implemented with incomplete dependency: [dependency title] — [status]."
   - **Exception — Gate C:** an incomplete *Contract* story is never waived by option [A] for a client story; [A] is offered only for non-contract dependencies.

If a dependency file cannot be found: warn "Dependency story not found: [path]. Verify the path or create the story file."

---

### Stack reference and project profile

Resolve and hold, for the layers the story touches (Phase 3 decides the lanes;
read the pointers now so the brief can name them):

- `stack.*`, `tenancy.model`, `distribution.model`, `core.track` from the resolved block / `project.yaml`. Any `unset` value for a layer this story touches → STOP (`/setup-stack`); never default it.
- `bash .claude/hooks/yaml-helper.sh resolve_code_root` — the code roots that exist; an empty result means **the roots could not be resolved: report it and stop** rather than guessing a path.
- `docs/stack-reference/<layer>/` — `VERSION.md` (pinned version and risk rating), `best-practices.md`, `deprecated-apis.md`, `breaking-changes.md` — and `docs/stack-reference/pins.yaml`. **If the layer's directory is missing or its `VERSION.md` carries no risk rating, the rating is `NOT ASSESSED` and counts as HIGH** (an unknown risk is not a low one). The story card's `Risk:` field is a hint; the reference wins where they disagree.
- `.claude/rules/` files whose `paths:` match the files the story will touch (`backend-go.md`, `backend-ktor.md`, `web-react.md`, `contracts.md`, `migrations.md`, `cache-code.md`, `integrations.md`, `security-sensitive.md`, `deploy.md`, …) — the lead reads them; list their paths in the brief.
- Editions: if the story's `Editions` line includes self-hosted, or it touches `deploy/self-hosted/`, the licence rules in `.claude/rules/deploy.md` bind the brief.
- `performance.enforce` (warn/block) and the budget row for the surface in `docs/architecture/perf-budgets.md` (a missing budget file or row is recorded as `budget not yet set`, not assumed met).
- `naming.*` from `project.yaml` if present.

**Stack-risk escalation.** If the layer's risk rating is HIGH or `NOT ASSESSED`,
or the research note / ADR lists an API that is beyond `docs/stack-reference/`
(a post-cutoff API), then (a) the lead's brief must require every such API to be
checked against the stack reference before use, with `NOT SOURCEABLE` gaps
returned to the user rather than filled from memory; and (b) at review mode
`full`, spawn `cto` via gate **CTO-STACK-RISK** (`.claude/docs/director-gates/cto-stack-risk.md`) before implementation. At `lean`/`solo` skip (b) and note it — the check in (a) still applies.

### Mark Story In Progress

Before spawning any agent, mark the story In Progress. In `collaborative` mode
ask once first — "May I mark this story In Progress? This sets `Status:`,
`Last Updated:` and `Started:` (plus a `Research gap accepted:` line if you
accepted a Draft note above) in `[story-path]` and its entry in
`production/sprint-status.yaml`."
(leave the sprint-status file out of the question when it does not exist);
`guided` and `autonomous` update these existing files without asking
(`.claude/docs/automation-modes.md`). If the user declines, change neither file,
print `Story not marked In Progress — declined` in the Phase 7 summary, and
continue. Otherwise update two things:

1. **`production/sprint-status.yaml`** (if it exists): find the entry matching this story's file path and set `status: in-progress`. Update the top-level `updated` field to today's date. If the file does not exist, say so in one line — `Sprint status not updated: production/sprint-status.yaml absent` — and continue. Do not skip silently: `/sprint-status` reads that file to report progress, so a story that never gets marked `in-progress` is invisible to the very command a producer uses to ask what is moving.

2. **The story file itself**: set the story header's `Status:` field to `In Progress`, and edit its `Last Updated:` field to today's date (format: `YYYY-MM-DD`; if the field does not exist, add it after the `Status:` line). Also add `Started: YYYY-MM-DD` after the `Status:` line **if it is not already there** (never overwrite an existing value on a resumed story). `/story-done` gate 1 compares the research note's `Date:` against this line when git history cannot answer (nothing committed yet). Setting `Status:` here is what actually marks the story In Progress — at `minimal` the `sprint-status.yaml` in step 1 is absent, so the story file is the only record of progress at that tier.

---
