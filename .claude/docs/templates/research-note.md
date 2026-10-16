# Research Note: [Feature / Topic]

> **Path**: `docs/research/<feature-slug>.md` — written **before** the first line of production code (`research-protocol.md`).
> **Status**: Draft | Complete | Stale (re-verify)
> **Author**: [researcher agent / person]
> **Date**: [YYYY-MM-DD]
> **Feature / story**: [`design/specs/<feature>.md`, story ID]
> **Triggers**: [new feature · new integration/provider · new library or major version · auth · billing · licensing · crypto · file upload · PII — sensitive topics also feed `threat-model.md`]

<!--
SOURCE HIERARCHY (cite the highest tier available; a lower tier never overrides a higher one):
  1 Normative specs: RFCs, OWASP ASVS/MASVS/API Top 10, W3C/WHATWG, OTel semantic conventions, PCI DSS, PDPL (Law 151/2020), GDPR text
  2 Official docs at the PINNED version (docs/stack-reference/<layer>/ first, then vendor docs for that exact version)
  3 Official source, changelogs, security advisories (GHSA, OSV, vendor advisories)
  4 Recognised engineering writing (maintainers' posts/talks) — corroborate
  5 Everything else — leads only, never the basis for a decision
  E Executed evidence: a test/query/spike run for this note at the pinned versions; source = saved script + output
    (docs/research/evidence/<slug>/ or prototypes/<slug>/), command, versions, date. Never overrides tier 1–2.
    Planned but not run = `PENDING — <spike id>`.
"Unsourceable is a valid finding": write `NOT SOURCEABLE — <what was searched>` rather than filling the gap from memory.
Never paste secrets, customer data or internal URLs into a search query.
A note older than the pinned version it cites is stale: re-verify before relying on it.
If implementation contradicts the note, update the note first, then the code.
-->

## 1. Question

<!-- What decision this research informs, in one paragraph. -->

## 2. Versions

<!-- Every library/service/API involved with the exact version and where that version is pinned. -->

| Component | Version | Where pinned (`pins.yaml`, lockfile, provider API version) | Verified on |
|-----------|---------|-----------------------------------------------------------|-------------|
| | | | [date] |

## 3. Findings

<!-- Each claim with its source link and tier (1–5, or E for executed evidence). Quote at most one short line per source. -->

| # | Claim | Source (link) | Tier | Notes |
|---|-------|---------------|------|-------|
| F1 | | | | |
| F2 | | | | NOT SOURCEABLE — [what was searched] |

## 4. Options Considered

<!-- At least two for any non-trivial choice. -->

| Option | Description | Cost | Risk | Performance | Operability (run, upgrade, self-hosted fit) |
|--------|-------------|------|------|-------------|---------------------------------------------|
| A | | | | | |
| B | | | | | |

## 5. Decision

<!-- The chosen option and why the others lost. If it is architectural, it becomes an ADR (or a decision-log line at minimal). -->

**Chosen**: [Option]
**Why**: [...]
**Why not the others**: [...]
**Follow-up record**: [ADR-NNNN | brief decision log | none]

## 6. Security Notes

<!-- Relevant ASVS/MASVS controls (look up IDs in the official document), known CVEs/advisories in the chosen versions, abuse cases. Link the threat model if one is required. -->

- **Controls**: [ASVS/MASVS IDs and what they require here]
- **Advisories**: [CVE/GHSA IDs in chosen versions, or "none found — searched OSV/GHSA on [date]"]
- **Abuse cases**: [...]
- **Threat model**: [`docs/architecture/threat-models/<feature>.md` | not required: reason]

## 7. Performance & Caching Notes

<!-- Expected load, hot paths, what can be cached, budgets affected (perf-budgets.md, caching-standard.md). -->

- **Expected load**: [requests/s, rows, tenants, payload sizes]
- **Hot paths**: [...]
- **Caching candidates**: [what, pattern, key idea — full decision goes in the spec or `cache-design.md`]
- **Budgets affected**: [...]

## 8. Observability Notes

<!-- Which spans, metrics and log events the feature must emit (observability-standard.md). -->

- **Spans**: [...]
- **Metrics (RED / business)**: [...]
- **Log events**: [...] (no PII, no secrets)
- **Alerts / SLO / runbook needed**: [...]

## 9. Open Questions

<!-- Anything that blocks implementation, each with an owner. -->

| Question | Blocks | Owner | Due |
|----------|--------|-------|-----|
| | | | |
