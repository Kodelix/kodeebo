# Research Protocol

**No feature is built from memory.** The model's training data lags every
stack this studio uses, and confidently recalled APIs are the most expensive
bugs: they compile against nothing, or worse, compile against a deprecated
path with a known CVE. Research is DoD gate 1.

## When research is required

| Change | Research note required? |
|---|---|
| New feature, new integration, new external provider | **Yes** |
| New library, framework feature, or major version bump | **Yes** |
| Anything touching auth, billing, licensing, crypto, file upload, PII | **Yes** — and it feeds the threat model |
| Bug fix inside existing, already-researched code | No — cite the existing note |
| Copy, styling, config value change | No |

## Source hierarchy

Cite the highest tier available. A lower tier never overrides a higher one.

1. **Normative specs and standards** — RFCs, OWASP ASVS/MASVS/API Top 10, W3C/WHATWG, OpenTelemetry semantic conventions, PCI DSS, the Egyptian PDPL (Law 151/2020), GDPR text.
2. **Official documentation at the pinned version** — `docs/stack-reference/<layer>/` first, then the vendor's docs for that exact version (Go release notes, Ktor docs, Android developers, Apple developer docs, PostgreSQL docs for the major in use, provider API references).
3. **Official source and changelogs** — the library's repository, release notes, security advisories (GitHub Security Advisories, OSV, vendor advisories).
4. **Recognised engineering writing** — maintainers' blogs, conference talks by maintainers, well-known engineering blogs. Corroborate before relying on it.
5. **Everything else** (forums, Q&A sites, AI-written articles) — leads only. Never cited as the basis for a decision.

**E. Executed evidence** — a test, query or spike run for this note at the
pinned versions. It sits beside the hierarchy, not in it: it shows what the
exact versions it ran did, not what they promise. The source cell names the
saved script and its output (`docs/research/evidence/<slug>/` when the
researcher ran it, `prototypes/<slug>/` for a spike), with the command,
versions and date; a run without saved command and output is not evidence. It
never overrides tier 1–2: when it contradicts the docs, both are stated as a
conflict. Re-run it when a pinned version it covers changes. A test that is
planned but has not run is `PENDING — <spike id>`, and a decision resting on it
is flagged, not accepted.

**Unsourceable is a valid finding.** Write `NOT SOURCEABLE — <what was searched>`
rather than filling the gap from memory.

## The research note

Path: `docs/research/<feature-slug>.md`. Written **before** the first line of
production code. Template: `.claude/docs/templates/research-note.md` (Wave 6).

Required sections:

1. **Question** — what decision this research informs, in one paragraph.
2. **Versions** — every library/service/API involved with the exact version and where that version is pinned.
3. **Findings** — each claim with its source link and tier. Quote at most one short line per source.
4. **Options considered** — at least two for any non-trivial choice, each with cost, risk, performance and operability notes.
5. **Decision** — the chosen option and why the others lost. If it is architectural, it becomes an ADR.
6. **Security notes** — relevant ASVS/MASVS controls, known CVEs in the chosen versions, abuse cases.
7. **Performance & caching notes** — expected load, hot paths, what can be cached, budgets affected.
8. **Observability notes** — which spans, metrics and log events the feature must emit.
9. **Open questions** — anything that blocks implementation, each with an owner.

## Rules

- Research is done by the `researcher` agent or `/research`; specialists consult the note, they do not re-research silently.
- A note older than the pinned version it cites is stale: re-verify before relying on it.
- If implementation contradicts the note, update the note first, then the code.
- Never paste secrets, customer data or internal URLs into a search query.
