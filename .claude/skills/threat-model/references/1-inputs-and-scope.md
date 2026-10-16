# /threat-model - Phase 1: Trigger, Inputs and Mode

> Phase 1 of `SKILL.md`. Read it again if the conversation was compacted.

## 1. Parse the argument

| Argument | Meaning |
|---|---|
| `<feature-slug>` | The spec filename stem (`design/specs/<slug>.md`); the model is `docs/architecture/threat-models/<slug>.md` |
| `--update` | A model for the slug exists and is being revised |
| no argument | Ask which feature (`AskUserQuestion`); offer the specs that flag a sensitive area (`Grep` the Non-Functional Requirements sections), never guess |
| `--review` | Override `review_mode` for this run (gates only) |

A product with no spec (`workflow: minimal`) uses a short slug agreed with the
user; the feature description comes from `design/product-brief.md` and the
research note.

## 2. Test the trigger

`security-baseline.md` "Threat modelling": required for any story touching

1. authentication
2. the authorization model
3. billing
4. licensing
5. file upload
6. webhooks
7. PII export or delete
8. admin or impersonation
9. a new external integration

For each area write **touches / does not touch** with the evidence (spec
section, contract operation, code path, research-note line). Ask the user when
the evidence is ambiguous. Two or more areas = one model, with every area named
in the header's **Required because** line.

- **No area touched:** report `NOT REQUIRED - <reason>`, write nothing, and offer
  a voluntary model only if the user asks. A "no" must name the evidence, so a
  skipped model is distinguishable from one that was not needed.
- **Any area touched:** continue, at every `workflow` tier.

## 3. Record every input as FOUND or ABSENT

Derive paths with `resolve_code_root` (`bash .claude/hooks/yaml-helper.sh
resolve_code_root`) and the directory structure
(`.claude/docs/directory-structure.md`); do not assume a layer exists.

| Input | Path | Why |
|---|---|---|
| Feature spec | `design/specs/<slug>.md` (`bash .claude/scripts/spec-structure-check.sh <path>` for section presence) | behaviour, roles, NFR security section |
| Research note | `docs/research/<slug>.md` | sourced facts, provider behaviour, standards lookups; **required** for a sensitive area |
| Architecture, data flow | `docs/architecture/architecture.md` | trust boundaries, deployment (hosted, self-hosted) |
| ADRs | `docs/architecture/adr-*.md` for identity, tenancy, licensing, messaging | decisions the model must not contradict |
| Contract | `contracts/openapi/*.yaml` operations of the feature | entry points, auth, error shapes |
| Code | code roots from `resolve_code_root` (retrospective model only) | controls that exist |
| Migrations, deploy | `**/migrations/`, `deploy/hosted/`, `deploy/self-hosted/` | RLS, roles, network exposure, secrets |
| Existing model, audits | `docs/architecture/threat-models/<slug>.md`, `production/qa/security-audit-*.md` | prior threats, open findings |
| Stories | `production/epics/**` mentioning the slug or a `Threat model:` line | links for Phase 4 |
| `project.yaml` via the resolved config | `stack`, `tenancy`, `distribution` | scoping facts |

**Absent input rules**
- **Research note absent** for a sensitive area: stop and route to `/research
  <slug>`. If the user insists on proceeding, every standards lookup is
  `NOT SOURCEABLE`, every provider behaviour is `assumed`, and the verdict cannot
  exceed `NOT ASSESSED`; say so in the first line of the report.
- **Spec absent at `standard`/`full`:** boundaries are drawn from the
  architecture and research note and each is labelled `assumed`; the verdict
  names the missing spec.
- **`tenancy.model` or `distribution.model` unset:** ask. If unanswered, model as
  a multi-tenant hybrid product, label it `assumed`, and say the scope fact is
  unset. An unset value is never the permissive reading.

## 4. Design-time or retrospective?

Ask once: is the feature **unbuilt** (design-time) or **built** (retrospective)?

- **Design-time:** controls are `Planned`, not `Met`. No code is expected; an
  empty code root is correct, not a failure. Boundaries come from the spec and
  architecture.
- **Retrospective:** controls claimed to exist are cited at `file:line`. A code
  root that does not resolve, or has no source, makes that boundary's existing-
  controls claims `NOT ASSESSED - no source under <root>`, never "no findings".

## 5. New or update

- `--update`, or a model already exists at the path: read it in full. **Keep the
  IDs stable** (T, AB, M, TB) so stories and tests stay linked; add rows, mark
  retired rows `Superseded by <ID>` rather than deleting, and add a Revision
  History entry stating the trigger (spec change, new boundary, provider change,
  role-model change, incident). Ask which trigger applies.
- No model yet but the user wrote `--update`: tell them, and continue as new.
- A model exists and no `--update`: ask (update / start over). Starting over keeps
  the old file until the user approves the replacement.

Get today's date once with `date +%F` for the header and revision history.

## 6. Report the plan

"Modelling [feature] ([design-time | retrospective]): areas [list]; editions
[hosted | self-hosted | both]; tenancy [model | unset]; inputs found [list],
absent [list]; review mode [mode]."
