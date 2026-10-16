# /api-contract - Phase 1 and Phase 2: Inputs, Modes, Design Brief

> Phases 1-2 of `SKILL.md`. Read it again if the conversation was compacted.

## 1. Parse the argument

| Argument | Meaning |
|---|---|
| `<feature-slug>` | Change mode for the feature (`design/specs/<slug>.md`, `docs/research/<slug>.md`) |
| `check [service]` | Check mode on the whole contract set, or one service |
| `--service <name>` | The service whose file is `contracts/openapi/<name>.yaml`; asked if the product has more than one and the feature does not name it |
| no argument | Ask: change or check, which feature or service (`AskUserQuestion`) |

If `contracts/` does not exist or has no `openapi/*.yaml`: in change mode this
is the first contract (continue; the "last released contract" is `none - first
contract`); in check mode there is nothing to check: report `NOT ASSESSED - no
contract under contracts/` and stop.

## 2. Inputs - record each as FOUND or ABSENT

Resolve the code roots with `bash .claude/hooks/yaml-helper.sh resolve_code_root`
and take the client targets from the resolved `stack` line: `web=vite-react` ->
TypeScript client; `mobile` containing `kmp` -> KMP client; containing `swiftui`
-> Swift client; `backend=go|ktor` -> where handlers will live. An unset `stack`
value is asked, never assumed. The client set is derived from the config, not
fixed.

| Input | Path | Why |
|---|---|---|
| Feature spec | `design/specs/<slug>.md` (Data & Contracts section) | operations, entities, roles |
| Research note | `docs/research/<slug>.md` | provider API facts, webhook formats; required for a new surface (`research-protocol.md`) |
| Threat model | `docs/architecture/threat-models/<slug>.md` | required for auth, billing, licensing, webhooks, upload, admin surfaces |
| Existing contract | `contracts/openapi/*.yaml` | the file being changed |
| **Last released contract** | see step 3 | the baseline for the breaking-change diff |
| ADRs | `docs/architecture/adr-*.md` | **JSON field-case convention** (`api-standards.md`: one per product, fixed by ADR), client-generator choice, API style, API policy |
| API policy | the product's stated minimum support window for deprecated versions (`api-standards.md` "Versioning and lifecycle") | deprecation obligations |
| Registry | `design/registry/entities.yaml` | plans, roles, permissions, quotas the API must express |
| Tooling | see `3-tooling-and-diff.md` | lint, diff, generators |

**Absent rules**
- Field-case ADR absent: ask the user (snake_case or camelCase) and record that an
  ADR is owed; never mix, never silently pick.
- Research note absent for a new provider-backed surface: route to `/research`.
- Threat model absent for a sensitive surface: route to `/threat-model`; the
  contract may be drafted but the verdict cannot be `COMPLETE`.
- API policy absent: state that no minimum support window is recorded, which
  matters only for a breaking or deprecating change (Phase 4).

## 3. Find the last released contract

The baseline for the diff is the contract **as released**, not the working tree.

1. `git tag --sort=-creatordate` (and any release record under `production/`)
   to find the latest release tag. Ask the user to confirm which tag is "last
   released" when more than one candidate exists (self-hosted channels may lag
   hosted): the diff matters against **every supported released version**; list
   the versions the product still supports if a policy names them.
2. Retrieve the file at that tag: `git show <tag>:contracts/openapi/<service>.yaml`
   (write it to a scratch path outside `contracts/` for diffing; do not leave it
   in the repo).
3. No tag, no history, or the file did not exist at the tag: record
   `last released contract: none (<reason>)`. The breaking-change diff is then
   `not run - no baseline`, not "no breaking changes".

## 4. Report the plan

"Contract change for [feature] in [service]: clients [TS | KMP | Swift | none];
field case [snake_case | camelCase | unset]; baseline [tag | none]; inputs found
[list], absent [list]; review mode [mode]; tooling defined in repo: lint
[yes/no], diff [yes/no], generators [list/none]."

---

## Design brief (`api-designer`, Phase 2)

Fill only the `{...}` slots. Add nothing else: no preferred shape for a resource,
no view on breaking-ness.

```text
Design the contract change for /api-contract. Return a proposal as text. Do NOT
write or edit anything under contracts/ - the caller asks the user first.

Feature: {slug}   Service: {service}   Contract file: {contracts/openapi/<service>.yaml}
Mode: {new contract | change to existing}
Inputs (read each; ABSENT ones are not to be guessed): {paths with FOUND/ABSENT}
Field-case convention: {snake_case | camelCase | unset - ask the caller}
Last released contract: {tag and scratch path | none}
Clients that will be generated: {TypeScript, KMP, Swift - as per the stack}
Tenancy: {tenancy.model | unset}   Editions: {hosted | self-hosted | hybrid}
Threat model: {path | ABSENT}   Sensitive areas touched: {list | none}

Rules: .claude/docs/api-standards.md, .claude/rules/contracts.md, your Senior Bar,
.claude/docs/security-baseline.md. Self-hosted customers and old mobile versions
lag - classify every change against the last released contract.

Return, in this order:
1. Operations: method, path (plural kebab-case), operationId (unique verb-noun),
   summary, security requirement or `security: []` with the reason, success and
   every error status (application/problem+json with a stable `code`)
2. Schemas: request DTOs separate from response DTOs; additionalProperties:false
   on requests; maxLength/maximum/maxItems on every unbounded field; formats
3. Lists: cursor + limit maximum, allowlisted filters and sort, the stable sort key
4. Idempotency-Key on create/charge operations (scope, TTL, replay, 409/422 on
   reuse); ETag/If-Match for contended updates; 202 + status URL for async
5. Tenant and authorization semantics: who may call it, what a caller in another
   tenant sees (404), which response fields are owner-only
6. Webhooks (out: events, payload schemas, event_id, signature, retry, replay;
   in: verify, dedupe, ack) if the feature has any
7. Examples for every operation
8. Breaking-change classification against the last released contract: for each
   change, ADDITIVE or BREAKING with the reason (removed/renamed field, tightened
   validation, changed type, new required input, changed semantics or status code)
9. Deprecations proposed (field/operation, Deprecation + Sunset, support window)
10. Open questions, each with an owner; and what you could not verify
Never write a tool, flag, generator option or version from memory.
```

The proposal is **data to review**, not the contract. Check that no operation is
missing an item in the brief; send gaps back once (resume the agent) before
filling them yourself.
