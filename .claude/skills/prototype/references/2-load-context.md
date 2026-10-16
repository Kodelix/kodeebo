# /prototype — Phase 2: Load Concept Context

> Part of `/prototype`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 2: Load Concept Context

Read `design/product-brief.md` if it exists. Extract:
- The ICP (who the product is for) and the job-to-be-done
- The core user journey (the steps being tested)
- The pricing model and the plan assumptions that matter to the hypothesis
- Distribution (`distribution.model`) and tenancy (`tenancy.model`) when they affect the question

Read the `stack` line from the resolved block (`project.yaml`): the languages and
frameworks a code spike may use. An `unset` layer is **not defaulted** — if a code
spike needs a layer that is `unset`, ask the user which stack to spike in rather
than guessing; the spike may use any language the user names, since it is
throwaway, but a spike meant to inform the stack choice says so in its README.

If the question touches an API, library or provider you are not certain of, read
`docs/stack-reference/<layer>/` first, and `docs/research/<topic>.md` if a
research note exists. **A prototype is not a substitute for research**: if no
note exists and the idea would involve a new provider or sensitive area, say so
in the report's "If Proceeding" section — `/research` is required before the real
build (DoD gate 1).

If `design/product-brief.md` does not exist, ask the user for the one-paragraph
pitch and the ICP in plain text; record them in the prototype README. Do not
invent them.

---
