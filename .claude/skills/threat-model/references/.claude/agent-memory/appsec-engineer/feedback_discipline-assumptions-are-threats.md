---
name: discipline-assumptions-are-threats
description: Founder wants "developers will do X" design rules (e.g. payloads hold ids only) modelled as threat rows with a test-based mitigation and an owning story, not listed as assumptions
metadata:
  type: feedback
---

A design rule that depends on developer discipline (example: "job payloads hold ids only", ADR-0012) is a threat row, not an assumption. Propose a mechanical guard (type that only accepts ids, architecture/unit test, DB CHECK where possible), a code-review checklist item, and name the story that owns it.

**Why:** founder, 2026-10-21, on the tenant-isolation TB6 extension for ADR-0012: a developer putting an email or name into a payload is a realistic slip, and dead items keep payloads 90 days.

**How to apply:** in every /threat-model draft, scan the ADR for "never/only/must" rules enforced only by convention (payload contents, idempotency-key construction, log fields, handler transaction use) and raise each as a threat with a negative test. Related: [[threat-model-id-continuity]] (existing IDs kept, new ones appended on --update).
