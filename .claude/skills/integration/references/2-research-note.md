# /integration - Phase 2: Research Note

> Phase 2 of `SKILL.md`. Fill only the `{...}` slots of the brief. Add nothing
> else: no view on the provider, no preferred option, no opinion on a source.

## 1. Before spawning

1. Reuse an existing `docs/research/<provider>.md` if it is dated on or after the
   provider's pinned API version; otherwise mode is `re-verify` or `extend`.
2. Collect the pinned versions already known: `docs/stack-reference/pins.yaml`
   entries for the backend HTTP client, JSON, resilience and test libraries, with
   each stack-reference file's Last verified date. Stale (older than the pin) and
   absent layers are listed in the brief.
3. The destination is `docs/research/<provider>.md`; the user approved it in
   Phase 1, so it is the sanctioned subagent write.

## 2. Brief

Spawn `researcher` via `Agent`. Independent sub-questions (two candidate
providers, or provider API plus a client library) go to one `researcher` each, in
parallel, in a single message, each writing its own temporary section file.

```text
Write a research note for /integration.

Charter: read .claude/docs/research-protocol.md and .claude/rules/research-docs.md
first; the note follows .claude/docs/templates/research-note.md exactly (nine
sections, same headings).

Destination (create this one new file, nothing else): {docs/research/<provider>.md
or the temporary section path}
Mode: {new | re-verify | extend}   Existing note: {path | none}

Provider / capability: {provider | capability with provider not chosen}
Capability class: {money | inbound webhooks | PII | outbox | per-tenant credentials | user-supplied URL | file transfer}
Distribution: {distribution.model}   Tenancy: {tenancy.model | unset}
Features served: {design/specs/<feature>.md, ...}
Pinned versions already read: {component - pins.yaml value - stack-reference file - Last verified}
Stale references: {list | none}   Layers with NO stack reference: {list | none}
Licence decisions in force (.claude/docs/standing-decisions.md L1-L4, T1): {those that apply}

Establish from the provider's OFFICIAL documentation, citing the URL fetched and
the date, or write NOT SOURCEABLE - <what was searched>:
1. The current API version, how it is selected (header, path, SDK version), the
   provider's version/upgrade and deprecation policy, and the dated changelog
   entries of the last 12 months that affect the operations we use.
2. Authentication scheme, key types and scopes, sandbox vs live credential
   separation, and how a live key is distinguishable from a test key.
3. Operations we need, and for each: idempotency-key support, documented
   timeouts, rate limits, pagination, error model.
4. Webhooks: event types, delivery and retry policy, ordering guarantees, signature
   scheme (algorithm, header, signed payload, timestamp tolerance), secret
   rotation, and how to re-fetch an object.
5. Sandbox behaviour and its documented differences from live; published test
   values only.
6. Data shared (categories, PII), data residency, sub-processor/DPA terms, and
   pricing/limits that affect design.
7. An official SDK vs raw HTTP: SDK version, licence, maintenance status.
8. Security advisories for the SDK and API version: search GHSA and OSV and record
   the date searched, or state the search could not run.
9. ASVS 5.0.0 / API Security Top 10 2023 requirement IDs for webhooks, outbound
   calls and secrets, looked up in the official document with the URL fetched.
At least two options for any non-trivial choice, each with cost, risk,
performance and operability including the self-hosted bundle and vendor exit.
An option that breaks a licence decision L1-L4 is listed as "licence-blocked".
Recommend, do not decide: mark the Decision "Recommended - pending user decision".
Never paste secrets, customer data or internal URLs into a search query or the note.

Return (text, under 200 words): the written path; finding counts by tier; the
NOT SOURCEABLE list; the open questions that block implementation; anything you
could not do and why. A reply without the file is a failed phase.
```

## 3. Check the returned note

| Check | Pass condition |
|---|---|
| File exists | `Read` it; a reply with no file is a FAILED PHASE (retry once naming the unmet return contract, then BLOCKED) |
| Nine sections, links and tiers | every finding has a fetched URL and a tier; tier-5 sources carry no decision |
| **API version** | the provider's current API version is stated with the official URL and fetch date. `NOT SOURCEABLE` here makes I1 `NOT ASSESSED` and the note's Status `Draft` |
| Webhook signature scheme and sandbox/live marker | sourced, or `NOT SOURCEABLE`; each gap is carried into the report |
| Versions match `pins.yaml` | a mismatch is reported, not silently corrected |
| No secrets, no customer data, quotes at most one short line | otherwise return to the researcher |

Present the options and recommendation. The **user** records the provider
decision (`AskUserQuestion`; a major decision in every mode). Write the decision
and who made it into the note's Decision section only through the user's choice.
Any `NOT SOURCEABLE` item that is load-bearing for the adapter (version, signature
scheme, idempotency support) routes to `/research` and keeps the verdict at best
`NOT ASSESSED` until closed.
