# /threat-model - Phase 6: Verify, Gate, Write

> Phase 6 of `SKILL.md`. A check that did not run is `not run - reason`, never
> passed.

## 1. Assemble the draft

Fill `.claude/docs/templates/threat-model.md` in full (all ten sections, same
headings). Header: Status `Draft`, Author line honest about who drafted
(`appsec-engineer via /threat-model` or `this session - appsec-engineer not
spawned: <reason>`), Reviewer `security-lead`, today's date (`date +%F`),
**Required because** naming every Phase 1 area, Standards line with the exact
versions read. Show the user the summary (assets, boundaries, High threats,
mitigations, residual risks, gaps), not only the file.

## 2. Mechanical checks

| # | Check | How | Result |
|---|---|---|---|
| C1 | Every sensitive area from Phase 1 has threats in the model; list area -> section | read | ran / uncovered: list |
| C2 | Boundary IDs agree in the diagram, boundary table and STRIDE headings | Grep tool with pattern `TB[0-9]+` (output_mode content) on the model file, compare the sets per part; a Mermaid fenced block exists | ran / mismatches |
| C3 | Six STRIDE categories per boundary, `N/A` with reason | read | ran / gaps |
| C4 | Cross-tenant prompts each answered (threat ID or `N/A - reason`); single-tenant recorded with its reason | read | ran / gaps |
| C5 | Business-flow abuse cases present; licence bypass present when licensing is in scope | read | ran / gaps |
| C6 | Every threat and abuse case has a mitigation or a section-7 row; every mitigation addresses at least one threat | cross-reference | ran / orphans |
| C7 | Every mitigation has a story (ID or `NEW:`) and a named negative test; counts of `Done` / `Planned` / `Gap` | read | ran |
| C8 | Mapping rows: ID + URL fetched, or `NOT SOURCEABLE`; counts; areas in scope with any `NOT SOURCEABLE` | read | ran / NOT ASSESSED areas |
| C9 | Residual risk: every High residual has a named person, role, date and review-by date; no placeholder or role-only acceptor | read | ran / Unaccepted list |
| C10 | Secrets and keys addressed (location, rotation, logging exclusions) | read | ran / gaps |
| C11 | Provider failure and compromise modes when an integration is in scope | read | ran / n/a |
| C12 | PII flows: legal basis and retention sourced, or `NOT ASSESSED - privacy review not done` | read | ran / n/a / not done |
| C13 | No secret, key material, working exploit or customer data | **read-through only**; no scanner was run on the file | read-through |
| C14 | Header complete: Required because, Standards versions, Next review trigger | read | ran |

## 3. Verdict (first match wins)

| Verdict | When |
|---|---|
| `BLOCKED` | a sensitive area is uncovered (C1); a High-impact threat with Medium/High likelihood, or any cross-tenant path, has neither a mitigation nor an accepted risk; a High residual is `Unaccepted`; or SL-THREAT-MODEL returned REJECT |
| `NOT ASSESSED` | any in-scope area's mapping is `NOT SOURCEABLE` (C8); PII review not done (C12); the research note or spec is absent and flows are `assumed`; a retrospective boundary's code could not be read; a scope fact (`tenancy.model`, `distribution.model`) stayed unset; the gate agent could not run. Each cause is named with what closes it |
| `COMPLETE WITH GAPS` | all of the above satisfied, but a mitigation is `Gap`, or `Planned` **without** a named owner (story ID, `NEW:` title with the stack lead, or a person) or without a named negative test; or, in a retrospective model, a test not yet written; or SL-THREAT-MODEL returned CONCERNS |
| `COMPLETE` | every mitigation linked to a story (existing, or `NEW:` proposed) **and** a named negative test; at design time a `Planned` test with a named owner and story counts (the code does not exist yet), in a retrospective model the test file exists; every mapped ID sourced, all residual risk accepted by name, gate APPROVE or recorded as skipped by review mode |

`NOT ASSESSED` ranks above `COMPLETE` and below `BLOCKED`. A `BLOCKED` finding is
reported first, with the unassessed area named beside it.

Status written in the header: `Draft` for any verdict other than `COMPLETE`;
`Reviewed` for `COMPLETE` after a gate APPROVE or the user's explicit review.
`Accepted` only on the user's explicit instruction.

## 4. SL-THREAT-MODEL (`full` review mode)

Write the file first (step 5), then gate it, so the director reads what is on
disk. Spawn `security-lead` via `Agent`. The prompt tells it to read
`.claude/docs/director-gates/sl-threat-model.md` first (you do not read it) and
passes: the model path; the spec path and the stories it covers (or `NEW:`
list); `docs/architecture/architecture.md`; the research note path;
`tenancy.model`, `distribution.model` and `stack`; related ADRs.

In `lean` or `solo`: record `SL-THREAT-MODEL skipped - [mode] mode`. Solo skips
the director's opinion, never the checks in step 2.

Verdict mapping: APPROVE -> no change; CONCERNS -> `COMPLETE WITH GAPS` at best,
each concern added to the model as an open row with an owner; REJECT -> `BLOCKED`;
NOT ASSESSED (model unreadable, spec or data flow unreadable) -> `NOT ASSESSED`.
If it cannot be spawned: `SL-THREAT-MODEL NOT ASSESSED - [reason]`.

## 5. Ask and write

Present the report (below) in conversation first. Then ask: "May I write the
threat model to `docs/architecture/threat-models/<feature>.md`?" (for an update,
state the rows added, changed and superseded and the revision-history entry).
Write only after approval; if the user declines, close with `BLOCKED — write declined by user` (the computed verdict stays in the report, marked not recorded). After a gate run changes the file (concerns as open
rows), ask again for that edit. Verify the file exists with `Read` before
reporting it written.

A suspected live secret, a working exploit path or a cross-tenant exposure
discovered while modelling a **built** feature is announced in conversation
immediately and routed to `security-lead`; it does not wait for the file.

## 6. Report

```text
Threat model: <feature>   Verdict: COMPLETE | COMPLETE WITH GAPS | NOT ASSESSED | BLOCKED
Mode: design-time | retrospective   Editions: ...   Tenancy: ... (set | unset)
Areas: <list>   Boundaries: N   Threats: N (High N)   Abuse cases: N
Mitigations: N  (Done N / Planned N / Gap N)   Stories: N existing, N NEW
Mapping: ASVS 5.0.0 N rows / MASVS 2.1.0 N rows / API Top 10 2023 N rows; NOT SOURCEABLE: N (areas: ...)
Residual risk: N accepted by name, N Unaccepted
Checks: C1..C14 each ran / not run - reason
SL-THREAT-MODEL: APPROVE | CONCERNS | REJECT | NOT ASSESSED | skipped - <mode> mode
NOT ASSESSED / BLOCKED causes: <each, with what closes it>
Written: <path | not written>
Mitigations needing stories (for /create-stories): <list>
```
