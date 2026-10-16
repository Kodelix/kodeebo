# /prototype — Spike Mode

> Part of `/prototype`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

**Triggered by:** `--spike` flag OR "Mid-build spike" entry choice in Phase 1.

**Purpose:** Test a specific technical or design question mid-build, without the
overhead of a full concept prototype workflow. No spec prerequisites. No phase-gate
implications. Hard cap: ~4 hours.

**When to use:**
- You're building and want to test whether a feature approach should be added
- You're unsure if a technical approach will work before building it properly (a query shape, a sync scheme, a library, a provider endpoint)
- A design change is being considered and you want a quick before/after comparison
- A spec'd feature is proving harder than expected and you want to prototype the hard part
- You need to confirm the target infrastructure can sustain the required load before writing the feature (**performance spike** — see below)

**Spike Mode workflow (replaces Phases 1–9):**

1. **Define the spike question** (plain text, not a widget): "What specific question does this spike answer? Give me one sentence: 'Can we [do X] using [approach Y]?'" Name the budget or threshold that would count as YES (a number from `docs/architecture/perf-budgets.md` where one exists).

2. **Choose path** — same `AskUserQuestion` widget as Phase 3 (mock / spike / concierge / paper).

3. **Scope** — maximum 2–3 bullet points. One question, nothing else.

4. **Build** — first ask "May I create `prototypes/[name]-spike-[date]/` and build the spike there?" Same relaxed standards, README and header as the concept prototype, same safety rules (sandbox credentials only, `127.0.0.1`, no real data). Hard cap: 4 hours. If not demonstrable in 4 hours, the question is too large. Split it. If the user declines the directory, build nothing and stop with `NOT ASSESSED — spike directory declined by user`.

5. **Observe and decide** — no formal debrief. Ask: "Did the spike answer the question? YES or NO, and why in one sentence — with the number if there is one." A result with no observation is `NOT ASSESSED`, not YES.

6. **Write a spike note** (not a full report) to `prototypes/[name]-spike-[date]/SPIKE-NOTE.md` — first ask once for this step and the next, naming both files: "May I write `prototypes/[name]-spike-[date]/SPIKE-NOTE.md` and clear the spike from `production/session-state/active.md`?" The note holds:
   - Question tested
   - Result (YES it works / NO it doesn't / PARTIAL — needs more investigation / NOT ASSESSED — not run) with the measurement **and its conditions** (data volume, hardware, warm/cold, command)
   - Security or tenancy surprises (or `none observed`)
   - What to do next (add to the current sprint — at `workflow: minimal`, the brief's build order — / investigate further / abandon the idea) and whether `/research` is needed before the real build

7. **Update `production/session-state/active.md`** per `.claude/docs/checkpoint-handoff.md` to clear the spike and return to the current sprint state (at `workflow: minimal`, the story in progress): Current task `/prototype --spike <name> — <result>`, Next step = the spike note's "what to do next", plus Blocked on / Files in progress / Open questions; append the Notes line. A `NOT ASSESSED` spike or a declined note still updates it with the blocker.

**No product-director gate. No phase gate. No PROCEED/PIVOT/KILL.** Spike results
inform decisions; they don't make them.

**Performance spike (special case):** if the feature involves demanding load —
large tenants, bulk imports, heavy aggregation, many concurrent connections — run a
performance spike before writing the feature to confirm the stack can meet the
budget. Distinct from other spikes:
- The question is "can [query / endpoint / job] hold p95 ≤ [budget] with [N rows, M tenants, C concurrent] on [instance size]?"
- The output is a benchmark number (`EXPLAIN (ANALYZE, BUFFERS)`, a k6 summary), not an opinion
- Generate representative data (volume and skew), run warm, and record the setup; a number from a toy dataset is `indicative only`
- If the answer is NO at this scope, it is an architecture or scope constraint that affects everything downstream — surface it now, and route it to `/architecture-decision`

---
