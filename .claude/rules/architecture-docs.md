---
paths:
  - "docs/architecture/**"
---

# Architecture Document Rules

- ADRs: `docs/architecture/adr-NNNN-<slug>.md` with Status, Context, Decision, Consequences, Alternatives considered, and links to the research note and affected specs. Superseded ADRs are kept and marked, never edited into a new decision.
- Threat models: `docs/architecture/threat-models/<feature>.md` — STRIDE per trust boundary, abuse cases, mitigations linked to stories/tests, residual risk accepted by name.
- Performance budgets: `docs/architecture/perf-budgets.md` is the single source; specs reference it.
- SLOs: `docs/architecture/slos.md`, one SLI/SLO per critical journey, each with alert and runbook links.
- Diagrams as code (Mermaid/D2) so they diff in review.
