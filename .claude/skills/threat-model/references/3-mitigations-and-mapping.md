# /threat-model - Phase 4: Mitigations, Stories, Tests, Mapping

> Phase 4 of `SKILL.md` (and the `researcher` brief for Phase 3). A mitigation
> with no story and no negative test is a wish.

## 1. Consolidate mitigations

From the `appsec-engineer` draft plus your own review, build section 6 of the
model: ID, mitigation, the threats and abuse cases it addresses, requirement
reference, story, negative test, status. One mitigation may serve several
threats; every threat and abuse case must be addressed by at least one
mitigation or sit in section 7. Duplicates are merged and IDs renumbered **only
in a new model**; in an update, IDs are never changed.

Prefer the studio's baseline mitigations over invented ones
(`security-baseline.md`, `.claude/rules/security-sensitive.md`): deny-by-default
policy per route, object-level authorization in the use case, tenant-scoped
repositories plus RLS, explicit request DTOs, rate limits per tenant/actor/route,
signature + timestamp + event-ID dedupe for webhooks, an egress allowlist client,
an append-only per-tenant audit log. Cite the rule; do not restate it from
memory.

## 2. Link each mitigation to a story

For each mitigation, `Glob`/`Grep` `production/epics/**` for a story that covers
it (by slug, TR-ID or a `Threat model:` line).

| Found | Record |
|---|---|
| A story covers it | its ID |
| A story partly covers it | the ID and what is missing (status `Gap`) |
| No story | `NEW: <proposed title>, type Security` (status `Planned`); the caller feeds the list to `/create-stories`. **This skill creates no story** |
| Stories do not exist yet (design-time, no epics) | all `NEW:`; say that no epic was found |

## 3. Name the negative test

Each mitigation names the test that proves it: what is attempted and what must be
refused. Attempt classes (testing-standards "Security"): authorization bypass
(anonymous, wrong role, wrong tenant), cross-tenant read/write/guess, injection,
replay, brute force and rate limit, expired or forged token, mass assignment,
oversized or malformed input, tampered signature. Use the project's naming
convention for the layer (`.claude/docs/testing-standards.md` "Naming") and the
test location from `.claude/docs/directory-structure.md` "Code roots".

- **Design-time:** the test is a *named plan*; status `Planned`.
- **Retrospective:** `Glob`/`Grep` the test file. Found -> record the path and
  `exists; not run by this skill` (the pass state is established by
  `/story-done` or `/test`, not by this skill). Not found -> `Gap`.
- A test that only checks the happy path does not count. Say why when rejecting
  one.
- The set of tests for a security story also requires: real dependencies for
  integration (Testcontainers), not mocks, and RLS tests connecting as the
  non-owner, no-bypass application role (`docs/stack-reference/postgres/best-practices.md`
  section 7).

## 4. Requirement mapping (looked up, never recalled)

Standards in force and levels (`security-baseline.md`): OWASP ASVS **5.0.0**
(Level 2 default; **Level 3** for authentication, billing and licensing),
OWASP API Security Top 10 **2023** for every HTTP/gRPC API, OWASP MASVS **2.1.0**
for Android, iOS and KMP when mobile is in scope. ASVS 5.0.0 renumbered the
4.0.3 IDs: a recalled 4.x ID is wrong by default.

Spawn `researcher` (in parallel with the `appsec-engineer` draft, Phase 3):

```text
Look up requirement IDs for /threat-model {feature}. Return text only.
Standards: OWASP ASVS 5.0.0; OWASP API Security Top 10 2023; {OWASP MASVS 2.1.0
only when mobile is in scope}. Fetch the official documents (search for the
official OWASP document of that exact version; cite the URL you actually fetched
for every row).
Areas to map: {chapter/area list derived from the sensitive areas and the
mitigation themes - e.g. authentication, session, access control, validation and
encoding, cryptography and secrets, logging and error handling, API/web service,
business logic, file handling, mobile storage/network}
Levels: ASVS Level 2 default; Level 3 for {auth | billing | licensing | none}.
For each area return rows: requirement ID exactly as printed in the document,
the requirement in one short line (paraphrase), the level the document assigns,
URL fetched. If you cannot fetch or find an item, write "NOT SOURCEABLE - <what
was searched>". Do not recall IDs, do not copy IDs from other files in this
repository, do not map to a nearby chapter "close enough".
Also state the document version and date you read.
```

The first lookup runs in parallel with the draft, so its areas come from the
sensitive areas alone. If the `appsec-engineer` draft introduces mitigation themes
outside them, resume `researcher` for that delta before mapping.

Then fill **section 8** (mapping) and the "ASVS / MASVS ref" column of
section 6 from the researcher's rows. Status per row: `Met (evidence)`,
`Partially met`, `Not applicable (reason)` or `Gap (story)`. At design time
nothing is `Met`: planned controls are `Gap (<story or NEW>)`.

**Wire the gap to the verdict.** Count `NOT SOURCEABLE` mapping rows per area in
scope. Any such area makes the mapping `NOT ASSESSED` and the verdict at best
`NOT ASSESSED` (Phase 6). MASVS Android control IDs are a known gap in the stack
reference (see the mobile category of the `/security-audit` skill); if the
lookup fails, the Android mobile mapping is `NOT SOURCEABLE`.

## 5. Verification plan (model section 9)

List: the negative-test classes above for this feature; dependency and image
scans on the changed components and a secrets scan (the scanners and pinned
versions are in `docs/stack-reference/tooling/`; run them via `/security-audit`
or `/dependency-audit`, not here); the `/security-audit` scope that should be
re-run; and the re-review triggers. State plainly that this skill ran no
scanner.
