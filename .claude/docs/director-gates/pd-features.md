> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# PD-FEATURES — Feature Decomposition Vision Check

Agent: `product-director` | Model tier: Opus | Domain: Product vision, positioning, user value

**Trigger**: After the domain map is written by `/map-domains` — validates the
complete feature set before spec authoring begins.

**Context to pass**:
- Domain map path (`design/specs/domain-map.md`)
- Product principles, ICP and core value (`design/product-brief.md`; if the brief has no principles section, its pitch and ICP, and say so)
- Priority tier assignments (MVP / Vertical Slice / Beta / Full Vision)
- Any high-risk or bottleneck contexts or features identified in the dependency map

**Checks**:
1. The MVP-tier features together deliver the core value statement end to end: walk the primary customer journey (sign-up → first value → billing → ongoing use) and name the feature that owns each step.
2. Every feature serves at least one principle; a feature that serves none is flagged as scope creep, with its tier.
3. Every principle-critical customer experience has a feature assigned to deliver it.
4. Every capability the core journey requires exists in the map (for example identity and onboarding, tenant administration, plan/entitlement enforcement, billing, notifications, audit log, data export); a missing one is named.
5. Features the self-hosted edition needs that the hosted edition does not (licence activation, offline grace, installer, upgrade path) are present when `distribution.model` is `self-hosted` or `hybrid`.
6. Tier assignment is shippable: each tier, if work stops there, is a product a customer could pay for.

**Prompt**:
> "Review this feature decomposition against the product's principles. Does the
> full set of MVP-tier features collectively deliver the core value? Are there
> features that don't serve any stated principle — indicating they may be scope
> creep? Are there principle-critical customer experiences that have no feature
> assigned to deliver them? Are any features missing that the core journey
> requires? Return APPROVE (features serve the vision), CONCERNS [specific gaps
> or misalignments with their principle implications], or REJECT [fundamental
> gaps — the decomposition misses critical product intent and must be revised
> before spec authoring begins]."

**Verdicts**: APPROVE / CONCERNS / REJECT

**NOT ASSESSED when**: the domain map or the product brief cannot be read, or
tier assignments were not passed. A tier the skill reports as unassigned is a
finding.

**Output**: the standard block, with the journey walk from check 1 as a table (step — owning feature — tier).
