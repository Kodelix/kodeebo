# /architecture-review — Phase 4: Cross-ADR Conflict Detection

> Part of `/architecture-review`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 4: Cross-ADR Conflict Detection

Compare every ADR against every other ADR (and against `docs/registry/architecture.yaml`
when it exists) to detect contradictions. A conflict exists when:

- **Data ownership conflict**: Two ADRs claim exclusive ownership of the same data, or one reads another context's tables
- **Integration contract conflict**: ADR-A assumes a context has interface Y, but
  ADR-B defines that context with a different interface (port, event, `contracts/` shape)
- **Performance budget conflict**: ADR-A allocates N ms of a request budget to one
  hop, ADR-B allocates another, together they exceed the endpoint's p95 in `perf-budgets.md`
- **Dependency cycle**: ADR-A needs X decided before Y; ADR-B needs Y before X
- **Architecture pattern conflict**: ADR-A uses event-driven communication for a
  context; ADR-B uses direct calls to the same context
- **Tenancy conflict**: ADRs disagree on how tenant context is established or
  enforced (app-layer only vs RLS vs schema per tenant), or one ADR adds a store or
  cache path that bypasses the tenancy ADR
- **Consistency/state authority conflict**: Two ADRs define authority over the same
  state (e.g. both Billing and Identity ADRs claim to own the plan or entitlements)
- **Edition conflict**: an ADR that works hosted but breaks the self-hosted bundle
  against another ADR that promises both editions (detail in Phase 5)
- **Server-authority conflict**: an ADR makes a client-computed derived value
  authoritative (price, total, stock effect, entitlement), or leaves unversioned
  server data that an offline client may have computed from, against
  `.claude/docs/security-baseline.md` § Server authority. Check every ADR for this
  even when no second ADR contradicts it; name the baseline as "ADR-MMMM"

For each conflict found:

```
## Conflict: [ADR-NNNN] vs [ADR-MMMM]
Type: [Data ownership / Integration / Performance / Dependency / Pattern / Tenancy / State / Edition / Server authority]
ADR-NNNN claims: [...]
ADR-MMMM claims: [...]
Impact: [What breaks if both are implemented as written]
Resolution options:
  1. [Option A]
  2. [Option B]
```

### ADR Dependency Ordering

After conflict detection, analyse the dependency graph across all ADRs.

**Build the graph deterministically — do not trace it by hand:**

```
Bash: bash .claude/scripts/adr-dep-graph.sh
```

It collects every `Depends On` edge, runs Kahn's algorithm, and emits
`ADRS:` / `EDGES:` / `NO_DEPS_SECTION:` / `CYCLE:`. A model tracing A→B→C→A across
a dozen ADRs eventually misses an edge; the algorithm cannot. It reports
observations, not a verdict — you apply the meaning below.

**`NO_DEPS_SECTION` is load-bearing**: it makes "no cycles because the graph is
clean" distinguishable from "no cycles because half the ADRs declare no
dependencies". Report the second case as a structural gap, never as a clean graph.

Then interpret:

1. **Topological sort**: the emitted order — ADRs with no
   dependencies come first (Foundation), ADRs that depend on those come next, etc.
2. **Flag unresolved dependencies**: cross the `EDGES:` list against the `## Status`
   values already scanned in Phase 1b. If ADR-A depends on an ADR that is still
   `Proposed` or does not exist, flag it:
   ```
   ⚠️  ADR-0005 depends on ADR-0002 — but ADR-0002 is still Proposed.
       ADR-0005 cannot be safely implemented until ADR-0002 is Accepted.
   ```
3. **Cycle detection**: every `CYCLE:` line the script emitted is a
   `DEPENDENCY CYCLE` — report each one. Do not re-derive them by hand:
   ```
   🔴 DEPENDENCY CYCLE: ADR-0003 → ADR-0006 → ADR-0003
      This cycle must be broken before either can be implemented.
   ```
4. **Output recommended implementation order**:
   ```
   ### Recommended ADR Implementation Order (topologically sorted)
   Foundation (no dependencies):
     1. ADR-0001: [title]
     2. ADR-0003: [title]
   Depends on Foundation:
     3. ADR-0002: [title] (requires ADR-0001)
     4. ADR-0005: [title] (requires ADR-0003)
   Feature layer:
     5. ADR-0004: [title] (requires ADR-0002, ADR-0005)
   ```

---
