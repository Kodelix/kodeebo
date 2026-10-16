# /review-all-specs — Phase 3: Product Holism

> Part of `/review-all-specs`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 3: Product Holism

**In this file:**

- 3a: Permissions versus Plans
- 3b: Duplicated Capabilities (and `saas-core` candidates)
- 3c: Quota and Entitlement Collisions
- 3d: Onboarding and Attention Budget
- 3e: Abuse and Loophole Detection
- 3f: Principle Alignment
- 3g: Pricing, Edition and Journey Coherence

Review all specs together through the lens of product design and SaaS packaging.
These are issues that individual spec reviews cannot catch because they require
seeing all features at once.

### 3a: Permissions versus Plans

Build the plan × capability grid from every spec's Plan/pricing impact and
entitlement keys, then check it against the permission matrices:
- a capability that a role can use on a plan that does **not** include it (a spec grants `export.create` to Members but the pricing model gates export to the Team plan, and no spec states the denial behaviour);
- a capability a **plan promises** (pricing model, brief) that no spec implements, or implements for a narrower role set than the plan page would promise;
- an entitlement key referenced by a spec that the pricing model does not define, or defined by two specs with different meanings;
- two specs that disagree on **what the denial looks like** (403 vs 402/422 `plan_limit_reached` vs hidden UI) for the same gated capability.

```
⚠️  Permission / Plan Mismatch
reports.md: "Members can create scheduled reports" (no plan gate stated)
pricing-model.md: scheduled reports are Team-plan only
→ Starter members may reach a Team-only capability, or the spec omits the gate.
```

### 3b: Duplicated Capabilities (and `saas-core` candidates)

Scan for capabilities specified in more than one feature, or specified in a
feature that `saas-core` is meant to provide (identity, OTP, notify, storage,
billing, licensing, tenancy, audit, ratelimit, observability):

- the same behaviour re-specified in two features (two notification-preference models, two file-upload pipelines, two audit trails, two invitation flows for different object types);
- a feature that defines its own sign-in step, OTP, email/SMS sending, subscription lifecycle, licence check or file storage rather than consuming the core module;
- a pattern now needed by three or more features that is not yet a module: report it as an **extract-candidate** for `/core-extract`, not as a defect.

Before reporting a capability as "belongs in core", ask `principal-engineer` whether a released module already covers it (or state `core pin not readable` if `core.version` is unset); "in core" is a claim about a repo this review has not necessarily read.

```
⚠️  Duplicated Capability
team-invitations.md: defines email delivery with its own template store and retry policy
billing.md: defines email delivery with a second retry policy for dunning notices
→ Two specs reimplement notification delivery. Consume the core `notify` module
  from both, or extract a shared one — do not keep two.
```

### 3c: Quota and Entitlement Collisions

Identify every limit across all specs (seats, storage, requests, projects,
exports, retention, API rate limits, trial length) and map each to its **owner**
(the pricing model or the one spec that defines it) and its **enforcers** (each
spec that checks it). Flag:

| Condition | Sign | Risk |
|-----------|------|------|
| **Same limit, two definitions** | Two specs name or size it differently | Inconsistent enforcement; support tickets |
| **Enforced, never defined** | A spec checks a quota no spec or plan defines | Unreachable or hardcoded value |
| **Defined, never enforced** | A plan promises a limit no spec enforces | Free capacity; revenue leak |
| **Limit conflict across features** | Total of sub-quotas exceeds the parent quota, or two features draw on the same pool with different accounting | Surprising denials |
| **Downgrade gap** | A downgrade lowers a limit and no spec defines what happens to data/users above it | Data loss or silent overage |
| **Tier cliff** | Quota jumps so that a plan is unreachable or never rational | Dead plan |

```
🔴 Quota Conflict
team-workspaces.md: "Starter allows 3 members" (counts pending invitations)
team-invitations.md: "Seat limit counts accepted members only"
→ The same limit is counted two ways. A tenant can be over or under the limit
  depending on which feature checks it.
```

### 3d: Onboarding and Attention Budget

Walk the first-run journey the specs imply (sign-up → verify → create tenant →
first value → invite → pay). Count the **required steps and decisions** before a
new user reaches the core job, and the number of simultaneously active surfaces
(modals, setup checklists, banners, tours) that specs add:

- more than ~5 required steps before first value, or required steps that two specs each add independently, is a time-to-value risk;
- a setup checklist item with no owning spec, or two specs both showing a blocking banner on the same screen;
- every spec requiring its own onboarding step with no coordination.

```
⚠️  Onboarding Load Risk
Required before first value: verify email (identity) → create workspace
(tenancy) → choose plan (billing) → connect provider (integrations) →
import data (core) → invite team (invitations)
→ 6 required steps. Which can be deferred or made optional?
```

### 3e: Abuse and Loophole Detection

Look for ways a user or tenant can obtain value outside the intended plan or
boundary, using only what the specs say:
- trial abuse (repeat sign-ups, a trial restarted by deleting and recreating a tenant, a trial that gates nothing useful);
- coupon / discount stacking across billing and growth specs;
- seat inflation (invite-accept-remove loops that evade seat counts, or counts that exclude certain roles);
- a free path to a paid capability through another feature (export via reports, API access via an integration, a paid limit bypassed by the public API);
- enumeration surfaces: two specs that answer differently for "exists but forbidden" versus "does not exist";
- a cancelled/suspended tenant that retains access through a feature that checks a different state.

Each finding names the path through two or more features. A loophole inside one spec belongs to `/spec-review`.

### 3f: Principle Alignment

Every feature should serve at least one product principle. A feature that serves
none is scope creep by design. For each spec, check its User Value (or Overview)
against the principles and the domain map's tier:
- a feature serving no principle, and not required by another feature, is flagged;
- check anti-principles: flag any spec that does what an anti-principle says the product will NOT do.

```
🔴 Anti-Principle Violation
Anti-principle: "We will NOT require a call with sales to start" (self-serve first)
enterprise-onboarding.md: requires a sales-approved activation step for all plans
→ This spec directly violates the defined anti-principle.
```

If no principles are defined, report: "Principle alignment not checked — no
`design/product-principles.md`." (This is a NOT ASSESSED trigger for 3f only; see Phase 5.)

### 3g: Pricing, Edition and Journey Coherence

- **Pricing coherence**: do the plans described in specs and the brief form a ladder a customer can reason about (each step adds something real), or does packaging differ between specs? Does any spec restate a price (a violation of `.claude/rules/specs.md`)?
- **Edition coherence** (`distribution.model` hosted / self-hosted / hybrid): features that behave differently in the self-hosted bundle (licence claims, no outbound calls, offline grace) — are the differences stated, consistent across specs, and backed by a licensing spec? A hosted-only assumption (managed provider, shared infrastructure, central telemetry) in a feature the brief promises to self-hosted customers is a finding.
- **Journey coherence**: do the specs agree on who the customer is (buyer vs. user vs. admin) and on the unit of billing (seat, tenant, usage) — or do two specs imply different units?

```
⚠️  Billing Unit Conflict
billing.md: charges per seat
usage-metering.md: meters API calls and bills overage per tenant
→ Two units of billing with no spec defining how they combine on one invoice.
```

---
