# /review-all-specs — Phase 4: Cross-Feature Scenario Walkthrough

> Part of `/review-all-specs`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 4: Cross-Feature Scenario Walkthrough

Walk through the product from a customer's and an attacker's perspective to find
problems that only appear at the interaction boundary between multiple features —
things static analysis of individual specs cannot surface.

### 4a: Identify Key Multi-Feature Moments

Scan all specs and identify the 3–5 most important moments where multiple
features activate simultaneously. Look specifically for:

- **Billing + Access overlap**: payment failure, dunning, cancellation, downgrade, trial end — and what each feature does to access, data and limits
- **Tenancy + Identity overlap**: a user belonging to several tenants, removal of the last owner, ownership transfer, tenant suspension, account deletion
- **Provider + Retry overlap**: duplicated or out-of-order webhooks, a provider outage mid-checkout, a refund arriving after a downgrade
- **Data lifecycle overlap**: export, retention, deletion and audit applied to the same record by different specs
- **3+ feature chains**: any user action that triggers Feature A, which emits an event that Feature B handles, which calls Feature C (the highest-risk interaction paths)

List each identified scenario with a one-line description before proceeding.

### 4b: Walk Through Each Scenario

For each scenario, step through the sequence explicitly:

1. **Trigger** — what user action, provider event or schedule starts this?
2. **Activation order** — which features act, in what sequence, sync or event?
3. **Data flow** — what does each feature output, and is that a valid input for the next (tenant context carried? idempotency key present?)
4. **User experience** — what does the user see, receive by email, or get as an API response at each step?
5. **Failure modes** — are there any of the following?
   - **Race conditions**: two features modifying the same state at once (two admins changing a plan and a member list)
   - **Feedback loops**: Feature A's event triggers B which re-triggers A with no cap (retry storms, notification loops)
   - **Broken state transitions**: a feature assumes a state another feature already changed (acts on a tenant that was just suspended or deleted)
   - **Contradictory messaging**: the user receives conflicting emails/UI from two features reacting to the same event
   - **Compounding limits**: two features both tightening at the same point (downgrade lowers seats and storage and API rate at once, leaving the tenant unable to fix it)
   - **Double effects**: two features reacting to the same trigger with effects that together exceed intent (two credits, two emails, two charges)
   - **Cross-tenant bleed**: an event handler, job or cache key that does not carry the tenant and could act on, or reveal, another tenant's data
   - **Undefined behaviour**: the specs don't say what happens in this combined state (neither feature's rules cover it)

```
Example walkthrough:
Scenario: Payment fails for a tenant while an admin is mid-way through inviting
members

Trigger: provider sends invoice.payment_failed
→ billing.md: marks subscription past_due, starts a 7-day grace period
→ team-invitations.md: assumes "active subscription" before sending an invite;
  does not define behaviour in past_due
→ access.md: restricts writes after 3 days of past_due
  ⚠️  Undefined behaviour: during days 1–3 may an admin send invites that
  would exceed the post-downgrade seat count? Which spec decides? Do invitees
  receive an invite the tenant cannot honour?
```

### 4c: Flag Scenario Issues

For each problem found during the walkthrough, categorize severity:

- **BLOCKER**: undefined behaviour, broken state transition, cross-tenant bleed, or contradictory user messaging — the product is broken, insecure or incoherent in this scenario
- **WARNING**: compounding limits, feedback loops without caps, double effects — it works but produces unintended outcomes
- **INFO**: minor ordering ambiguity or messaging overlap — worth noting but unlikely to cause visible problems

Add all findings to the output report under **"Cross-Feature Scenario Issues"**.
Each finding must cite: the scenario name, the specific features involved, the
step where the issue occurs, and the nature of the failure mode.

---
