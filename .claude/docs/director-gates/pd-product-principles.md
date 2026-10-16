> Gate definition. The spawning skill passes this file's path to the director agent; the AGENT reads it — the parent session should not.

# PD-PRODUCT-PRINCIPLES — Product Principles Stress Test

Agent: `product-director` | Model tier: Opus | Domain: Product vision, positioning, user value

**Trigger**: After product principles and anti-principles are defined
(`/brainstorm`, principles phase), or any time they are revised. Runs in
parallel with DD-CONCEPT-VISUAL.

**Context to pass**:
- Full principle set with names, definitions, and design tests (`design/product-brief.md`, "Principles" section)
- Anti-principles list
- Core value statement: the customer (ICP), the job they hire the product for, the outcome
- Positioning statement ("Unlike X, this product does Y for Z") and the closest alternatives it is compared against (`docs/research/` notes if present)

**Checks** (answer each with a `file:line` or quote from the brief):
1. Each principle is falsifiable: name one real product decision (a feature, a limit, a price point) that would fail it. A principle no decision could fail is not a principle.
2. Each principle has a design test — a question a spec author can answer yes/no.
3. At least one pair of principles creates a genuine tension (a trade-off that forces a choice), and the brief says which wins.
4. Each principle separates this product from its closest alternatives; a principle every competitor would also claim (for example "simple", "secure", "fast") without a measurable form is generic.
5. Each anti-principle names something a customer might plausibly ask for that the product refuses, and why.
6. The set would settle a real scope disagreement in practice — state one disagreement it resolves and how.
7. The principles are consistent with the core value statement and with the editions promised (`distribution.model`: what hosted can promise vs the self-hosted bundle).

**Prompt**:
> "Review these product principles. Are they falsifiable — could a real product
> decision actually fail this principle? Do they create meaningful tension with
> each other? Do they differentiate this product from its closest alternatives?
> Would they help resolve a scope disagreement in practice, or are they too
> vague to be useful? Return specific feedback for each principle and an overall
> verdict: APPROVE (strong), CONCERNS [list] (needs sharpening), or REJECT (weak —
> principles do not carry weight)."

**Verdicts**: APPROVE / CONCERNS / REJECT

**NOT ASSESSED when**: the principle set, the core value statement or the list of
alternatives cannot be read. Missing anti-principles that the skill reports as
not yet defined is a finding (CONCERNS), not a missing input.

**Output**: the standard block (`director-gates.md` → Standard output block), with one row per principle under Checks 1–4 and the named disagreement from check 6.
