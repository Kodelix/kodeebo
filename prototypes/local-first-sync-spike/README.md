<!-- PROTOTYPE - NOT FOR PRODUCTION -->
<!-- Question: Does local-first sync ever lose or double-count money or session time under faults? (phase 0: can the harness detect it?) -->
<!-- Date: 2026-10-16 -->

# Prototype: local-first sync spike

**Status:** in-progress — phase 0 gate PASS; phase 1 gate PASS on run 2 after the OQ28 fix (run 1 failed: WAL silent loss P1-F1); phase 2 gate PASS (run 2 on committed harness `be3f49e`: 50 seeds per cell, 3,000 campaign runs, 0 violations); phase 3 in progress — SC-19 (server restore) PASS on committed harness `a65d6f8`; SC-20 (disk full) PASS on committed harness `daac687`; SC-21a (app update) PASS on committed harness `128cdea`; SC-22 (two instances) PASS on committed harness `db53f27` (tamper suite fixed in `74fac52`); SC-23 (prices while offline, widened rule 2, no-price-list refusal) PASS on committed harness `8cc8df6`; SC-25a (7-day backlog over cut windows) PASS on committed harness `a5900db` (phase 2 regression fixed in `be11ae1`); SC-25b (N5 lease expiry) PASS on committed harness `04996e2`; SC-28 (dashboard edit of an open bill) PASS on committed harness `a77dfa3`, finding P3-F10; SC-29 (stock policy per item) PASS on committed harness `6e2ecff`; SC-30 (device off while sessions run, mechanics) PASS on committed harness `c23f137`; SC-31 (End Day) PASS on committed harness `56c8dbc`; SC-13 + TS-01a (cloned disk, rollback, OQ7 policy) PASS on committed harness `245ddde`; TS-07a (clock change during an open session) PASS on the dev run, finding P3-F12; remaining phase 3 legs in order A (founder, 2026-10-18): TS-02a/b, S207, TS-01b with TS-10, S206 with TS-03b and TS-06a/b, then the compound-fault campaign as the gate (S109 not run: key custody not ready);, SC-31 and SC-13 + TS-01a next
**Risk tested:** `design/product-brief.md` risk 1, the product's top-ranked risk: "Local-first sync never loses or double-counts money or time".
**Plan:** `docs/research/local-first-sync.md` § 9.1 (phases), § 9.1.1 (tamper scenarios TS-01–TS-10, invariant I10) and § 5.1.5 (Part E: invariants I1–I9, fault points P1–P12, scenarios SC-01–SC-18, pass/fail rules).
**Path:** code spike (feasibility).

This code is throwaway (`.claude/rules/prototype-code.md`). Nothing here is imported by production code, and if the idea proceeds the production code is written from scratch. The spike does **not** choose the stack: Python is used for the harness because it is not a product language, and the Go server stub is a stand-in, not a backend decision.

## Cap waiver (founder, written, 2026-10-16)

`/prototype` caps a concept prototype at 1 day. The founder waived that cap for this spike, in these words:

> "I accept the longer timebox in writing: the sync spike tests brief risk 1, the product's top risk; each phase has a pass/fail gate and stops on the first failure."

