---
name: threat-model
description: "STRIDE and abuse-case threat model for a sensitive feature (auth, authz, billing, licensing, upload, webhooks, PII export/delete, admin, new provider): assets, trust boundaries as a diagram, mitigations linked to stories and negative tests, ASVS 5.0.0 / MASVS 2.1.0 IDs looked up, residual risk accepted by name. Runs SL-THREAT-MODEL."
argument-hint: "[feature-slug] [--update] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, WebFetch, WebSearch, Bash(date *), Bash(bash "*/.claude/skills/threat-model/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(bash .claude/scripts/spec-structure-check.sh *)
model: opus
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,automation,workflow,automation_always_ask,stack`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt). **Accepting a residual risk
is never delegated to a mode**: it always asks, in every mode, and the answer
must be a named person (Phase 5).

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

**`workflow`** does **not** relax this skill. The threat model is engineering,
not documentation: a story touching a sensitive area needs one at `minimal`,
`standard` and `full` (`security-baseline.md` "Threat modelling";
`workflow-modes.md`). What a tier changes is how many *other* documents exist
around it.

# Threat Model

Security is a property of every story, not a phase. This skill produces the
threat model for one feature before its sensitive stories are implemented:
scope, assets, trust boundaries (drawn as code), a STRIDE table per boundary,
abuse cases for the business flows (cross-tenant, trial and quota abuse,
licence bypass), mitigations linked to a story **and** a negative test, the
ASVS 5.0.0 / MASVS 2.1.0 requirement IDs **looked up in the official
documents, never recalled**, and the residual risk accepted by a named person.
Owner: `security-lead`. The gate is **SL-THREAT-MODEL**.

**Output:** `docs/architecture/threat-models/<feature>.md`, from
`.claude/docs/templates/threat-model.md`, then a mitigation-to-story list the
caller feeds to `/create-stories` or `/story-readiness`.

**Run this skill** for any feature touching: authentication, the authorization
model, billing, licensing, file upload, webhooks, PII export/delete,
admin/impersonation, or a new external integration. Also when a model is stale:
a spec change, a new trust boundary, a provider change, a role-model change or
an incident (`Next review` in the template header). It reads and designs; it
does not attack (`/pentest`) and does not fix (the stack lead does).

> **Verdicts:** `COMPLETE` / `COMPLETE WITH GAPS` / `NOT ASSESSED` / `BLOCKED`,
> plus `NOT REQUIRED - <evidence>` when Phase 1 finds no sensitive area touched
> (nothing is written; it is a recorded decision, not a pass or a gap).
> Precedence: `BLOCKED`, then `NOT ASSESSED`, then `COMPLETE WITH GAPS`, then
> `COMPLETE`. `NOT ASSESSED` outranks `COMPLETE` (a boundary whose code could not
> be read, a requirement mapping that is `NOT SOURCEABLE`, an input that is
> absent) and ranks below `BLOCKED` (a known unmitigated, unaccepted High
> threat is more actionable than an unknown). Reasons are named in the report.
> **A model that cites no story and no test for a mitigation is a wish
> (template), and shows as a gap, never as complete.** At **design time** a
> mitigation whose story is `NEW:` (proposed for `/create-stories`) or existing, and
> whose negative test is a *named plan* with an owner (the story or the stack lead),
> is complete for this verdict: a test cannot exist before the code. A `Planned`
> mitigation with no named test, no owner or no story is a gap.

---

## Phase 1: Trigger, Inputs and Mode

**Read `references/1-inputs-and-scope.md` now and follow it.** It parses the
argument, tests the trigger (which sensitive areas the feature touches, listed
by name), records each input as FOUND or ABSENT, and decides new / `--update`.
An absent research note for a sensitive area sends the user to `/research`
first; it is the source of the standards lookups and the feature's data flows.
Read it again if the conversation was compacted or resumed.

## Phase 2: Scope, Assets, Actors, Boundaries

Work with the user (`AskUserQuestion`): in scope, out of scope and why,
assumptions (which are asserted to the user, not buried), actors including the
**malicious tenant**, **operator/support** and **self-hosted operator**, the asset
list with classification and C/I/A impact, and the boundaries. Hosted and
self-hosted editions are separate deployments with different boundaries when
`distribution.model` is `hybrid`: model both or state which is out of scope.
The diagram is Mermaid in the model file (the template's `flowchart`), each
edge labelled with its boundary ID.

## Phase 3: Draft the Threats (appsec-engineer, researcher in parallel)

**Read `references/2-stride-and-abuse.md` now.** Then spawn, **in one message** (all independent):

1. `appsec-engineer` with the fixed brief in that file: STRIDE per boundary,
   abuse cases, the stack-reference prompts, cross-tenant coverage, mitigation
   proposals. It returns text; it does not write the model.
2. `researcher` with the lookup brief in `references/3-mitigations-and-mapping.md`:
   ASVS 5.0.0 (and MASVS 2.1.0 when mobile is in scope, API Security Top 10 2023)
   requirement IDs for the chapters the model touches, each with the URL
   actually fetched. The two are independent, so they run in parallel.
3. When personal data is in scope, `privacy-compliance-specialist` with the brief
   in `references/2-stride-and-abuse.md` (legal basis and retention under Egypt
   PDPL and GDPR, looked up, never recalled), in the same message.

If `appsec-engineer` cannot be spawned, say why, do the STRIDE pass here, and
let the model's **Author** line say so. If `researcher` cannot be spawned, every
requirement ID is `NOT SOURCEABLE` and the verdict is at best `NOT ASSESSED`.
**You** review both outputs: you add what the agent missed (an untreated
boundary, a cross-tenant path, a business flow) rather than accepting a
fluent table.

## Phase 4: Mitigations, Stories, Tests, Mapping

**Read `references/3-mitigations-and-mapping.md` now and follow it.** Every
threat gets a mitigation or an explicit acceptance; every mitigation is linked to
a story ID (existing, found in `production/epics/`, or proposed for
`/create-stories`) and to a named negative test; every mapped ID carries its
source URL or `NOT SOURCEABLE`.

## Phase 5: Residual Risk, Accepted by Name

For every threat or abuse case left with a residual level, `AskUserQuestion`:
mitigate further / accept / defer with an owner. **Accept** requires the user to
give a **name and role** (a real person), a date and a review-by date. Obtain
today's date from the system (`date +%F`, granted); never write a date from memory.
Neither this skill, `appsec-engineer`, `security-lead` nor `cto` accepts risk on
the company's behalf. A High residual with no named acceptor is `Unaccepted` and
makes the verdict `BLOCKED`. If the question comes back skipped or empty, the
risk stays `Unaccepted`; ask again in plain text.

## Phase 6: Verify, Gate, Write

**Read `references/4-checks-gate-and-write.md` now and follow it.** It runs the
cross-reference checks on the draft (every boundary in the diagram has a table
row and a STRIDE section and the reverse; every threat has a mitigation or
acceptance; every mitigation has story and test; IDs sourced), derives the
verdict, spawns **SL-THREAT-MODEL** in `full` review mode, asks to write, and
hands the mitigation list onward. Read it again after compaction.

---

## Error Recovery Protocol

**First, verify the artifact.** An agent told to return text is checked for a
substantive return (tables, not a preamble); an agent told to write a path is
checked for the file on disk. If any spawned agent returns BLOCKED, errors or
cannot complete: surface it immediately, do not proceed past a dependency it
blocks, offer skip / retry narrower / stop via `AskUserQuestion`, and always
produce a partial report. A skipped `researcher` leaves the mapping `NOT
SOURCEABLE`; a skipped `appsec-engineer` leaves a draft this session produced
itself and says so. A gate agent that could not run is recorded `NOT ASSESSED -
[what was missing]` and keeps the verdict at best `NOT ASSESSED`. A skip does
not clear a block. Full procedure: `.claude/docs/error-recovery-protocol.md`.

## Collaborative Protocol

- **Question -> Options -> Decision -> Draft -> Approval.** Scope, assumptions,
  acceptance of residual risk and the final write are the user's.
- **Never recall a requirement ID, level, version, flag or CVE.** Look it up in
  the official document and cite the URL fetched, or write `NOT SOURCEABLE`;
  never copy an ID from another document in this repo without re-checking it
  (ASVS 5.0.0 renumbered the 4.0.3 IDs).
- **A threat with no mitigation and no accepted risk is a finding**, not a row to
  tidy away. `N/A` needs a written reason.
- **Risk acceptance is a person's.** Never accept, soften or re-rate a threat to
  reach a better verdict.
- **Never put a secret, key material, working exploit or customer data in the
  model.** Name where a key lives, not what it is.
- **Fixes are not made here**; the model routes them to stories and the owning
  stack lead through `principal-engineer`.
- **Describe only what you read.** A boundary's controls are cited from code,
  config or the spec at `file:line`; an assumption is labelled as one.
- A skipped, dismissed or empty answer is not an answer: act on nothing, ask
  again in plain text and wait.

---

## Recommended Next Steps

**Checkpoint.** Before the final message, update `production/session-state/active.md` per `.claude/docs/checkpoint-handoff.md`: Current task `/threat-model <feature> — <verdict>`, Next step = the first item below that matches the verdict (`/create-stories` on COMPLETE), plus Blocked on (NOT ASSESSED causes, Unaccepted residual risk) / Files in progress (the threat model path) / Open questions; append the Notes line. Still updated on `BLOCKED — write declined by user`, with the blocker named.

- `COMPLETE` or `COMPLETE WITH GAPS`: run `/create-stories` (or `/story-readiness [story]`) so each `Planned` mitigation becomes a Security story with its negative test; the story's `Threat model:` line points at this file
- Cross-tenant paths found: `/tenant-check [feature]` for the isolation audit and SL-TENANT-ISOLATION
- Contract surface changes: `/api-contract [feature]`; schema changes: `/db-migration [feature]`; rate limits, sessions, idempotency on the Redis protocol: `/cache-design [feature]`
- Licensing features: `/license-design`; new provider: `/integration [provider]`
- Detection and alerting mitigations: `/observability-plan plan [feature]`
- Before a release or a first public launch: `/security-audit full`, then consider `/pentest`
- `NOT ASSESSED` on the mapping: `/research` the missing standard text, then `/threat-model [feature] --update`
