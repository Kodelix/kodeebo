# /uat — Phase 2 and 3: The Plan and the Environment

> Part of `/uat`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its headings still apply here.

## 1. Brief for `uat-coordinator`

Fill only the `{…}` slots from Phase 1; add no opinion on the release's quality.

```text
Write the UAT plan for /uat. Follow .claude/agents/uat-coordinator.md.
Release: {id, tag/build, editions shipping, upgrade-from versions}
Stories and specs in scope: {list with design/specs/<feature>.md paths}
Acceptance criteria: read them from the specs; a criterion with no scenario, or a
scenario with no criterion, is listed as a gap in the plan.
Personas and plans: {from design/product-brief.md and design/specs/pricing-model.md, or "absent"}
Already covered by automated tests (do not repeat as UAT): {summary from the QA plan, or "unknown"}
Open bugs in scope: {IDs and severities, or "none on file"}
Stack: {stack line}    Seed data: tools/seed/ (version {..})
Languages: English and Arabic (RTL); Arabic wording is a draft until reviewed.
Write the plan to {production/qa/uat-plan-<release>.md} - that named path is your
write authorisation. Return only (1) the path, (2) a <=5-bullet summary,
(3) BLOCKED/CONCERNS one line each, gaps first.
```

## 2. What the plan contains (`uat-plan-[release].md`)

1. **Header** — release, build/commit, environment, seed version, region, enabled
   flags, plan(s) under test, schedule, exit criteria version and date agreed.
2. **Scope** — covered, and **not covered** with the reason (an edition, a role, a
   feature).
3. **Participants** — by role and organisation, with consent to take part, as
   participant IDs (`P1`, `P2` …). No personal data beyond name and role is stored
   in the repository.
4. **Scenarios** — each a row:

   | ID | Role | Scenario (the user's words) | Starting state | Steps | Observable expected result | Criterion (spec path + ID) | Must-have? | EN | AR |
   |---|---|---|---|---|---|---|---|---|---|

   Example of the register: "As a clinic owner I add a colleague, and she can see
   only her own appointments." No endpoint, table or feature-flag vocabulary.
5. **Scripts per role** — owner, admin, member, and read-only/finance/support if
   the product has them. Each role has **at least one negative scenario**: an
   action it must be refused, with the user-visible message expected.
6. **Money, access and data flows**, when the release touches them: sign-up, plan
   change, invoice or receipt content in local currency and the VAT display rule,
   entitlement limits and the over-limit message, export, deletion. The numbers
   and rules are quoted from the pricing model and specs — never recalled.
7. **Arabic expectations** — number and date formatting, plural forms, mixed-
   direction text and truncated labels, per `localization-lead` guidance and
   `design/localization/`.
8. **Self-hosted scenarios** (when the bundle ships), run as a customer would: install
   from the **signed bundle on a clean host**, **upgrade from the last supported
   version**, **activate a licence**, **restore from a backup**. Each is a must-have.
9. **Exit criteria — numeric and agreed before the first session**, for example:
   100 % of must-have scenarios run; zero open S1/S2; S3 only with an owner and a
   target release. The figures are the user's decision (`AskUserQuestion`); the
   plan states them, the sign-off compares against them.
10. **Gaps** — criteria without scenarios, scenarios without criteria, absent
    inputs.
11. **Arabic review status** — `reviewed by [reviewer, date]` or `unreviewed`.

## 3. Environment

- **Release candidate.** The build under test is the one the release gate sees.
  Record the commit/tag and the build's identity; a rebuild invalidates passed
  scenarios touched by the diff. When sessions have begun and the build changes,
  list the invalidated scenarios from `git diff --stat <tested>...<new>` mapped to
  features; they return to `NOT RUN`.
- **Seeded data.** A dedicated UAT tenant per participant group from `tools/seed/`
  (or factories). Missing seed roles/plans are passed to `dev-tooling-engineer`;
  the UAT environment itself is `infra-engineer`'s — this skill states what it
  needs, it does not build it.
- **No production data.** No production export is loaded. If the user approves
  masked customer-shaped data, record in the plan: the approver, the date, the mask
  rules and the deletion date.
- **Health.** The environment is up and healthy: its readiness endpoint answers
  (`observability-standard.md`), the migrations ran, the build identity matches.
  Only a host the user names is probed, with a single `curl` to its readiness
  endpoint that is **not pre-approved**: the permission prompt shows the host, so
  the user sees what is contacted. Not confirmable → the run is
  `NOT ASSESSED — environment not confirmed`.
- **Self-hosted** scenarios need a clean host with the bundle; if none exists they
  are `NOT RUN — no clean host` and the UAT result cannot be `READY FOR SIGN-OFF`.
- **The smoke result** for the same build is cited from `production/qa/smoke-*.md`
  (run `/smoke-check` through the `Skill` tool if absent; it covers the local stack
  only) — not re-run here.
