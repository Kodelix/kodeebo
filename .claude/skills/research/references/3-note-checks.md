# /research - Phase 4: Check the Note, Decide, Route

> Phase 4 of `SKILL.md`. Run every check; a check that could not run is `not
> run - reason`, never passed.

## 1. Mechanical checks on the returned note

Read the whole note. Build this table in the report.

| # | Check | How | Result |
|---|---|---|---|
| C1 | All nine sections present with the template's headings (Question, Versions, Findings, Options Considered, Decision, Security Notes, Performance & Caching Notes, Observability Notes, Open Questions) | `Grep '^## [1-9]\.'` | ran / MISSING: list |
| C2 | Header fields filled: Status, Author, Date, Feature/story, Triggers | read | ran |
| C3 | Every Findings row has a link and a tier 1-5; or tier E with a saved script and output path, command, versions and date; or `NOT SOURCEABLE - <what was searched>`; or `PENDING - <spike id>` | read the table; `Glob` each tier-E path | ran / rows without / E paths missing |
| C4 | Every Versions row has an exact version, where it is pinned and a Verified-on date | read the table | ran |
| C5 | Each version agrees with `pins.yaml` / the layer `VERSION.md`, or the row states why it differs (newer than the pin = candidate for `/research refresh`) | compare with Phase 2 | ran / differences listed |
| C6 | A Decision resting on a tier-5 finding, a `NOT SOURCEABLE` claim or a `PENDING` spike is flagged | trace the F-numbers cited by Decision | ran / flagged |
| C7 | At least two options for any non-trivial choice; licence-blocked options (L1-L4) named, not dropped | read | ran |
| C8 | Security Notes: ASVS/MASVS IDs carry the URL fetched or `NOT SOURCEABLE`; advisories list the date searched or say the search did not run | read | ran / gaps |
| C9 | Performance, caching and observability notes name concrete things (a hot path, a cache candidate, spans/metrics/log events) rather than "TBD" | read | ran / gaps |
| C10 | Every open question has an owner; blockers are marked | read | ran |
| C11 | No quoted passage longer than one short line per source | read | ran |
| C12 | No secrets, tokens, customer data, personal data or internal hostnames | **read-through only** - no scanner was run on the note; say so | read-through |

C12 is honest about what it is: a human-style read, not a secrets scan. Do not
write "secrets scan clean". If the user wants a scanner run, the tool and its
pinned version are in `docs/stack-reference/tooling/`; its flags are not
restated here.

## 2. Verdict

First match wins.

| Verdict | When |
|---|---|
| `BLOCKED` | an open question marked as blocking implementation, a load-bearing `NOT SOURCEABLE` claim that the Decision depends on, or the user has not decided between options that gate downstream work |
| `NOT ASSESSED` | the researcher returned no file, a source needed for a load-bearing claim could not be fetched (say which URL and why), a stack reference needed by the question is absent, or a check above could not run for lack of an input |
| `COMPLETE WITH GAPS` | every load-bearing claim sourced; peripheral `NOT SOURCEABLE` items or non-blocking open questions remain; list each |
| `COMPLETE` | all checks ran and passed; no `NOT SOURCEABLE` item; no open question |

Who decides "load-bearing"? **You propose, the user confirms** (`AskUserQuestion`
listing each `NOT SOURCEABLE` item with "blocks the decision / does not"). The
model never downgrades a gap on its own authority.

Status written into the note: `Complete` only for `COMPLETE`; `Draft` for every
other verdict. The status is written in the same approved Phase 5 write as the
decision. If that write is declined, the note on disk keeps the researcher's
`Status: Draft` (the brief sets it), nothing is changed, and the verdict is
`BLOCKED — write declined by user` — a declined write never leaves a note that says
`Complete` over unchecked content. A `Draft` note does not satisfy gate 1 for the claims it marks
unsourced; `/dev-story` and `/story-done` read the Status.

## 3. Present the options and obtain the decision

Show the Options table (cost, risk, performance, operability) and the
researcher's recommendation. This is a **major decision**
(`automation-modes.md`): `AskUserQuestion` with 2-4 options and a
recommendation in `guided` mode capped at 2; in `autonomous` mode pick the
recommended option and log it with `log_decision` **unless** it falls in an
`automation_always_ask` category (`version_bumps` when the choice bumps a
major version; `external_calls`/`architecture_decisions` when configured).

Hold the choice as part of the corrections drafted for Phase 5 — chosen option, why,
why not the others, follow-up record — and write it into section 5 of the note only
in Phase 5, after the user approves that write. Nothing here is written to the note
before "May I apply" is answered. **Why-not-the-others must be specific to this product**,
not generic.

## 4. Route follow-ups

| The note found... | Next |
|---|---|
| Auth, billing, licensing, crypto, file upload, PII, webhooks, admin or impersonation touched | `/threat-model [feature]` (security-baseline "Threat modelling"); the Security Notes are its input |
| An architectural choice (tenancy, identity, data store, messaging, API style, topology, licensing = critical ADR) | `/architecture-decision`; at `minimal` the brief's decision log |
| New or changed HTTP operations | `/api-contract [feature]` |
| Schema or data change | `/db-migration [feature]` |
| A read worth caching, or a rate limit / session / idempotency use of the Redis protocol | `/cache-design [feature]` |
| New endpoints, jobs, provider calls; SLO-relevant journey | `/observability-plan plan [feature]` |
| External provider | `/integration [provider]` |
| A version in the Versions table newer or older than its pin | `/research refresh <layer>` |
| A finding that contradicts an Accepted ADR | surface it; `/architecture-decision` supersedes, this skill never edits an ADR |

## 5. Gate (full review mode only)

CTO-STACK-RISK per `SKILL.md` Phase 4. Pass the API/library, the layer, the
pinned version and the note path. Record APPROVE / CONCERNS / REJECT / NOT
ASSESSED. REJECT sends the question back to Phase 3 with the gate's finding as
a delta; CONCERNS become open questions in the note, each with an owner.
