# Story Readiness Checklist

For each story file, evaluate every item. A story is READY only if all items
pass or are explicitly marked N/A with a stated reason.

> **Workflow tier adjustment** (resolved in Phase 0, per the story's feature). The
> full checklist below is the `full` baseline:
> - **`full`** — every item is blocking (TR registry + ADR + control manifest
>   fully validated).
> - **`standard`** — **Design Completeness**, **Research and Security Gates**,
>   **Layers, Owners and Contract Order** and **Scope Clarity** stay blocking. In
>   **Architecture Completeness**, an ADR the story references that is missing,
>   `Proposed`, `Deprecated` or `Superseded` BLOCKS at every tier (see that
>   section's note). Beyond that, only a **critical ADR** (tenancy model,
>   identity/auth, data store, messaging, API style, deployment topology,
>   licensing — `workflow-modes.md`) that is missing or `Proposed` BLOCKS; an
>   absent "ADR referenced" note is **advisory** (NEEDS WORK note, not BLOCKED).
>   The TR-ID and manifest items are advisory.
> - **`minimal`** — **acceptance criteria, scope, research and security floor**:
>   evaluate Design Completeness (with `design/product-brief.md` standing in for
>   the spec), Scope Clarity, Research and Security Gates, Layers/Owners/Contract
>   Order, and the Definition of Done items. Treat the rest of **Architecture
>   Completeness** as N/A — except that a referenced ADR that is missing,
>   `Proposed`, `Deprecated` or `Superseded` still BLOCKS. Do not flag a missing
>   ADR, TR-ID or manifest reference. Decisions live in the brief's decision log.
>
> The tier changes documents, never engineering: the research note and the
> threat model for a security-sensitive story are required at every tier.

## 1. Design Completeness

- [ ] **Spec requirement referenced**: The story includes a `design/specs/<feature>.md`
  (or `design/quick-specs/`) path and quotes or links a specific requirement,
  acceptance criterion, or rule from it — not just the filename. A link to the
  document without tracing to a specific requirement does not pass. At `minimal`,
  `design/product-brief.md` — the build-order item and the core journey the story
  traces to — stands in for the spec.
- [ ] **Requirement is self-contained**: The acceptance criteria in the story
  are understandable without opening the spec. A developer should not need to
  read a separate document to understand what DONE means.
- [ ] **Acceptance criteria are testable**: Each criterion is a specific,
  observable condition — not "implement X" or "the endpoint works correctly".
  Bad example: "Implement invitation expiry." Good example: "An invitation older
  than 7 days returns 410 with problem type `invitation-expired`; a second accept
  attempt on a valid invitation returns 409."
- [ ] **No acceptance criteria require judgment calls** *(auto-pass for UI criteria that
  are paired with an evidence reference)*: Criteria like "fast", "secure", "feels
  clean" or "user-friendly" are not testable without a number or observable.
  For Logic, Integration, Contract, Security, Performance and Config stories these
  must be replaced with specific observable conditions. For UI stories, subjective
  criteria are acceptable only when paired with an evidence reference (e.g.,
  "screens in `design/ux/<screen>.md`; `/impeccable audit` result and Arabic RTL +
  English screenshots in `production/qa/evidence/<story-id>/`"). PASS if the
  criterion ends with, or is accompanied by, such an explicit file path. NEEDS
  WORK if the criterion is purely subjective with no evidence path.
- [ ] **Negative and cross-tenant criteria present** *(where the story touches tenant
  data, an entitlement, money, or an authz decision)*: at least one criterion for
  the wrong role, one for another tenant, and — where input is accepted — one for
  invalid input. Missing → NEEDS WORK (spec rule in `.claude/rules/specs.md`).

## 2. Research and Security Gates

- [ ] **Research note exists (DoD gate 1)**: `docs/research/<feature>.md` exists
  (named in the story or matched by the feature slug), **or** the story states
  `Research: exempt — [row]` and the row is in the exempt list in
  `references/triggers.md` and genuinely fits the story (a "bug fix" that adds an
  endpoint is not exempt; a "config value change" that adds a provider is not).
  - Missing and not exempt → **NEEDS WORK**. Fix: `Run /research [feature]; link docs/research/[feature].md in the story.`
  - Exempt claimed but the story content contradicts it → **NEEDS WORK**; name the contradiction.
  - Exists but has a section marked stale (cites an older pinned version than `docs/stack-reference/pins.yaml`) → NEEDS WORK, Fix: re-verify.
  - Exists but its `Status:` is `Draft` (verdict COMPLETE WITH GAPS) → **NEEDS WORK** unless the story carries a `Research gap accepted:` line naming the gaps and the user who accepted them (`/dev-story` Gate A records it). Only `Status: Complete` passes outright. No readable `Status:` line → **NOT ASSESSED** for this item.
  - Exists and its **Open questions** section lists an item that blocks this story with no owner or resolution → **BLOCKED**.
  - A note that cannot be opened → **NOT ASSESSED** for this item.
- [ ] **Threat model linked when a trigger applies (SL-THREAT-MODEL)**: if the story
  or its feature hits a threat-model trigger (`references/triggers.md`:
  authentication, authorization model, billing, licensing, file upload, webhooks,
  PII export/delete, admin/impersonation, new external integration), then
  `docs/architecture/threat-models/<feature>.md` exists **and** the story links it.
  - Trigger applies and no threat model exists → **BLOCKED** (SL-THREAT-MODEL says do not start the sensitive story). Fix: `Run /threat-model [feature].`
  - Model exists but the story does not link it, or the threat model's mitigations are not mapped to this story's criteria → **NEEDS WORK**.
  - A recorded SL-THREAT-MODEL `REJECT` on the model → **BLOCKED**.
  - Residual risk not accepted by name — section 7 has a row with no named acceptor/date/review-by, is empty without an explicit "no residual risk" statement, or the model's `Status:` is `Needs update` → **BLOCKED** (`/dev-story` stops on the same condition). Fix: the accountable person records it with `/threat-model [feature] --update`; nothing here drafts an acceptance.
  - At `workflow: minimal` the research note's Security notes may stand in for the model file when it names the assets, abuse cases and the mitigation-to-test mapping; say so in the pass line.
  - No trigger applies → `N/A — no threat-model trigger ([what was checked])`.
- [ ] **Security story names its controls** *(Type: Security, or any trigger story)*: the
  ASVS 5.0.0 / MASVS 2.1.0 / API Top 10 requirement IDs the story will satisfy are
  listed (looked up per the research note — never recalled), and the negative
  tests are named (authz bypass, cross-tenant, injection, rate limit, replay).
  Missing → NEEDS WORK.

## 3. Architecture Completeness

> The `BLOCKED` / fail outcomes in this section are the `full` baseline, with one
> rule that holds at every tier: **an ADR the story references that is missing,
> `Proposed`, `Deprecated` or `Superseded` BLOCKS**. `/dev-story` stops on it at
> `full`, `standard` and `minimal` alike, so a READY here would send the story
> straight into a stop. Beyond that, apply the tier note above: at `standard` the
> other items are advisory unless they concern a **critical** ADR; at `minimal`
> the rest of this section is N/A.
>
> At `standard`, an advisory item — a stale manifest version, missing stack notes
> or manifest rules for a non-critical ADR — is written up like a NEEDS WORK item,
> under Gaps with its `Fix:` line, but it never BLOCKS and does not by itself
> downgrade READY. An ADR is critical when it governs a foundation concern
> (`.claude/docs/workflow-modes.md`) or its `**Layer**`/category row is missing —
> when in doubt, treat it as critical. Read those rows once, alongside the
> Section 2 status scan: `Grep pattern="\*\*Layer\*\*" glob="docs/architecture/adr-*.md" output_mode="content"`.

- [ ] **ADR referenced or N/A stated**: The story references at least one ADR,
  OR explicitly states "No ADR applies" with a brief reason.
  A story with no ADR reference and no explicit N/A note fails this check.
- [ ] **ADR is Accepted (not Proposed)**: For each referenced ADR, check its
  `Status:` field using the cached ADR statuses loaded in Section 2.
  - If `Status: Accepted` → pass.
  - If `Status: Proposed` → **BLOCKED**: the ADR may change before it is accepted,
    and the story's implementation guidance could be wrong.
    Fix: `BLOCKED: ADR-NNNN is Proposed — wait for acceptance before implementing.`
  - If the ADR file does not exist → **BLOCKED**: referenced ADR is missing.
  - If `Status:` is `Deprecated` or `Superseded by ADR-XXXX` → **BLOCKED**: the
    decision no longer stands.
    Fix: `BLOCKED: ADR-NNNN is [status] — point the story at [successor] (edit its ADR field — /create-stories never rewrites an existing story).`
  - If the ADR file exists but has no readable `## Status` (the Section 2 scan
    found none in it) → **NOT ASSESSED** for this check: its status is unknown,
    not failed. Name the file and route to `/architecture-decision retrofit [file]`.
  - Auto-pass if story has an explicit "No ADR applies" N/A note.
- [ ] **TR-ID is valid and active**: If the story contains a `TR-[feature]-NNN`
  reference, look it up in the TR registry loaded in Section 2.
  - If the ID exists and `status: active` → pass.
  - If the ID exists and `status: deprecated` or `status: "superseded-by: ..."`
    (quoted or not) → NEEDS WORK: the requirement was removed or replaced.
    Fix: update the story to reference the current requirement ID or remove if no longer applicable.
  - If the ID does not exist in the registry → NEEDS WORK: ID was not registered
    (story may predate registry, or registry needs an `/architecture-review` run).
  - Story has no TR-ID reference → `N/A — no TR-ID`.
  - Registry does not exist → **not checked — `tr-registry.yaml` absent**, never a
    pass: a story can carry an invalid or placeholder ID (`TR-[feature]-???`) that
    only the registry would catch. At `full` this item blocks, so the story is
    **NOT ASSESSED** for it (route: `/architecture-review`); at `standard` and
    `minimal` it is advisory and printed under Gaps as `not checked`.
- [ ] **Manifest version is current**: If the story has a `Manifest Version:` date
  in its header AND `docs/architecture/control-manifest.md` exists:
  - If story version matches current manifest `Manifest Version:` → pass.
  - If story version is older than current manifest → NEEDS WORK: new rules may
    apply. Fix: review changed manifest rules, update story if any must/never
    entries changed, then update the story's `Manifest Version:` to current.
  - Auto-pass if either the story has no `Manifest Version:` field OR the manifest
    does not exist.
- [ ] **Stack-reference notes present**: For any library, framework or platform API
  this story is likely to touch, implementation notes point to the relevant
  `docs/stack-reference/<layer>/` entry at the pinned version (`pins.yaml`), or
  the research note covers it. An API beyond the stack reference with neither →
  NEEDS WORK (route to CTO-STACK-RISK via `/research`). A pure data/config change
  with no library API: "N/A — no library API involved" is acceptable.
- [ ] **Control manifest rules noted**: Relevant layer rules from the control
  manifest are referenced, OR "N/A — manifest not yet created" is stated.
  This item auto-passes if `docs/architecture/control-manifest.md` does not
  exist yet (do not penalize stories written before the manifest was created).

## 4. Layers, Owners and Contract Order

- [ ] **Layers and owner agents named**: The story states each layer it touches
  (contracts, backend, data, web, mobile, platform) and the owner agent for each,
  using names from `.claude/docs/agent-roster.md` (`api-designer`, `go-lead` /
  `ktor-lead`, `data-lead`, `web-lead`, `android-lead`, `ios-lead`,
  `kmp-specialist`, `platform-lead`, …). A layer the `stack` in the resolved block
  does not include is flagged. No owner named for a touched layer → NEEDS WORK. A
  story spanning more than two lanes with no split → NEEDS WORK, suggest splitting
  by lane with the contract story first.
- [ ] **Contract story merged first**: if the story consumes or implements an API
  operation that is new or changed (backend implementation or web/mobile client):
  - It names the contract (`contracts/openapi/...` or `contracts/proto/...` operation) and the contract story ID that defines it.
  - That contract story is `Complete` (merged) per the index built in Section 2 → pass.
  - The contract story is `Draft`, missing, or not `Complete` → **BLOCKED** (dependent backend/client stories wait for the merged contract). Name the story ID and its status. A client story may be marked "starts on reviewed contract + mock" only when the story says so explicitly and the contract story is `In Review` with an approved file in `contracts/` — then it is NEEDS WORK-advisory, not BLOCKED.
  - The story names no contract and none of its criteria concern an HTTP/event surface → `N/A — no API surface`.
  - Type `Contract` itself: criteria map to a path under `contracts/` and name the consumer contract test per consumer.

## 5. Scope Clarity

- [ ] **Estimate present and DoD-inclusive**: The story includes a size estimate
  (days, points, or a t-shirt size) **and** it covers the evidence work for the
  story's type — research note, tests, observability, cache decision, performance
  evidence, security negatives, run-and-observe (`/estimate`). A story with no
  estimate cannot be planned (NEEDS WORK). An estimate stated as "build only"
  with a Security, Integration or Performance type → NEEDS WORK (PR-SPRINT check 4).
- [ ] **In-scope / Out-of-scope boundary stated**: The story states what
  it does NOT include, either in an explicit Out of Scope section or in
  language that makes the boundary unambiguous. Without this, scope creep
  during implementation is likely.
- [ ] **Story dependencies listed**: If this story depends on other stories
  being DONE first, those story IDs are listed. If there are no dependencies,
  "None" is explicitly stated (not just omitted).

## 6. Open Questions

- [ ] **No unresolved design questions**: The story does not contain text
  flagged as "UNRESOLVED", "TBD", "TODO", "?", or equivalent markers in
  any acceptance criterion, implementation note, or rule statement.
- [ ] **Dependency stories are not in DRAFT**: For each story listed as a
  dependency, check if the file exists and does not have a DRAFT status. A
  story that depends on a DRAFT or missing story is BLOCKED, not just
  NEEDS WORK.

## 7. Referenced Files Check

- [ ] **Referenced files exist**: Scan the story text for repo path references:
  `contracts/…`, `design/…`, `docs/…`, `production/…`, `PRODUCT.md`, `DESIGN.md`,
  and image or fixture files.
  - For each path found: use Glob to check whether the file exists. Paths that name
    a file this story will create (an evidence file, a new migration) are not
    checked.
  - If any referenced file does not exist: **NEEDS WORK** — note the missing
    path(s). Either remove the reference, create the artifact, or mark it as an
    explicit dependency.
  - A UI story must reference its screens in a UX spec (`design/ux/…`) and the
    design system files (`PRODUCT.md`, `DESIGN.md`) must exist; if impeccable has
    not been run for the product yet → NEEDS WORK, Fix: `/impeccable teach`
    (via `design-director`).
  - If all referenced files exist: note "Referenced files verified: [count] found."
  - If none are referenced in the story: note "No file references found in story —
    skipping check." This item auto-passes.
  - This is an existence-only check. Do not validate content.

## 8. Definition of Done

- [ ] **Story Type declared**: The story includes a `Type:` field in its header
  identifying the category (Logic / Integration / Contract / Security / Performance
  / UI / Config). Without this, test evidence requirements cannot be enforced at
  story close. Fix: Add `Type: [Logic|Integration|Contract|Security|Performance|UI|Config]`
  to the story header. A story whose content spans types names the primary type
  and lists the extra evidence of each other type it touches.
- [ ] **Minimum testable acceptance criteria by story type**:
  - Logic / Integration / Contract / Security stories: at least 3
  - Performance and UI stories: at least 2
  - Config stories: at least 1
  Apply the threshold matching the story's `Type:` field. If the story has fewer
  than the minimum, mark as NEEDS WORK.
- [ ] **Performance budget and cache decision noted on hot paths**: if the story
  touches a hot path (`references/triggers.md` → Hot paths: per-request code, list
  or search endpoints, auth/entitlement lookups, jobs over many rows, anything with
  a stated p95 in the spec), then both are present:
  - a performance budget reference (`docs/architecture/perf-budgets.md` row or the
    spec's NFR budget — p95, queries per request, payload), or "no performance impact
    expected — [reason]";
  - a cache decision reference (the spec's Caching Decision, or `cache-design`
    artifact, or the written "no cache — [reason]") per `caching-standard.md`.
  Either missing on a hot-path story → NEEDS WORK. Not a hot path → `N/A — [why]`.
- [ ] **Test evidence requirement is clear** *(validated at every `qa.level`: Logic,
  Integration, Contract and Security stories name tests that must exist and pass; UI
  stories name the retained screenshot of each screen touched; Security stories the
  negative tests and ASVS/MASVS mapping; Performance stories the budget + load-test
  named when `performance.enforce: block`; and run-and-observe evidence on anything a
  user can see or call. A Config story names its smoke check. `qa.level` adds extra
  evidence only, it never removes the test requirement)*: If the Story Type is set, the story includes a
  `## Test Evidence` section listing the evidence required for the type and where it
  will live (`coding-standards.md` → Test evidence by story type):

  | Type | Required evidence | Location |
  |---|---|---|
  | Logic | Unit tests | beside the code (`directory-structure.md`) |
  | Integration | Testcontainers integration test | per layer |
  | Contract | Contract test against `contracts/` | per consumer |
  | Security | Negative tests + ASVS/MASVS mapping | per layer + `production/qa/evidence/` |
  | Performance | Load-test result vs budget | `production/qa/evidence/` |
  | UI | Retained screenshot of every screen touched + `/impeccable audit` result (desktop + mobile, Arabic RTL + English) | `production/qa/evidence/` |
  | Config | Smoke check pass | `production/qa/smoke-[date].md` |

  Plus, for any type that changes something a user can see or call: the
  run-and-observe evidence in `production/qa/evidence/<story-id>/`
  (`run-and-observe.md`).

  Resolve this item's gate level from the `testing.strict` block **resolved in
  Phase 0** — not by reading `project.yaml`, which would ignore a developer's
  locally-overridden value. Map the Story Type to a key (Logic→`logic`,
  Integration→`integration`, Contract→`contract`, Security→`security`,
  Performance→`performance`, UI→`ui`, Config→`config`) and take
  `testing.strict.<key>`; use it only if its value is `true` or `false`
  (case-insensitive). If the key is absent, empty, or holds any other value, read
  `testing.strict` as a plain boolean (legacy single-value form); if that too is
  absent or invalid, apply the defaults in `coding-standards.md`: strict for
  Logic, Integration, Contract, Security and UI; advisory for Config; advisory for
  Performance unless `performance.enforce` resolves to `block`, in which case
  strict. **Security evidence on a security-sensitive story is always strict.**
  Surface any unrecognized value to the user.
  - At a **strict** gate level, a missing `## Test Evidence` section marks the
    story **NEEDS WORK**.
  - At an **advisory** gate level, a missing section is listed as a gap but does
    not by itself downgrade the verdict from READY.
  Fix: Add `## Test Evidence` with the expected evidence location for the story's type.
