# /prototype — Phase 3: Choose the Prototype Path

> Part of `/prototype`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 3: Choose the Prototype Path

Select the prototype path. If `--path [mock|spike|concierge|paper]` was passed, use
that. Otherwise use this quick reference, then read the path details below:

| The riskiest assumption is… | Recommended path | Key reason |
|---|---|---|
| Desirability / usability of a flow or screen | **Click-through mock** | Real ICP users react to a screen in minutes; no backend needed |
| Willingness to pay, pricing page, plan packaging | **Click-through mock** + pre-order/quote ask | Test the ask, not the code |
| Feasibility: query performance, a data model, a sync algorithm, a library | **Code spike** | The answer is a measurement or it works / it doesn't |
| Integration viability (payment, SMS/OTP, email, storage provider) | **Code spike** against the provider **sandbox** | The provider's real behaviour is the unknown |
| A service you would build (reports, onboarding, matching) | **Concierge / manual** | Deliver the outcome by hand to 3–5 real users before automating anything |
| Rules, entitlements, pricing logic, workflow states | **Paper** | Validate that the rules are coherent and the edge cases are answerable before building |
| Performance at scale (concurrency, volume) | **Code spike** + k6 | Needs real load; see the performance-spike note in Spike Mode |

**Rule of thumb:** "Do they want it / can they use it?" → Mock. "Does it work / is it fast enough?" → Spike. "Can we deliver the value at all?" → Concierge. "Are these rules coherent?" → Paper.

### Path: Click-through mock

**Best for:** onboarding, a core screen or flow, dashboard layouts, pricing and
plan pages. **Output:** a self-contained `prototype.html` (or a small static
folder) opened by double-clicking or `python3 -m http.server --bind 127.0.0.1` —
no backend, no build step, hardcoded sample data, no real accounts. It does not
go through `/impeccable`; it is deliberately rough (a design pass is a production
concern). **Limitation:** proves desirability and comprehension, not feasibility
or performance. **Reach real users:** share the file with ICP members and watch
a screen-share or recording; for Arabic-speaking users, include Arabic (RTL)
copy if language is part of the risk.

### Path: Code spike

**Best for:** feasibility and integration questions. **Output:** a minimal
runnable project in `prototypes/<name>/` — any language/stack the question needs,
hardcoded config, seeded or generated data, no auth, no tenancy unless tenancy
*is* the question. Provider calls use **sandbox credentials the user supplies via
environment variables**, never committed. **Reliability:** expect 2–4 rounds of
run-and-report iteration — normal, not failure. **Sunk-cost rule:** more than 2
hours without a running spike → stop, reframe, or switch path. The measurement
(timing, row counts, error rate, API behaviour) is the deliverable, recorded with
its conditions.

### Path: Concierge / manual

**Best for:** "can we deliver this outcome at all, and will they value it?" The
team performs the service by hand (spreadsheet, script run manually, email) for 3–5
real ICP users. **Output:** a `playbook.md` of the manual steps and a `log.md` of
each delivery — time spent, user reaction, what broke. **Limitation:** proves value
and process, not technical scalability. Real customer data is handled under the
participant's explicit consent and is not committed to the repository.

### Path: Paper

**Best for:** pricing/entitlement logic, workflow state machines, permission models,
quota rules. **Output:** `rules.md` (the rules) and `walkthrough.md` (one complete
scenario traced step by step, including a wrong-role, other-tenant and over-quota
case). **Observation protocol (5+ people):** brief the rules once, then stay silent;
note every re-read and question; ask one thing afterwards — "What was confusing?";
use fresh people each iteration; if 3+ hit the same confusion, the rule is broken —
fix it before re-testing. **Limitation:** cannot validate interaction feel or
performance.

---

Assess which path best fits the hypothesis, then use `AskUserQuestion` with your
recommendation pre-stated:

- **Prompt**: "Which prototype path would you like to use? (Based on your concept, I'd recommend [path] — [one sentence reason].)"
- **Options**:
  - `Click-through mock` — desirability, comprehension, pricing-page tests. No install, no backend.
  - `Code spike` — feasibility, integration, performance. Runnable; iterates 2–4 rounds.
  - `Concierge / manual` — deliver the outcome by hand to a few real users.
  - `Paper — rules document + walkthrough` — entitlement, pricing and workflow rules. 100% reliable; cannot validate feel.

---
