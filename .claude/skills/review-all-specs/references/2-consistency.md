# /review-all-specs — Phase 2: Cross-Spec Consistency

> Part of `/review-all-specs`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 2: Cross-Spec Consistency

**In this file:**

- 2a: Dependency Bidirectionality
- 2b: Rule Contradictions
- 2c: Stale References
- 2d: Data Ownership, Tenancy and Configuration Conflicts
- 2e: Contract, Event and Formula Compatibility
- 2f: Acceptance Criteria Cross-Check
- 2g: Permission Model Consistency

Work through every pair and group of specs to find contradictions and gaps.

### 2a: Dependency Bidirectionality

For every spec's Dependencies section, check that every listed dependency is
reciprocal:
- If Spec-A lists "depends on Spec-B", check that Spec-B lists Spec-A as a dependent
- If Spec-A lists "depended on by Spec-C", check that Spec-C lists Spec-A as a dependency
- Flag any one-directional dependency as a consistency issue
- A spec whose Dependencies section is absent (optional at `standard`) is reported
  as `no Dependencies section — reciprocity not checked`, not as reciprocal

```
⚠️  Dependency Asymmetry
[feature-a].md lists: Depends On → [feature-b].md
[feature-b].md does NOT list [feature-a].md as a dependent
→ One of these documents has a stale dependency section
```

### 2b: Rule Contradictions

For each rule, state machine or constraint defined in any spec, check whether any
other spec defines a contradicting rule for the same situation:

Categories to scan:
- **Limits and floors**: Does any spec define a minimum or maximum? Does any other say a different feature can bypass it? These contradict.
- **Lifecycle ownership**: if two specs both define how a shared object (subscription, tenant, membership, invitation) moves between states, do they agree on states, triggers and who may transition it?
- **State transitions on shared events**: if Spec-A describes what happens when a user is removed or a tenant is suspended, does Spec-B's description of the same event agree?
- **Timing and ordering**: if Spec-A says "revoke happens synchronously", does Spec-B assume it is eventual? Webhook-versus-poll assumptions that differ?
- **Stacking and precedence**: if Spec-A says discounts/trials/limits stack, does Spec-B assume they don't? Which wins on a tie?
- **Retention and deletion**: if Spec-A keeps data for 30 days after cancellation and Spec-B assumes immediate deletion, these contradict.

```
🔴 Rule Contradiction
[billing].md: "On cancellation access continues until period end"
[team-workspaces].md: "A cancelled tenant's members are signed out immediately"
→ These rules directly contradict. Which spec is authoritative?
```

### 2c: Stale References

**Start from the `## Cross-References` table where a spec has one.** That table is
the document's own declaration of what it depends on — `templates/feature-spec.md`
tells authors it is machine-checked here, and `/design-spec` requires it whenever
Dependencies or any rule names another spec. For each row, confirm the `Target Spec`
exists and the `Specific Element Referenced` is still present in it under that
name, with the declared `Nature` still accurate.

A table that is absent, or still holding the template's bracketed examples, is
itself reportable: say the spec declares no cross-references and that the prose
scan below was the only check applied. Do not treat an absent table as "no
dependencies" — it far more often means the section was never authored.

**Then scan the prose regardless**, table or no table: a declared table catches
what the author remembered, and the scan below catches what they did not.

For every cross-document reference (Spec-A mentions an entity, entitlement,
endpoint, event or rule from Spec-B), verify the referenced element still exists in
Spec-B with the same name and behaviour:

- If Spec-A says "seat limit comes from the plan", check that the pricing model /
  billing spec actually defines that entitlement under that key
- If Spec-A consumes an event "subscription.cancelled", check that its producer
  spec emits it with that name and payload
- If Spec-A was written before Spec-B and assumed an endpoint or rule that Spec-B
  later designed differently, flag Spec-A as containing a stale reference.
  Severity: a reference to an element that **does not exist** is **Blocking** —
  the architecture would inherit a rule nobody defined; one that exists but was
  designed differently is a **Warning**, unless the difference changes a rule the
  referencing spec depends on (then Blocking)
- If the **target spec is not written yet** (no file in `design/specs/`): when
  `domain-map.md` lists that feature (e.g. `Status: Not Started`), it is a
  **Warning** — a dependency on planned work, to re-check when that spec is
  written; when neither a spec nor a domain-map entry exists for it, it is
  **Blocking** — nothing will ever define it

