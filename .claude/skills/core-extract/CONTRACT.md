# /core-extract - Handoff Contract

## Role in Pipeline
Decides, with evidence, whether a product capability belongs in
`saas-core-<track>`, and produces the artifacts for the core repo (proposal) and
for the product (ADR, consume-back plan). Called by `/studio` (flow `core`),
`/team-feature` (core-first check), `/integration`, and by agents that find a
capability gap (`auth-identity-specialist`, `integrations-engineer`). Feeds
`/create-stories` (consume-back stories), `/core-use` (after the core release),
and, in the core repo, `/studio` and `/core-release`.

## Inputs Consumed
| Input | Required | Read-only? |
|-------|----------|-----------|
| Capability description or product path; optional `--module` | Yes | - |
| The capability's code, tests, config, tables; specs; research note; threat model; ADRs | The code: yes. Others when they exist | Yes |
| A second product's artifact (opened file) or a core-module category match | One of the two, or an accepted exception | Yes |
| `project.yaml` `core.*` and `stack`; the core repo at `core.repo` (module list, layout, versioning and deprecation policy) | `stack.backend` required; core repo unreadable = existing coverage `NOT ASSESSED` | Yes - the core repo is never written |
| `docs/stack-reference/pins.yaml`, `.claude/docs/templates/technical-design-document.md`, ADR template | Yes | Yes |

## Preconditions
- The strip test leaves a product-neutral capability (else `BLOCKED - product-specific`).
- Reusability is `EVIDENCED`, `CATEGORY`, or a user-recorded exception (else `BLOCKED`).
- The core does not already host the capability (else route to `/core-use`).

## Verdicts Emitted
`COMPLETE` / `COMPLETE WITH GAPS` / `NOT ASSESSED` / `BLOCKED`. Precedence:
BLOCKED, NOT ASSESSED, COMPLETE WITH GAPS, COMPLETE. Evidence verdict:
`EVIDENCED` / `CATEGORY` / `NOT EVIDENCED` / `NOT ASSESSED`. CTO-ADR (full review
mode): APPROVE / CONCERNS / REJECT / NOT ASSESSED / skipped.

## Outputs Produced
| File | Guaranteed content | Notes |
|------|--------------------|-------|
| `production/core/proposals/<module>/evidence.md` | strip-test list, evidence table with opened artifacts, claimed-unevidenced rows, verdict, any exception in the user's words with risk, owner, review date | written after approval |
| `production/core/proposals/<module>/design.md`, `review-<agent>.md` | port design (13 items) and one review per spawned specialist | written by the named agents under the bounded exception |
| `docs/architecture/adr-NNNN-<slug>.md` | via `/architecture-decision`; status stated; never set to Accepted by this skill | decision-log line at `workflow: minimal` |
| `production/core/proposals/<module>/proposal.md` | the technical-design-document template filled, plus numbered acceptance criteria for the core repo | no secrets, customer data or product-private values |
| `production/core/proposals/<module>/consume-back.md` | dependency gate, interim state, cut-over steps, parity tests, rollback, stories, risks | written after approval |

## Output Guarantees
- Evidence rows cite an artifact opened in the session; claims are listed separately and never counted.
- The proposal always contains a conformance-suite case list and a deprecation/versioning stance, or states the missing policy as `NOT SOURCEABLE` with an owner.
- Skipped reviews and gates are named (`skipped - <mode> mode`, `not spawned - <reason>`), never absent.
- The report ends with a `Not run / not checked` list.

## Immutability Rules
- No core repo file is created, edited, checked out or pushed; no message is sent to anyone.
- The product's code, `project.yaml` and `contracts/` are not edited (no pin change here).
- The ADR `Status` field is never set to Accepted by this skill.
- No commit.
