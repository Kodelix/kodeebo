> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# CTO-CONTEXT-BOUNDARY — Bounded Context Architecture Review

Agent: `cto` | Model tier: Opus | Domain: Architecture, stack risk, performance

**Trigger**: After `/map-domains` dependency mapping is agreed but before spec
authoring begins — validates that the context structure is architecturally sound
before teams invest in writing specs against it.

**Context to pass**:
- Domain map path (`design/specs/domain-map.md`), or the dependency map summary if the map is not yet written
- Layer assignments (Foundation / Core / Feature / Presentation)
- The full dependency graph (what each context and feature depends on)
- Any bottleneck contexts flagged (many dependents)
- Any circular dependencies found and their proposed resolutions
- Data ownership table (entity — owning context) and `tenancy.model` from `project.yaml`

**Checks**:
1. Each context owns a distinct concern with minimal overlap: no two contexts claim the same entity; each entity has exactly one owning context.
2. No God-context risk: no context owns more than one reason to change; list contexts with more than one business capability.
3. Dependency ordering does not create implementation-sequencing problems: the build order follows the dependency graph.
4. No implicit shared state across boundaries: shared tables, shared caches or shared config that would force tight coupling when implemented are named.
5. No inverted dependency: no Foundation-layer context depends on a Feature-layer context.
6. Circular dependencies are resolved by a stated mechanism (event, port, merge, split), not deferred.
7. The tenant boundary is explicit: which contexts are tenant-scoped, which are global (plans, licences, platform admin), and how tenant context propagates across them.
8. Capabilities the studio already provides in `saas-core` modules (identity, OTP, notify, storage, billing, licensing, tenancy, audit, ratelimit) are consumed, not planned as new contexts.
9. Integration style between contexts (synchronous call, event/outbox) is stated for each edge that crosses a transaction boundary.

**Prompt**:
> "Review this domain decomposition from an architectural perspective before
> spec authoring begins. Are the context boundaries clean — does each context
> own a distinct concern with minimal overlap? Are there God-context risks
> (contexts doing too much)? Does the dependency ordering create
> implementation-sequencing problems? Are there implicit shared-state problems
> in the proposed boundaries that will cause tight coupling when implemented? Is
> the tenant boundary explicit? Are any Foundation-layer contexts actually
> dependent on Feature-layer contexts (inverted dependency)? Return APPROVE
> (boundaries are architecturally sound — proceed to spec authoring), CONCERNS
> [specific boundary issues to address in the specs themselves], or REJECT
> [fundamental boundary problems — the structure will cause architectural issues
> and must be restructured before any spec is written]."

**Verdicts**: APPROVE / CONCERNS / REJECT

**NOT ASSESSED when**: the domain map (or dependency summary) or the data
ownership table cannot be read. An ownership table the skill reports as not yet
written is a finding (check 1 cannot be met), not a missing input.

**Output**: the standard block, with the data ownership table annotated (entity — owner — conflict?).
