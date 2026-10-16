> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# DD-CONCEPT-VISUAL — Visual Identity Anchor

Agent: `design-director` | Model tier: session (inherit) | Domain: Visual identity, design system, UI production readiness

**Trigger**: After product principles are locked (`/brainstorm`, principles
phase), in parallel with PD-PRODUCT-PRINCIPLES. Its chosen direction seeds
`/impeccable init` (`PRODUCT.md`).

**Context to pass**:
- Product concept (elevator pitch, ICP, core value, positioning)
- Full principle set with names, definitions, and design tests
- Target platforms (`stack.web`, `stack.site`, `stack.mobile`, if known) and locales (Arabic and English, RTL)
- Reference products, visual touchstones and anti-references mentioned by the user

**Checks**:
1. Two or three directions are proposed, each distinct from the others (not variations of one idea) and each named.
2. Each direction states four elements: (1) a one-line visual rule that could guide all visual decisions (for example "everything is a table until proven otherwise"), (2) mood and brand-personality targets, (3) shape language (sharp / rounded / organic / geometric emphasis), (4) colour philosophy (palette direction and what colour roles mean in the product).
3. One direction directly serves the primary principle; say which and cite the principle.
4. No direction is the generic-SaaS default (purple gradients, stock illustration, interchangeable card grids); each cites the anti-reference it avoids.
5. Each direction is workable for dense operational screens (Operate) and for persuasion surfaces (Persuade), and for Arabic/RTL.
6. A recommendation is made with the reason.

**Prompt**:
> "Based on these product principles and concept, propose 2-3 distinct visual
> identity directions. For each direction provide: (1) a one-line visual rule
> that could guide all visual decisions, (2) mood and brand-personality targets,
> (3) shape language (sharp/rounded/organic/geometric emphasis), (4) colour
> philosophy (palette direction, what colours mean in this product). Be
> specific — avoid generic descriptions. One direction should directly serve the
> primary product principle. Name each direction. Recommend which best serves
> the stated principles and explain why."

**Verdicts**: CONCEPTS (multiple valid options — user selects) / STRONG (one direction clearly dominant) / CONCERNS (principles don't provide enough direction to differentiate visual identity yet — name each principle that gives none, and which of the four elements above it leaves open)

**Mapping to the Standard Verdict Format** (`director-gates.md`): `CONCEPTS` and `STRONG` are both APPROVE-class (`CONCEPTS` needs the user to select a direction before proceeding; `STRONG` proceeds with the dominant direction). `CONCERNS` is the CONCERNS row: not blocking, surfaced to the user, and the principles are revised before a direction is chosen. This gate has no REJECT-class word; a missing input is `NOT ASSESSED`, never one of the three.

**NOT ASSESSED when**: the concept or the principle set cannot be read.
Missing reference products or platforms is not a missing input — say so in the
rationale and proceed.

**Output**: the standard block; the Findings section holds the proposed directions (name — rule — mood — shape — colour) and the recommendation.
