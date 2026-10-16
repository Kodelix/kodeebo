# DoD Effort Table

What each Definition of Done gate (`.claude/docs/coding-standards.md`) adds to an
estimate. Use as multipliers of the *build* effort of the lane, not as padding.
Ranges are starting points — calibrate against `production/retrospectives/`
estimation-accuracy tables when they exist, and say so in the estimate.

## By story type (evidence on top of build effort)

| Story type | Evidence to budget | Typical add-on to build effort |
|---|---|---|
| **Logic** | Unit tests on domain and use cases | +25–40% |
| **Integration** | Testcontainers tests on the real PG / Mongo / Redis / Dragonfly; provider sandbox or WireMock fixtures | +40–70% |
| **Contract** | OpenAPI/proto change, generated clients, consumer contract test per consumer | +30–50% per consumer |
| **Security** | Negative tests (authz bypass, cross-tenant, injection, rate limit, replay), ASVS/MASVS mapping lookup, dependency scan, threat-model update | +50–100% |
| **Performance** | Load-test script (k6), budget comparison, query-count assertion, evidence file | +50–100% |
| **UI** | Component/E2E test, screenshots (desktop + mobile, Arabic RTL + English), `/impeccable audit` fixes | +40–70% |
| **Config** | Smoke check | +10–20% |

## Gate-by-gate items (budget when the story touches the gate)

| Gate | What to budget | Skip only when |
|---|---|---|
| 1 Research first | Research note from primary sources at pinned versions: 0.5–2 days for a new feature, 1–3 for a new provider or auth/billing/licensing | Research-exempt per `research-protocol.md` (bug fix in researched code, copy, styling, config value) |
| 2 Clean architecture | Ports/adapters split, fakes for use-case tests | Never — included in build |
| 3 Tests | Per story type above | Never scaled down by `qa.level`: Logic, Integration, Contract and Security tests exist and pass at every tier. `qa.level` changes only the extra evidence (manual cases, coverage signal, UAT) |
| 4 Observability | Span, RED metrics, structured logs with `trace_id`, no PII; one retained trace | Never for an endpoint or job |
| 5 Caching | Written cache decision (pattern, key schema, TTL, invalidation, stampede) or the written reason for none | Never — "no cache" still needs its sentence |
| 6 Performance | Budget lookup in `docs/architecture/perf-budgets.md`, N+1 check, load test on hot paths | Not a hot path — say why |
| 7 Security | ASVS/MASVS IDs, negative tests, tenant-isolation test, dependency scan; threat model for sensitive areas | Never waived by the model on a security-sensitive story |
| 8 Decision record | ADR (or decision-log entry at `minimal`) per architectural decision | No architectural decision made |
| Run and observe | Bring the stack up, call as each role, screenshots, trace; 0.5–1 day per user-visible slice | Never — not waived at any `qa.level` |

## Lane-specific notes

- **Backend (Go / Ktor):** migration stories add expand/migrate/contract steps and a rollback note; hot tables need a lock plan. Self-hosted products add a multi-version upgrade check (`migration-specialist`).
- **Web:** Arabic/English and RTL screenshots double the screenshot effort; each new screen carries an `/impeccable audit`.
- **Mobile:** add emulator/simulator observation time, and store-review lead time (calendar, not effort) for any release-bound story. KMP shared-module changes touch both app lanes.
- **Contracts:** estimate once; every consumer lane carries its own contract-test day.
- **Platform / deploy:** a change to the compose bundle is also a change to the self-hosted installer; budget the licence-rule review (`.claude/rules/deploy.md`).
