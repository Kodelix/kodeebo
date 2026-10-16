# /team-feature — Phases 2–4: Research, Spec, Threat Model

> Part of `/team-feature`. Read again if the conversation was compacted.

Each phase ends in a gate that **always prompts**. Present it as:

```
## Decision: <what>
Produced: <paths>
It decides: <one line>
Options: A) … B) … C) …
Recommendation: <option> — <why, citing the artifact>
```

then `AskUserQuestion`. After every gate, update the checkpoint (Phase 9 §4).

## 1. Phase 2 — Research (`/research`)

Invoke `/research <slug>` via the `Skill` tool with: the feature sentence, the
routing note's open questions, the layers and pins involved. It writes
`docs/research/<slug>.md` from primary sources (research-protocol.md); the
`researcher` agent does the work. Verify the file exists (Trigger 0) and read its
**Decision** and **Open questions** sections.

- Exemption (`research-protocol.md`): a bug fix inside researched code, or copy /
  styling / config value changes. State the row and cite the existing note; no
  `/research` run. Anything touching auth, billing, licensing, crypto, file upload
  or PII is never exempt.
- Anything the note marks `NOT SOURCEABLE` is carried forward as an open question
  with an owner; it is not resolved from memory by anyone downstream.

**Gate — research conclusion.** Options: accept the decision · ask for another
option to be researched · stop. A research note older than the pinned version it
cites is stale (`research-protocol.md`): say so and offer `/research refresh`.

## 2. Phase 3 — Spec (`/design-spec` or `/quick-spec`)

Skipped at `workflow: minimal` (named: `workflow: minimal — brief + research note
are the record`); the stories then trace to the product brief and the research
note.

1. **Consultants first, when their trigger fires** (active set permitting; below
   `small` they are consulted through `principal-engineer` with an informational
   note):
   - `pricing-billing-designer` — plans, entitlements, metering, trials, tax or
     dunning change. Writes `consult-pricing-billing-designer.md`.
   - `domain-architect` — a new bounded context, or a change to context
     relationships. Writes `consult-domain-architect.md`; updates to
     `design/specs/domain-map.md` go through the skill/agent that owns it, with
     approval.
   Spawn both in one message when both fire.
2. Invoke `/design-spec <slug>` (standard/full), or `/quick-spec <slug>` for a
   small, non-sensitive change. Pass the research note, the routing note, the
   consultant outputs, `system_overrides`. The spec must name the **core modules
   it depends on** (Dependencies), the acceptance criteria including negative and
   cross-tenant cases, the localization needs (Arabic and English, RTL) and the
   NFRs (security IDs, performance budget, caching, observability).
3. `PD-SPEC-ALIGN` runs inside those skills per `review_mode`; record its verdict
   or `skipped — <mode> mode`. Run `bash .claude/scripts/spec-structure-check.sh`
   on the spec and show its real output (observations, not a verdict); the
   sections required are those of the resolved tier.

**Gate — spec approval.** The spec is the contract with the product-director's
intent: no contract, migration or story starts before it is approved. CONCERNS
from `PD-SPEC-ALIGN` go to the user as `Revise flagged items` / `Accept and
proceed` / `Discuss further`.

## 3. Phase 4 — Threat model (`/threat-model`)

Fires on the `security-baseline.md` triggers: authentication, the authorization
model, billing, licensing, file upload, webhooks, PII export/delete,
admin/impersonation, a new external integration. State the trigger that fired —
or `no security-baseline trigger fired` as the named skip.

Invoke `/threat-model <slug>`. It produces
`docs/architecture/threat-models/<slug>.md` with mitigations linked to stories and
negative tests, and runs `SL-THREAT-MODEL` per `review_mode`. At `studio` size
also spawn `security-lead` to review the mitigations against the spec in parallel
with the next phase's non-dependent work (write `review-security-lead.md`).

**Gate — residual risk.** Residual risk is accepted **by name** (owner, expiry) in
the threat model, by the user — never by this orchestrator and never by an agent.
A `REJECT` blocks the contract/data/story phases for the affected surface.
