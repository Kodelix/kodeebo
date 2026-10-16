# /postmortem - Phases 6-7: Draft, Checks, Review, Write

## 1. Fill the template

Use `.claude/docs/templates/post-mortem.md`; do not invent a parallel format.
Mapping for an incident postmortem:

| Template section | Content |
|---|---|
| Document Status | Date, **Facilitator: `sre-lead`** (the skill drafts on its behalf), Participants as **roles** (and people only if the user lists them), Period Covered = detection -> resolution UTC; add `Incident: [id], SEV[n], link to the incident record` |
| Summary | 2-3 sentences: what customers experienced, how long, how it was resolved, in customer terms; root-cause confidence word |
| Goals vs Results | rows per breached/affected objective: SLO target vs result (from the impact work) |
| Timeline | the rebuilt UTC timeline with a **Basis** column (EVIDENCED / REPORTED / INFERRED) and the standard intervals |
| What Went Well | per category, What / Why it worked / How to repeat |
| What Went Poorly | per contributing factor: What / Root cause (the safeguard) / Impact / Prevention |
| Key Metrics | time to detect/acknowledge/mitigate/resolve; tenants affected; escaped-defect count; **SLO error budget consumed** with arithmetic; DoD gates not met for the change that caused it (from the story, if known) |
| Lessons Learned | numbered lessons and **where we got lucky** |
| Action Items | the action table of `2-factors-and-actions.md` §6 (owner, deadline, status, story, type, factor) |
| Acknowledgments | contributions by role, if the user wants them |
| *(append)* Not Known | every `NOT KNOWN` with the evidence that would settle it and an owner - the `sre-lead` postmortem format requires it |

Fill every field that applies; a section that does not apply says `Not applicable
- [reason]`. Remove template placeholders; none may remain.

## 2. The blameless check (mechanical)

Run both scans on the draft text and report the output:

1. **Names**: list author/committer names of the commits in the incident window
   (`git log --since=<start> --until=<end> --format='%an%n%cn'`, run without a pipe;
   de-duplicate the names yourself) and every name the
   user gave for participants; search the draft for each (case-insensitive,
   including first names). Any match outside the Participants list (and Participants
   only if the user chose to list people) is a finding.
2. **Blame phrases**: search for wording that attributes cause to a person's act or
   character, such as "forgot", "should have known", "careless", "negligent",
   "mistake by", "failed to notice", "human error", "fault of", "sloppy",
   "didn't bother". Each hit is rewritten to the missing safeguard, with the user's
   approval; "human error" as a final cause is never accepted (ask "what made that
   error easy to make and hard to catch?").

If the git history is unavailable the names scan is `not run` and is stated; the
phrase scan still runs. A clean scan is reported with the terms searched, not as
"blameless".

## 3. Checks P1-P14

Each is `met` / `not met` / `not applicable (reason)` / `not run (reason)`, with
the section or file cited.

| ID | Check |
|---|---|
| P1 | The incident was `Resolved` and a record exists; postmortem decision and deadline stated |
| P2 | Evidence inventory complete: every source FOUND / ABSENT / NOT READ |
| P3 | Timeline in UTC, every row classed EVIDENCED / REPORTED / INFERRED; conflicts shown; intervals only from evidenced rows |
| P4 | Impact numbers each have a named source or are `NOT KNOWN` |
| P5 | SLO / error-budget impact computed with arithmetic and inputs, or `NOT ASSESSED` with the missing input; the policy line quoted |
| P6 | Root cause stated with confidence (PROVEN / LIKELY / UNKNOWN); trigger, causes, aggravators distinguished |
| P7 | Every contributing factor names the missing/weak safeguard and cites evidence |
| P8 | What went well recorded with evidence |
| P9 | Blameless check run and clean (names and phrases), terms listed |
| P10 | Runbook gaps listed with the exact step; updates written or ticketed; `Last verified` untouched |
| P11 | Every action has type, owner, due date, acceptance check and a story (or `story pending`, a gap) |
| P12 | Every factor maps to an action or a user-recorded acceptance with owner and expiry |
| P13 | Detection analysis present (agent output) or `NOT ASSESSED` |
| P14 | No secrets, PII, customer data or hostnames in the document; tenants by internal ID |

## 4. Verdict

First match wins: **BLOCKED** (incident not resolved, no record, or a person named
as a cause and not reworded) -> **NOT ASSESSED** (P2/P3 sources unreadable so the
timeline is unevidenced; P5 uncomputable; root cause UNKNOWN; an agent needed for
P13 could not run) -> **COMPLETE WITH GAPS** (P10-P12 open: missing owner, date,
story or mapping; `story pending`) -> **COMPLETE**. State every cause and what
closes it.

## 5. Review by `sre-lead`

Spawn `sre-lead` with the draft path and ask for a review against its Senior Bar
items for postmortems: blameless wording, actions with owner and date, SLO impact
in numbers, runbook link, RPO/RTO where data was involved. It returns findings;
it does not edit. Apply its findings with the user. In `solo` mode a SEV3/SEV4
postmortem may skip this review - recorded `sre-lead review skipped - [mode]`;
for SEV1/SEV2 ask the user to confirm the skip explicitly.

## 6. Write

Ask the three questions of `SKILL.md` Phase 7 (postmortem file, runbook edits,
incident record status). Write the postmortem; apply approved runbook edits;
on the incident record set `Status: Post-Mortem Complete` (only when the
verdict is `COMPLETE` or `COMPLETE WITH GAPS` and the user approves) and link the
postmortem in its header and in the `active.md` line. A `NOT ASSESSED` postmortem
leaves the incident `Resolved` and says why.

Report: verdict with causes, the action count by type with how many have owner/date/
story, error-budget numbers, the blameless scan terms and result, and the **Not
run / not checked** list.
