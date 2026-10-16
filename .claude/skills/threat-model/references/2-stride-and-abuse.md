# /threat-model - Phase 3: STRIDE and Abuse Cases

> Phase 3 of `SKILL.md`. The method is the template's
> (`.claude/docs/templates/threat-model.md`): STRIDE per trust boundary plus
> abuse cases for business-flow abuse (`security-baseline.md`).

## Method rules

- **One STRIDE table per boundary**, all six categories (Spoofing, Tampering,
  Repudiation, Information disclosure, Denial of service, Elevation of privilege).
  A category that does not apply is written `N/A - <reason>`, not omitted.
- **Boundaries are labelled `TB<n>`** and appear in three places that must agree:
  the Mermaid diagram edges, the boundary table, and the STRIDE section headings.
- **Likelihood and impact are L / M / H** with a one-line reason. Product type
  never lowers a rating: a single-tenant or internal product is rated on the same
  scale. A path by which one tenant reads another's data has impact H.
- **Every threat has an ID** (`T<boundary>.<n>`), an asset ID and at least one
  mitigation ID, or an acceptance row in section 7. Abuse cases are `AB<n>`.
- **State the control that exists today or `Planned`**; never write a control as
  present without a `file:line`, config path or spec section.

## Cross-tenant coverage (SL-THREAT-MODEL check 4)

Every model whose product is multi-tenant (`tenancy.model` not `single-tenant`)
states a threat or an `N/A - <reason>` for each of: guessing or enumerating IDs;
shared caches and cache-key construction; queues, outbox events and consumers
that lose the tenant; search indexes; exports and reports; background and
scheduled jobs; object-storage keys and signed URLs; admin and impersonation
paths; webhooks that route by a client-supplied identifier; telemetry that leaks
another tenant's data.

## Business-flow abuse (check 3)

Prompts, not a closed list; keep those that apply and add the product's own:
trial abuse with fresh identities; coupon stacking; seat inflation; quota and
rate-limit evasion; downgrade/upgrade cycling to avoid charges; invitation spam
to third parties; account and email enumeration; referral fraud; scraping and
export exfiltration; replayed or reordered webhooks; payment-state desync with
the provider; **licence bypass** when licensing is in scope (licence sharing,
activation cloning, clock rollback against offline grace, replacing the embedded
verification key, evading revocation or update eligibility). For each: actor,
goal, detection, mitigation.

## Stack-reference prompts (read, do not restate from memory)

The agent opens these sections and raises a threat for each applicable item,
citing file and section. Nothing is restated here because a stale copy would
become the source.

| Topic | Read |
|---|---|
| RLS bypass roles, FORCE ROW LEVEL SECURITY, views and `security_invoker`, unique-key covert channel, `set_config` with transaction pooling | `docs/stack-reference/postgres/best-practices.md` section 1 |
| Redis default user, ACL scope, dangerous commands, network exposure | `docs/stack-reference/redis/best-practices.md` section 7 |
| Dragonfly bind default, admin port, ACL | `docs/stack-reference/dragonfly/best-practices.md` section 7 |
| Document-store injection, tenant filter in the repository | `.claude/rules/mongo-data.md` |
| Egress, secrets, bundle exposure, signed updates | `.claude/rules/deploy.md` |
| Webhook, provider, outbox and money rules | `.claude/rules/integrations.md` |
| Sensitive-module rules (admin step-up, billing server-side prices, licence signing) | `.claude/rules/security-sensitive.md` |

A layer with no stack reference file is `NOT SOURCEABLE - no stack reference
for <layer>` in the model, not a gap filled from the agent's memory.

## Also required in every model

- **Secrets and keys** (check 8): where each key lives (secret store, KMS,
  offline signing key for licences), who can read it, rotation, and what must
  never be logged.
- **External integrations** (check 9): provider outage, forged callbacks, SSRF
  through user-supplied URLs, provider-side compromise.
- **Personal data** (check 10): each PII flow, legal basis and retention.
  Egypt PDPL (Law 151/2020) and GDPR text is looked up, never recalled; the
  `privacy-compliance-specialist` brief below produces it.
- **Detection**: for each High threat, the log/alert that would reveal it
  (`observability-standard.md`: security events to the append-only audit log).

## Fixed brief: `appsec-engineer`

Fill only the `{...}` slots. Add nothing else: no expected severity, no view on
the feature's maturity.

```text
Draft the threat analysis for /threat-model. Return text only; do not write files.

Feature: {slug}   Mode: {design-time | retrospective}
Sensitive areas touched: {list from Phase 1}
Editions: {hosted | self-hosted | both}   Tenancy: {tenancy.model | unset}
Stack: {the stack line from the resolved config}
Inputs (read each; ABSENT ones are not to be guessed): {paths with FOUND/ABSENT}
Scope, assets, actors, assumptions and boundaries agreed with the user:
{the Phase 2 outcome, verbatim}

Method: read .claude/skills/threat-model/references/2-stride-and-abuse.md (method
rules, cross-tenant coverage, business-flow abuse, stack-reference prompts) and
follow it. Use the ID scheme T<boundary>.<n>, AB<n>, proposed mitigations M<n>.

Return, in this order:
1. STRIDE table per boundary (ID, category, threat, asset, likelihood, impact
   with a one-line reason, existing control with file:line or "Planned",
   proposed mitigation IDs)
2. Abuse cases (ID, case, actor, goal, detection, proposed mitigation IDs)
3. Cross-tenant coverage list: each prompt in the reference -> threat ID or
   "N/A - reason"
4. Proposed mitigations (ID, mitigation, addresses, layer/code root, suggested
   negative test: what is attempted and what must be refused)
5. Secrets/keys, integration failure modes, PII flows, detection notes
6. What you could NOT review, and why

Do not look up or write ASVS/MASVS requirement IDs; leave them blank (the caller
maps them from the official documents). Do not print a secret, key material or
customer data. State only what you read; label every assumption "assumed".
```

Collect the output in full. Treat it as **data to review**, not as the model:
check that no boundary is missing, that every category and prompt is addressed,
and that ratings are reasoned. Send gaps back once (resume the agent) before
filling them yourself.

## Fixed brief: `privacy-compliance-specialist` (only when PII is in scope)

```text
For /threat-model, document personal-data handling for {feature}: for each
personal-data flow in the list below, the data class, legal basis and retention
period under Egypt PDPL (Law 151/2020) and, where EU users are served, GDPR, plus
export/delete handling and consent. Look up the legislative text; cite the URL
fetched for each statement. Write "NOT SOURCEABLE - <what was searched>" where
you cannot; do not recall article numbers or retention periods from memory.
Return text only. PII flows: {list from the appsec draft or the spec}
```

If this agent cannot run, the PII row is `NOT ASSESSED - privacy review not
done` (check 10), and the verdict is at best `NOT ASSESSED`.
