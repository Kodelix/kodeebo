> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# DD-VISUAL — Design Director Visual Consistency Review

Agent: `design-director` | Model tier: session (inherit)

**Trigger**: After design decisions are made, when a new surface type is
introduced (for example a settings area, billing screens, a marketing page, a
mobile screen family), or when a token or component decision affects visual
identity (`/team-ui`, `/ux-review`).

**Context to pass**:
- `PRODUCT.md` and `DESIGN.md` (repository root), if they exist
- The specific surface, token, component or style decision being reviewed
- Screenshots (path, locale, viewport) or style descriptions, and the `/impeccable audit` result path
- Platform and performance constraints (`stack.*`, `accessibility.target`, UI budgets in `perf-budgets.md`)

**Checks**:
1. The decision matches `DESIGN.md` and the brand personality in `PRODUCT.md`; cite the token or rule it follows or departs from.
2. Values come from tokens: no raw hex, pixel or font values in the reviewed change where a token exists.
3. Contrast, focus state and touch-target size meet `accessibility.target`; cite audit findings or measured values.
4. The surface works in Arabic (RTL) and English: mirrored layout, numerals and typography per the policy in `DESIGN.md`.
5. The surface mode (Persuade, Operate, Read) is the right one for the screen and the density matches it.
6. It is achievable within the web or mobile performance budget (font payload, images, JS, animation cost).
7. Pipeline implications: the decision can be exported to every platform that consumes the tokens (CSS variables, Compose theme, SwiftUI assets), or the platform that cannot is named.

**Prompt**:
> "Review this visual decision for consistency with the established design
> system and production constraints. Does it match DESIGN.md and PRODUCT.md? Is
> it achievable within the platform's performance budget and the accessibility
> target? Does it work in Arabic and English? Are there token-export or
> implementation implications that create technical risk? Return APPROVE,
> CONCERNS [specific adjustments], or REJECT [style violation or production risk
> that must be resolved first]."

**Verdicts**: APPROVE / CONCERNS / REJECT

**NOT ASSESSED when**: the decision under review or its screenshots cannot be
opened. A `DESIGN.md` the skill reports as absent is a finding (CONCERNS or
REJECT depending on whether the decision defines it), not a missing input.

**Output**: the standard block; the agent's design-review template adds an `Evidence` line (screenshot paths, audit path) and a `Not checked` list — include both.
