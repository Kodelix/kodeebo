# /architecture-review — Phase 6: Architecture Document Coverage

> Part of `/architecture-review`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 6: Architecture Document Coverage

**If `docs/architecture/architecture.md` does not exist, say so in the report** —
`Architecture document coverage: NOT ASSESSED — no docs/architecture/architecture.md`
— and carry it into the Phase 7 verdict per the trigger list below. Phase 5
already models this for the stack lead consultation (*"A skipped check that says
nothing is indistinguishable from a check that passed"*); this phase is the one
that must do the same. Silently producing no Phase 6 findings reads as an architecture
document that was checked and found clean, which is the opposite of what
happened.

If it exists, validate it against the specs and the domain map:

- Does every bounded context from `domain-map.md` appear in the architecture's context map?
- Does the data flow section cover all cross-context communication defined in the specs?
- Do the API boundaries (and `contracts/` files) support all client and integration requirements from the specs?
- Is there a data store, tenancy enforcement point and topology (hosted and, where applicable, self-hosted) for every context?
- Are there contexts in the architecture doc that have no corresponding spec (orphaned architecture)?
- Does the architecture's Document Status carry a CTO-ARCHITECTURE and PE-FEASIBILITY record (or the mode that skipped them)?

---
