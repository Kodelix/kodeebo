# /threat-model - Handoff Contract

## Role in Pipeline
Produces the threat model that gates sensitive stories (security-baseline
"Threat modelling"; SL-THREAT-MODEL). Called by `/team-security`, `/design-spec`
and `/map-domains` (routing), `/story-readiness` and `/dev-story` (presence for a
sensitive story), `/create-architecture`, `/integration`, `/license-design`.
Read by `/story-done`, `/security-audit`, `/tenant-check`, `/pentest`. `/dev-story`, `/story-readiness` and `/story-done` also require section 7 (residual risk) to carry a named acceptor, date and review-by date per row (or an explicit "no residual risk" statement) — in every review mode — and refuse `Status: Needs update`; this skill records an acceptance a person gives, never grants one.

## Inputs Consumed
| Input | Required | Read-only? |
|-------|----------|-----------|
| Feature slug; sensitive areas touched (evidenced) | Yes | - |
| `docs/research/<feature>.md` | Yes for a sensitive area (absence limits the verdict to NOT ASSESSED) | Yes |
| `design/specs/<feature>.md`, `docs/architecture/architecture.md`, ADRs, `contracts/` | When they exist; absence recorded | Yes |
| Code roots (retrospective only), migrations, `deploy/` | Retrospective model | Yes |
| `project.yaml` via `resolve_config` (`stack`, `tenancy`, `distribution`, `review_mode`, `automation`) | Yes (unset = asked, never defaulted permissively) | Yes |
| Existing `docs/architecture/threat-models/<feature>.md` | For `--update` | No - IDs kept stable |

## Preconditions
- At least one sensitive area is touched, or the skill reports `NOT REQUIRED - <evidence>` and writes nothing.

## Verdicts Emitted
`COMPLETE` / `COMPLETE WITH GAPS` / `NOT ASSESSED` / `BLOCKED`. Precedence:
BLOCKED, NOT ASSESSED, COMPLETE WITH GAPS, COMPLETE. SL-THREAT-MODEL:
APPROVE / CONCERNS / REJECT / NOT ASSESSED / skipped (REJECT -> BLOCKED,
CONCERNS -> COMPLETE WITH GAPS at best, NOT ASSESSED -> NOT ASSESSED).

## Outputs Produced
| File | Guaranteed content | Notes |
|------|--------------------|-------|
| `docs/architecture/threat-models/<feature>.md` | all ten template sections; boundary IDs consistent across diagram, table and STRIDE; each mitigation with story and named negative test; each requirement ID with its source URL or `NOT SOURCEABLE`; residual risk accepted by a named person with dates | written after explicit approval; Status `Draft` unless COMPLETE and reviewed |

## Output Guarantees
- Requirement IDs come from the official ASVS 5.0.0 / MASVS 2.1.0 / API Top 10 2023 documents, with the URL fetched; none is recalled.
- The report lists checks C1-C14 as ran / not run; C13 is labelled read-through.
- No story is created; the list of mitigations needing stories is returned for `/create-stories`.

## Immutability Rules
- Threat, mitigation and boundary IDs are never renumbered in an update; retired rows are marked `Superseded`.
- Risk is never accepted, softened or re-rated by this skill, `appsec-engineer`, `security-lead` or `cto`.
- Specs, ADRs, stories and code are never edited here.