```
🔴 Stale Reference
team-invitations.md (written first): "Seat count comes from the `max_seats`
  entitlement"
billing.md (written later): Defines `member_limit` as a plan quota and no
  `max_seats`
→ team-invitations.md references an entitlement that doesn't exist — Blocking
```

### 2d: Data Ownership, Tenancy and Configuration Conflicts

**Data ownership.** An entity or table has exactly one owning context. Scan every
Data & Contracts / Entities table (and the registry) and flag:
- the same entity defined by two specs (different owners, or the same owner described twice with different fields);
- a spec that writes to, or reads from the tables of, an entity owned by another context instead of going through that owner's port or events;
- an entity in the spec that the domain map's "Ownership & Data Boundaries" table assigns elsewhere.

**Tenancy assumptions.** Compare each spec's tenancy stance — tenant key on every
entity, tenant-scoped vs global, how the tenant context reaches the feature, what
"other tenant" returns — against the project's `tenancy.model` and against each
other:
- an entity with no tenant key in one spec but treated as tenant-scoped in another;
- one spec assuming a user belongs to exactly one tenant, another allowing many;
- one spec assuming per-tenant data stores or schemas, another assuming shared tables with RLS;
- a global/platform-level entity (plans, licences, platform admin) read by a tenant-scoped feature without a stated access path.
If `tenancy.model` is not configured, report the comparison as spec-versus-spec
only and say the model could not be checked.

**Configuration and quota ownership.** Scan all Configuration tables and abuse
limits and flag duplicates:

```
⚠️  Ownership Conflict
[feature-a].md Configuration: "invite_rate_limit — caps invitations per hour per tenant"
[feature-b].md Configuration: "invitations_per_hour — limits invites per hour per actor"
→ Two specs define limits on the same action. Which owns the final value?
  This will produce either a double-enforcement bug or a conflicting limit.
```

### 2e: Contract, Event and Formula Compatibility

- **Events**: every consumed event has a producer spec; payload fields a consumer relies on exist in the producer's payload; delivery guarantees are compatible (a consumer assuming exactly-once from an at-least-once producer).
- **Endpoints**: two specs defining the same method+path, or the same resource under different paths; error `code` names that mean the same thing but differ.
- **Formulas**: for specs whose formulas are connected (the output of one feeds the input of another), check that the upstream output range is within the downstream input range, rounding conventions agree (minor units, half-even), and currencies/periods match.

Flag incompatibilities as CONCERNS (judgement needed, not necessarily wrong):

```
⚠️  Formula Range Mismatch
[billing].md: proration rounds half-even to minor units
[invoicing].md: totals computed from unrounded per-day amounts
→ Invoice total can differ from the charged amount by one minor unit.
  Is this intentional? If not, one spec's rounding rule needs aligning.
```

### 2f: Acceptance Criteria Cross-Check

Scan Acceptance Criteria sections across all specs for contradictions:

- Spec-A criteria: "A Starter tenant can invite up to 5 members"
- Spec-B criteria: "A Starter tenant is limited to 3 seats"
These criteria cannot both pass simultaneously.

Also flag a criterion in one spec that is unreachable because another spec removes
the precondition (for example "an admin can transfer ownership" when the identity
spec defines no transfer).

### 2g: Permission Model Consistency

Build one table from the "Permissions per Role" matrices across all specs: role names
used, and for each shared resource the action × role cells. Flag:
- a **role name used by a spec that the identity/access spec does not define** (or defined with different semantics: "Admin" meaning tenant-admin in one spec and platform-admin in another);
- the **same action** granted to different roles by two specs (for example `members.remove` is Admin-only in one and Owner-only in another);
- a **cross-tenant cell that is not 404** (403 leaks existence) or an anonymous cell that is not 401;
- an action present in one spec's UI/flow description but absent from every permission matrix.

```
🔴 Role Mismatch
[team-invitations].md: roles Owner / Admin / Member
[admin-console].md: roles Superuser / Support / Customer
→ No spec maps Support to a tenant role or defines impersonation scope.
  Permission semantics undefined across the two specs.
```

---
