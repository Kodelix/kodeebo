> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# PR-MILESTONE — Milestone Risk Assessment

Agent: `producer` | Model tier: Opus | Domain: Scope, timeline, dependencies, production risk

**Trigger**: At milestone review (`/milestone-review`), or when a scope change is
proposed that affects the milestone.

**Context to pass**:
- Milestone definition and target date
- Current completion percentage (stories Done / total, by story points or count — say which)
- Blocked stories count and the blockers
- Sprint velocity data (if available)
- Stories closed with a DoD waiver (count) and open BLOCKING evidence gaps

**Checks**:
1. At the current velocity the remaining work finishes by the target date: show the arithmetic (remaining points ÷ velocity = sprints; sprints vs time left). Velocity absent is reported as such and the date is judged on counts alone.
2. The top 3 production risks between now and the milestone are named with likelihood, impact, owner and mitigation.
3. Blocked stories are on the critical path or not: list those that are, with the dependency and the wait duration.
4. Scope items are classified as cuttable (to protect the date) or non-negotiable, with the reason; cuts keep the product shippable.
5. "Done" is genuine: the count of stories closed with waived DoD gates or missing evidence is stated, and work remaining to retire them is included in the estimate.
6. External lead times that fall before the date (payment provider approval, store review, security review) are on the timeline.

**Prompt**:
> "Review this milestone status. Based on current velocity and blocked story
> count, will this milestone hit its target date? What are the top 3 production
> risks between now and the milestone? Are there scope items that should be cut
> to protect the milestone date vs. items that are non-negotiable? Return ON
> TRACK, AT RISK [specific mitigations], or OFF TRACK [date must slip or scope
> must cut — provide both options]."

**Verdicts**: ON TRACK / AT RISK / OFF TRACK

**NOT ASSESSED when**: the milestone definition, target date or completion
figure is missing. Velocity data the skill reports as unavailable is not a
missing input.

**Output**: the standard block, with the arithmetic from Check 1 and, for OFF TRACK, both options (new date; scope cut list).
