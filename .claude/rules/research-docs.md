---
paths:
  - "docs/research/**"
  - "docs/stack-reference/**"
---

# Research and Stack Reference Rules

Protocol: `.claude/docs/research-protocol.md`.

- Every factual claim has a source link and tier (1–5), or is executed evidence
  (tier E: saved script and output, command, versions, date); versions are exact.
- No claim from memory. Unknown → `NOT SOURCEABLE — <what was searched>`.
- At most one short quote per source; summarise in your own words.
- Record options considered and why each lost; the chosen option becomes an ADR if architectural.
- Stack reference files record **Last verified** dates; a reference older than the pinned version is stale and must be re-verified before use.
- Never put secrets, customer data or internal hostnames in research notes or search queries.
