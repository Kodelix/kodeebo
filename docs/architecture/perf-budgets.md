# Performance Budgets — Kodeebo

**Status:** approved by the founder, 2026-10-19
**Enforcement:** `performance.enforce: warn` (`project.yaml`). A missed budget is reported, not blocking. A budget with no measurement is "not checked", never "met".
**Standard:** `.claude/docs/performance-standard.md` (DoD gate 6)

## Rules

- **Founder ceiling (2026-10-16): no counter action takes longer than 3 seconds, worst case, on the 4 GB reference PC.** 3 s is a hard maximum, not a p95 target; every counter budget below sits under it. Principle 2 is "the counter never waits".
- **App start-up has its own budget**, separate from counter actions.
- **Reference PC:** no physical 4 GB PC exists (founder, 2026-10-19). Until one does, the proxy is the 4 GB / 2 vCPU Windows 10 22H2 VM with its disk throttled to 100 IOPS + 80 MiB/s (HDD-class random I/O; sequential reads are slower than a real HDD). Every VM number is **indicative only**. The first pilot café's own PC is measured before a release reaches it.
- **Every measurement records its conditions:** hardware, data volume, warm or cold, and build.

## Counter actions (device)

| Action | Budget | Measured so far (VM proxy, indicative) | Evidence |
|---|---|---|---|
| Close bill, from the cashier's action until the print job is handed to the printer driver or port (not until the paper is out) | p95 ≤ 500 ms; max ≤ 3 s. **Not met until the 2.68 s outlier is explained (see below)** | Warm, 200 runs: p50 / p95 / max 201 / 244 / 390 ms (runtime A), 201 / 247 / 392 ms (B). A repeat run had one 2.68 s outlier (A, database part 2.64 s) | desktop spike README, G2 table |
| First close after app start (native layer and printer warmed up at start) | ≤ 1.5 s | 0.66 s (A), 0.87 s (B) | desktop spike README, G2 table, A-F3 |
| Start session, add item | p95 ≤ 200 ms; max ≤ 1 s | not measured: sync spike phase 4 | — |
| End Day, shift close | p95 ≤ 1 s; max ≤ 3 s | not measured: sync spike phase 4 | — |
| Local commit alone (rollback journal, `synchronous=FULL`, commit marker; OQ28 A + B) | p95 ≤ 150 ms; max ≤ 1 s | not measured on the HDD-class disk: phase 4. On the NVMe dev host the journal and marker cost about +24–36% on the spike's suites (indicative) | sync spike README, phase 1 run 2 |
| Counter reads while sync writes (SC-26) | p95 ≤ 100 ms; p99 ≤ 300 ms; max ≤ 3 s. The cashier never sees `SQLITE_BUSY` | not measured: phase 4 | sync note § 9.1.2 SC-26 |

**Two clarifications (founder, 2026-10-19):**
- **Where the close-bill budget ends:** when the print job is handed to the printer driver or port. The printer's own print time (paper out) is measured on the printer day (S50) and recorded separately. It is not part of this budget.
- **The 2.68 s close-bill outlier (runtime A, database part 2.64 s) is open for phase 4.** Phase 4 finds and records its cause (disk flush, garbage collection, antivirus, or something else) before the close-bill budget is called met. A cause that can recur must be fixed, or bounded below 3 s.

## App start-up (device)

| Item | Budget | Measured so far (VM proxy, indicative) | Evidence |
|---|---|---|---|
| Warm launch to first frame | ≤ 2 s | 0.95–1.01 s (A), 0.26–0.29 s (B) | desktop spike README, G2 table |
| App start to ready to sell: store open and integrity check on a 60-day store (about 300,000 money commands; OQ16 × OQ29, derived from capacity) | ≤ 10 s in total, of which the integrity check ≤ 5 s. If the check is slower, the options in SC-24 apply, each re-running TS-03a | Store open 2.6–3.2 s on a small store; 60-day size not measured: phase 4 (SC-24) | desktop spike README (warm-up row); sync note SC-24 |
| Cold boot to first frame | **No number yet.** Measured on the first pilot café's PC before a release reaches it | VM upper bounds 49.0 s (A), 56.7 s (B), inflated by the throttle (G0-F2) | desktop spike README, G2 table |
| Local schema migration after an update | A migration that can exceed 3 s shows an "updating" screen with progress, never a frozen window (founder, 2026-10-19) | A 0.68–4.05 s, B 0.24–0.87 s (20-bill store) | desktop spike G5-F2 |

## Sync

| Item | Budget | Measured so far | Evidence |
|---|---|---|---|
| A closed bill reaches the server while the device is online | p95 ≤ 10 s | not measured end to end: phase 4 | — |
| A dashboard change reaches an online counter | p95 ≤ 5 s with a change signal, and the scheduled pull as fallback. **Proposed: the final number is set in the sync ADR (OQ30)** | not measured: S202 | sync note OQ30 |
| 7-day offline backlog (about 35,000 commands) | Drains within 15 min of total online time on the reference PC, over windows that can end mid-drain, without slowing the counter | Dev host only: SC-25a full size, 3 of 3 runs, 0 violations | sync spike README, SC-25a |
| Server receives one batch (adaptive batch, at most 50 commands) | p95 ≤ 300 ms server time | not measured: backend implementation | sync spike `BATCH_MAX` |

**Load margin (founder, 2026-10-18):**
- **Per bill:** about 50×. The spike's load is about 5,000 closed bills a day, against a measured busy day of about 100 bills (sync note OQ16).
- **Commands per bill:** not measured; measured in the pilot. No command-level margin is claimed until then.

## Server and dashboard

The studio defaults apply until a measurement or a spec tightens them.

| Surface | Budget (p95 unless stated) |
|---|---|
| Read API endpoint | ≤ 150 ms server time |
| Write API endpoint | ≤ 300 ms server time |
| Auth / token refresh | ≤ 200 ms |
| DB queries per request | ≤ 5 on reads, no N+1 ever |
| Single SQL query | ≤ 20 ms; any query > 100 ms is logged with its plan |
| API payload | list pages ≤ 100 items; responses ≤ 200 KB uncompressed |
| Web — LCP / INP / CLS | ≤ 2.5 s / ≤ 200 ms / ≤ 0.1 (p75, field data) |
| Web — initial JS | ≤ 170 KB gzipped for the authenticated shell |
| Service memory | steady-state RSS within the container limit with 30 % headroom, on the 8 GB VPS |

**Note 2026-10-24 (founder; ADR-0015, research `backend-code-conventions` part 4): counting "DB queries per request".** On reads, the gateway lookups (the session lookup and the principal read) count toward the 5, so a use case has 3 business statements. The tenant-scope statements (one per transaction; each also sets `transaction_timeout` and `lock_timeout`) are counted separately under their own cap of 2. A read that cannot fit 3 business statements does not meet this budget and is precomputed or redesigned (ADR-0016). The statement guard of ADR-0016 counts per attempt; request paths run once (`defaultMaxAttempts = 1`).

## Open

- **The reference PC:** the first pilot café's PC replaces the VM proxy for every device number.
- **Phase 4 measures** the "not measured" counter, start-up and sync rows on the VM, and finds the cause of the 2.68 s close-bill outlier.
- **The printer's own print time:** measured on the printer day (S50), recorded separately.
- **The dashboard-to-counter number:** set in the sync ADR (OQ30).
- **Commands per bill:** measured in the pilot.
