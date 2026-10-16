# /team-api — Phases 3–4: Breaking-Change Policy, Stories, Lanes

> Part of `/team-api`. Read again if the conversation was compacted.

## 1. Phase 3 — the breaking-change route (BREAKING only)

`/api-contract` already put the three routes to the user: **(a) a new major
version** (`/v2` alongside the old for the support window), **(b) an ADR plus
`Deprecation`/`Sunset` headers**, **(c) rework as an additive change**. Read which
was chosen from its record and enforce what it implies:

| Route | What this run requires |
|---|---|
| (a) New major | both versions live for the support window; the old major is deprecated (headers on every old operation); clients migrate to the new major; removal of the old major is a separate story after the sunset |
| (b) ADR | the ADR is `Accepted` (the user, or `cto` on the user's explicit confirmation — never this skill); `CTO-ADR` verdict recorded or `skipped — <mode> mode`; the support window, the sunset date and the removal story are in it |
| (c) Additive rework | re-run Phase 2; the classification must read ADDITIVE |

A BREAKING change with none of these is `BLOCKED`. Do not smuggle it in as additive:
removed or renamed field, tightened validation, changed type, new required input,
changed semantics or status code (`api-standards.md`).

## 2. Phase 3 — the deprecation plan (DEPRECATING and BREAKING)

Read the product's **API policy** for the minimum support window. If none is
recorded: `API policy: ABSENT — no support window recorded`; the window is asked
of the user and recorded as `stated by user` with an owner to write the policy; a
window is never invented. Self-hosted customers and old mobile app versions lag
several releases (`api-standards.md`), so the window is checked against the
supported upgrade-from range the product publishes (`release-manager`).

Plan, written by `release-manager` (active at `small`+; below that, drafted by the
backend lead and reviewed by `principal-engineer`) to
`production/api/<slug>/deprecation-plan.md`:

1. **Headers.** The old operations return `Deprecation` and `Sunset` response
   headers for the whole window (`api-standards.md`, "Versioning and lifecycle").
   The value formats come from the primary sources (the RFCs) cited in the
   research note: `NOT SOURCEABLE in docs/stack-reference/` — the lead reads them
   there (or `/research`), never recalls them. A `Link` to the migration guide is
   proposed only if the sourced format supports it.
2. **Old and new at once.** The server serves both behaviours until the sunset;
   no big-bang cut.
3. **Timeline.** Announcement (changelog + notice), deprecation start, sunset date,
   removal story (scheduled after the sunset, never in the same release as the
   deprecation), with owners and dates.
4. **Mobile.** Apps in the field cannot be migrated: the minimum supported app
   version and force-upgrade policy are the lever (`release-manager`,
   `android-lead`, `ios-lead` — Play/App Store timing is theirs); stated, not
   assumed.
5. **Self-hosted.** The bundle's upgrade notes and the minimum upgrade-from
   version.
6. **Communication.** Changelog entry (`/changelog`), release notes
   (`/release-notes`), a customer notice drafted by `customer-success` at `studio`
   size, a migration guide drafted by `technical-writer` at `small`+ to
   `production/api/<slug>/migration-guide-draft.md`. **Publishing any of these is
   external publication: it always prompts and is not done here** — drafts only.
7. **Telemetry to watch usage of the old operations** (route-template metrics and
   `trace_id` per `observability-standard.md`), so the sunset is decided on data.

**Gate — deprecation plan and timeline.** `AskUserQuestion`: approve · change
window / dates · stop. Record the user's choice.

## 3. Phase 4 — stories

If stories for this change exist, use them (check each has the `Contract:` line
pointing at the change record). Otherwise `/create-stories` from the
contract-test plan: one **Contract** story per consuming lane (backend,
web, KMP, Android, iOS), a Security story where a sensitive surface is touched,
and the removal story (Blocked until after the sunset). Contract-first order.

**Gate — story list.** Present with type, lane, owner, dependencies; the user
approves. Per story, the prerequisites of `/dev-story` Phase 2 apply (research
note or its exemption, threat model for a sensitive surface, ADRs `Accepted`,
**contract merged**, `stack` set for the lane). Failing prerequisite → that story
stops.

## 4. Phase 4 — lanes

`principal-engineer` routes (spawn only if consumers/lanes are unclear; otherwise
the Phase 0 table is the routing). Then spawn **in one message, in parallel**:

| Wave | Lanes | Notes |
|---|---|---|
| 1 | Backend ‖ Web ‖ KMP shared | each depends only on the merged contract and the regenerated client; the clients do **not** wait for the backend |
| 2 | Android ‖ iOS | after the KMP module's client adapters and ports exist (they consume them); a native-only lane with no KMP starts in wave 1 |

Briefs (paths and decisions, not pasted documents): the contract file and the
contract-change record (operations, classification, the contract-test plan), the
spec section, the research note, the threat-model rows for sensitive surfaces, the
deprecation plan, `docs/stack-reference/<layer>/` and `pins.yaml`, the matching
`.claude/rules/*.md` (`contracts.md`, `backend-go.md` / `backend-ktor.md`,
`web-react.md`, `kmp-shared.md`, `android-compose.md`, `ios-swift.md`).

**Backend lead** (`go-lead` + `go-api-specialist`, or `ktor-lead`): handlers/routes
and request/response DTOs **separate** from domain models; validation that matches
the contract's limits (`additionalProperties: false`, `maxLength`, `maxItems`);
RFC 9457 problem details with the stable `code` and `trace_id` **at the HTTP edge
only**; object-level authz in the use case and 404 for another tenant's object;
the tenant from the authenticated context, never the request; `Idempotency-Key`
semantics and `ETag`/`If-Match` where the contract states them; `Retry-After` on
429/503; cursor pagination with the server cap; the deprecation headers on the old
operations; spans named by route template, RED metrics, no PII. Schema steps wait
for `/db-migration` or `/team-data` artifacts. Never re-implement a core-module
concern (identity, rate limiting, audit).

**Client leads** (`web-lead`, `kmp-specialist`, `android-lead`, `ios-lead`):
regenerate the client **only through the repo's generator** (reported `not
regenerated` when none exists; generated code is never hand-edited, a diff from
what the generator emits is a review failure); adapt call sites; map errors by the
stable `code`, never by message text; tolerate unknown enum values; stop using
deprecated operations (a deprecated operation still in use is listed with file:line
and the sunset date); no endpoint is added from the client side; no secret in the
client; the Android/iOS lanes consume the KMP client rather than re-generating
where `kmp` is in the stack. Screens that change → `/team-ui`, not this skill.

**Compatibility during a window.** Test **old client × new server** (the old
generated client against the new server, for the deprecated operations) and **new
client × new server**; the first is the evidence that the deprecation path works.
Old mobile versions in the field are covered by the server's dual behaviour, not by
a client change.

**File set.** Each lead first returns the files it will create or change; ask once
for the full set across leads ("May the leads create/change these files?") —
multi-file changes need explicit approval for the full changeset. Each lead then
writes its report to `production/api/<slug>/impl-<lane>.md` (files, commands run
with real output summaries, each check that could not run as `not run — <reason>`)
and you verify it exists.
