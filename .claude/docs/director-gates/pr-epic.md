> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# PR-EPIC — Epic Structure Feasibility Review

Agent: `producer` | Model tier: Opus | Domain: Scope, timeline, dependencies, production risk

**Trigger**: After epics are defined by `/create-epics`, before stories are
broken out — validates the epic structure is producible before `/create-stories`
is invoked.

**Context to pass**:
- The epic structure for the layer, inline — every epic's scope summary and governing-ADR count. `/create-epics` runs this gate *before* writing any epic file, so there are no paths yet.
- Milestone timeline and target dates
- Team capacity (`team.size`: individual / small / studio, and hours or people available per sprint)
- Layer being epiced (Foundation / Core / Feature / Presentation) and the bounded context or module each epic belongs to

**Checks**:
1. Each epic is scoped so it can complete before a milestone deadline: compare its size (story count or estimate) to capacity and the date.
2. Epics are ordered by dependency: no epic needs another epic's output before it can start; list any that do.
3. No epic is underscoped (so small it should merge) or overscoped (so large it should split into 2-3 focused epics): name each.
4. Foundation-layer epics (tenancy, identity, data stores, CI/deploy, observability baseline) are scoped so Core-layer epics can begin at the start of the sprint after Foundation completes.
5. Each epic's governing ADRs are Accepted (at `workflow: minimal`, the decision-log entry exists); an epic that depends on an unresolved Foundation decision is flagged.
6. Epics that carry security-sensitive features (authentication, billing, licensing, upload, PII, integrations) show the threat-model and research-note work as planned effort, not an afterthought.
7. Epics that need an external lead time (payment provider onboarding, Play Console / App Store review, DNS and TLS, licence signing keys) show it on the timeline.

**Prompt**:
> "Review this epic structure for production feasibility before story breakdown
> begins. Are the epic boundaries scoped appropriately — could each epic
> realistically complete before a milestone deadline? Are epics correctly
> ordered by dependency — does any epic require another epic's output before it
> can start? Are any epics underscoped (too small, should merge) or overscoped
> (too large, should split into 2-3 focused epics)? Are the Foundation-layer
> epics scoped to allow Core-layer epics to begin at the start of the next
> sprint after Foundation completes? Return REALISTIC (epic structure is
> producible), CONCERNS [specific structural adjustments before stories are
> written], or UNREALISTIC [epics must be split, merged, or reordered — story
> breakdown cannot begin until resolved]."

**Verdicts**: REALISTIC / CONCERNS / UNREALISTIC

**NOT ASSESSED when**: the epic structure, the milestone dates or the capacity
figure is not passed. Capacity the skill reports as unknown is a finding.

**Output**: the standard block, with an ordering table (epic — depends on — earliest start — fits milestone?).