- **Risk it tests:** brief risk 1.
- **Planned length:** about 6–9 working days on Linux (phases 0–3, plus phase 5 once Part D's billing rules exist), and phase 4 on Windows once the Windows image exists.
- **Gate per phase:** each phase below has a pass/fail gate.
- **Stop rule:** **stop at the first failed gate.** The 2-hour reframe rule applies inside each phase.

| Phase | Question | Gate |
|---|---|---|
| 0 | Can the harness catch planted bugs? | Every mutant caught; the correct stub passes ≥ 300 seeded runs with 0 violations; every failure replays from its seed |
| 1 | Is "bill closed + outbox row" atomic on the encrypted store under process kill? Tamper TS-03a, TS-04a, TS-05a | 0 violations over every fault cell × ≥ 50 seeds; tamper pass signals |
| 2 | Exactly one effect per action under network faults, resend, duplicate replay, concurrent retry and server kill (real PostgreSQL 18.6) | 0 violations; ≥ 3,000 randomized runs |
| 3 | Compound faults, reordering, partial batch, restored backup, cloned disk, re-bootstrap; tamper TS-01, TS-02, TS-03b, TS-06a/b, TS-07a, TS-09, TS-10; added cases SC-19 (first), SC-20, SC-21a, SC-22, SC-23, SC-25a and SC-25b mechanics (table below) | 0 violations; ≥ 3,000 runs (30,000 stretch); tamper pass signals; each added case's pass signal |
| 4 | Windows 10/11 durability and tamper legs; added cases SC-21b, SC-24, SC-26, SC-27 | per § 9.1 / § 9.1.1 / § 9.1.2; measured against `docs/architecture/perf-budgets.md` (founder ceiling: no counter action over 3 s, worst case, on the 4 GB reference PC) |
| 5 | Day-close totals and tampered clocks; SC-25b with the real N5 rules. Runs without S308 (server billing parity): **PARKED, trigger: the backend-track decision** (founder, 2026-10-18). The tax order is a configurable inclusive/exclusive setting until ETA answers | per § 9.1 / § 9.1.2 |
| PowerSync track | Does PowerSync fit (sync note Part A, S1–S4)? **Order (founder, 2026-10-17):** after the phase 3 gate passes, not in parallel. S2–S4 on Linux right after the gate; S1 on Windows inside phase 4. The FSL counsel reading (sync note OQ2) is **closed by founder statement (2026-10-18)**: counsel found no issues, and the tech/IP counsel brief is no longer drafted. The product's own licence obligations still apply (third-party notice file) | Part A's pass conditions |

**Order (founder, 2026-10-18):** close the sync spike before the tenancy review and the backend research start. It runs in parallel with the desktop spike, and neither has priority. Everything in phases 3, 4 and 5 runs before the sync ADR, except S308 (parked), in this order:
1. the phase 3 gate (≥ 3,000 runs, phase 2 at full size in the same campaign);
2. PowerSync S2–S4 on Linux;
3. phase 4 on the Windows VM;
4. phase 5.

**Phase 4 VM (founder, 2026-10-16):**
- **Baseline:** the shared Windows VM's baseline is snapshot **`clean-ssh2`**, not `clean`.
- **What it contains:** Windows 10 22H2 with no cumulative updates; Edge/WebView2 self-updated to 155; OpenSSH with key-only access (the desktop spike's dedicated key in `prototypes/desktop-client-spike/.keys/`, host key pinned); cashier auto-logon; and the 100 IOPS + 80 MiB/s disk throttle.
- **Rules:** coordinate with the desktop spike before using the VM, and restore `clean-ssh2` after each run.
- **Shared with the desktop spike's round 4 (founder, 2026-10-18):** claim the VM in the checkpoint (`production/session-state/active.md`) before use and release it there afterwards. When the desktop block says FREE, the VM goes to whichever spike is ready; there is no priority between the spikes. Run each tamper leg both spikes need once, on the shared store, and cite that run from both READMEs.

**Added cases (founder, 2026-10-16; full rows with mechanisms in `docs/research/local-first-sync.md` § 9.1.2).** SC-19 is the highest-risk gap and runs first in phase 3.

| ID | Case | Pass signal (short) | Phase |
|---|---|---|---|
| SC-19 | Server restored from backup or PITR after the device holds acknowledged commands and has deleted those outbox rows | Every action acknowledged before the restore is on the server exactly once after reconnect. The server detects the gap itself (device's highest acknowledged sequence above the server cursor), records it and alerts the owner. Resent commands are byte-identical to the originals. A range already pruned from the device is reported exactly, never silently | 3 (first) |
| SC-20 | Disk full during the "close and pay" transaction and during the marker write | Sale fails visibly with no partial rows (explicit `ROLLBACK`). A failed marker write leaves the store ahead of the marker (safe), with an event recorded and the write retried. Nothing lost or duplicated | 3 |
| SC-21 | App update with an unsynced outbox and a local schema migration; kill at every step | Store fully old or fully new. Pending commands are sent byte-identical and dedupe across versions. The marker stays valid. The pre-migration copy is kept until verified. A downgrade is refused | 3 (a); 4 (b, Windows updater) |
| SC-22 | Two app instances started at once on the same store | Second instance refused or kept waiting with a message. No sequence used twice, no lost sale, marker never moves backwards | 3 |
| SC-23 | Owner changes a price or config on the server while the device is offline with a session running | Billed from the price frozen at session start, with the config version recorded. The server flags it and does not re-price it. Totals agree at day close | 3 |
| SC-24 | Start-up integrity-check time on a retention-sized store, HDD-throttled VM | Within the start-up budget ("not checked" until `perf-budgets.md` exists). Options if slow: `quick_check`, a partial check of hot tables, a full check only after an unclean shutdown, a smaller live store | 4 |
| SC-25 | (a) Days-long offline backlog; (b) N5 grace expiring mid-shift | (a) Drains in order with exactly one effect per action; batches shrink instead of looping; the counter keeps selling. (b) Open sessions can still be closed and billed; nothing lost or hidden | 3 (a, b mechanics); 5 (b, real rules) |
| SC-26 | Counter read latency while sync writes, rollback-journal mode | p95/p99 within the counter budget ("not checked" until it exists); no `SQLITE_BUSY` reaches the cashier | 4 |
| SC-27 | Windows Defender holding a lock on the database, journal or marker | 0 lost or duplicated sales and 0 false refusals over N commits; failures visible; any needed exclusion listed with its security cost | 4 |

**Device retention rule under test (founder):** an outbox row goes once a fully parsed ack arrives. The business records behind it stay on the device for a bounded window longer than ETA's 30-day late-submission route and the server's backup window, and are pruned only after the server confirms its archive. The window values are open (sync note OQ29); the spike uses placeholders.

## Phase 0 hypothesis

The harness's independent oracle catches each of four planted defects, and the correct stub passes at least 300 seeded runs with zero violations. Any failure replays from its seed.

The four defects (mutants):

| Mutant | Planted defect | Where | Invariant expected to catch it |
|---|---|---|---|
| `separate_outbox_txn` | Bill committed in one local transaction, outbox row in a second one (fault point P3 exists) | client | I1: a bill on the device never reaches the server |
| `no_dedupe` | Server applies every command it receives, with no inbox and no cursor check | server | I2: one action, two effects |
| `ack_before_commit` | Server sends "applied" before its database commit | server | I1: an acknowledged action is missing on the server |
| `double_minute` | Session billing counts the end minute too (off by one) | client | I5: a session minute billed twice; I3: amount differs |

**Signal:** the kill table below. Every mutant must be caught within its run budget, and the correct stub must stay at zero violations.

## How it works

- **Driver** (`harness/driver.py`, never killed): generates a seeded script of "close and pay a bill" actions, syncs, duplicate replays and one fault per run. It writes every action to its own intent log **before** submitting it.
- **Client stub** (`sut/client.py`): a local SQLite store in WAL mode with `synchronous=FULL`. It writes the bill, payment, session minutes, per-device sequence counter and outbox row in one `BEGIN IMMEDIATE` transaction, and syncs pending outbox rows in sequence order.
- **Server stub** (`sut/server/`): Go 1.27.2 and pgx 5.11.0 against `postgres:18.6`, listening on 127.0.0.1. It has an inbox keyed `(tenant, device, command_id)` with a payload hash, a compare-and-set cursor and one database transaction per batch.
- **Faults:** named failpoints (environment variable `FP=name:hit`); the process SIGKILLs itself when the point is reached. The driver restarts it without the fault.
- **Oracle** (`harness/oracle.py`): compares the intent log, the client's store and the server's ledger, then checks I1, I2, I3, I4, I5, I7, I8 and I9. I10 (tamper is visible) is a hook only; tamper cases start in phase 1.

## Run

Needs Docker, Go 1.27.2 and Python 3.14 on Linux.

```bash
bash prototypes/local-first-sync-spike/run.sh selftest
```

Other commands:

```bash
bash prototypes/local-first-sync-spike/run.sh replay <seed> [mutant]
```

```bash
bash prototypes/local-first-sync-spike/run.sh stop
```

Phase 1 and 2 commands (they use the `.venv` with `apsw-sqlite3mc`; phase 2 also needs Toxiproxy in `tools/`, see "Tools fetched"):

```bash
bash prototypes/local-first-sync-spike/run.sh phase1
```

```bash
bash prototypes/local-first-sync-spike/run.sh phase2 [seeds_per_cell] [campaign_runs]
```

```bash
bash prototypes/local-first-sync-spike/run.sh replay2 <seed> <cell|random> [mutant]
```

```bash
bash prototypes/local-first-sync-spike/run.sh ts09
```

Phase 3 commands (SC-19, server restore):

```bash
bash prototypes/local-first-sync-spike/run.sh sc19 [seeds_per_cell]
```

```bash
bash prototypes/local-first-sync-spike/run.sh replay19 <seed> <cell> [mutant]
```

SC-20 (disk full); `sc20real` runs the driver inside `unshare -r -m` to mount a 256 KiB tmpfs per run (Linux with unprivileged user namespaces):

```bash
bash prototypes/local-first-sync-spike/run.sh sc20 [seeds_per_cell]
```

```bash
bash prototypes/local-first-sync-spike/run.sh sc20real [seeds]
```

```bash
bash prototypes/local-first-sync-spike/run.sh replay20 <seed> <cell> [mutant]
```

SC-21a (app update with an unsynced outbox):

```bash
bash prototypes/local-first-sync-spike/run.sh sc21 [seeds_per_cell]
```

```bash
bash prototypes/local-first-sync-spike/run.sh replay21 <seed> <cell> [mutant]
```

SC-22 (two app instances on one store):

```bash
bash prototypes/local-first-sync-spike/run.sh sc22 [seeds_per_cell]
```

```bash
bash prototypes/local-first-sync-spike/run.sh replay22 <seed> <cell> [mutant]
```

SC-23 (owner changes prices while the device is offline):

```bash
bash prototypes/local-first-sync-spike/run.sh sc23 [seeds_per_cell]
```

```bash
bash prototypes/local-first-sync-spike/run.sh replay23 <seed> <cell> [mutant]
```

SC-25a (7-day backlog drained over cut windows; `full` takes about 9 minutes per run):

```bash
bash prototypes/local-first-sync-spike/run.sh sc25 [tenth|full|both]
```

```bash
bash prototypes/local-first-sync-spike/run.sh replay25 <seed> <tenth|full> [mutant]
```

SC-25b (N5 offline lease expiry, injected clocks):

```bash
bash prototypes/local-first-sync-spike/run.sh sc25b [seeds_per_cell]
```

```bash
bash prototypes/local-first-sync-spike/run.sh replay25b <seed> <cell> [mutant]
```

SC-28 (dashboard edit of an open bill):

```bash
bash prototypes/local-first-sync-spike/run.sh sc28 [seeds_per_cell]
```

```bash
bash prototypes/local-first-sync-spike/run.sh replay28 <seed> <cell> [mutant]
```

SC-29 (stock policy per item):

```bash
bash prototypes/local-first-sync-spike/run.sh sc29 [seeds_per_cell]
```

```bash
bash prototypes/local-first-sync-spike/run.sh replay29 <seed> <cell> [mutant]
```

SC-30 (device off while sessions run, injected clock):

```bash
bash prototypes/local-first-sync-spike/run.sh sc30 [seeds_per_cell]
```

```bash
bash prototypes/local-first-sync-spike/run.sh replay30 <seed> <cell> [mutant]
```

SC-31 (End Day):

```bash
bash prototypes/local-first-sync-spike/run.sh sc31 [seeds_per_cell]
```

```bash
bash prototypes/local-first-sync-spike/run.sh replay31 <seed> <cell> [mutant]
```

SC-13 and TS-01a (cloned disk; rollback; OQ7 policy):

```bash
bash prototypes/local-first-sync-spike/run.sh sc13 [seeds_per_cell]
```

```bash
bash prototypes/local-first-sync-spike/run.sh replay13 <seed> <cell> [mutant]
```

TS-07a (clock change during an open session, injected clock):

```bash
bash prototypes/local-first-sync-spike/run.sh ts07 [seeds_per_cell]
```

```bash
bash prototypes/local-first-sync-spike/run.sh replay07 <seed> <cell> [mutant]
```

`selftest` starts a throwaway `postgres:18.6` container on `127.0.0.1:56432`, builds the server and runs the correct stub and each mutant. `replay` re-runs one seed and prints its trace. `stop` removes the container. Run output goes to `runs/`, which is not committed.

## Pinned cell lists (guard)

Phase 2 and the tamper suite check, before they run anything, that their cell lists equal the lists pinned here (`harness/pins.py`). The tamper suite also checks, after the run, that it produced exactly these rows for each cipher. A new case that changes a shared table, as SC-25a's slow-link toxic once did for phase 2, therefore stops the run at once with a message naming what was added or removed. Without the guard, an untested cell surfaced only at the end of a 1 h 40 min regression. A deliberate change updates the list here in the same commit.

- `pinned phase2-cells: down, req_blackhole, req_cut_10, req_cut_120, req_cut_400, reset_peer, resp_blackhole, resp_cut_1, resp_cut_150, resp_cut_20, slicer, slow, concurrent`
- `pinned phase2-campaign-toxics: down, req_blackhole, req_cut_10, req_cut_120, req_cut_400, reset_peer, resp_blackhole, resp_cut_1, resp_cut_150, resp_cut_20, slicer, slow`
- `pinned tamper-scenarios: db_middle_page, db_page1, hot_journal_crash_control, hot_journal_crash_flip, marker_flipped, marker_deleted, store_older_than_marker, db_page_while_running, walmode+marker-wal_header, walmode+marker-wal_first_frame, walmode+marker-wal_last_frame, wrong_key, truncated_key, empty_key, right_key_wrong_cipher, wrong_key_x20, right_key_after_attempts, ts04a_plaintext_scan`

**Phase 3 gate campaign — required (founder, 2026-10-17):** it re-runs **phase 2 at full size** (50 seeds per cell, 3,000 campaign runs). After the toxic-table fix (SC-25a), phase 2 was re-checked only at reduced size (10 seeds, 300 runs).

## Tools fetched (not committed)

Downloaded binaries live in `tools/`, which git ignores. Only their provenance is recorded here.

**Toxiproxy v2.13.0** (phase 2 network faults), fetched 2026-10-16 into `tools/toxiproxy-2.13.0/`:

| Item | Value |
|---|---|
| Release | [Shopify/toxiproxy v2.13.0](https://github.com/Shopify/toxiproxy/releases/tag/v2.13.0), published 2026-10-14T18:26:53Z, not a prerelease |
| Tarball | `toxiproxy_2.13.0_linux_amd64.tar.gz`, 9,303,933 bytes |
| Tarball SHA-256 | `08fd7b3d677bd11358d16a5ce8fd9e1a08f69aa24984bc16781c84200d6b3b4d` |
| Check 1 | matches the line in the release's `checksums.txt` (`sha256sum -c`: OK) |
| Check 2 | matches the digest the GitHub releases API lists for the tarball |
| `checksums.txt` SHA-256 | `dc0558603352f0f2f812495ac891852bbfc7e5acdd824fd983d0c189c419541b`, matching its API digest |
| `toxiproxy-server` SHA-256 | `bf529e8bb9a05cd293f45a3f1d0aa66ff9469680dcdca7e0ebeae21f1b83de89`, matching the release's standalone `toxiproxy-server-linux-amd64` asset |
| `toxiproxy-cli` SHA-256 | `0cab3a7262ffed75dd4cadfbd69ecc3f0a80e8c10adbc925bac67552b620ced8`, matching `toxiproxy-cli-linux-amd64` |
| Archive contents | `toxiproxy-server`, `toxiproxy-cli` (static Go ELF x86-64), `README.md`, `LICENSE`, `CHANGELOG.md`; no absolute or `..` paths |
| Smoke test | `-version` reports 2.13.0; API bound to `127.0.0.1:18474` and a test proxy on `127.0.0.1:18475` only; clean shutdown |
| Licence | MIT (sync note F410); test-only, never shipped |

To reproduce, download the two files from the release page into an empty folder, then:

```bash
grep ' toxiproxy_2.13.0_linux_amd64.tar.gz$' checksums.txt | sha256sum -c -
```

Fallback if v2.13.0 misbehaves: v2.12.0 (2025-03-18), verified the same way.

## Shortcuts taken

- **Deferred to later phases:** reordering, partial batches, compound faults and server restore (phase 3); Windows (phase 4); real billing and clock rules (phase 5).
- **TS-09 uses a fake "business hours" switch** (`BUSINESS_HOURS=1|0` on the server) and a 500 ms gap threshold; the real schedule and threshold come from the spec.
- **Out of the spike entirely:**
  - No authentication or device identity checks.
  - A single tenant and a single device.
  - No error UX and no UI.
  - The server stub's schema and endpoints are probes, not a design.
- **The driver plays the cashier:** action ids come from the seeded RNG so that runs replay exactly; in production the client generates them.
- **Idempotency is not a shortcut;** it is the thing under test.

## Safety

- Everything binds to `127.0.0.1`; the PostgreSQL container uses a throwaway password and holds generated data only.
- No real secrets and no customer data.
- Nothing is deployed.

## Findings

The spike is not concluded; the verdict comes after the last phase. Phase results so far:

### Phase 0 — harness and mutation self-test: gate PASS (run 2, 2026-10-16; reproduced on committed harness in run 3)

**Committed-harness evidence:** run 3 ran on clean commit `72bebbe` (summary `harness_commit: "72bebbe"`, no `+dirty`) and reproduced run 2 exactly: the same kill table, 0 violations in 300 correct-stub runs, and identical fault coverage (`evidence/phase0-run3-*`, 123.8 s). Runs 1 and 2 ran on the uncommitted tree (`11ace09+dirty`) and are kept as history. The only code change between run 2 and commit `72bebbe` moved the throwaway database password from the connection string to `PGPASSWORD`.

**Kill table** (run 2, identical in run 3; evidence in `evidence/phase0-run2-*` and `evidence/phase0-run3-*`):

| Mutant | Result | Runs to catch (budget 200) | Fault that exposed it | First violation |
|---|---|---|---|---|
| `separate_outbox_txn` | caught | 7 | `client:after_business_commit` hit 2 | I1: sale recorded on the device but missing on the server |
| `no_dedupe` | caught | 2 | `client:before_local_commit` hit 1, then a resend | I2: one sale has 2 sale rows |
| `ack_before_commit` | caught | 24 | `server:after_response_before_commit` hit 1 | I1: acknowledged but missing on the server |
| `double_minute` | caught | 1 | (every run) | I3: sale 23,200 ≠ expected 23,050 piasters |
| correct stub | **0 violating runs of 300** | — | 149 client and 67 server SIGKILLs | — |

**Replay:** `run.sh replay 24 ack_before_commit` run twice gave the same fault, the same violations and a byte-identical trace (`evidence/phase0-run2-ack_before_commit-seed24-replay-result.json`).

**Fault coverage on the correct stub** (`evidence/phase0-run2-fault-coverage.txt`):
- All 8 fault points on the correct path fired, 18–37 times each: before the local commit (P1), mid local transaction (P2), after the local commit (P4), before send, server before commit (P6/P7), server after commit before response (P8), after response before mark (P10), and after mark (P12).
- The two points that exist only in mutants (P3 and "after response before commit") never fired on the correct stub, as expected.
- **Not yet covered:** P5 (request cut mid-send), P9 (response lost in flight) and P11 (inside the ack-mark write). These come with network faults in phase 2 and I/O-error injection in phase 1.

**Findings:**
- **P0-F1 — the first run failed its gate because a mutant was not expressed.** In run 1, `ack_before_commit` survived 200 runs (`evidence/phase0-run1-*`). The server streamed its reply chunked, and the kill landed before the final chunk, so the client saw an incomplete body (`IncompleteRead`) and never took it as an acknowledgement. The fault fired in all 18 runs that drew it, but the defect never reached the client. The fix makes the mutant send a complete reply (`Content-Length`) before dying, as a real ack-before-commit bug would.
  - **Lesson for every later phase:** a surviving mutant is investigated before anything is concluded, and "the fault fired" is not the same as "the defect was exercised".
- **P0-F2 — the client crashed on a truncated reply.** This was a defect in the correct stub. An incomplete HTTP reply raised an uncaught exception and killed the client (`client died rc=1`, `evidence/phase0-run1-ack_before_commit-seed102-client-traceback.txt`). It was safe here only because a crash meant a restart and a resend. A truncated or unparseable reply now counts as a failed sync, and run 2 had no rc=1 crashes. **Production rule:** any incomplete or malformed server reply is a failed sync, never an acknowledgement and never a crash.
- **P0-F3 — one lost acknowledgement stalls the device, and the stall is visible.** In the `ack_before_commit` seed-24 run, the lost first command left a sequence gap. The server refused every later command (compare-and-set cursor), all 8 sales stayed unsynced and the outbox never drained (I7). Nothing was double-counted, but the device stopped syncing. This confirms that a persistent gap needs the owner alert planned for TS-02a and OQ7, not only a log line.

**Speed (S401, indicative only):** 300 correct-stub runs took 105 s, about 0.35 s per run of 8 actions. At that rate, N = 3,000 runs takes about 18 minutes and 30,000 about 3 hours. Measured with plain SQLite (no encryption), Python 3.14.8 with SQLite 3.54.0, Go 1.27.2 with pgx 5.11.0, and `postgres:18.6` (`sha256:74935e72241653ca55e0414067e6d8763aceb8a810eb51b452253ec3dcfc4336`) in Docker 29.9.1. Host: Linux 7.2.9, 16 threads, 15 GB RAM, NVMe disk, warm caches. This is **not** the 4 GB HDD reference PC, and phase 1's encryption will slow it down.

### Phase 1 — encrypted store under process kill and tamper: run 1 gate FAIL (WAL), run 2 gate **PASS** after the OQ28 fix (2026-10-16)

#### Run 1 (WAL store) — gate FAIL, stopped at this gate

**Binding:** `apsw-sqlite3mc` 3.54.0.0 (SQLite 3.54.0, **SQLite3 Multiple Ciphers 2.6.1**), installed in `.venv/` inside this folder. Every test ran under two ciphers: `chacha20` (sqleet: ChaCha20-Poly1305, SQLite3MC's default) and `sqlcipher` (the SQLCipher AES-256 scheme). **The spike's binding is not the product decision:** the engine is chosen in the storage ADR, per runtime. SQLite3MC was chosen here because its engine is also reachable from the shortlisted runtimes (JVM: the Willena `sqlite-jdbc` fork; Node/Electron: `better-sqlite3-multiple-ciphers`, desktop-note F109, sync-note F11).

**Probe** (`evidence/phase1-probe-apsw.*`): on both ciphers the file has no plaintext SQLite header and no planted canary string. A wrong key still makes `PRAGMA key` answer `ok`, confirming desktop-note F110; the first read then fails with `NotADBError` and the file stays unchanged. The client therefore verifies every open with a full `PRAGMA integrity_check`, which reads every page through the HMAC.

**Process-kill matrix: PASS** (`evidence/phase1-killmatrix-run1.*`, 282 s):
- 7 cells × 50 seeds × 2 ciphers = 700 runs, with 0 violations. The cells are P1, P2, P4, before send, P10, **P11 (new: inside the acknowledgement write)** and P12.
- The fault fired in 48–50 of 50 seeds per cell; a few seeds drew a hit number beyond the process's lifetime.
- The outbox mutant on the encrypted store was caught in 50 of 50 fired runs, under each cipher.
- The plaintext scan (TS-04a) ran after every kill and every clean exit and found no leak.
- The phase 0 self-test re-run with the phase 1 client gave identical numbers.

**Tamper tests** (`harness/tamper.py`, `evidence/phase1-tamper-run1-*`), identical under both ciphers:

| Scenario | Result |
|---|---|
| TS-03a: byte flipped in a database page / in page 1 (app closed) | **PASS**: detected at start, refused, event recorded, file not written |
| TS-03a: byte flipped in the database while the app runs | detected at the **next start**, not while running. The open app kept serving the correct page from its cache, so no corrupted data was used |
| TS-03a: byte flipped in `-shm` | no effect and no loss (SQLite rebuilds it) |
| **TS-03a: byte flipped in the WAL header** | **FAIL: opened normally with 0 of 5 acknowledged sales, no event** |
| **TS-03a: byte flipped in the first WAL frame** | **FAIL: 0 of 5 sales, silently** |
| **TS-03a: byte flipped in the last WAL frame** | **FAIL: 4 of 5 sales, silently** |
| TS-05a: wrong, truncated or empty key; right key with the wrong cipher; 20 repeated wrong-key starts | **PASS**: every attempt refused and recorded, the client exited cleanly, the file was unchanged and no new file was created; the right key then opened all 5 sales |
| TS-04a: plaintext scan of every store file | **PASS** |

**Finding P1-F1 — one flipped byte in the WAL silently erases committed sales.** This is a design-level failure of "never lose money silently", and it is not specific to tampering: a disk error in the WAL does the same.
- **Mechanism (tier 2, [SQLite file format § 4](https://www.sqlite.org/fileformat2.html)):** a WAL frame is valid only if its checksum matches a cumulative checksum over the WAL header and every earlier frame. One damaged byte therefore invalidates that frame and every later frame. SQLite treats the log as ending at the last valid commit before the damage, without an error.
- **Why the check passes:** the store left behind is internally consistent, so `integrity_check` reports `ok`. Encryption does not change this.
- **Exposure:** every sale committed since the last checkpoint. The WAL is only folded into the main file every 1,000 pages by default, so between checkpoints committed sales live only in the WAL.
- **Server side:** sales already synced are not lost there. Unsynced sales are gone without a trace.

**Finding P1-F2 — damage to the open database is caught only at the next start.** While running, SQLite reads pages from its cache, so a runtime integrity check passed and no corrupted data was used. Detection came at the next start.

**Run 1 gate:** the process-kill part passed, but TS-03a failed, so phase 1 failed its gate and the spike stopped. The founder chose the fix (sync note OQ28): **A, rollback-journal mode, plus B, a MAC'd commit high-water mark** (D, prompt sync, applies in every case).

#### Run 2 (rollback journal + commit marker) — gate PASS

**Store design under test:**
- `journal_mode=DELETE` with `synchronous=FULL`, so committed sales always sit in the HMAC-checked main file.
- `<db>.hwm` = {sequence, HMAC-SHA256(key, sequence)}, written atomically (temporary file, fsync, rename, directory fsync) after every commit that advances the device sequence.
- On start the client refuses and records the event when: the store is behind the marker ("committed sales missing"), the marker's MAC is bad, or the marker is missing beside a non-empty store. A store ahead of the marker (a crash between commit and marker write) is safe; the marker is moved forward.
- Before opening a store that has a hot journal or WAL, the client copies the store files aside (P1-F3 below) and deletes the copy once verification passes.

**Tamper tests (`evidence/phase1-tamper-run2-*`): all 36 rows PASS under both ciphers.**
- Byte flips in a database page or page 1: detected, refused, recorded; the file was not written.
- A flip while running: detected at the next start.
- A crash mid-transaction leaving a hot journal: rolled back to exactly 5 consistent sales.
- The same crash with a byte flipped in the hot journal: detected, refused and recorded, with the originals preserved byte-identical.
- A flipped marker, a deleted marker, and an older store copy put back beside a newer marker: detected, refused, recorded.
- Every wrong-key case: refused, recorded, file unchanged. The plaintext scan is clean.
- **For comparison, WAL mode with the marker:** the three WAL flips are now **detected** (for example "store sequence 4 < marker 5") instead of silent, but the sales in the damaged WAL are still lost. That is why the rollback journal, not the marker alone, is the primary fix.

**Process-kill matrix (`evidence/phase1-killmatrix-run2.*`): PASS.**
- 700 runs with 0 violations, both ciphers, every cell exercised (48–50 of 50 seeds fired).
- The outbox mutant was caught in 50 of 50 runs on each cipher. The plaintext scan, now including recovery copies, found no leak.
- **196 of 196 kills inside a transaction (P2, P11) left a hot journal**, and every one recovered cleanly: the copy was made, SQLite rolled back, verification passed, and the copy was deleted. No run recorded an event.
- Phase 0 regression on the new client (`evidence/phase1-phase0-regression.log`): identical kill table and gate PASS.

**Finding P1-F3 — SQLite rewrites the main file during recovery, before the app can verify it.** On open, a hot journal is rolled back into the main file. In WAL mode, closing the connection checkpoints the surviving frames and deletes the WAL. In both cases the app's verification runs too late to keep the originals. With a damaged journal or WAL that means irreversible changes and lost evidence. **Production rule:** after a crash (hot journal or WAL present), copy the store files aside before opening, and keep the copy if verification fails.

**Cost (indicative only, NVMe dev host):** the phase 0 self-test took 142.8 s versus 105 s with WAL and no marker, about +36%. The kill matrix took 351 s versus 282 s, about +24%. That is two extra fsyncs per sale for the marker, plus the rollback journal. Commit latency on the 4 GB HDD reference PC is still to be measured in phase 4. If it breaks the counter budget, OQ28 must be revisited.

**Not covered by phase 1:**
- Power loss and lying disks: process kill keeps the OS cache. This is phase 4, on Windows.
- Injected I/O errors and a full disk.
- A crash during COMMIT itself: the Python failpoints cannot stop inside SQLite.
- TS-03b recovery from the server: phase 3.
- Minor: the client leaves an empty `.recovery/` folder after a clean recovery.

**Gate:** process-kill cells, tamper pass signals (TS-03a, TS-04a, TS-05a) and the phase 0 regression all pass. **Phase 1 gate: PASS (run 2).**

**Committed-harness evidence (run 3):** re-run on clean commit `4caabd2` (logs say `commit 4caabd2`, no `+dirty`): kill matrix identical to run 2 cell by cell (342.5 s), tamper 36 of 36 PASS with runtime-random test keys, phase 0 regression identical (`evidence/phase1-run3-*`). Runs 1 and 2 ran on uncommitted code and are kept as history.

**Conditions:** phase 1 on harness `7309208` plus uncommitted phase 1 changes, on the same host as phase 0, with the encrypted store on NVMe. Kill-matrix speed was about 0.35 s per run, indicative only.

**Conditions (phase 0):** harness commit `72bebbe` for run 3 (`11ace09+dirty` for runs 1–2), seeds 1–300 for the correct stub and seeds 1 to the catching seed for each mutant, one fault per run, 8 actions per run, and a single tenant and device.

### Phase 2 — network faults, resend, concurrent retry, server kill (real PostgreSQL 18.6)

**Setup:** the client talks to the server through Toxiproxy v2.13.0 (proxy `127.0.0.1:18481` in front of the stub on `127.0.0.1:18471`); the oracle reads the server directly. Store: SQLite3MC `chacha20`, rollback journal plus commit marker (OQ28 A + B). Client HTTP timeout 2 s.

**Probe S402 (`evidence/phase2-probe-toxiproxy.*`):** Toxiproxy can cut only the response (`stream=downstream`) or only the request (`stream=upstream`). A lost response leaves exactly one server effect and the resend returns `duplicate`; a cut or blackholed request leaves none.

**Finding P2-F1 — a cut response can look like "200 OK".** When only the first 20 bytes come back, Python's `http.client` reports status 200 with an empty body; the server had committed. **Rule:** acknowledge only the commands named in a fully parsed results body, never on the status code. The client now checks for a `results` list and treats anything else as a failed sync.

**Cells** (one toxic on every sync and replay, no process kill; a cell whose toxic never bit is NOT ASSESSED, never PASS):

| Cell | Toxic | Covers |
|---|---|---|
| `resp_blackhole` | downstream `timeout` 300 ms | P9: committed, reply lost |
| `resp_cut_1`, `resp_cut_20`, `resp_cut_150` | downstream `limit_data` | P9, P2-F1 |
| `reset_peer` | downstream `reset_peer` | connection reset |
| `req_cut_10`, `req_cut_120`, `req_cut_400` | upstream `limit_data` | P5: request cut mid-send |
| `req_blackhole` | upstream `timeout` 300 ms | request never arrives |
| `down` | proxy disabled | server unreachable |
| `slow` | `latency` 150 ± 100 ms both ways | slow but working |
| `slicer` | downstream `slicer` | reply in 4-byte pieces |
| `concurrent` | `slow`, and every sync sends the same batch twice at once | SC-05 concurrent retry |

**Randomized campaign:** each sync has a 25% chance of being a concurrent double send. Each sync and replay gets a random toxic, or none 35% of the time. Half the runs also get one process kill: client points P1–P4 and P10–P12, server points P6–P9 (before commit, after commit before the reply, reply before commit).

**Mutants** run under the campaign's faults; **TS-09** runs two planned outages (1.2 s and 2.0 s) while the cashier keeps selling. Pass: each outage is recorded once by the server from its own clock, within 0.25 s of what the driver saw, with an owner alert only when business hours are on, and the money invariants hold.

#### Run 1 (dev, uncommitted harness on `b6eb3dd`) — gate PASS at reduced size

`evidence/phase2-run1-dev.log` and `-summary.json`: 10 seeds per cell and 300 campaign runs (393 s).
- **Cells:** all 13 PASS with 0 violations, and every toxic was shown to bite. In the four response-loss cells and `reset_peer`, the server committed and the client got no reply 80 times per cell, and every resend came back `duplicate` (80 of 80). In the `concurrent` cell both replies parsed 80 times, and the second was `duplicate` every time.
- **Campaign:** 300 runs, 107 with a process kill, 0 violations.
- **Mutants:** all four caught. `separate_outbox_txn` after 5 runs, `no_dedupe` after 1, `ack_before_commit` after 147, `double_minute` after 1.
- **TS-09:** PASS in both modes. Two periods recorded, each within 2 ms of the driver's observation; `owner_alert` true only with business hours on; 16 of 16 sales on the server.

**Finding P2-F2 (harness, not protocol).** The first dev attempt never caught `separate_outbox_txn`. Its only catching point is P3 (`client:after_business_commit`), which exists only in that mutant and was missing from the phase 2 kill list. P3 is now in the list; on the correct client it never fires. Separately, `ack_before_commit` needed 147 runs, close to the 200-run budget, so phase 2 uses a budget of 400. Seeds are deterministic, so the budget changes no outcome.

#### Run 2 (full size, committed harness `be3f49e`) — gate **PASS**

`evidence/phase2-run2.log` and `-summary.json` (log header `commit be3f49e`, no `+dirty`), 2,513 s in total.
- **Cells:** all 13 PASS, 50 seeds each (650 runs), 0 violations, and every toxic was shown to bite. Response-loss cells and `reset_peer`: 400 committed-but-unacknowledged commands per cell, and every resend came back `duplicate` (400 of 400). `concurrent`: both replies parsed 400 times, and the second was `duplicate` every time. Request-side cells and `down`: 400 failed syncs per cell, and the server had no effect from any of them. `slow` and `slicer`: 0 failed syncs.
- **Campaign:** 3,000 runs with 0 violations. 1,098 runs had a process kill fire; 12,502 ops crossed a toxic and 9,564 of those failed; the server answered `duplicate` 11,810 times, and 1,527 concurrent double sends had both replies parse.
- **Mutants** (budget 400): all four caught, in the same number of runs as run 1. `separate_outbox_txn` after 5, `no_dedupe` after 1, `ack_before_commit` after 147, `double_minute` after 1.
- **TS-09:** PASS in both modes. Recorded `from` and `to` were within 0.3–1.6 ms of the driver's observations; `owner_alert` was true only with business hours on; 16 of 16 sales reached the server.

**Gate:** 0 violations across every cell and ≥ 3,000 randomized runs, every mutant caught, TS-09 pass signals met. **Phase 2 gate: PASS (run 2).** Run 1 ran on uncommitted code and is kept as history.

**Conditions:** same NVMe dev host as phases 0–1, single tenant and device, 8 actions per run, loopback network only. About 0.56 s per campaign run, indicative only.

**Not covered by phase 2:** a real lossy link (Toxiproxy acts at the TCP stream level, not on packet loss or reordering); a server crash during PostgreSQL's own commit (the server failpoints sit before and after `COMMIT`); several devices; reordering and partial batches (phase 3).

### Phase 3 — SC-19: server restored from backup (first case, the highest-risk gap)

**Design under test** (sync note § 9.1.2; retention values from OQ29, provisional):
- **Client (`RETENTION=1`):**
  - An outbox row is deleted once a fully parsed ack arrives.
  - The bill row keeps the command id, sequence, payload bytes and hash, so a command can be rebuilt byte-identical.
  - Every batch reports `acked_seq` (H, the highest acknowledged sequence) and `low_seq` (the lowest retained one).
  - A bill is pruned only if it is **below the server's durable watermark and older than 60 days** (simulated days).
- **Server:**
  - **Watermark:** the highest sequence in a backup whose restore has been verified. The driver restores each backup into a scratch database, reads the cursor there, then posts it.
  - **Restore epoch:** every restore sets a new epoch (the runbook step), so the server knows it was restored. Each device's first contact in a new epoch is recorded.
  - **Resend:** when the cursor N is below H, the server answers "resend from N+1".
  - **Lost range:** when the device has already pruned part of N+1..H, that exact range is recorded as lost with an owner alert, and the cursor skips it explicitly.
- **Backups:** real `pg_dump` archives restored with `pg_restore --clean --single-transaction`. A dump is a transaction-consistent snapshot, which is what a PITR target gives. PostgreSQL's own WAL-archive PITR is not exercised.
- **Config feed (variant d):** `epoch, version, price`. The device compares the epoch first, because after a restore the same version number can come back with different content.

**Cells** (calendar in simulated days: sales on days 1, 8, 30 and 75; B2 on day 31; restore on day 76):

| Cell | Restore | Expected |
|---|---|---|
| `a_before`, `a_inside`, `a_after` | latest backup B2, taken before, inside (server sleeps before COMMIT) or after a batch | full recovery by resend |
| `b_older` | B1 (day 20, inside a server window shorter than 60 days) | full recovery: everything after B1 is younger than 60 days |
| `b_expired` | B1 (day 2, older than 60 days) | exact lost range = the pruned day-8 sales, owner alert |
| `c_offline` | B2, while the cashier keeps selling | full recovery, offline sales synced after |
| `d_config` | B2, then two owner edits that reuse version numbers | device ends on the server's config |
| `e_unverified` | B1; B2's restore check failed, so it gave no watermark | full recovery: nothing above the last verified watermark was pruned |

**Oracle (added):**
- **R2:** a lost range is legitimate only if every lost sequence is below a verified watermark and older than 60 days.
- **R3:** every restore produces a reconciliation event, plus a resend or lost range with an owner alert when the restored cursor is below H.
- **R4:** every command on the server has its original command id and the canonical payload hash.
- **R5:** the device's config equals the server's.
- **I1:** applies as before; missing actions are excused only inside a reported lost range.

**Mutants:** `prune_unconfirmed` (prunes by age, without the watermark), `no_reconcile` (server ignores H), `rebuild_new_ids`, `config_version_only`.

#### Run 1 (dev, uncommitted harness on `1a686d6`) — PASS

`evidence/phase3-sc19-run1-dev.log` and `-summary.json`, 951 s.
- **Cells:** all 8 PASS, 50 seeds each, 0 violations. Every cell pruned bills, and `a_inside` backed up mid-batch in 50 of 50 runs.
- **`b_expired`:** the exact lost range was recorded with an owner alert in 50 of 50 runs; it is the only cell where the rule allows a loss.
- **Mutants:** all four caught. `prune_unconfirmed` after 8 runs (the first `e_unverified` run), the others after 1.

#### Run 2 (committed harness `a65d6f8`) — SC-19 **PASS**

`evidence/phase3-sc19-run2.log` and `-summary.json` (log header `commit a65d6f8`, no `+dirty`), 940 s. Identical to run 1, cell by cell: 8 × 50 runs with 0 violations, `a_inside` mid-batch in 50 of 50 runs, `b_expired` exact lost range in 50 of 50, and the four mutants caught after the same number of runs (8, 1, 1, 1). Run 1 ran on uncommitted code and is kept as history.

**Finding P3-F1 — what "archive confirmed" means decides whether a restore can lose money.** An earlier placeholder rule pruned on archive confirmation alone, with no age limit. Under it, restoring the older backup lost 3 of 11 sales in every `b_older` run: reported exactly, but lost. Under the founder's OQ29 rule (verified-restore watermark **and** 60 days, with a server backup window shorter than 60 days), a restore from any backup inside the window recovers everything. A loss needs a backup older than 60 days (`b_expired`). Two conditions carry this result:
- **The server backup window must stay shorter than the device window.** If backups older than 60 days are ever restored, the loss in `b_expired` is real.
- **The watermark must come from a verified restore.** `e_unverified` shows that a backup whose restore was not verified must not move it; `prune_unconfirmed` is caught exactly there.

**Finding P3-F2 (harness).** The first SC-19 attempt could not tell whether the `a_inside` backup really fell inside a batch: earlier syncs had drained the outbox, so the "inside" sync sent nothing. The cell now forces pending commands and is NOT ASSESSED unless the backup misses a batch that then commits.

**Regression after the client change** (`evidence/phase3-regression-*.log`, same uncommitted harness): phase 0 self-test PASS, with a kill table identical to phase 1 run 3 except elapsed time; phase 1 kill matrix PASS, identical cell by cell; phase 2 at 10 seeds per cell and 300 runs PASS, the same as phase 2 run 1; tamper 36 of 36 PASS. Phases 0–2 run without `RETENTION`, so this shows the shared code path did not change their behaviour. The phase 3 campaign runs with it.

**Not covered by SC-19:**
- **A device that lies about H.** Under-reporting would hide its own lost sales from the server. That is the insider case of OQ27.
- **A device that is offline across the whole restore and the backup window.** It reconnects with records the server never had in any backup; they resend normally, which the `c_offline` and backlog cases cover.
- **Side effects re-sent after a restore** (ETA submissions, alerts): not modelled. ETA's handling of a resubmitted receipt UUID is open (ETA note F310, F325).
- **Several devices.**

### Phase 3 — SC-20: disk full

**Founder expectation (2026-10-16):**
- The counter keeps selling as soon as space is freed, with no restart.
- The cashier and the owner both see a clear "disk full" warning.
- A failed marker write never crash-loops the app; it fails safe and records the event.

**Probe P3-probe-ENOSPC** (`evidence/phase3-probe-enospc.*`, run before any harness change):
- **Where it was tested:** an apsw VFS shim above SQLite3MC's cipher VFS failed the n-th write with `SQLITE_FULL` (32 cases, with and without mid-transaction cache spills); a real 96 KiB tmpfs filled up; and the page-count limit was hit.
- **Result:** SQLite 3.54.0 (SQLite3MC 2.6.1) rolled back the **whole** transaction every time. It never left half a "close and pay" open, the counts were unchanged, and `integrity_check` was ok.
- **Why the client still issues an explicit `ROLLBACK`:** the docs say such errors "may or may not" roll back (sync note F443), so that rule stays.
- **Encryption:** the shim does not weaken it; there was no plaintext on disk.

**Finding P3-F3 — before SC-20 the client failed the founder's expectation in two ways (shown by the mutants that keep the old code):**
- **`full_refuses`:** a disk-full sale made the client refuse its store until restart, so selling did not resume after space was freed.
- **`marker_crash`:** a failed marker write after COMMIT was not caught, so the client crashed. On restart it tried the marker again and, while the disk was still full, crashed again.

Also, the event log lived on the same full disk, so recording the event could itself fail.

**Fix under test (client):**
- **Disk full during a sale or an ack write:** explicit `ROLLBACK`, then the reply `{"ok": false, "error": "disk_full", "warning": "disk_full"}`. The event is recorded and sent to the server, which raises an owner alert (`POST /device_event`). The store is not refused, so the next write after space is freed goes through.
- **Failed marker write after COMMIT:** the sale stays saved and acknowledged, with a warning. The store is ahead of the marker, which is the safe direction, and a `marker_behind` event is recorded. The marker catches up on the next commit or start; a failed catch-up at start is recorded, never fatal.
- **Events while the disk is full:** if the event log cannot be written, the event is kept in memory and sent to the server at the next chance.
- **Telling disk full apart from damage:** a store error counts as "disk full" only for `SQLITE_FULL`, or when less than 64 KiB is free. Any other store error still refuses the store, as in phase 1.

**Cells:**

| Cell | Fault | Covers |
|---|---|---|
| `a_txn_transient` | `SQLITE_FULL` on write 1–3 of a sale, once | sale fails visibly; the next sale works |
| `a_txn_persistent` | every write fails from write 1–3 until `free_space`; two sales and a sync while full | resume without restart |
| `b_marker_write`, `b_marker_fsync`, `b_marker_replace` | ENOSPC at that marker stage; the app is restarted while still full | no crash loop; sale saved with a warning; marker catches up |
| `c_ack_mark` | disk full while writing the acknowledgement of a batch the server applied | the sync fails visibly; the resend comes back `duplicate` |
| `d_real_tmpfs` | real ENOSPC: a 256 KiB tmpfs per run holds the store, journal, marker and event log; a filler file fills it, then is deleted | the same signals on a real kernel error, including the ack write |

**Checks added:**
- **R6:** selling resumes after space is freed.
- **R7:** every failed sale carries the disk-full warning, the server holds an owner-alert event, and sales saved during a marker failure carry a warning.
- **R8:** no process died, and the app starts while the marker still cannot be written.
- **R9:** the marker equals the store counter at the end.
- **R10:** a sale answered "not saved" is neither on the device nor on the server.

**Mutants:** `full_refuses`, `marker_crash`, `ack_despite_full` (answers "saved" for a sale whose commit failed).

#### Run 1 (dev, uncommitted harness on `4ff3c68`) — PASS

`evidence/phase3-sc20-run1-dev.*` and `evidence/phase3-sc20real-run1-dev.*`.
- **Shim cells:** all 6 PASS, 50 seeds each, every run hit its fault, 0 violations (89 s).
- **Mutants:** all three caught. `full_refuses` after 1 run (I7, outbox never drained; R6), `marker_crash` after 3 (R7, no owner alert; R8, client died), `ack_despite_full` after 1 (I1, an acknowledged sale missing on the server).
- **Real tmpfs leg:** 50 of 50 runs hit real ENOSPC, 0 violations (20 s).
  - In every run the two sales made on the full disk were answered `disk_full` and left no trace.
  - The sync hit a real failed ack write: the server had applied the sale, the client could not record the ack, and after space was freed the resend came back `duplicate`, counted once.
  - The event log could not be written to the full tmpfs, so the events went to the server from memory.

#### Run 2 (committed harness `daac687`) — SC-20 **PASS**, full regression PASS

`evidence/phase3-sc20-run2-*` (log headers `commit daac687`, no `+dirty`).
- **SC-20 shim cells and mutants:** identical to run 1, line by line (88 s).
- **Real tmpfs leg:** 50 of 50 runs exercised, 0 violations.
- **Regression on the same harness:**
  - phase 0 self-test: PASS;
  - phase 1 kill matrix: PASS;
  - tamper: 36 of 36 PASS;
  - SC-19: PASS, identical to its run 2;
  - phase 2 at 10 seeds per cell and 300 runs: PASS, the same as before.

The phase 2 log header says `commit c0e7fd2`. A desktop-spike commit landed on `main` during the run; it changes nothing in this folder (`git diff daac687 c0e7fd2 -- prototypes/local-first-sync-spike` is empty), so the harness was byte-identical.

**Not covered by SC-20:**
- **The marker failing on a real full disk:** a commit needs a journal file, so on a real full disk the commit always failed first. Marker failures are covered by injection only (the `b_marker_*` cells).
- **First start on an already-full disk:** the initial marker write would fail, and the next start would see "marker missing beside a non-empty store" and refuse. A known limitation of this spike client.
- **Windows:** whether a full disk reports `ERROR_DISK_FULL` the same way is phase 4.
- **A cashier-facing message:** the reply carries `warning: disk_full`; the actual UI text and the owner's alert wording belong to the spec.

### Phase 3 — SC-21a: app update with an unsynced outbox and a local schema migration (Linux leg)

**Design under test (client, `SCHEMA_VERSION` 1 or 2, kept in `PRAGMA user_version`):**
- **Schema 1 → 2:** a new column on bills, a new table, and the outbox rebuilt with an envelope column (create, copy, drop, rename).
- **The migration, in order:**
  1. Copy the store files aside to `<db>.premigrate/`.
  2. Run every DDL step and the version bump in **one** transaction.
  3. Verify: `integrity_check` plus unchanged row counts.
  4. Refresh the marker.
  5. Delete the copy.

  A restart after a kill finds the store wholly at schema 1 or wholly at schema 2. If the copy still exists beside a schema-2 store, the app verifies the store and then deletes the copy.
- **Pending commands:** they keep their stored payload bytes and hash across the upgrade, so a command the server applied before the update (its ack lost) dedupes as `duplicate` afterwards.
- **Downgrade:** an older app refuses a newer store before any write and records `downgrade_refused`.

**Script per run:**
1. App 1 makes 3 synced sales and 2 pending ones.
2. A sync is killed inside the ack write (`client:mid_mark`), so the server holds 2 commands whose ack the device lost; one more pending sale follows.
3. App 2 starts and is killed at the cell's migration point.
4. An inspect-only start looks at the store exactly as crash recovery leaves it.
5. App 2 starts again, finishes the migration and sells.
6. In the `downgrade` cell, app 1 is started on the migrated store, then app 2 again.

**Checks added:**
- **R11:** after any kill the store is wholly schema 1 or wholly schema 2.
- **R12:** a valid schema-1 copy exists after any kill that came after the COMMIT, and no copy is left at the end.
- **R13:** every command on the server carries the canonical payload hash.
- **R14:** the downgrade is refused, the store and marker are byte-identical afterwards, and the event is recorded.
- **I8** (existing) catches `payload_mismatch` flags.

**Mutants:** `nonatomic_migration`, `no_premigrate_copy`, `reserialize_on_upgrade`.

#### Run 1 (dev, uncommitted harness on `6faf519`) — PASS

`evidence/phase3-sc21a-run1-dev.*`, 213 s.
- **Cells:** all 8 PASS (`none`, the six kill points, `downgrade`), 50 seeds each, every kill fired, 0 violations.
- **Every kill:** a kill before or during the transaction (including mid-DDL) left a store wholly at schema 1, since crash recovery rolled back the hot journal. A kill after COMMIT left schema 2 with a valid schema-1 copy beside it.
- **Lost acks:** in every run the two commands whose ack was lost before the update came back `duplicate` after it.
- **Downgrade:** refused in 50 of 50 runs, files unchanged.
- **Mutants:** all three caught.
  - `nonatomic_migration` after 4 runs: a half-migrated store that the next start could not finish, so acknowledged sales never synced (I1, I7, R11).
  - `no_premigrate_copy` after 5 runs (R12).
  - `reserialize_on_upgrade` after 1 run: the server flagged `payload_mismatch` for the lost-ack commands (I8, R13).

#### Run 2 (committed harness `128cdea`) — SC-21a **PASS**, full regression PASS

`evidence/phase3-sc21a-run2-*` (every log header `commit 128cdea`, no `+dirty`).
- **SC-21a:** identical to run 1, line by line (218 s).
- **SC-20 and SC-19:** identical to their run 2.
- **SC-20 real tmpfs leg:** 50 of 50 runs exercised, 0 violations.
- **Earlier phases:** phase 0 PASS, phase 1 kill matrix PASS, phase 2 at 10 seeds per cell and 300 runs PASS, tamper 36 of 36.

**Finding P3-F4 — an update must never change the bytes of a stored command.** If the new version rewrites stored payloads, even only their JSON layout, a command the server applied before the update (its ack lost) no longer dedupes: the server sees the same command id with a different hash. Under OQ6 that is recorded and flagged for review, never applied twice, but every such sale lands in the owner's review queue. **Rule:** stored command payloads are immutable; the wire format may change only for new commands, behind the envelope version.

**Not covered:**
- **The real updater on Windows:** files locked by the running app, installer rollback. That is SC-21b in phase 4.
- **A failed verification after the migration:** there is no automatic restore from the copy yet; the copy is kept and the store refused.
- **A two-step jump (schema 1 to 3).**
- **The server rejecting an envelope version it no longer supports:** the stub ignores the envelope.

### Phase 3 — SC-22: two app instances started on the same store (Linux leg)

**Design under test (client):**
- **The lock:** before anything touches the store (crash recovery, migration, marker), the client takes an exclusive, non-blocking OS lock (`flock`) on `<db>.lock` and holds it for its whole life.
- **A second instance** touches nothing. It records `second_instance_refused` and answers every operation `{"ok": false, "error": "another_instance", "warning": "another_instance"}`, so the cashier sees why.
- **Take-over:** the OS releases the lock when the holder dies, so a restarted instance takes the store over with the normal crash recovery.
- **Windows:** `LockFileEx` or a named mutex, in phase 4.

**Cells:**

| Cell | What happens | Pass signal |
|---|---|---|
| `a_simultaneous` | two instances started back to back, 5 rounds per run; each sells | exactly one serves in every round; the other's sale is refused visibly and leaves no trace |
| `b_second_later` | a second instance started while the first is selling (a double-click) | the second is refused for every operation; the first keeps selling |
| `c_kill_holder` | the holder is killed mid-transaction (hot journal), the refused instance is closed, the app is started again | the new instance takes over, recovers and sells; nothing acknowledged is lost |

**Checks added:**
- **R15:** the commit marker never tears or moves backwards (sampled after every operation).
- **R16:** at most one instance serves the store at a time, and a restarted instance can take over after the holder dies.
- **R17:** a sale refused for "another instance" carries the warning and leaves no trace.

**Mutants:** `no_instance_lock`, `lock_released_early` (lock held only while opening).

#### Run 1 (dev, uncommitted harness on `a3edfc6`) — PASS

`evidence/phase3-sc22-run1-dev.*`, 58 s.
- **Cells:** all 3 PASS, 50 seeds each, 0 violations.
- **Second instance refused:** 400 times in total; in 250 of 250 simultaneous starts exactly one instance served.
- **Take-over:** in 50 of 50 kills of the holder mid-transaction the hot journal was present, and the restarted instance took over and recovered.
- **Mutants:** `no_instance_lock` caught after 1 run, `lock_released_early` after 2 (both R16).

#### Run 2 (committed harness `db53f27`) — SC-22 **PASS**; the regression found a tamper-suite gap, fixed in `74fac52`

`evidence/phase3-sc22-run2-*` (log headers `commit db53f27`, no `+dirty`).
- **SC-22:** PASS, 3 × 50 runs, 0 violations. The cells are identical to run 1; `lock_released_early` was caught after 1 run instead of 2. It is caught in a cell where two processes race to start, so the run that catches it depends on timing, not on the seed. It is caught either way.
- **Earlier cases:** SC-21a, SC-20 and SC-19 are identical to their previous runs. SC-20's real tmpfs leg had 50 of 50 runs exercised.
- **Earlier phases:** phase 0, phase 1 and phase 2 (10 seeds per cell, 300 runs) all PASS.
- **Tamper on `db53f27`: 18 of 36 FAIL** (`-tamper-before-fix.log`). The SC-22 lock file `client.db.lock` was counted as a store file:
  - in the five wrong-key cases it was an "extra file";
  - in the crash-recovery cases it was a "missing original", because the pre-recovery copy deliberately leaves it out.

  Nothing about the store's protection changed. **Fix in `74fac52`:** the empty lock file is excluded from the store-file comparisons, and every tamper row now also asserts that the lock file stays empty.
- **Tamper on `74fac52`: 36 of 36 PASS**, row results identical to the pre-SC-22 run (`-tamper-74fac52.log`). The tamper suite stamps no commit in its output; it ran with the spike tree clean at `74fac52`.

**Finding P3-F5 (harness) — "started first" does not mean "holds the store".** The first `c_kill_holder` attempt spawned the second instance right after the first. The second sometimes reached the lock first, so the intended holder was the one refused, and the driver waited for a process that never died. The cell now confirms the holder serves the store before starting the second. The product consequence: on a simultaneous start, which instance wins is arbitrary, so the loser must say so clearly (R17) rather than assume it is the second.

**Observation:** with the lock removed (`no_instance_lock`) the money invariants still held in these runs, because SQLite serialises the two writers and the driver sends one operation at a time. The lock is what keeps a single counter UI, a single marker writer and a single sync loop. A concurrent two-writer stress run without the lock (marker races) was not run; under the lock it cannot happen.

**Not covered:**
- **Windows:** `LockFileEx` or a named mutex, and two Windows user sessions on one PC. Phase 4.
- **A lock file on a network share.** Out of scope: the store is local.
- **The instance that loses waiting for the lock** instead of refusing; the founder's pass signal allows either.

### Phase 3 — SC-23: the owner changes prices while the device is offline with sessions running

**Founder rules under test (2026-10-16):**
1. A running session keeps the prices frozen at its start (G12). A price-tier change during the session (N4) uses the price list the device holds at that moment.
2. A sale made offline at the last price the device knew is a valid fact. The server accepts it with no per-sale "needs review" flag and shows the owner **one summary per offline period**: "N sales at the previous price while the counter was offline from X to Y".
3. A new price takes effect on the device when the device receives it, never retroactively. The server never re-prices a recorded sale.

Permission revocation while offline (abuse case 3) is **not** in SC-23. It is a separate later cell, because its rules come from the staff auth and roles research, which has not run yet.

**Design under test:**
- **Device:**
  - Keeps the last price list it pulled: a per-tier station rate and the café item price.
  - `start_session` freezes the tier rate of the list it holds at that moment.
  - `change_tier` opens a new segment at the rate of the list it holds at *that* moment.
  - `close_session` bills each segment at its own rate, rounding each half-up (a placeholder until OQ8), and prices the café items at the current list.
  - The bill carries `cfg_version` (the newest list version it used), the segments and the café line.
- **Server:**
  - Records the device's amount as sent.
  - Counts the sales billed under an older version than its current one into one `price_summaries` row (with an owner alert) per offline period: the period the device has just come back from, taken from the TS-09 contact-gap record (`GAP_MS=500`).
  - Pulling the config counts as device contact.
- **Driver model (independent of the client code):**
  - Records which price list the device received, and when.
  - Computes every bill from that record.
  - Predicts the summary each offline period should produce; offline periods are real wall-clock gaps of 0.8 s with no device contact.

**Cells:**

| Cell | Script | Expected |
|---|---|---|
| `a_offline_session` | a session starts online; the device goes offline; the owner changes the list; the session closes and a second one runs, both offline; reconnect; the new list is pulled; a third session runs | both offline bills at the old list, one summary of 2 for that period; the third bill at the new list |
| `b_tier_change` | a session starts at list v2; the device pulls v3; a tier change, then close; then offline: the owner changes the list, and a session with a tier change runs offline | first bill: std part at v2, vip part and café at v3, not counted as previous-price; second bill: one summary of 1 |
| `c_two_periods` | three offline periods: a price change in the first and third, none in the second | summaries of 1 and 2; none for the second period |

**Checks added:**
- **R18:** every bill on the device equals the model. **I3**, via the model amount, checks the server's ledger, so a re-priced sale fails.
- **R19:** the per-period summaries equal the model exactly, none fall outside an offline period, and each has its owner alert and period.
- **R20:** every bill carries the version the model says it used.
- **I8:** no per-sale review flag.

**Mutants:**
- `reprice_on_server`: the server recomputes with today's list.
- `per_sale_flag`: the server flags every previous-price sale.
- `retroactive_price`: the device re-prices the open session with the list at close.
- `tier_uses_start_price`: a tier change uses the session's start list.

#### Run 1 (dev, uncommitted harness on `9c1602b`) — PASS

`evidence/phase3-sc23-run1-dev.*`, 247 s.
- **Cells:** all 3 PASS, 50 seeds each, every run exercised, 0 violations. The server produced exactly the 200 expected summaries (50 + 50 + 100), none outside an offline period, and no per-sale flag.
- **Mutants:** all four caught.
  - `reprice_on_server` after 1 run (I3: the server stored 4,871 for a sale billed 7,433).
  - `per_sale_flag` after 1 (I8).
  - `retroactive_price` after 2 (I3).
  - `tier_uses_start_price` after 2 (I3).

  The last two need a new list to arrive while a session is open, which happens in `b_tier_change`. In `a_offline_session` re-pricing at close changes nothing, because the device holds the same list.
- **Spot checks after the config change:** SC-19 `d_config` PASS (13 of 13); tamper 36 of 36. The full regression follows on the committed harness.

#### Run 2 (dev, uncommitted harness on `89510c2`) — founder follow-ups (2026-10-17): PASS

`evidence/phase3-sc23-run2-dev*`, 340 s. Changes since run 1:
- **Rule 2 widened:** one owner summary per period in which the device lacked the current list, offline or simply not yet pulled. The server judges a sale only by its `cfg_version` against the list in force at upload, and keys the summary by the old version the device was on. The period runs from the server's publication of the next version to the device's first pull of a newer one, both in server time. Offline periods inside it are context (`offline_periods` count) for the owner's message. The first implementation of the online case attached an online sale to the preceding offline period, through a 30-second "continuation" heuristic; cell `d` caught it, and the heuristic is gone.
- **Rule 4:** a device with no price list, or with a price missing, refuses with `no_price_list` / `price_missing` and bills nothing. There is a café-only `sell_items` operation; the spike's older `sale` operation takes its rate from the driver and is harness scaffolding only.
- **OQ8:** a multi-segment session is rounded once on its total, to the owner's `round_piasters` step from the price list (the list held at close; the billing spec confirms which). No default lives in code.
- **Oracle fix:** a bill for an action the driver never logged used to crash the oracle; now it is reported (I8 "never submitted").

| New cell | Script | Result (50 seeds) |
|---|---|---|
| `d_online_lag` | sales online before the device pulls a new list; then an offline period followed by an online sale before the pull | one summary per old version (v2: 2 sales, no offline period inside; v3: 2 sales, with an offline period inside), bounds within 0.5 s of the publication and pull times |
| `e_no_price_list` | `start_session`, `sell_items` and `close_session` before any list arrives; then a list without a vip price | every action refused with `no_price_list`; 0 bills and 0 outbox rows before the list; vip refused with `price_missing`; std billed normally |
| `f_corrupt_session_op` | tiny page cache, cache dropped, one byte flipped in every data page, then `start_session` | the store is refused by the session operation (`store: refused`) and for the next operation, `store_error_during_operation` is recorded, and the file is not written after detection |

**Checks added:** R21 (no price list or no price: refused clearly, nothing billed, no zero bill on the server) and R22 (a store error reached first by a session operation still refuses the store).

**Mutants (8, all caught):** the four of run 1, plus:
- `offline_only` (the first rule's per-offline-period summaries) after 1 run (R19);
- `zero_price_default` after 5 (I8 and R21: a session "started" at rate 0 and zero bills reached the server);
- `swallow_store_errors` after 6 (R22: the damaged store came back as a plain action error);
- `round_per_segment` after 2 (I3).

**Tamper suite on the changed client:** 36 of 36.

#### Run 3 (committed harness `8cc8df6`) — SC-23 **PASS**, full regression PASS

`evidence/phase3-sc23-run3-*`.
- **SC-23:** 6 × 50 runs, 0 violations, 8 of 8 mutants caught. Identical to run 2 except a wall-clock timestamp inside one violation message.
- **Regression:**
  - SC-22: PASS (the race-cell mutant caught after 1 run, as before);
  - SC-21a, SC-20 and SC-19: identical to their previous runs;
  - SC-20 real tmpfs leg: 50 of 50;
  - phases 0, 1 and 2 (10 seeds, 300 runs): PASS;
  - tamper: 36 of 36.
- **Provenance:** the SC-23 to SC-21a logs say `commit 8cc8df6`. Later logs say `e50aac3` or `cf2bcd1`: three commits from other sessions (the desktop spike decisions, the tenant-isolation note, a studio update) landed during the run. None changes this folder (`git diff 8cc8df6 cf2bcd1 -- prototypes/local-first-sync-spike` is empty), and the tamper suite ran with the folder clean.

**Finding P3-F6 — judging by version alone counts some current-price sales as "previous price".** A sale made while its version was still current, but uploaded after the next version was published, also lands in that version's summary. The server cannot tell the two apart without trusting device time, which the founder's rule excludes. **Decision (founder, 2026-10-17):** keep judging by `cfg_version` only. The owner summary may show the device's sale time as context, labelled unverified, and never uses it to decide. Wording: "N sales billed at a price list that was no longer current when they reached the server (device times, unverified: …)".

**For the billing and config spec (founder, 2026-10-17):** the dashboard refuses to publish a price list that lacks a required setting (a tier price, the rounding step, the minimum minutes) and names what is missing. The device's `no_price_list` / `price_missing` refusal is the last defence, not the normal path. The spike's server stub accepts any list, so cell `e` tests only that last defence.

**Not covered:**
- **Rounding settings beyond the step:** minimum billable minutes and the billing increment are owner settings (OQ8) but not exercised; they belong to the billing spec.
- **The billing rules themselves** (rounding, minimum minutes, per-segment or total rounding): placeholders until OQ8.
- **The owner's summary wording and dashboard view:** belong to the spec.
- **Permission revocation:** a later cell, as above.

### Phase 3 — SC-25a: a 7-day offline backlog drained over short online windows, each cut mid-drain

**Load (sync note OQ16, founder 2026-10-17), labelled "derived from capacity, not measured":**
- **The bound:** 25 stations, 24 h, one session per station every 30 minutes (1,200 sessions/day), 3 café orders per session (3,600/day): about 5,000 money commands/day.
- **The longest offline period:** 7 days, about 35,000 commands. It drains over online windows of a few minutes at shift changes, which can end mid-drain.
- **Replace** the bound with a measured busy day when the founder supplies one.

**Design under test:**
- **Client (`RETENTION=1`), adaptive batch size:** start at 50; a sync that times out halves the batch, down to 1; a successful one grows it by a quarter (additive increase, multiplicative decrease).
- **Driver:**
  - Generates the 7 days offline as real committed sales: sessions of 10–40 minutes and café orders, in the OQ16 mix.
  - Opens 6 online windows through Toxiproxy. The first 5 end with a seeded cut on the last batch: request cut (the server does not commit), reply cut after the commit (the reply is lost) or connection reset. The 6th drains to the end.
  - Throttles one window's uplink to 3 KB/s, where a 50-command batch exceeds the 2 s HTTP timeout.
  - Has the cashier keep selling during and between windows.

**Checks:**
- **R23:** every window advances the device's acknowledged mark. That is the drain progress: after a lost reply the next window may collect only "duplicate" acknowledgements, which move the device and not the server cursor. The final cursor equals all commands, and duplicates stay within one batch per cut.
- **I1, I2, I4, I7** apply at the end over every command.

**Mutants:** `fixed_batch` (never shrinks), `drop_on_send` (outbox rows deleted when sent, before any reply).

#### Run 1 (dev, uncommitted harness on `15f1943`) — PASS

`evidence/phase3-sc25a-run1-dev-*`.
- **Full size** (3 seeds), 0 violations. Acked commands per window, slow window marked:

| Seed | Commands | Generate s | Total s | Acked per window | Duplicates |
|---|---|---|---|---|---|
| 1 | 34,479 | 342.3 | 509.0 | 4100, 3700, 5200, 656 (slow), 4311, 16512 | 170 |
| 2 | 34,482 | 321.1 | 554.1 | 3650, 5250, 1154 (slow), 4827, 3200, 16401 | 170 |
| 3 | 34,476 | 352.9 | 518.4 | 4400, 3050, 2900, 5500, 679 (slow), 17947 | 236 |

- **One-tenth size** (about 3,440 commands): 28 of 30 seeds completed with 0 violations before the session ended. The clean run repeats all 30.
- **Mutants:** both caught after 1 run. `fixed_batch`: the slow window made no progress (R23). `drop_on_send`: after the first cut every later command was gone, so 3,190 acknowledged sales never reached the server (I1, R23).
- **Cost:** generating the backlog takes about 9–10 ms per sale (a real commit with rollback journal and marker fsyncs, on NVMe), so 34,500 sales take about 5.5 minutes. On the HDD reference PC this cost is SC-26's concern (phase 4).

#### Run 2 (committed harness `a5900db`, fix `be11ae1`) — SC-25a **PASS**; the regression found a phase 2 gap, fixed and guarded

`evidence/phase3-sc25a-run2-*`.
- **SC-25a on `a5900db`:** one-tenth size 30 of 30 and full size 3 of 3 (about 34,480 commands each), 0 violations, both mutants caught (3,527 s). Timings are slower than run 1, because other sessions shared the machine; they are indicative only.
- **Regression on `a5900db`:** everything passes except phase 2.
  - SC-23, SC-22, SC-21a, SC-20 and SC-19 match their previous runs, except a timestamp in a violation message (SC-23) and the race detail of the SC-22 mutant caught after 1 run.
  - SC-20's real tmpfs leg: 50 of 50. Phases 0 and 1: PASS. Tamper: 36 of 36.
  - **Phase 2: gate FAIL** (`-a5900db-p2-FAIL.log`). SC-25a had added its `bandwidth_3k` toxic to the shared `TOXICS` table, from which phase 2 derives its cells and its random campaign. Phase 2 therefore gained a cell whose toxic never bites with its small batches (NOT ASSESSED, so the gate failed), and the campaign's fault choice shifted. No money check failed and all phase 2 mutants were caught; it was a test regression.
- **Fix `be11ae1`:** the toxic moves to its own table, and a **guard** (`harness/pins.py`, section "Pinned cell lists" above) makes phase 2 and the tamper suite stop at once if their cell lists change (`evidence/phase3-pins-guard-check.txt`: passes for the current lists; a leaked toxic and a dropped tamper row both stop with a clear message).
- **Re-run on `be11ae1`** (log headers `commit be11ae1`, no `+dirty`):
  - phase 2 at 10 seeds per cell and 300 runs: PASS, identical to the pre-SC-25a run except TS-09's sale count (15 against 16), which depends on wall-clock outages, not on the seed;
  - tamper: 36 of 36 with the guard;
  - SC-25a at one-tenth size: 30 of 30, progress per window identical to `a5900db`, both mutants caught.
- **Still owed:** the phase 3 gate campaign re-runs phase 2 at full size (section "Pinned cell lists").

**Finding P3-F7 — on a slow link the batch size must grow back slowly.** In the first dev attempt the client doubled its batch after every success. On the 3 KB/s uplink it went 50 → 25 → 12 → 24 → 25: each success jumped straight back to a size that timed out again, so most syncs failed. With additive increase and multiplicative decrease the batch settles at the link's capacity (11–25 commands) and the window keeps draining.

**Finding P3-F8 (harness) — after a lost reply, drain progress is on the device, not on the server cursor.** The first version of R23 measured the server cursor and flagged the slow window as stuck. It was not: it followed a cut where the server had committed a batch whose reply was lost, so its first successful batches were all `duplicate`. The device advanced and the server cursor did not. R23 now measures the device's acknowledged mark.

**Observation:** a variant of `drop_on_send` that also advanced the acknowledged mark would be healed by SC-19's reconciliation: the server, behind the device, asks for a resend from the retained bills. That is why the planted defect deletes the outbox rows without moving the mark.

**Not covered:**
- **ETA's 24-hour late-submission route:** the spike has no ETA channel.
- **Drain time on the HDD reference PC or a real venue link:** phase 4 and S105.
- **Several devices draining at once:** server load is S201.

### Phase 3 — SC-25b: the N5 offline lease runs out mid-shift (mechanics, injected clocks)

**Founder rule under test (2026-10-17, sync note OQ3):**
1. The cashier and the owner are warned 24 hours before the offline lease ends (G = 7 days on the base plan, licensing note).
2. At expiry, open sessions can still be closed and paid; no money is lost.
3. No new session and no new sale until the device reaches the server.
4. Local data stays readable and exportable, and the whole backlog is accepted when the device reconnects.

The lease is counted on server time plus the device's monotonic counter, never the Windows clock (founder design input in `docs/research/licensing.md` § 5; one clock with D1-B).

**Design under test (`LEASE=1`):**
- **Server:** every contact (a batch reply, a config pull) issues a lease `{server_time, grace_s, warn_s}` (7 days and 24 h, from the server's settings). The owner's warning and expiry come from the server's own clock and the last lease issued, so the owner is warned even while the device is offline. The server never refuses a backlog because a lease ran out.
- **Device:**
  - Stores the server time and its monotonic reading at each contact, and counts on the monotonic counter only.
  - Every reply carries the lease status (`ok`, `warning`, `expired`).
  - After expiry, `start_session` and `sell_items` (and the older `sale`) are refused with `lease_expired`. `close_session`, `export` and `stats` still work.
  - A wall clock that moves more than 5 minutes against the monotonic counter is recorded and sent to the owner.
- **Injected clocks (spike test hooks):** the driver moves the device's monotonic counter and the server's clock by the same amount; in one cell it moves the wall clock alone.

**Cells:**

| Cell | Script | Expected |
|---|---|---|
| `a_expiry_mid_shift` | sessions open, then offline; day 5, then 6 d 22 h, then 7 d 1 h | day 5: no warning, a sale works. 6 d 22 h: cashier and owner warned. 7 d 1 h: new session and sale refused; both open sessions closed and paid; export works. Reconnect: backlog accepted, lease renewed, new session works |
| `b_wall_clock_back` | as `a`, with the Windows clock set back 3 days before 6 d 22 h | the same timeline (the wall clock changes nothing); the owner gets a `wall_clock_moved` alert |
| `c_warning_boundary` | one minute before and one minute after the start of the last 24 h | no warning, then warnings on the device and for the owner; after reconnect the lease is renewed in full |

**Checks added:**
- **R24:** device and owner warnings exactly in the last 24 hours.
- **R25:** no new session or sale after expiry; sales work before it.
- **R26:** open sessions closed and paid after expiry; I1 then checks they reach the server.
- **R27:** export works after expiry.
- **R28:** after reconnect the backlog is accepted and the lease renewed in full.
- **R29:** the wall-clock change reaches the owner.

**Mutants:** `wall_clock_lease`, `expiry_blocks_close`, `no_warning`, `reject_after_expiry` (the server refuses an expired device's backlog), `no_heartbeat`.

#### Run 1 (dev, uncommitted harness on `5352924`) — PASS

`evidence/phase3-sc25b-run1-dev*`, 19 s.
- **Cells:** all 3 PASS, 20 seeds each, 0 violations.
- **Mutants:** all five caught.
  - `wall_clock_lease` after 2 runs: with the wall clock set back 3 days, a sale went through after the real expiry (I8, R25).
  - `expiry_blocks_close` after 1 (R26).
  - `no_warning` after 1 (R24).
  - `reject_after_expiry` after 1: the backlog never reached the server (I1).
  - `no_heartbeat` after 3 (R28).

#### Run 2 (committed harness `04996e2`) — SC-25b **PASS**, full regression PASS

`evidence/phase3-sc25b-run2-*` (every log header `commit 04996e2`, no `+dirty`).
- **SC-25b:** 3 × 20 runs, 0 violations, 5 of 5 mutants caught after the same number of runs as run 1.
- **SC-25a:** one-tenth size 30 of 30 and full size 3 of 3, 0 violations, both mutants caught. Progress per window matches `a5900db`, except the slow-uplink window, which differs by about ±10 commands: how many batches finish inside the real-time timeouts on a throttled link is timing, not seed.
- **Earlier cases:** SC-23, SC-22, SC-21a, SC-20 (and its real tmpfs leg, 50 of 50) and SC-19 PASS, matching their previous runs. The only differences are wall-clock timestamps inside violation messages and the race detail of the SC-22 mutant.
- **Earlier phases:** phase 0, phase 1 and phase 2 (10 seeds, 300 runs) PASS; phase 2's TS-09 sale count is 15 against 16, a wall-clock effect. Tamper: 36 of 36.
- **The pinned-list guard** passed for phase 2 and tamper.

**Finding P3-F9 — the lease must be renewed even when there is nothing to upload.** In the first attempt, a device that came back online with an empty outbox kept its old lease: its sync returned early and never contacted the server. A device used only to view data, or one that had already drained, would then run out of lease while connected. The client now sends an empty batch as a heartbeat. The server stub returned `"results": null` for an empty batch, which the client rightly rejected (P2-F1); it now always returns a list.

**Not covered:**
- **Reboots and powered-off time:** the monotonic counter restarts at boot; this is licensing note part 3.
- **Restoring an older state file:** the TPM clock question.
- **A signed lease:** the Ed25519 library is licensing note part 2. The spike's lease is unsigned.
- **Plan-specific lease lengths and an emergency unlock:** OQ3 is still open on both.
- **A real Windows clock change:** S304, phase 4.

### Phase 3 — SC-28: the owner edits an open bill from the dashboard

**Founder rule under test (2026-10-17, sync note OQ9 (2) and (3)):**
1. The owner may edit an open bill or session from the dashboard **only while the device is connected**.
2. The edit goes to the device as a command. The device applies it and confirms, and the dashboard shows "pending" until then.
3. If the device is offline, the dashboard refuses the edit.
4. If the bill closed first, the edit is rejected visibly.
5. A closed bill is changed only by a correction (void or adjustment) that keeps the original.

**Design under test (`EDITS=1`; the edit is "add n cafe items to session S"):**
- **Who writes what:** the server is the writer of the edit request, the device of the bill.
- **Server:**
  - `POST /edit` is idempotent on the edit id.
  - It is **refused, and nothing is stored**, when the device has not been in contact within the presence window (spike: 15 s of server time).
  - It is **rejected at once** (`bill_closed`) when the server already holds the closing bill.
  - Otherwise it is stored as `pending`, with a deadline (spike: 120 s).
  - Every batch reply carries the device's pending edits and the server's time, and records the delivery.
- **Device:**
  - It decides each edit **once, at receipt**, in the same transaction as the acknowledgement. The edit is `applied` if the session is still open and the reply's server time is before the deadline. Otherwise it is `rejected` with `bill_closed`, `unknown_session` or `expired`.
  - The decision and its result command are written together. The result is an ordinary command in the device sequence (same outbox, same dedupe).
  - An edit id already decided is never decided again.
  - A sync with nothing to send still contacts the server (heartbeat), so a connected device receives edits.
  - `close_session` adds the applied edits' items at the price list held at close.
  - Edit results are retained like bills, so a server restore (SC-19) can rebuild them.
- **Deadline:**
  - An edit **never delivered** by its deadline is rejected by the server (`device_unreachable`) and is never sent afterwards.
  - An edit **delivered once** can be ended only by the device, because the reply may have reached it. It stays pending until the device's next contact.
- **Correction:** `POST /correction` records a new row, idempotent on its id. The original sale row is never rewritten.

**Cells:**

| Cell | Script | Expected |
|---|---|---|
| `a_connected` | Session open and device in contact. The owner adds 2 items (and presses again); then sync, sync, close | Dashboard: `pending` right after the edit, still `pending` until the result arrives, then `applied`. The repeated press is the same edit. The bill includes the items once |
| `b_offline` | Device cut and no contact for longer than the presence window; the owner edits | Answer 409 `refused / device_offline`. No edit row on the server. After reconnect the bill closes without the items |
| `c_race` | Seeds cycle through three orders: `edit_first` (edit applied, then close); `close_unsynced` (bill closed on the device, not yet uploaded, then edit); `close_synced` (closing bill already on the server, then edit) | `edit_first`: applied, included. `close_unsynced`: the device rejects `bill_closed`. `close_synced`: the server rejects `bill_closed` at once, nothing delivered. In both rejections the closed bill is unchanged, and a correction posted twice gives one correction row while the original sale keeps its amount |
| `d_cut` | Seeds cycle through four cuts: `reply_cut` (the reply carrying the edit is cut); `confirm_cut` (the upload of the device's result is cut by `resp_cut_20`, `req_cut_120` or `reset_peer`); `backlog` (3 offline sales queued, batch size 1, so the edit is offered with each batch until its result arrives); `deadline` (one edit delivered and applied, then the device is cut; a second edit accepted just before the cut; the server clock passes the deadline) | Applied at most once (the device's decision count is 1). Every edit ends `applied` or `rejected`, matching the device. `deadline`: at the deadline the undelivered edit reads `rejected / device_unreachable` and is never delivered; the delivered one still reads `pending` and ends `applied` when the device comes back |

**Checks added:**
- **R30:** each edit ends as the model says; it is decided once on the device; the dashboard shows `pending` before the confirmation and `applied` after it.
- **R31:** an edit to an offline device is refused, and nothing is queued.
- **R32:** an edit that loses the race to the close is rejected visibly (at once if the server holds the bill). A correction is one new record carrying the original amount.
- **R33:** no edit is still pending after quiescence, and the server's state matches the device's decision both ways.
- **R34:** an undelivered edit expires on the server and is never delivered. A delivered one is left to the device.
- **I3** checks every bill's amount against the driver's model, edits included. **I8** reports an `edit_conflict` flag (a device result that contradicts the server's state).

**Mutants:**
- `edit_apply_twice` (client): no dedupe on the edit id.
- `edit_after_close` (client): answers "applied" for a closed bill.
- `queue_when_offline` (server): stores edits for an offline device.
- `expire_delivered` (server): rejects delivered edits at the deadline too.
- `correction_rewrites` (server): changes the original sale.

#### Run 1 (dev, uncommitted harness on `daeb489`) — PASS

`evidence/phase3-sc28-run1-dev*`, 33 s.
- **Cells:** all 4 PASS, 24 seeds each, 0 violations. `c_race` ran each order 8 times; `d_cut` ran each cut 6 times (`confirm_cut` used each of its three faults twice).
- **Exercised:** `reply_cut` and `backlog` count only when the server delivered the edit at least twice. The samples in the summary show 2 deliveries after a cut reply and 3 during the backlog, each applied once. In `close_synced` the edit was rejected by the server with 0 deliveries. In `deadline` the undelivered edit ended `rejected / device_unreachable` with 0 deliveries.
- **Mutants:** all five caught.
  - `edit_apply_twice` after 12 runs, in the `backlog` cut: the re-offered edit was applied three times (bill 15,000 against 9,000, I3).
  - `edit_after_close` after 7 (R30).
  - `queue_when_offline` after 2 (I3: the queued edit reached the device after reconnect).
  - `expire_delivered` after 16, in the `deadline` cut: the device's "applied" contradicted the server's expiry (I8 `edit_conflict`).
  - `correction_rewrites` after 7 (I3: the original sale changed).
- **Smoke on the changed client and server:** SC-19 (3 seeds), SC-25b (3) and SC-23 (2) PASS with every mutant caught. The full regression follows on the committed harness.

#### Run 2 (committed harness `a77dfa3`) — SC-28 **PASS**, full regression PASS

`evidence/phase3-sc28-run2-*` (every log header `commit a77dfa3`, no `+dirty`).
- **SC-28:** 4 × 24 runs, 0 violations. All five mutants were caught after the same number of runs as run 1.
- **Earlier cases:** SC-25b, SC-25a (one-tenth size 30 of 30 and full size 3 of 3), SC-23, SC-22, SC-21a, SC-20 (and its real tmpfs leg, 50 of 50) and SC-19 PASS, every mutant caught. SC-25a's progress per window again varies with timing only on the slow-uplink window.
- **Earlier phases:** phase 0, phase 1 and phase 2 (10 seeds, 300 runs) PASS. Phase 2's TS-09 sale count is 16 against 15 on `04996e2`, a wall-clock effect. Tamper: 36 of 36.
- **The pinned-list guard** passed for phase 2 and tamper.

**Finding P3-F10 — once an edit has been sent, only the device can end it.** A reply carrying the edit may or may not have arrived, so after delivery the server cannot safely declare it rejected. If it did and the device had applied it, the dashboard would say "rejected" while the bill includes the items (`expire_delivered` shows exactly this). The rule "pending ends in applied or rejected, never stuck" therefore holds in two parts:
- **Never delivered:** the server ends the edit at its deadline and never sends it afterwards.
- **Delivered:** the device ends it at its next contact. Until then the dashboard must say "sent to the device at X, waiting for it", not just "pending".

A device that goes offline right after receiving an edit keeps that edit open on the dashboard until it reconnects. **Decided (founder, 2026-10-18), for the dashboard spec:**
- P3-F10 is acceptable. Until the device confirms, the dashboard shows "sent to the device at X, waiting for it", and it never shows "rejected" for a delivered edit.
- While an edit to a bill has been delivered and is not yet confirmed, the dashboard refuses a second edit to the same bill. The spike does not build this refusal; it is a dashboard rule.

**Not covered:**
- **Real presence:** a live channel (WebSocket or SSE) instead of "contact within 15 s". The window, the deadline (120 s) and the dashboard wording are spike values, for the dashboard and billing specs.
- **Edits other than "add items":** remove an item, change a tier, move a station.
- **Several dashboard users editing one bill at once.**
- **Corrections reaching the device and the ETA Return Receipt** (OQ9 (3); ETA note).
- **Authorisation:** who may edit, and the audit record.

### Phase 3 — SC-29: stock policy per item

**Founder rule under test (2026-10-17, sync note OQ9 (1)):**
1. Per item, the owner chooses "allow negative stock and alert" or "refuse the sale".
2. New items default to "allow and alert".
3. A policy change applies when the device receives it (as SC-23 rule 3).

**Design under test:**
- **Server:**
  - `POST /stock` edits the item catalogue (price, and policy `allow_alert`, `refuse` or none) and records stock receipts. Each change is a new config version, sent on the config feed.
  - A sale's item lines move the server's stock mirror (receipts minus items sold), and its `neg_alerts` become owner alerts. Both are effects of the applied command, so the inbox keeps them single across resends and restores.
  - The server never refuses a sale for stock: the device decided from the policy it held (OQ6).
- **Device:**
  - Applies a feed when it receives it: the catalogue is replaced, and each receipt is added to its stock once (receipt id).
  - `sell_stock` decides from the policy it holds. A `refuse` item without enough stock refuses the **whole** sale with `out_of_stock`, naming the items; nothing is billed and no stock moves. An `allow_alert` item (or one with no policy) may go negative.
  - Stock is decremented in the bill's transaction.
- **When the owner is alerted (founder, 2026-10-18):** when an item's stock **crosses** from ≥ 0 to < 0. There is no alert on further negative sales, and the next alert comes only after a restock brings the item back to ≥ 0 and it crosses again. Offline that is at most once per item per offline period, because a restock needs the feed. The alert rides the sale command.
- **Old-policy sales (founder, 2026-10-18):** folded into the SC-23 owner summary, so there is one summary per period in which the device lacked the current config, keyed by the old `cfg_version`. It counts every sale under that version (`n_sales`, as SC-23 does). Among them it also counts the sales of an item whose policy at that version differs from its policy now (`n_policy`), and lists those items. The server keeps each item's policy per config version to judge this.

**Cells:**

| Cell | Script | Expected |
|---|---|---|
| `a_allow_offline` | snack (allow, stock 1) and gum (no policy, stock 0). Offline: snack ×3, gum ×1, then snack + gum. Online: the owner restocks snack +5, then snack ×3 | Every sale goes through. Alerts: snack once offline, gum once (the default is allow), snack again after the restock crossing. Final stock snack −1, gum −2 on device, server and model |
| `b_refuse_offline` | cola (refuse, stock 1) and snack (allow, stock 0). Offline: cola, cola, cola + snack, snack. Online: restock cola +2, then cola ×2, cola | Last cola sold; the next cola and the mixed sale refused whole (`out_of_stock`, naming cola); snack goes negative with one alert; after the restock cola ×2 sells and the next cola is refused |
| `c_restore` | snack (allow, 1) and cola (refuse, 1). Backup, then the last snack and one more, and the last cola; synced. The server is restored from the backup and the device resends; then cola again and snack again | The restored server asks for the resend. Each sale is on the server once, with one snack alert. The second cola is refused (the device's stock says 0); the later snack sale goes further negative without a new alert |
| `d_policy_change` | snack allow, cola refuse, gum allow, stock 0. Offline, the owner swaps snack and cola; the device sells one of each, and a gum. Online, after the pull, snack and cola again | Offline: snack sells under the allow it holds, cola is refused under the refuse it holds, gum sells. After the pull: snack refused, cola sells. One alert each. One owner summary for the old version: 2 sales, 1 of them an old-policy sale (snack) |
| `e_dup_reply` | snack (allow, 0) sold; the reply of the sync that uploads it is cut (`resp_cut_20`); the resend is answered `duplicate` | One sale, one alert |

**Checks added:**
- **R35:** a refuse item without stock refuses the whole sale at the counter, naming the item. Nothing is billed: I8 catches a bill that reached the server anyway.
- **R36:** an allow item goes negative, and the owner gets exactly one alert per crossing below zero.
- **R37:** a new item behaves as allow-and-alert.
- **R38:** a policy change applies when the device receives it, not before.
- **R39:** device stock, server mirror and the driver's model agree for every item.
- **R40:** exactly one owner summary per period in which the device lacked the current config, with the sale count and the old-policy sales and items the model expects; no summary in a cell with no such period.

**Mutants:**
- `refuse_ignored` (client): the refuse policy is not enforced.
- `alert_every_sale` (client): every negative sale alerts.
- `default_refuse` (client): a new item defaults to refuse.
- `stale_policy` (client): a policy once held is never updated.
- `alert_outside_inbox` (server): alerts are recorded for every command received, duplicates included.
- `summary_ignores_policy` (server): the summary counts the sales but never the old-policy ones.

#### Run 1 (dev, uncommitted harness on `f4aa0ab`) — PASS

`evidence/phase3-sc29-run1-dev*`, 42 s (rerun after the founder's answers added R40).
- **Cells:** all 5 PASS, 20 seeds each, 0 violations.
- **Exercised:** `c_restore` counts only when the restored server asked for a resend. `e_dup_reply` counts only when the cut sync failed and the resend was answered `duplicate`.
- **Mutants:** all six caught.
  - `refuse_ignored` after 2 runs: the refused cola reached the server as a sale nobody submitted (I8).
  - `alert_every_sale` after 1 (R36: 4 snack alerts against 2).
  - `default_refuse` after 1 (R37).
  - `stale_policy` after 4, in `d_policy_change`: after the pull the device still sold snack under the old allow (I8).
  - `alert_outside_inbox` after 5, in `e_dup_reply` (R36: 2 alerts against 1).
  - `summary_ignores_policy` after 4, in `d_policy_change` (R40: `n_policy` 0 against 1).
- **Smoke on the changed client and server:** SC-28 (4 seeds), SC-23 (3, after the summary change) and SC-19 (2) PASS with every mutant caught. The full regression follows on the committed harness.

#### Run 2 (committed harness `6e2ecff`) — SC-29 **PASS**, full regression PASS

`evidence/phase3-sc29-run2-*`. No log is marked `+dirty`.
- **Log headers:** two other-session commits landed on `main` while the run went on: `4edb8af` and `2309b5c`, ADR documents only. The harness stamps HEAD, so later logs name those commits: SC-23 onwards say `6e2ecff`, SC-22/21a/20 say `4edb8af`, and the rest say `2309b5c`. Neither commit touches the spike folder or the sync note (`git diff 6e2ecff 2309b5c -- prototypes/local-first-sync-spike` is empty). Every step therefore ran the `6e2ecff` harness.
- **SC-29:** 5 × 20 runs, 0 violations. All six mutants were caught after the same number of runs as run 1.
- **Earlier cases:** SC-28, SC-25b, SC-25a (one-tenth size 30 of 30 and full size 3 of 3), SC-23, SC-22, SC-21a, SC-20 (and its real tmpfs leg, 50 of 50) and SC-19 PASS, every mutant caught.
- **Earlier phases:** phase 0, phase 1 and phase 2 (10 seeds, 300 runs) PASS; TS-09 counted 16 of 16 sales. Tamper: 36 of 36.
- **The pinned-list guard** passed for phase 2 and tamper.

**Founder decisions (2026-10-18):** (1) alert at the crossing below zero, as built; (2) old-policy sales go into the SC-23 owner summary rather than a separate note (R40).

**Not covered:**
- **Several devices selling the same stock in one branch:** S203, after Tier 1.
- **Stock counts and adjustments by the owner** other than receipts (damage, count corrections).
- **Recipes:** an item that uses up other stock.
- **The refusal message in Arabic and English:** the desktop spike's G3 and the UI spec.

### Phase 3 — SC-30: the cashier PC is off while sessions run (mechanics, injected clock)

**Founder rule under test (2026-10-17, sync note OQ8 (3)):**
1. If the cashier PC is off while a session runs, the time keeps counting.
2. The owner sees a "device was off from X to Y" notice when it restarts.
3. No session minute is lost or counted twice.

**Design under test (`CLOCKED=1`; D1-B from Part D):**
- **Injected clock:** `<db>.testclock` holds `{boot, mono, wall}`, written by the driver. A new boot id with a restarted monotonic counter means the PC was powered off. The same boot id with the counter still running means only the app was killed.
- **Session time:** a session is anchored at (boot, monotonic reading) and accumulates time across outages. Billable minutes are whole minutes, rounded down; the owner's minimum and increment are not exercised (billing spec).
- **Last-alive checkpoint:** the app's one-minute timer (`tick`) writes (boot, monotonic, wall) to the store.
- **At start, in one transaction:**
  - **Earlier boot:** every open session gets (checkpoint monotonic − its anchor) + (wall now − checkpoint wall), and its anchor moves to the new boot. The two parts meet at the checkpoint, so nothing is counted twice.
  - **Same boot:** nothing to add; the monotonic counter kept running.
  - **Gap longer than the tick interval (60 s):** a `device_off` record (`power_off` or `app_down`, from = checkpoint wall, to = restart wall, open session count) is queued as a command in the device sequence. The server records it once; the inbox keeps it single.
  - **The checkpoint is refreshed** in the same transaction.
- **What the owner sees (founder, 2026-10-18):** every outage longer than a minute stays visible.
  - **With open sessions:** an owner notice at once, because money is affected.
  - **With no open session:** the owner's daily summary only, no notice. A PC switched off in business hours with nothing recorded is a known way to take cash off the books.
  - **Two kinds, told apart:** "PC was off" (the boot id changed) and "App was closed while the PC was on" (same boot id). The second is the more suspicious one and says so ("unusual: check why the app was closed").
  - **Phase 4:** the boot-id signal on Windows (which value changes on a reboot, and how sleep and hibernate behave) is still to be confirmed (S301/S302).
- **Trust:** the outage bounds rest on device wall time. Phase 5 tests them with tampered clocks.

**Cells** (seeds vary the time between the last checkpoint and the cut by 0–30 s):

| Cell | Script | Expected |
|---|---|---|
| `a_off_minutes` | Session open 20 min, PC off 7 min (30 s boot), then 15 min more, close | Bill = true elapsed minutes. One "PC was off" notice at once, from the last checkpoint to the restart, 1 open session |
| `b_off_hours` | As `a` with the PC off 3 h 17 min | The same, over hours |
| `c_app_kill` | Session open 12 min, app killed 5 min, restart; 3 min later killed for 10 s, restart; close | One "app was closed while the PC was on" notice, marked unusual, for the 5-minute outage; nothing for the 10-second restart; the bill covers the whole time |
| `d_two_outages` | s1 open; off 4 min; s2 starts; off 2 h; both close | Two notices (1, then 2 open sessions); each session billed its own true time |
| `e_kill_mid_notice` | As `a`, but the first restart is killed inside the outage write; then the app restarts, crashes again 20 s later before its first timer tick, and restarts | One notice; the outage counted once; the second crash adds nothing and raises no notice |
| `f_idle_outages` | Nothing open: PC off 30 min, later the app closed 10 min with the PC on; then a session runs 5 min | Both outages in the daily summary only, no notice; the app closure marked unusual; the later session billed normally |

**Checks added:**
- **R41:** every session is billed its true elapsed time across outages. I5 and I3 check the same on the server rows.
- **R42:** exactly one record per outage longer than the tick interval, with the checkpoint and the restart as its bounds and the open session count; none for a quicker restart. With open sessions it is a notice (owner alert); with none it goes to the daily summary only. App closures (same boot) are marked suspicious; PC power-offs are not.
- **R43:** a kill inside the outage write, or a crash before the first tick after a restart, changes neither.

**Mutants:**
- `outage_not_counted` (client): the wall-clock part of an outage is dropped.
- `mono_across_boot` (client): the anchor is not moved, so monotonic readings from two boots are subtracted.
- `no_alive_update` (client): the checkpoint is not refreshed at start.
- `notice_outside_txn` (client): the notice is written after the adjustment commits.
- `notice_every_restart` (client): a notice even for a restart inside the tick interval.
- `idle_outage_hidden` (server): an outage with no open session is dropped.
- `all_outages_notify` (server): every outage is sent as a notice.
- `app_down_not_flagged` (server): an app closure is not marked suspicious.

#### Run 1 (dev, uncommitted harness on `68ad1e1`) — PASS

`evidence/phase3-sc30-run1-dev*`, 78 s (rerun after the founder's answers added `f_idle_outages` and the routing checks).
- **Cells:** all 6 PASS, 20 seeds each, 0 violations. Seed 1 billed 42 min in `a`, 232 min in `b`, 26 min in `c`, 150 + 139 min in `d` and 43 min in `e`, each equal to the true elapsed time.
- **Mutants:** all eight caught.
  - `outage_not_counted` after 1 run (I3: 35 min billed against 42).
  - `mono_across_boot` after 1 (I3: a negative amount).
  - `no_alive_update` after 5, in `e` (R43: a second notice and the outage counted again).
  - `notice_outside_txn` after 5, in `e` (R43: the notice was lost).
  - `notice_every_restart` after 3, in `c` (R42).
  - `idle_outage_hidden` after 6, in `f` (R42: the outages were missing).
  - `all_outages_notify` after 6, in `f` (R42).
  - `app_down_not_flagged` after 3, in `c` (R42).
- **Smoke on the changed client and server:** SC-23 (2 seeds), SC-25b (3), SC-28 (4), SC-29 (3) and SC-19 (2) PASS with every mutant caught. The full regression follows on the committed harness.

**Design consequence (shown by the `no_alive_update` mutant):** the checkpoint must be refreshed in the start-up transaction, not left to the first timer tick. In the first draft every restart was followed at once by a tick, which hid the defect. An app that crashes again before its first tick would then count the same outage a second time and repeat the notice.

#### Run 2 (committed harness `c23f137`) — SC-30 **PASS**, full regression PASS

`evidence/phase3-sc30-run2-*`. No log is marked `+dirty`.
- **Log headers:** two other-session commits landed during the run, `35fcc26` (desktop notes) and `676b9da` (ADR documents). SC-30 says `c23f137`, SC-29 to SC-25b say `35fcc26`, and the rest say `676b9da`. Neither commit touches the spike folder or the sync note (`git diff c23f137 676b9da -- prototypes/local-first-sync-spike` is empty), so every step ran the `c23f137` harness.
- **SC-30:** 6 × 20 runs, 0 violations. All eight mutants were caught after the same number of runs as run 1.
- **Earlier cases:** SC-29, SC-28, SC-25b, SC-25a (one-tenth size 30 of 30 and full size 3 of 3), SC-23, SC-22, SC-21a, SC-20 (and its real tmpfs leg, 50 of 50) and SC-19 PASS, every mutant caught.
- **Earlier phases:** phase 0, phase 1 and phase 2 (10 seeds, 300 runs) PASS; TS-09 counted 16 of 16 and 15 of 15 sales (a wall-clock effect). Tamper: 36 of 36.
- **The pinned-list guard** passed for phase 2 and tamper.

**Founder decisions (2026-10-18):** (1) every outage longer than a minute is shown: a notice at once with open sessions, the daily summary only without; (2) "PC was off" and "app was closed while the PC was on" are separate, and the second is marked unusual. The Windows boot-id signal is to be confirmed in phase 4 (S301/S302).

**Not covered:**
- **Tampered clocks:** phase 5. A wall clock set back during the outage shortens the bill.
- **Real reboots, sleep and hibernate on Windows:** the boot id and monotonic behaviour, S301–S305 in phase 4. The founder's split between "PC was off" and "app was closed" rests on the boot id, so S301/S302 must confirm it.
- **The daily summary itself:** the spike records the channel; the summary's content and schedule are for the dashboard spec.

### Phase 3 — SC-31: End Day

**Founder rule under test (2026-10-17, confirmed 2026-10-18; sync note OQ8 (4)):**
1. There is no cut-off hour. The business day is opened and closed by an explicit **End Day**, independent of the calendar.
2. End Day is **refused while any bill, session or shift is open**, so a session and its bill always belong to the same business day.

**Design under test (`ENDDAY=1`):**
- **Business day:** a device counter, not a date. Every bill carries the day it was paid in (`bday`). After End Day, the first action (a sale, a session, a tab or a shift) opens the next day.
- **`end_day`:**
  - Refused with `day_has_open_items` while a tab (an open bill), a session or a shift is open. The reply names each one.
  - Otherwise one transaction writes the End Day command (kind `end_day`: the day, its bill count and total) as an ordinary command in the device sequence, and closes the day.
  - On a day already closed it is refused with `no_open_day`; pressing it twice creates no empty day.
- **Server:** applies the End Day command in sequence order, so every bill of that day is already applied. It recomputes count and total from the bills it holds for the day and records both. A mismatch is flagged (`day_close_mismatch`), and so is a bill for a day already closed (`bill_after_day_close`).
- **Not modelled:** what a shift contains (the shift spec). Tabs and shifts here are only open or closed.

**Cells:**

| Cell | Script | Expected |
|---|---|---|
| `a_nothing_open` | Day 1: 2 cafe sales and a session closed; End Day; End Day again; a sale; End Day | Day 1 closes with 3 bills; the second press is refused (`no_open_day`); the sale opens day 2, which closes with 1 bill |
| `b_open_bill` | A tab open, a sale; End Day; the tab paid; End Day | Refused naming the tab; then day 1 closes with both bills |
| `c_running_session` | A session running, a sale; End Day; the session closed; End Day | Refused naming the session; the session's bill is in day 1, the day it was paid in |
| `d_open_shift` | A shift open; End Day; then a tab and a session as well; End Day; tab paid and session closed; End Day; shift closed; End Day | Refused three times, each naming exactly what is open; then day 1 closes |
| `e_offline` | Offline: day 1 (sales and a session) closed, day 2 (a sale) closed; reconnect | Both days reach the server once, in order; server and device totals agree for each |
| `f_kill_end_day` | A kill inside the End Day transaction (odd seeds) or just after its commit with the reply lost (even seeds); then End Day again, a sale, End Day | After the kill the day is either still open with nothing queued (then End Day closes it) or closed with its command (then End Day is refused as already closed). Never half. The next day closes normally |

**Checks added:**
- **R44:** End Day is refused while a bill, session or shift is open, naming each one, and refused again on a closed day.
- **R45:** every closed day reaches the server once with the model's bill count and total, and the server's own recomputation agrees. A mismatch or a late bill is a server flag, so I8 reports it too.
- **R46:** a kill during End Day leaves the day closed with its command, or open without one.
- **R47:** every bill belongs to the day the model paid it in.

**Mutants:**
- `end_day_ignores_sessions` (client): running sessions do not block End Day.
- `refuse_without_names` (client): the refusal does not say what is open.
- `end_day_two_txns` (client): the day is closed, then the command written in a second transaction.
- `bill_old_day` (client): after End Day a bill is stamped with the closed day.

#### Run 1 (dev, uncommitted harness on `a66621b`) — PASS

`evidence/phase3-sc31-run1-dev*`, 44 s.
- **Cells:** all 6 PASS, 20 seeds each, 0 violations. In every closed day the device's count and total equal the server's recomputation (seed 1 of `a`: day 1 = 3 bills, 10,500; day 2 = 1 bill, 3,000).
- **Mutants:** all four caught.
  - `end_day_ignores_sessions` after 3 runs (R44: End Day closed the day with a session running).
  - `refuse_without_names` after 2 (R44).
  - `end_day_two_txns` after 6, in `f` (R46: the day was closed with no End Day command).
  - `bill_old_day` after 1 (I8: the server flagged a bill for a closed day).
- **Smoke on the changed client and server:** SC-23 (2 seeds), SC-30 (3) and SC-29 (3) PASS with every mutant caught. The full regression follows on the committed harness.

#### Run 2 (committed harness `56c8dbc`) — SC-31 **PASS**, full regression PASS

`evidence/phase3-sc31-run2-*`. No log is marked `+dirty`.
- **Log headers:** two other-session commits landed during the run, `37d226b` and `e5bd849` (ADR documents). SC-31 to SC-25b say `56c8dbc`, the rest say `e5bd849`. Neither commit touches the spike folder or the sync note (`git diff 56c8dbc e5bd849 -- prototypes/local-first-sync-spike` is empty), so every step ran the `56c8dbc` harness.
- **SC-31:** 6 × 20 runs, 0 violations. All four mutants were caught after the same number of runs as run 1.
- **Earlier cases:** SC-30, SC-29, SC-28, SC-25b, SC-25a (one-tenth size 30 of 30 and full size 3 of 3), SC-23, SC-22, SC-21a, SC-20 (and its real tmpfs leg, 50 of 50) and SC-19 PASS, every mutant caught.
- **Earlier phases:** phase 0, phase 1 and phase 2 (10 seeds, 300 runs) PASS; TS-09 counted 16 of 16 sales. Tamper: 36 of 36.
- **The pinned-list guard** passed for phase 2 and tamper.

**Not covered:**
- **What a shift is** (cashier hand-over, cash count): the shift spec.
- **The day-close report content and the cash count against it** (brief F3): the billing and reporting specs. The spike only checks that the device's and the server's counts and totals agree.
- **Several devices in one branch closing one business day:** S203, after Tier 1.
- **End Day under tampered clocks:** not needed, because the business day uses no clock.

### Phase 3 — SC-13 and TS-01a: a cloned disk, and a rollback that reuses synced sequence numbers (OQ7 policy)

**Founder policy under test (2026-10-17, sync note OQ7; confirmation at the sync threat model):**
1. The counter keeps selling locally.
2. Sync for that device identity is quarantined.
3. Every money command from both copies is stored, and none is dropped (as OQ6).
4. The owner is alerted and chooses in the dashboard which copy is the real device.

**Design under test (`CLONE_POLICY=1` on the server, `MACHINE_ID` on the client):**
- **Machine id:** every batch carries the machine id it came from, read from outside the store. On Windows it would be a hardware-bound id (phase 4). The first machine seen is registered for the device identity.
- **Detection:**
  - **Clone (SC-13):** a second machine id under one identity quarantines it at that copy's first contact, before any of its commands is applied.
  - **Rollback (TS-01a):** the store and its commit marker are restored together on the same PC, so the device starts normally. It then sends a sequence number the server holds with different content. That quarantines the identity at that command, which is stored, not flagged and dropped as before.
  - **Marker not restored:** a store restored without its marker is refused at start by the OQ28 marker check (tamper suite, `store_older_than_marker`).
- **In quarantine:**
  - Every command from every copy is stored (idempotent per copy) and acknowledged to the device as stored. Nothing reaches the ledger.
  - A clone's copy of a command applied before the fork is a plain duplicate.
  - The owner gets one alert. Every counter keeps selling, and replies tell the device it is quarantined.
- **The owner's choice (`POST /quarantine/resolve {device_id, keep}`):**
  - **Fork:** the kept copy's first quarantined sequence minus one.
  - **Refiled:** commands applied to the identity after the fork belong to the other copy, or to the timeline a rollback overwrote. They are refiled, with identical amounts, into a retired stream (`dev-1@<machine>` or `dev-1@overwritten`).
  - **Kept copy:** its quarantined commands are applied to the identity in order, and it continues normally.
  - **Other copies:** their quarantined commands are applied into their retired stream.
  - **Review queue:** every retired-stream sale is listed in the owner's review queue. Money is never dropped (OQ6).
  - **Retired copy:** its later batches go to its stream, and the reply tells it it is retired.
- **What the owner sees (founder, 2026-10-18), `GET /owner_report`:**
  - **Totals:** review-queue sales count in revenue and day-close totals at once, because the cash was taken and the totals must match the drawer. Until the owner marks them reviewed (`POST /review/ack`), they also show on their own labelled line, for example "of which 75.00 EGP from a retired copy, pending your review" (or "from a timeline a restore overwrote").
  - **During quarantine:** the device shows "held: N sales, X EGP" with the alert, so the owner sees the money is safe and acts.
- **Oracle:** per-device order (I4) is checked per stream.

**Cells:**

| Cell | Script | Expected |
|---|---|---|
| `a_clone_keep_original` | The original sells and syncs; 2 sales pending; the store is copied to a second machine (m2). The original syncs and sells 2 more (applied). The clone sells 3 and syncs. Both keep selling and syncing. The owner keeps m1; then each sells once more | Quarantine reason `second_machine` at the clone's first contact; the clone's copies of the 2 pending commands are duplicates. During quarantine nothing new reaches the ledger and every new command is stored. After the choice the original's quarantined sales join `dev-1`, and the clone's 5 sales sit in `dev-1@m2` and the review queue. The clone is told it is retired |
| `b_clone_keep_clone` | As `a`, but the owner keeps the clone (m2) | The original's 2 sales applied after the fork are refiled into `dev-1@m1` with its quarantined and later sales (5 in review). The clone continues `dev-1`, and the original is told it is retired |
| `c_rollback_ts01a` | 2 sales synced; snapshot of the store and marker; 3 more synced; the snapshot is restored over the live store on the same PC; the device sells 3 and syncs; the owner keeps m1 | Quarantine reason `sequence_reused` at the first reused number. The 3 restored-device sales are stored, then applied to `dev-1` after the choice. The 3 sales of the overwritten timeline stay on the server in `dev-1@overwritten` and the review queue |

**Checks added:**
- **R48:** the identity is quarantined for the right reason, with exactly one owner alert.
- **R49:** every counter keeps selling throughout.
- **R50:** in quarantine every command from every copy is stored, and none reaches the ledger.
- **R51:** after the owner's choice each sale sits in the stream the model expects. The review queue holds exactly the other copy's (or the overwritten) sales, and the retired copy is told so. I1 checks that none is dropped, I2 that none is doubled.
- **R52:** during quarantine the owner report shows "held: N sales, X EGP" with the alert, N and X as the model expects.
- **R53:** after the choice the report's total includes every sale of every copy, and the pending-review line equals the review queue. After the owner marks the streams reviewed, the line is gone and the total is unchanged.

**Mutants:**
- `drop_conflicting` (server): the old behaviour; a reused sequence is flagged and the command not stored.
- `no_machine_check` (server): the machine id is ignored.
- `resolve_drops_other` (server): the other copy's commands are discarded at the choice.
- `alert_each_batch` (server): an owner alert on every quarantined batch.
- `block_on_quarantine` (client): the counter refuses sales while quarantined.
- `review_not_in_totals` (server): retired streams left out of the totals.
- `held_hidden` (server): the held line omitted.

#### Run 1 (dev, uncommitted harness on `a1d820e`) — PASS

`evidence/phase3-sc13-run1-dev*`, 46 s.
- **Cells:** all 3 PASS, 20 seeds each, 0 violations. Rerun after the founder's answers added R52 and R53.
  - Seed 1 of `a`: 14 sales from two copies, each on the server once; the clone's 5 in `dev-1@m2` and in review. The owner saw "held: 6 sales, 90.00 EGP", then "of which 75.00 EGP from a retired copy, pending your review".
  - Seed 1 of `c`: 9 sales, the 3 overwritten ones in `dev-1@overwritten` and in review, shown as "of which 45.00 EGP from a timeline a restore overwrote, pending your review".
- **Mutants:** all seven caught.
  - `drop_conflicting` after 3 runs, in `c` (I1: the restored device's sales never reached the server). This is the behaviour before OQ7, and it loses money in a rollback.
  - `no_machine_check` after 1 (R48: the clone was caught only later, by a reused number).
  - `resolve_drops_other` after 1 (I1).
  - `alert_each_batch` after 1 (R48).
  - `block_on_quarantine` after 1 (R49).
  - `review_not_in_totals` after 1 (R53: total 135.00 EGP against 210.00).
  - `held_hidden` after 1 (R52).
- **Harness fixes during the dev run:** a failed owner choice raised an HTTP error mid-script; it now reads the refusal as an answer. A refused sale left an empty action id in the model's sets.
- **Smoke on the changed client, server and oracle:** the phase 0 self-test, SC-19 (2 seeds), SC-23 (2), SC-28 (4) and SC-31 (2) PASS with every mutant caught. The full regression follows on the committed harness.

#### Run 2 (committed harness `245ddde`) — SC-13 + TS-01a **PASS**, full regression PASS

`evidence/phase3-sc13-run2-*`. No log is marked `+dirty`.
- **Log headers:** two other-session commits landed during the run, `dc3e30b` (tenant-isolation threat model, ADR-0001 amendment) and `b9f3da6` (ADR-0005). SC-13 and SC-31 to SC-25b say `245ddde`, phase 2 says `b9f3da6`, the rest say `dc3e30b`. Neither commit touches the spike folder or the sync note (`git diff 245ddde b9f3da6 -- prototypes/local-first-sync-spike` is empty), so every step ran the `245ddde` harness.
- **SC-13 + TS-01a:** 3 × 20 runs, 0 violations. All seven mutants were caught after the same number of runs as run 1.
- **Earlier cases:** SC-31, SC-30, SC-29, SC-28, SC-25b, SC-25a (one-tenth size 30 of 30 and full size 3 of 3), SC-23, SC-22, SC-21a, SC-20 (and its real tmpfs leg, 50 of 50) and SC-19 PASS, every mutant caught.
- **Earlier phases:** phase 0 (self-test, including the oracle's per-stream I4), phase 1 and phase 2 (10 seeds, 300 runs) PASS; TS-09 counted 16 of 16 sales. Tamper: 36 of 36.
- **The pinned-list guard** passed for phase 2 and tamper.

**Finding P3-F11 — before OQ7, a rollback that reuses synced sequence numbers lost the restored device's sales.** The server flagged the reused number and kept nothing, so the sales made after the restore never reached it (`drop_conflicting` is that behaviour). Under OQ7 they are stored, and after the owner's choice they are applied. Nothing is lost either way round.

**Founder decisions (2026-10-18):** (1) review-queue sales count in revenue and day-close totals at once, on their own labelled line until the owner reviews them; (2) during quarantine the dashboard shows "held: N sales, X EGP" with the alert (R52, R53).

**Not covered:**
- **TS-01b** (sales that never reached the server, erased by a restore): no mechanism detects it. OQ27, the founder's position on accepting it, waits for the threat model.
- **The machine id on Windows** and a clone onto an identical VM image that reports the same id: phase 4. A clone with the same machine id is still caught, later, by its first reused sequence number.
- **Re-enrolling the retired copy as a new device:** the device enrolment spec.
- **Refiling the stock moves and business days of a retired stream:** these SC-29/SC-31 records are not run with the clone policy.

### Phase 3 — TS-07a: the wall clock is changed during an open session (injected clock)

**Pass signal (sync note § 9.1.1, TS-07; Linux phase 3 leg (a)):** session time is billed from the trusted time source, not the edited wall clock, and the edit is recorded.

**Design under test (with `CLOCKED=1`, SC-30's injected clock):**
- **Durations:** within one boot every duration comes from the monotonic counter, never the wall clock. That covers session time, and the length of an app closure (same boot id). Only a power-off (new boot id) is spanned by the wall clock, and trusting that is phase 5.
- **Recording a move:** the one-minute timer, and the start after an app closure, compare wall and monotonic time since the last checkpoint. A difference above 5 minutes is recorded as `wall_clock_moved` with the size of the move, and reported to the server (owner alert). Smaller drift, such as an NTP correction, is not reported.
- **Notice wording:** an outage notice carries its measured length. When the device's wall times disagree with it by more than 5 minutes, the notice says the device clock was changed.

**Cells** (seeds vary the time before the change by 0–30 s):

| Cell | Script | Expected |
|---|---|---|
| `a_forward` | Session open 10 min; wall clock +2 h; 10 min more; close | Bill 20 min; one `wall_clock_moved` (+7,200 s) owner event |
| `b_back` | As `a`, wall clock −3 h | Bill 20 min; one event (−10,800 s) |
| `c_back_during_app_kill` | Session open 10 min; the app is closed 5 min and the clock set back 3 h meanwhile; restart; 4 min; close | Bill 19 min; one event; one "app was closed" notice saying "measured length 5 min - the device clock was changed during this time" |
| `d_small_drift` | Wall clock +30 s (an NTP correction) | Bill 20 min; no event |

**Checks added:**
- **R54:** the session is billed its true elapsed time whatever the wall clock did. I5 and I3 check the same on the server rows.
- **R55:** every wall-clock move above 5 minutes is recorded once, with its size, as an owner-visible event; smaller drift is not.
- **R56:** an app closure during which the clock moved still gets its notice, measured on the monotonic counter.

**Mutants:**
- `bill_from_wall` (client): session time from the wall clock.
- `no_wall_move_event` (client): the move is not recorded.
- `app_down_gap_from_wall` (client): an app closure measured on the wall clock (SC-30's first draft).

#### Run 1 (dev, uncommitted harness on `94bb337`) — PASS

`evidence/phase3-ts07a-run1-dev*`, 34 s.
- **Cells:** all 4 PASS, 20 seeds each, 0 violations.
- **Mutants:** all three caught.
  - `bill_from_wall` after 1 run (I3: 140.00 EGP billed for 20 minutes instead of 20.00).
  - `no_wall_move_event` after 1 (R55).
  - `app_down_gap_from_wall` after 3, in `c` (R56: no notice at all).
- **Smoke on the changed client and server:** SC-30 (3 seeds) and SC-13 (2) PASS with every mutant caught. The full regression follows on the committed harness.

**Finding P3-F12 — an app closure must be measured on the monotonic counter, not the wall clock.** SC-30's first version measured the closure from the wall times at the last checkpoint and at restart. A cashier who closes the app and sets the clock back gets a negative gap, so no notice at all. A clock set forward inflates it. This is the most suspicious kind of outage (founder, 2026-10-18), and it was the one a clock change hid. The fix: within one boot the monotonic counter measures the closure, and the notice shows the wall times with the measured length.

**Not covered:**
- **A clock change across a power-off** (the wall clock is the only bridge there): phase 5, with S306.
- **Real Windows clock edits and event 4616:** S304, phase 4 (TS-07b).



- **The owner's minimum and increment:** billing spec.



