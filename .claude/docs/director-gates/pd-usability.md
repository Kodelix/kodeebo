> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# PD-USABILITY — User Experience Validation

Agent: `product-director` | Model tier: Opus | Domain: Product vision, positioning, user value

**Trigger**: After a usability report is generated (`/usability-report`), or
after any session that produces customer feedback.

**Context to pass**:
- Usability report — its file path, or its content inline when the calling skill reviews before saving (`/usability-report` does)
- Product principles and core value statement (`design/product-brief.md`)
- The specific hypothesis being tested
- Participant profile (role, plan, edition) and the ICP it should match

**Checks**:
1. The hypothesis is stated and the report answers it with observations (counts of participants, tasks completed, failures), not impressions.
2. Participants match the ICP in the brief; a mismatch is stated and its effect on the findings is judged.
3. The experience observed matches the intended value: for each principle the tested flow is supposed to deliver, cite the observation that confirms or contradicts it.
4. Systematic issues — the same failure across three or more participants, or the same step abandoned — are separated from one-off issues, and each systematic issue is classed as principle drift (a feature works in isolation but undermines the intended experience) or a local defect.
5. Every finding has a proposed action and an owner (`product-manager`, `ux-designer`, `design-director`), and any finding that would change scope is flagged for `product-director`.

**Prompt**:
> "Review this usability report against the product's principles and core value.
> Is the customer experience matching the intended value? Are there systematic
> issues that represent principle drift — features that work in isolation but
> undermine the intended experience? Return APPROVE (core value is landing),
> CONCERNS [gaps between intended and actual experience], or REJECT [core value
> is not present — redesign needed before further usability testing]."

**Verdicts**: APPROVE / CONCERNS / REJECT

**NOT ASSESSED when**: the report (path or inline content), the principles or
the tested hypothesis was not passed or cannot be read. A report with no stated
hypothesis is a finding (CONCERNS), not a missing input.

**Output**: the standard block, with a table of systematic issues (issue — participants affected / total — principle — class: drift or defect).
