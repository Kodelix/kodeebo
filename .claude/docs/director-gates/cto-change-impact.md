> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# CTO-CHANGE-IMPACT — Spec Change Impact Review

Agent: `cto` | Model tier: Opus | Domain: Architecture, stack risk, performance

**Trigger**: After the Spec Change Impact Report is produced
(`/propagate-spec-change`), before the resolution workflow begins.

**Context to pass**:
- The full Spec Change Impact Report — change summary, every affected ADR with its Still Valid / Needs Review / Likely Superseded classification, affected contracts (`contracts/`), affected migrations and stories, and the recommended actions
- Path of the changed spec (`design/specs/<feature>.md`) and its previous version (git ref)
- `docs/architecture/architecture.md` (for cascade tracing)

**Checks**:
1. Every ADR classified Still Valid has been tested against the change: name the ADR assumption the change would have to contradict, and confirm it does not. An ADR marked Still Valid when the change contradicts its assumptions is under-classified.
2. Every Needs Review and Likely Superseded classification cites the changed spec line and the ADR line in conflict.
3. Cascades are traced: decisions that depend on an already-flagged ADR are listed, including data-store, tenancy, API contract, and licence/entitlement decisions.
4. Contract impact is complete: each changed endpoint or event is mapped to `contracts/` and flagged breaking or non-breaking for hosted clients and for deployed self-hosted versions.
5. Data impact is complete: a schema change names the migration shape (expand → migrate → contract) and the effect on tenants' existing data and on multi-version self-hosted upgrades.
6. Recommended actions are architecturally sound and ordered (what must be decided before what), and each has an owner.
7. Security, pricing/entitlement and observability consequences of the change are each addressed or marked not applicable with a reason.

**Prompt**:
> "Review this spec-change impact assessment before any ADR is revised. Are the
> impact classifications correct — in particular, is any ADR under-classified
> (marked Still Valid when the change actually contradicts its assumptions)? Are
> the recommended actions architecturally sound? Were any cascading effects on
> other ADRs, contracts, data or contexts missed — decisions that depend on the
> ones already flagged? Return APPROVE, CONCERNS [the specific ADRs or
> recommendations to revisit], or REJECT [the assessment must be re-analyzed
> before resolution begins — say what was missed]."

**Verdicts**: APPROVE / CONCERNS / REJECT

**NOT ASSESSED when**: the impact report, the changed spec or its previous
version cannot be read.

**Output**: the standard block, with an ADR table (ADR — classification given — classification judged — evidence).
