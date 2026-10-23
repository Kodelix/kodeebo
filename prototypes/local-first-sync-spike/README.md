<!-- PROTOTYPE - NOT FOR PRODUCTION -->
<!-- Question: Does local-first sync ever lose or double-count money or session time under faults? (phase 0: can the harness detect it?) -->
<!-- Date: 2026-10-16 -->

# Prototype: local-first sync spike

**Status:** in-progress — phase 0 gate PASS; phase 1 gate PASS on run 2 after the OQ28 fix (run 1 failed: WAL silent loss P1-F1); phase 2 gate PASS (run 2 on committed harness `be3f49e`: 50 seeds per cell, 3,000 campaign runs, 0 violations); phase 3 in progress — SC-19 (server restore) PASS on committed harness `a65d6f8`; SC-20 (disk full) PASS on committed harness `daac687`; SC-21a (app update) PASS on committed harness `128cdea`; SC-22 (two instances) PASS on committed harness `db53f27` (tamper suite fixed in `74fac52`); SC-23 (prices while offline, widened rule 2, no-price-list refusal) PASS on committed harness `8cc8df6`; SC-25a (7-day backlog over cut windows) PASS on committed harness `a5900db` (phase 2 regression fixed in `be11ae1`); SC-25b (N5 lease expiry) PASS on committed harness `04996e2`; SC-28 (dashboard edit of an open bill) PASS on committed harness `a77dfa3`, finding P3-F10; SC-29 (stock policy per item) PASS on committed harness `6e2ecff`; SC-30 (device off while sessions run, mechanics) PASS on committed harness `c23f137`; SC-31 (End Day) PASS on committed harness `56c8dbc`; SC-13 + TS-01a (cloned disk, rollback, OQ7 policy) PASS on committed harness `245ddde`; TS-07a (clock change during an open session) PASS on committed harness `8350016`, finding P3-F12; TS-02 (outbox deletion, renumbering) PASS on committed harness `3253ba0`, finding P3-F13, (b2) blind spot confirmed; S207 (old client against a newer server) PASS on committed harness `31b853d`; TS-01b + TS-10 + OQ27 items PASS on committed harness `4094520` (TS-01b blind spot confirmed, M3 limit confirmed); S206 + TS-03b + TS-06a/b PASS on committed harness `a9ee56a`, findings P3-F14 and P3-F15; every order-A leg done; G5-F4 tamper row and S206 cell f added (finding P3-F16, limit P3-F17); **phase 3 gate PASS** on committed harness `0f13d43` (compound-fault campaign 3,000 runs, 0 violations, all 5 mutants caught; phase 2 at full size PASS; full regression of every leg, phases 0 and 1, tamper 38 of 38); S109 not run (key custody not ready); PowerSync track closed (rejected by ADR-0001, founder 2026-10-19; S2–S4 not run); next: `perf-budgets.md`, then phase 4 on the Windows VM, then phase 5
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
| PowerSync track | Does PowerSync fit (sync note Part A, S1–S4)? **Closed, not run (founder, 2026-10-19): PowerSync is rejected by ADR-0001.** Under ADR-0001's restrictive tenant policy its replication role would have to bypass RLS to read every tenant (desk check, nothing downloaded: sync note 9.3.1 [A]). The rest of this cell is kept for the record. **Order (founder, 2026-10-17):** after the phase 3 gate passes, not in parallel. S2–S4 on Linux right after the gate; S1 on Windows inside phase 4. The FSL counsel reading (sync note OQ2) is **closed by founder statement (2026-10-18)**: counsel found no issues, and the tech/IP counsel brief is no longer drafted. The product's own licence obligations still apply (third-party notice file) | Part A's pass conditions |

**Order (founder, 2026-10-18):** close the sync spike before the tenancy review and the backend research start. It runs in parallel with the desktop spike, and neither has priority. Everything in phases 3, 4 and 5 runs before the sync ADR, except S308 (parked), in this order:
1. the phase 3 gate (≥ 3,000 runs, phase 2 at full size in the same campaign) — **PASS, 2026-10-19**;
2. ~~PowerSync S2–S4 on Linux~~ — **closed, not run: PowerSync rejected by ADR-0001 (founder, 2026-10-19)**;
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

**Device retention rule under test (founder):** an outbox row goes once a fully parsed ack arrives. The business records behind it stay on the device for a bounded window longer than ETA's 30-day late-submission route and the server's backup window, and are pruned only after the server confirms its archive. Values (sync note OQ29): 60 days on the device (provisional), and a server backup window of **30 days** (founder, 2026-10-18; ADR-0005 Decision 6).

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

TS-02 (outbox deletion and renumbering by an insider):

```bash
bash prototypes/local-first-sync-spike/run.sh ts02 [seeds_per_cell]
```

```bash
bash prototypes/local-first-sync-spike/run.sh replay02 <seed> <cell> [mutant]
```

S207 (old client against a newer server):

```bash
bash prototypes/local-first-sync-spike/run.sh s207 [seeds_per_cell]
```

```bash
bash prototypes/local-first-sync-spike/run.sh replay207 <seed> <cell> [mutant]
```

TS-01b, TS-10 and the OQ27 founder input (restore after offline sales, drawer count, offline alert, USB restore):

```bash
bash prototypes/local-first-sync-spike/run.sh ts01b [seeds_per_cell]
```

```bash
bash prototypes/local-first-sync-spike/run.sh replay01b <seed> <cell> [mutant]
```

S206, TS-03b and TS-06a/b (re-bootstrap after a lost or damaged store; no resurrected deletes):

```bash
bash prototypes/local-first-sync-spike/run.sh s206 [seeds_per_cell]
```

```bash
bash prototypes/local-first-sync-spike/run.sh replay206 <seed> <cell> [mutant]
```

`selftest` starts a throwaway `postgres:18.6` container on `127.0.0.1:56432`, builds the server and runs the correct stub and each mutant. `replay` re-runs one seed and prints its trace. `stop` removes the container. Run output goes to `runs/`, which is not committed.

## Pinned cell lists (guard)

Phase 2 and the tamper suite check, before they run anything, that their cell lists equal the lists pinned here (`harness/pins.py`). The tamper suite also checks, after the run, that it produced exactly these rows for each cipher. A new case that changes a shared table, as SC-25a's slow-link toxic once did for phase 2, therefore stops the run at once with a message naming what was added or removed. Without the guard, an untested cell surfaced only at the end of a 1 h 40 min regression. A deliberate change updates the list here in the same commit.

- `pinned phase2-cells: down, req_blackhole, req_cut_10, req_cut_120, req_cut_400, reset_peer, resp_blackhole, resp_cut_1, resp_cut_150, resp_cut_20, slicer, slow, concurrent`
- `pinned phase2-campaign-toxics: down, req_blackhole, req_cut_10, req_cut_120, req_cut_400, reset_peer, resp_blackhole, resp_cut_1, resp_cut_150, resp_cut_20, slicer, slow`
- `pinned tamper-scenarios: db_middle_page, db_page1, hot_journal_crash_control, hot_journal_crash_flip, hot_journal_page1_flip, marker_flipped, marker_deleted, store_older_than_marker, db_page_while_running, walmode+marker-wal_header, walmode+marker-wal_first_frame, walmode+marker-wal_last_frame, wrong_key, truncated_key, empty_key, right_key_wrong_cipher, wrong_key_x20, right_key_after_attempts, ts04a_plaintext_scan`

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
- **The server backup window must stay shorter than the device window.** If backups older than 60 days are ever restored, the loss in `b_expired` is real. The founder set the window to 30 days (2026-10-18; ADR-0005 Decision 6), below the 60-day device retention.
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
- **The real updater on Windows:** files locked by the running app, installer rollback. That is SC-21b in phase 4. The Windows migration itself has since run under power cuts in the desktop spike's round 4 (G5.1, commit `4dfc169`, `prototypes/desktop-client-spike/evidence/g5/run-log-g5-20261019.txt`): a cut at each of the 6 migration steps, 24 of 24 cuts PASS in both runtimes; the schema never mixed, the queued rows' bytes unchanged, the copy removed only after the verify, and the old app refused the newer store untouched (G5-F1). Migration time on the throttled disk: runtime A 0.68–4.05 s (control 2.08 s), runtime B 0.24–0.87 s (control 0.24 s); only A can pass the 3 s ceiling (G5-F2). **Founder (2026-10-19, G5 verdict):** no physical 4 GB PC exists, so the risk closes on the first pilot café's own PC before a release reaches it; a migration that can exceed 3 s shows an "updating" screen with progress, never a frozen window. Still for phase 4: the sync half (byte-identical send and dedupe across versions after the real update).
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

#### Run 2 (committed harness `8350016`) — TS-07a **PASS**, full regression PASS

`evidence/phase3-ts07a-run2-*`. No log is marked `+dirty`.
- **Log headers:** four other-session commits (ADR documents) landed during the run: `d836939`, `43f2c5e`, `79de922` and `3830eb4`. TS-07a, SC-13 and SC-31 to SC-25b say `8350016`; SC-23 to SC-20 say `43f2c5e`; SC-19 says `79de922`; phases 0–2 say `3830eb4`. None of them touches the spike folder or the sync note (`git diff 8350016 3830eb4 -- prototypes/local-first-sync-spike` is empty), so every step ran the `8350016` harness.
- **TS-07a:** 4 × 20 runs, 0 violations. All three mutants were caught after the same number of runs as run 1.
- **Earlier cases:** SC-13 + TS-01a, SC-31, SC-30, SC-29, SC-28, SC-25b, SC-25a (one-tenth size 30 of 30 and full size 3 of 3), SC-23, SC-22, SC-21a, SC-20 (and its real tmpfs leg, 50 of 50) and SC-19 PASS, every mutant caught.
- **Earlier phases:** phase 0, phase 1 and phase 2 (10 seeds, 300 runs) PASS; TS-09 counted 16 of 16 sales. Tamper: 36 of 36.
- **The pinned-list guard** passed for phase 2 and tamper.

**Finding P3-F12 — an app closure must be measured on the monotonic counter, not the wall clock.** SC-30's first version measured the closure from the wall times at the last checkpoint and at restart. A cashier who closes the app and sets the clock back gets a negative gap, so no notice at all. A clock set forward inflates it. This is the most suspicious kind of outage (founder, 2026-10-18), and it was the one a clock change hid. The fix: within one boot the monotonic counter measures the closure, and the notice shows the wall times with the measured length.

**Not covered:**
- **A clock change across a power-off** (the wall clock is the only bridge there): phase 5, with S306.
- **Real Windows clock edits and event 4616:** S304, phase 4 (TS-07b).

### Phase 3 — TS-02: an insider with the database key deletes a queued command, or deletes and renumbers

**Pass signal (sync note § 9.1.1, TS-02):** the server detects the sequence gap and alerts the owner. The note expects (b), renumbering that leaves no gap, to fail (the same blind spot as TS-01b, OQ27).

**Founder decision (2026-10-18) for (a2):**
- **Owner action:** the owner may "accept the gap".
- **Held, never dropped:** until then, commands after the gap are stored, never refused or dropped, and held unapplied, exactly as in the OQ7 quarantine.
- **Dashboard:** it shows "held: N sales, X EGP" with the alert "missing sequence N, possibly deleted on the device".
- **On acceptance:** the lost number is recorded permanently as a lost range, and the held commands apply once.

**Design under test (`GAP_HOLD=1` on the server):**
- **Holding:** a command whose sequence leaves a gap is stored unapplied (`held`), and the device counts it as stored. While a gap is open, every reply asks the device to resend from it.
- **(a1) the device still has the command in its bill (retention rule):** the rebuild sends it. The gap closes, and the held commands apply once. No alert.
- **(a2) the device does not have it:** the gap stays open. Once it is older than the threshold (spike: 600 s of server time), one owner alert is raised. The owner report shows the held sales, with the alert text once it is raised. `POST /gap/accept` records the missing range permanently and applies the held commands.

**Cells** (each: 3 sales synced, then 3 queued, seq 4–6):

| Cell | Insider's edit | Expected |
|---|---|---|
| `a1_outbox_row_deleted` | Deletes the queued outbox row of seq 5; the bill stays | 4 applied, 6 held, then 5 rebuilt from the bill and applied; the gap is closed by the device; all 6 sales once; no alert |
| `a2_sale_erased` | Erases sale 5 entirely (outbox row, bill, payment); then 2 more sales | 4 applied; 6, 7, 8 held and not applied. Before the threshold the report shows "held: 3 sales, 45.00 EGP" without the alert, after it "missing sequence 5, possibly deleted on the device" (one alert). The owner accepts: lost range 5–5, permanent, with an owner alert; 6, 7, 8 apply once |
| `b2_renumber_marker_forged` | Erases sale 5, renumbers 6 to 5, lowers the counter and rewrites the commit marker with the key | The device starts and syncs normally. **Expected blind spot (OQ27), confirmed:** no gap, no alert, no lost range, and sale 5 is gone. Recorded, not counted as a violation |

**(b1), renumbered without the marker:** the store's counter is then below the marker, and the device refuses the store at start. That is the tamper suite's `store_older_than_marker` row, PASS since phase 1. The marker is signed with the database key, so an insider who holds that key can forge it, as in `b2`. A marker key the cashier cannot reach (TPM or DPAPI machine scope) is the key-custody question (desktop-note S11).

**Checks added:**
- **R57 (a1):** every sale once, no alert, and the gap closed by the device.
- **R58 (a2):** held commands are stored and none is applied before the owner accepts. One alert after the threshold, with the founder's wording; the report shows the held sales; the lost range 5–5 is recorded with an owner alert; the held commands apply once (I1, I2).

**Mutants:**
- `gap_silent` (server): no alert.
- `gap_auto_skip` (server): the cursor jumps the gap with no owner and no record.
- `gap_refused` (server): the old behaviour; a gap is refused and nothing is stored.

#### Run 1 (dev, uncommitted harness on `d721b26`) — PASS

`evidence/phase3-ts02-run1-dev*`, 29 s.
- **Cells:** all 3 PASS, 20 seeds each, 0 violations. In every `b2` run the blind spot was confirmed.
- **Mutants:** all three caught.
  - `gap_silent` after 2 runs, in `a2` (R58).
  - `gap_auto_skip` after 1, in `a1` (I1: the sale the device could have resent was skipped and lost).
  - `gap_refused` after 1, in `a1` (I1).
- **Smoke on the changed client and server:** SC-13 (2 seeds) and SC-19 (2) PASS with every mutant caught. The full regression follows on the committed harness.

#### Run 2 (committed harness `3253ba0`) — TS-02 **PASS**, full regression PASS

`evidence/phase3-ts02-run2-*`. No log is marked `+dirty`.
- **Log headers:** the studio update `1546a8e` landed during the run. TS-02 to SC-29 say `3253ba0`, the rest say `1546a8e`. That commit touches only `.claude/` studio files, not the spike folder or the sync note, so every step ran the `3253ba0` harness.
- **TS-02:** 3 × 20 runs, 0 violations, (b2) blind spot confirmed in every run. All three mutants were caught after the same number of runs as run 1.
- **Earlier cases:** TS-07a, SC-13 + TS-01a, SC-31, SC-30, SC-29, SC-28, SC-25b, SC-25a (one-tenth size 30 of 30 and full size 3 of 3), SC-23, SC-22, SC-21a, SC-20 (and its real tmpfs leg, 50 of 50) and SC-19 PASS, every mutant caught.
- **Earlier phases:** phase 0, phase 1 and phase 2 (10 seeds, 300 runs) PASS; TS-09 counted 15 of 15 sales (a wall-clock effect). Tamper: 36 of 36.
- **The pinned-list guard** passed for phase 2 and tamper.

**Finding P3-F13 — while a gap is open the server must ask for a resend, because a held acknowledgement empties the device's outbox.** In the first design the device, once told "held", had nothing pending and stopped syncing. The command it still had in its bill was never sent, and a recoverable deletion would have looked like a real loss. With the resend request, the retention rule turns a deleted queued command into no loss at all (`a1`).

**Not covered:**
- **A forged `low_seq`:** an insider who also edits what the device reports as its lowest retained sequence could make SC-19's lost-range path record a skip without the owner. It is recorded and alerted, but automatic. That belongs to the sync threat model.
- **What the owner sees when a gap is accepted:** the amount of the lost sale is unknown to the server. The dashboard spec decides the wording.
- **The threshold value:** 600 s here; the spec sets it.

### Phase 3 — S207: an old client against a newer server

**Pass signal (sync note § 9.1, S207):** the client keeps selling and queuing, and applies no feed it cannot read.

**Design under test:**
- **Protocol version:**
  - Every batch carries the client's sync protocol version (`PROTO`). Below the server's minimum (`PROTO_MIN`), the server applies nothing and answers `upgrade_required` with an empty result list, so the client keeps its whole queue.
  - The owner gets one alert per episode: "this device needs an app update before it can sync; its sales are kept on the device".
  - The counter keeps selling. After the update the backlog syncs once.
- **Feed schema version:**
  - The config feed carries `feed_schema`; schema 2 sends prices as objects (`{"amount": n, "currency": "EGP"}`).
  - An app that reads only schema 1 (`FEED_SCHEMA_MAX=1`) applies nothing from a newer feed. It keeps the price list it holds and records `feed_unreadable` once per feed version.
  - The updated app reads the schema-2 shape.

**Cells** (each: 2 sales, then the out-of-date period with 2 more, then the update and 1 sale):

| Cell | Out of date | Expected |
|---|---|---|
| `a_old_protocol` | Protocol 1 against a server that needs 2 | Sync answers `upgrade_required` with the 2 (then 4) commands kept queued; nothing on the server; one owner alert. After the update all 5 sales apply once |
| `b_unreadable_feed` | The owner publishes a schema-2 feed with new prices | The pull is refused (`feed_unreadable`, recorded once over two pulls); the 2 sales in this period use the held price (15.00 EGP), and sync works normally. After the update the feed is read and the next sale uses 20.00 EGP |
| `c_both` | Both at once | Both behaviours; after the update the backlog applies once and the new feed is read |

**Checks added:**
- **R60:** the counter keeps selling and queuing throughout, and nothing is dropped (I1).
- **R61:** an unsupported protocol is refused with nothing applied and one owner alert; the backlog syncs once after the update.
- **R62:** an unreadable feed is not applied, so sales keep the held price (I3 against the model); it is recorded once, and the updated app reads it.

**Mutants:**
- `drop_on_refusal` (client): queued commands deleted on `upgrade_required`.
- `stop_on_upgrade_required` (client): the counter refuses sales until updated.
- `apply_unknown_feed` (client): a newer feed applied as if readable.
- `apply_old_protocol` (server): the minimum ignored.

#### Run 1 (dev, uncommitted harness on `ac4bdec`) — PASS

`evidence/phase3-s207-run1-dev*`, 27 s.
- **Cells:** all 3 PASS, 20 seeds each, 0 violations.
- **Mutants:** all four caught.
  - `drop_on_refusal` after 1 run (I1).
  - `stop_on_upgrade_required` after 1 (R60).
  - `apply_unknown_feed` after 2 (R62).
  - `apply_old_protocol` after 1 (R61).
- **Smoke on the changed client and server:** SC-19, SC-23 and SC-29 (2 seeds each, the cases that read the config feed) PASS with every mutant caught. The full regression follows on the committed harness.

#### Run 2 (committed harness `31b853d`) — S207 **PASS**, full regression PASS

`evidence/phase3-s207-run2-*`. No log is marked `+dirty`.
- **Log headers:** one other-session commit landed during the run, `d064639` (a registry section for ADR-0006). S207 to SC-25a say `31b853d`, the rest say `d064639`. It touches neither the spike folder nor the sync note, so every step ran the `31b853d` harness.
- **S207:** 3 × 20 runs, 0 violations. All four mutants were caught after the same number of runs as run 1.
- **Earlier cases:** TS-02, TS-07a, SC-13 + TS-01a, SC-31, SC-30, SC-29, SC-28, SC-25b, SC-25a (one-tenth size 30 of 30 and full size 3 of 3), SC-23, SC-22, SC-21a, SC-20 (and its real tmpfs leg, 50 of 50) and SC-19 PASS, every mutant caught.
- **Earlier phases:** phase 0, phase 1 and phase 2 (10 seeds, 300 runs) PASS; TS-09 counted 15 of 15 and 16 of 16 sales (a wall-clock effect). Tamper: 36 of 36.
- **The pinned-list guard** passed for phase 2 and tamper.

**Not covered:**
- **How the app gets updated:** the desktop updater, the desktop spike's G4 and S10.
- **An old server against a newer client** (a server rollback): the release process.
- **Command payloads in a newer format sent by an updated client to a server not yet updated:** the deployment order (server first) is a release rule.

### Phase 3 — TS-01b, TS-10 and the OQ27 founder input: a restore that erases offline sales, the drawer count, the offline alert, and the USB copy

**What is tested (sync note § 9.1.1 TS-01 (b) and TS-10; OQ27 founder input 2026-10-18):**
- **TS-01b:** a copy of the store (file access only) is restored after offline sales that never reached the server. The note expects no mechanism to detect it (OQ27).
- **TS-10 (M3):** the shift closes with a counted drawer. (a) The erased sales' cash is still in the drawer: the close must flag a surplus equal to it, as an owner event. (b) That cash was removed: expected not detected; that is M3's limit.
- **OQ27 (2):** an offline-duration alert to the owner and the cashier after a threshold (founder example: 6 hours; the spec sets the value).
- **OQ27 (3):** an hourly encrypted copy to a USB drive, restored on a new PC through the OQ7 quarantine and review queue.
- **OQ27 (1)** is already SC-25a. **OQ27 (4)**, the printed End Day summary, cannot be tested here; its figures are SC-31's totals.

**Design under test:**
- **Shift close (TS-10, with `ENDDAY=1`):** `close_shift` with `counted_piasters` compares the counted drawer with the cash taken during the shift (payments of bills sequenced after the shift opened). It queues a `shift_close` command carrying expected, counted and the difference. The server raises one owner event for any difference ("drawer surplus of X EGP at shift close" or "shortage").
- **Offline alert, owner (OQ27 (2)):** a device with no contact for longer than the threshold raises one alert per offline episode: "device offline for more than 6 h: its sales since then are only on the device". It uses the server's clock and is checked whenever the owner report is read, so it fires while the device stays silent, which matters because a stolen or burned device never reconnects. A contact ends the episode.
- **Offline warning, cashier (OQ27 (2)):** every reply carries "no connection to the server for N h" past the threshold, counted on the device's monotonic clock.
- **USB copy (OQ27 (3)):** `usb_backup` copies the store and its commit marker between operations. Restored on a new PC, it has a new machine id, so SC-13's quarantine takes over and the owner keeps the new PC.
- **Not tested here:** the store key on the new PC. Escrowing it is the key-custody question (desktop-note S11, licensing note); the spike uses its test key.

**Cells:**

| Cell | Script | Expected |
|---|---|---|
| `a_restore_drawer_kept` | Shift open; 2 sales synced; the store and marker copied; 3 offline cash sales; the copy restored; sync; the shift closed with the 3 sales' cash still in the drawer | TS-01b: nothing on the server shows the restore, and the 3 sales are gone (blind spot confirmed). TS-10 (a): the shift close shows a difference of +45.00 EGP and one owner event "drawer surplus of 45.00 EGP at shift close" |
| `b_restore_cash_removed` | As `a`, with that cash taken out of the drawer | Blind spot confirmed; difference 0, no event: M3's limit, as the note expects |
| `c_offline_alert` | One sale synced; 2 h with no contact; 5 h more; the owner opens the dashboard twice; contact again; 1 h more | No alert at 2 h, one at 7 h (not repeated on the second look), none after the contact. The cashier is warned at 7 h, not at 2 h or after the contact |
| `d_usb_restore` | 2 sales synced; 1 pending; the hourly copy; the pending one synced; 2 more synced; 2 more never synced; the PC burns; the copy restored on a new PC (new machine id), which sells 2; the owner keeps the new PC | Quarantine `second_machine`; "held: 2 sales" during it. After the choice everything in the copy and everything synced is on the server; the old PC's 2 sales synced after the copy are in the review queue, labelled as from a retired copy. Exactly the 2 sales after the copy that never synced are lost |

**Checks added:**
- **R63 (TS-01b):** the blind spot is recorded per run, not counted as a violation.
- **R64 (TS-10):** the shift's difference and drawer events match the model: a surplus equal to the erased cash, or nothing.
- **R65 (OQ27 (2)):** owner alerts 0 / 1 / 1 at 2 h, 7 h and after the contact; cashier warnings false / true / false.
- **R66 (OQ27 (3)):** the lost sales are exactly the model's; the quarantine reason, the held line and the review queue are as expected.

**Mutants:**
- `no_drawer_check` (client): the counted drawer is ignored.
- `offline_alert_never` (server).
- `offline_alert_repeat` (server): an alert on every check.
- `no_offline_warning` (client).
- `no_machine_check` (server): the restored copy is caught only later, by a reused number.

#### Run 1 (dev, uncommitted harness on `d1aea85`) — PASS

`evidence/phase3-ts01b-run1-dev*`, 45 s.
- **Cells:** all 4 PASS, 20 seeds each, 0 violations. TS-01b's blind spot was confirmed in every `a` and `b` run.
- **Mutants:** all five caught.
  - `no_drawer_check` after 1 run (R64).
  - `offline_alert_never`, `offline_alert_repeat` and `no_offline_warning` after 3, in `c` (R65).
  - `no_machine_check` after 4, in `d` (R66).
- **Smoke on the changed client and server:** SC-31 (2 seeds) and SC-13 (2) PASS with every mutant caught. The full regression follows on the committed harness.

#### Run 2 (committed harness `4094520`) — TS-01b + TS-10 + OQ27 items **PASS**, full regression PASS

`evidence/phase3-ts01b-run2-*`. Every log header says `commit 4094520`, none `+dirty`; no other commit landed during the run.
- **This leg:** 4 × 20 runs, 0 violations, TS-01b's blind spot confirmed in every `a` and `b` run. All five mutants were caught after the same number of runs as run 1.
- **Earlier cases:** S207, TS-02, TS-07a, SC-13 + TS-01a, SC-31, SC-30, SC-29, SC-28, SC-25b, SC-25a (one-tenth size 30 of 30 and full size 3 of 3), SC-23, SC-22, SC-21a, SC-20 (and its real tmpfs leg, 50 of 50) and SC-19 PASS, every mutant caught.
- **Earlier phases:** phase 0, phase 1 and phase 2 (10 seeds, 300 runs) PASS; TS-09 counted 16 of 16 and 15 of 15 sales. Tamper: 36 of 36.
- **The pinned-list guard** passed for phase 2 and tamper.

**What this measures for OQ27 (input to the sync threat model, not a decision):**
- **Rollback (TS-01b):** a restore erases offline sales without trace on the server.
- **Drawer count (M3):** it catches the erasure only if the cash stays in the drawer.
- **Offline alert:** it tells the owner, within the threshold, that the device was silent while it may have been selling.
- **USB copy:** it bounds the loss of a stolen or burned PC to the sales after the last copy that never synced. With an hourly copy, that is at most one hour of offline sales.

**Not covered:**
- **Key escrow for the new PC:** key custody.
- **The offline threshold value and the copy interval:** the spec.
- **The printed End Day summary:** the desktop spike's real-printer day (S50).
- **A copy that is itself tampered with:** it carries the commit marker, so the TS-02 / OQ28 marker reasoning applies.

### Phase 3 — S206, TS-03b and TS-06a/b: re-bootstrap after a lost or damaged store; no resurrected deletes

**Pass signals (sync note § 9.1 S206; § 9.1.1 TS-03 (b), TS-06 (a), (b)):**
- **S206:** no resurrected deletes; unsynced facts are never silently discarded.
- **TS-03b (store damaged) and TS-06 (store deleted, while closed or while running):** the app detects it, never writes over the damaged data, and re-bootstraps from the server. Unsynced commands that were lost surface as a reported gap, never silently.

**Design under test (`REBOOTSTRAP=1`):**
- **Detection:** at start, a damaged store fails its integrity check, and a deleted database beside a valid commit marker fails the marker check. Both already refused the store.
- **Re-bootstrap:**
  - The refused files and the marker are moved aside into `client.db.damaged-N/`, never written over.
  - The device asks `GET /bootstrap`, reporting the marker's sequence, the highest it ever committed.
  - The server records the range between its cursor and that sequence as a **permanent lost range** (`store_lost`) with one owner alert. The cursor skips it, explicitly and on record, and the device is told where its sequence continues. Then it opens a fresh store at that sequence.
- **Marker gone too:** every batch now reports the device's counter (`local_seq`), so the server knows the highest sequence committed at the last contact. Sales after that contact can't be counted, and the alert says so, with the last-contact time.
- **First install:** a fresh store with no marker always asks the server, so a known identity never restarts silently at sequence 1. A genuine first install (no cursor, nothing reported) raises nothing.
- **Deleted while running (TS-06b):** on Linux, SQLite refuses the next write to an unlinked database file ("attempt to write a readonly database"). That operation fails visibly, and the device re-bootstraps at once, in-process.
- **S206, deletes:** the config feed's catalogue is a full snapshot, so items the owner deleted are removed from the device. Before this leg the device only added or updated items.

**Cells** (each: 2 sales synced, then the loss):

| Cell | Loss | Expected |
|---|---|---|
| `a_ts06a_deleted_closed` | 2 unsynced sales; the app stopped; the database deleted (marker kept) | At start: refused, re-bootstrapped; lost range 3–4 recorded with one alert ("2 sales it had recorded never reached the server"); the next sale applies normally |
| `b_ts06b_unlinked_running` | The database deleted while the app runs | The next sale is refused visibly (SQLite: read-only, moved) and the device re-bootstraps in-process; nothing accepted, nothing lost; one alert (0 sales missing) |
| `c_ts03b_corrupted` | 2 unsynced sales; the app stopped; 64 bytes overwritten in a page | Integrity check fails; the damaged database is kept aside unchanged (same hash); lost range 3–4; the next sale applies |
| `d_marker_also_gone` | 2 unsynced sales; the database and the marker deleted | The fresh store asks the server; no countable range (the device last reported sequence 2); the alert says later sales cannot be counted, with the last contact time; the next sale applies, no conflict |
| `e_s206_deleted_item` | The owner deletes an item; 30 days pass; the device pulls the feed | Selling the deleted item is refused (`price_missing`); the other item sells |
| `f_g5f4_hot_journal_page1` | Added for G5-F4 (section below): 2 unsynced sales; an app update's migration killed mid-DDL with page 1 journaled; one byte of page 1's image in the hot journal flipped; the updated app starts | SQLite replays the damaged journal inside the open call and the store fails; the store as it was **before** the open is in `client.db.recovery/` (same hash); lost range 3–4; the next sale applies |

**Checks added:**
- **R67:** never a silent loss. The recorded range is exact when the marker survives; without it, the alert says later sales cannot be counted. One owner alert.
- **R68:** a damaged store is kept aside unchanged. In cell `f`, the store as it was before SQLite replayed the journal is kept.
- **R69:** after the re-bootstrap the counter sells and syncs normally; nothing is applied twice and nothing conflicts (I2, I8).
- **R70 (S206):** a deleted item is not resurrected.

**Mutants:**
- `recreate_silently` (client): a lost store recreated empty at sequence 0, no bootstrap.
- `overwrite_damaged` (client): the damaged files deleted.
- `silent_rebootstrap` (server): no loss recorded, no alert.
- `catalogue_upsert_only` (client): the old feed handling.
- `copy_after_open` (client, added with cell `f`): the desktop app's order in G5-F4, the copy taken after SQLite opened the store.

#### Run 1 (dev, uncommitted harness on `34cb848`) — PASS

`evidence/phase3-s206-run1-dev*`, 62 s.
- **Cells:** all 5 PASS, 20 seeds each, 0 violations.
- **Mutants:** all four caught.
  - `recreate_silently` after 1 run (I1: the new sales collided with sequences the server held and never reached it).
  - `overwrite_damaged` after 3, in `c` (R68).
  - `silent_rebootstrap` after 1 (I1).
  - `catalogue_upsert_only` after 5, in `e` (R70).
- **Smoke on the changed client and server:** SC-19, SC-29, SC-13 and SC-23 (2 seeds each) PASS with every mutant caught. The full regression follows on the committed harness.

#### Run 2 (committed harness `a9ee56a`) — S206 + TS-03b + TS-06a/b **PASS**, full regression PASS

`evidence/phase3-s206-run2-*`. No log is marked `+dirty`.
- **Log headers:** two other-session commits landed during the run, `10ab77b` and `e2d8236` (ADR-0006). S206 to SC-25a say `a9ee56a`; SC-23 to SC-19 say `10ab77b`; phases 0–2 say `e2d8236`. Neither touches the spike folder or the sync note (`git diff a9ee56a e2d8236 -- prototypes/local-first-sync-spike` is empty), so every step ran the `a9ee56a` harness.
- **S206 + TS-03b + TS-06a/b:** 5 × 20 runs, 0 violations. All four mutants were caught after the same number of runs as run 1.
- **Earlier cases:** TS-01b + TS-10 + OQ27, S207, TS-02, TS-07a, SC-13 + TS-01a, SC-31, SC-30, SC-29, SC-28, SC-25b, SC-25a (one-tenth size 30 of 30 and full size 3 of 3), SC-23, SC-22, SC-21a, SC-20 (and its real tmpfs leg, 50 of 50) and SC-19 PASS, every mutant caught.
- **Earlier phases:** phase 0, phase 1 and phase 2 (10 seeds, 300 runs) PASS; TS-09 counted 16 of 16 sales. Tamper: 36 of 36.
- **The pinned-list guard** passed for phase 2 and tamper.

**Finding P3-F14 — on Linux a database deleted under the running app refuses the next write, so nothing is accepted into a file about to vanish.** The first model expected the app to keep writing through its open file. SQLite instead detects the unlink and fails the write (`SQLITE_READONLY_DBMOVED`). The sale is refused visibly, which is safe. But the app then stayed refused until a restart, which breaks "the counter never waits". It now re-bootstraps at once. Windows' sharing rules behave differently (delete-while-open is the desktop spike's TS-06c).

**Finding P3-F15 — the device kept catalogue items the owner deleted.** The config feed was applied as an upsert, so a deleted item stayed sellable on the device forever, however long ago it was deleted. That is a resurrected delete with no tombstone window involved. The feed is a snapshot, and the device now applies it as one.

**Founder decision (2026-10-19): a device that lost its store while offline stays refused until it reaches the server, as the client does now; it never continues offline at the marker's sequence.** Reasons: the staff PIN verifiers lived only in that store (ADR-0007), so nobody can sign in and re-enrolment needs the server anyway; continuing at the marker's sequence would mask the OQ27 erase case, while refusing makes the server compare the marker's sequence with the last one it received and report the gap at once; a phone hotspot is enough to reach the server, and until then the café writes paper bills, which the End Day count reconciles. Recorded in the sync note's S206 row.

**Not covered:**
- **Stock, business day and open sessions after a re-bootstrap** (the SC-29, SC-31 and SC-30 state): the fresh store starts empty except for the feed. Rebuilding that state from the server is for the bootstrap spec.
- **Device identity kept outside the store:** the spike's device id is fixed. On Windows it must survive the store's loss (desktop-note S11 key custody, OQ7 machine id).
- **The Windows store half of TS-03c and TS-06c:** the desktop spike's round 4 (G5). Its run 4 result is cited in the G5-F4 section below.

### Phase 3 — G5-F4: a damaged hot journal is replayed at open, before the app can check it (Linux)

**Source:** the desktop spike's round 4 (G5.3, commit `4dfc169`, `prototypes/desktop-client-spike/README.md` finding G5-F4). A power cut left a hot journal; 64 bytes flipped inside the journal's saved copy of page 1. SQLite played the damaged journal back while opening, so the store became unreadable before the app's check ran, in both runtimes. The desktop app copied the store only after open, so it kept the already-overwritten file.

**Founder (2026-10-19):** add the mitigation to the store design in the note (before opening, if a hot journal exists, copy the store and the journal aside first) and a Linux tamper case for it in phase 3, before the gate campaign. The rule is now in the sync note's OQ28 row.

**This client already does it** (P1-F3, phase 1): `preserve_before_recovery` copies the store, the journal and the marker into `client.db.recovery/` before the open, whenever a hot journal or WAL exists. What phase 1 did not cover is the desktop case itself: page 1's image in the journal. A sale journals only the pages it changes, never page 1, so a schema change is needed.

**Tamper row `hot_journal_page1_flip`** (both ciphers; the suite now has 38 rows, pinned list updated):
- Build the 5-sale store; start the client as the next app version (`SCHEMA_VERSION=2`) with a small page cache and failpoint `migrate:mid_ddl:1`, so it dies inside the migration with page 1 in the hot journal.
- Find the page-1 record from the journal header (sector size, page size) and flip one byte 200 bytes into its page image.
- Start the client: **detected, refused, recorded (`store_unusable_at_start`); SQLite's recovery rewrote the file; the originals preserved byte-identical** in `client.db.recovery/`. The same result under `chacha20` and `sqlcipher`.

**S206 cell `f_g5f4_hot_journal_page1`** carries the same damage into the re-bootstrap: the refused store is moved aside, the device re-bootstraps, lost range 3–4 is recorded with one alert, and the pre-open copy is kept (R68). The `copy_after_open` mutant, the desktop app's order, is caught by R68.

#### Run 1 (dev, uncommitted harness on `4dfc169`) — PASS

- **Tamper:** 38 of 38 rows PASS, `hot_journal_page1_flip` included under both ciphers.
- **S206:** 6 cells × 20 seeds, 0 violations; cell `f` exercised 20 of 20 (a page-1 record in every hot journal). All five mutants caught: `copy_after_open` after 6 runs (R68, in cell `f`); the other four after the same number of runs as S206 run 2.
- **The committed run** is part of the gate run below.

**Finding P3-F16 — the copy before open has to be the rule, not the copy after a failure.** A hot journal is replayed during the first read, before any check the app can run. Whatever the app copies after that is the replayed file, so the only way to keep the evidence and the pre-crash state is to copy whenever a hot journal exists, before the first read. The copy is small (store plus journal) and is deleted after verification passes. It confirms G5-F4 on Linux and under both SQLite3MC ciphers: this is SQLite's recovery order, not the Windows binding's.

**Windows (desktop build 1.0.4, commit `fa12065`; `TS03J … v1.0.4` lines in `prototypes/desktop-client-spike/evidence/g5/run-log-g5-20261019.txt`): PASS in both runtimes.** With no flip the copy is made, SQLite rolls back, the store verifies and the copy is removed. With 64 bytes flipped SQLite still overwrites the store at open and the app refuses, but the pre-open store and the flipped journal survive byte-identical in the copy, and the `store_open_failed` event names it.

**Probe — repeat copies after a failed replay** (`evidence/phase3-probe-repeat-copy.py`, `.out.txt`; the desktop spike found the limit on Windows). Same damage as the tamper row, then three starts without re-bootstrap, both ciphers: the journal stays on disk after the failed replay, so **every start copies again**. Copy 1 holds the pre-open store and the damaged journal; copies 2 and 3 hold the already overwritten store (the same hash each time). The first copy is never lost, but the copies pile up.

**Finding P3-F17 — keep the first copy, one per distinct file hash.** A store refused after a failed replay is copied aside at every start until it is re-bootstrapped, and under the founder's decision above a device offline stays refused, so it restarts with the journal in place. The rule in the note (OQ28) is: copy before open, keep the first copy, and skip a copy whose files hash the same as one already kept. The spike client does not do this yet; it is a product rule, not changed in the gated harness.

### Phase 3 gate — the compound-fault campaign (`run.sh phase3 [runs]`, `replay3 <seed> [mutant]`)

**Pass signal (sync note § 9.1 phase 3):** 0 violations in ≥ 3,000 runs (30,000 stretch); every planted defect caught. Order A (founder, 2026-10-18): every leg first, the campaign last, on the final code. S109 is NOT RUN: key custody is not ready.

**Design** (phase 2's cells, campaign and RNG untouched; phase 2 reruns at full size in the same gate):
- **Retention on:** every run uses `RETENTION=1` (the OQ29 rule, 60 days).
- **Compound process faults:** a client kill and a server kill are each armed in 60 % of runs, drawn from the seed's own RNG; both are armed in about a third. The points and hit counts are phase 2's.
- **A network fault on every sync:** each sync crosses one of phase 2's toxics in 65 % of cases.
- **Reordering and partial batches:** a quarter of the syncs send the pending commands out of order (the second and third swapped, or the two reversed). The server applies the in-order prefix and refuses the rest as a gap, so the batch lands partly; the rest follows on a later sync. A fifth are concurrent syncs.
- **Duplicates out of order:** half of the duplicate resends of acknowledged commands arrive in reverse order.
- **Oracle:** I1–I10 and every leg's checks that apply to a plain run.
- **Mutants (400-run budget each):** phase 2's four (`separate_outbox_txn`, `no_dedupe`, `ack_before_commit`, `double_minute`) plus `drop_on_send`, all under compound faults.

#### Run 1 (dev, uncommitted harness on `7c17478`, 100 runs) — PASS

- **Campaign:** 100 runs, 0 violations. Kills fired: client 56, server 35, both in the same run 21. 608 faulted operations, 491 failed operations, 404 duplicates seen, 63 concurrent syncs with both replies parsed. 96 s.
- **Mutants:** all five caught: `no_dedupe`, `double_minute` and `drop_on_send` after 1 run, `separate_outbox_txn` after 12, `ack_before_commit` after 271.
- **The gate run** (≥ 3,000 runs, with phase 2 at full size, the full regression of every leg and the tamper suite) follows on the committed harness.

#### Run 2 (committed harness `0f13d43`) — **phase 3 gate PASS**

`evidence/phase3-gate-run1-*` (one log per step, plus the campaign, phase 2, S206 and tamper summaries). Started 2026-10-19 15:47, done 19:21. No log in evidence is marked `+dirty`.
- **Log headers:** other-session commits landed during the run (`87dabc8`, `fa12065`, `2b81274`, `47c74bc`, `7c25889`, `9c6eb1e`, `f6bc3d7`, `3244204`, `fe2b237`: the staff-auth note and ADRs, the desktop G5 records, two studio updates). None touches this folder (`git diff 0f13d43 fe2b237 -- prototypes/local-first-sync-spike` is empty), so every step ran the `0f13d43` harness. TS-01b, S207 and TS-02 first ran with a wording edit to this README in the working tree (marked `+dirty`); the edit was reverted and the three were rerun clean on the same harness (`fe2b237` headers); the evidence holds the clean reruns.
- **Compound-fault campaign: 3,000 runs, 0 violations.** Kills fired: client in 1,480 runs, server in 1,188, both in the same run in 585. 18,820 faulted operations, 15,355 failed, 12,955 duplicates seen, 1,895 concurrent syncs with both replies parsed. 47 min.
- **Mutants under compound faults:** all five caught: `no_dedupe`, `double_minute` and `drop_on_send` after 1 run, `separate_outbox_txn` after 12, `ack_before_commit` after 271.
- **Phase 2 at full size (founder requirement):** 13 cells × 50 seeds, 0 violations; campaign 3,000 runs (1,098 with a process kill), 0 violations; the four mutants caught (after 5, 1, 147 and 1 runs); TS-09 15 of 15 sales in both business-hours cases. The pinned-list guard passed.
- **Every leg:** S206 (6 cells, cell `f` included), TS-01b + TS-10 + OQ27, S207, TS-02, TS-07a, SC-13 + TS-01a, SC-31, SC-30, SC-29, SC-28, SC-25b, SC-25a (one-tenth size 30 of 30 and full size 3 of 3), SC-23, SC-22, SC-21a, SC-20 (and its real tmpfs leg, 50 of 50) and SC-19: PASS, every mutant caught (90 mutant lines, none survived).
- **Earlier phases:** phase 0 PASS (the four mutants caught); phase 1 kill matrix PASS (the outbox mutant caught 50 of 50 on each cipher); tamper 38 of 38 PASS, `hot_journal_page1_flip` included, the pinned-list guard passed.

**Phase 3 gate: PASS.** Not run: S109 (key custody not ready). Phase 3 also leaves these limits, each recorded in its section: the TS-01b and TS-02 (b2) blind spots (OQ27), Windows-only behaviour (phase 4), and P3-F17 (a product rule).

### Phase 4 — the same client on Windows 10 (shared VM)

**Plan (founder approved, 2026-10-19).**
- **System under test:** the phase 0–3 client (`sut/client.py`), unchanged except for three Windows ports:
  - the instance lock uses `msvcrt.locking` instead of `fcntl.flock`;
  - the marker rename uses `MoveFileExW(MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH)`, because Windows has no directory fsync;
  - the kill failpoint uses `TerminateProcess`.
- **Runtime on the VM:** Python 3.14.8 (embeddable) and `apsw-sqlite3mc` 3.54.0.0 (SQLite 3.54.0), the same binding as on Linux.
- **Server and oracle:** the Go server, PostgreSQL 18.6 and the phase 0 oracle stay on the host, bound to 127.0.0.1. The VM reaches the server through an SSH reverse tunnel (VM `127.0.0.1:18471` → host `127.0.0.1:18471`), which dies at every power cut.
- **Network faults:** host-side Toxiproxy, as in phase 2. S410 (clumsy/WinDivert on Windows) is not needed, so no unsigned network driver goes on the VM.
- **VM:** the shared `kodeebo-win10`, Windows 10 22H2, 4 GB, 2 vCPU, disk throttled to 100 IOPS + 80 MiB/s.
  - Claimed in the checkpoint; `clean-ssh2` is restored after each run.
  - Reached with the desktop spike's dedicated key **by path only**: `harness/p4.sh` passes the path to ssh and never reads, prints or copies the key.
- **Not run:**
  - TS-04b and TS-08: they need key custody (desktop-note S11), which is not ready (the same reason as S109).
  - S410: replaced, see above.
- **The 2.68 s close-bill outlier (runtime A):** the founder chose the desktop session to rerun A with GC logging under Windows Performance Recorder, in a VM slot claimed in the checkpoint. That session was not running on 2026-10-19, so the request is recorded in the sync block of the checkpoint.

**Tools fetched (2026-10-19, founder approved; in `tools/win-python-3.14.8/`, not committed):**

| File | Source | Bytes | SHA-256 | Check |
|---|---|---|---|---|
| `python-3.14.8-embed-amd64.zip` | python.org/ftp/python/3.14.8/ | 12,601,679 | `a93abe456ab01bd96d7a085b3cdb6566b3063f4241360d114142fbdb07f0a310` | equals the SHA-256 on the python.org 3.14.8 release page |
| `apsw_sqlite3mc-3.54.0.0-cp314-cp314-win_amd64.whl` | PyPI | 3,866,072 | `ce02879c647746af870ee6081fa1b1882b1bd6b9ab559a31008cb887a7726815` | equals PyPI's digest |

**S104 design (`run.sh p4 s104 <power-offs> <crashes>`):**
- **Each run:** 60 sales with syncs and duplicate resends, a cut, the reboot, 5 more sales, a drain, then the phase 0 oracle (I1–I10) against every sale the client acknowledged before the cut.
- **Cuts:**
  - **Power-off:** `virsh destroy`, so the guest's page cache is lost.
  - **OS crash:** an NMI turned into a bugcheck (`NMICrashDump=1`, no dump file, automatic restart).
- **When the cut lands:** half of each kind at a held failpoint. The client sleeps inside the point and the harness cuts once the VM shows the hold file: before or inside the local transaction, after the commit, before the send, before or inside the acknowledgement write, after it. The other half land at a seeded moment, 0–0.8 s after a seeded sale was sent.
- **Exercised:** each run records whether the client found a hot journal at restart (the `.recovery` copy, P1-F3), and the boot time.
- **Not emulated:** the disk's own write cache. QEMU keeps everything the guest already wrote, so this tests the Windows cache and SQLite's flushes, not a disk that acknowledges a flush it did not do; that is for the pilot PC.

Commands: `bash harness/p4.sh up` (revert `clean-ssh2`, boot, throttle), `bash harness/p4.sh install`, `bash run.sh p4 s104 <power-offs> <crashes>`, `bash harness/p4.sh down` (shut off, revert).

**Finding P4-F1 — a power flicker can leave the counter PC stuck at Windows' Recovery screen, waiting for a person.**
- **What happened:** during the first S104 smoke run, after three power-offs and an OS crash in quick succession, the VM did not boot. It stopped at "Recovery — It looks like Windows didn't load correctly", with two buttons (`evidence/phase4/p4-f1-recovery-screen-after-nmi.png`).
- **Reproduced from `clean-ssh2` (`evidence/phase4/p4-f1-probe3.*`):** two power-offs, each 10 s after the VM answered ssh. The first boot was normal; after the second Windows stopped at the Recovery screen and stayed there for 300 s (`p4-f1-a-cut2.png`). One OS crash on its own rebooted normally (probe 1). A crash followed by a power-off 30 s after the boot stopped at the Recovery screen (probe 2).
- **Microsoft's documented rule:** WinRE "starts automatically" after "Two consecutive unexpected shutdowns that occur within two minutes of boot completion", among other triggers ([Windows RE technical reference](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/windows-recovery-environment--windows-re--technical-reference), fetched 2026-10-19).
- **At a venue:** this is a power cut that comes back and drops again within two minutes. The counter then stays down, with the app unable to start, until someone presses "Restart my PC". The cashier may not know to do that.
- **Mitigation tested:** `bcdedit /set {current} recoveryenabled No` and `bcdedit /set {current} bootstatuspolicy IgnoreAllFailures` ("The computer will attempt to boot normally after an error occurs", [BCDEdit /set](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/bcdedit--set)). After them, three power-offs 10 s after boot all booted normally (probe 3 (b)).
- **Cost:** a PC that really cannot boot no longer offers automatic repair; repair then needs recovery media or the Advanced startup menu. Setting it needs administrator rights, once, at installation or onboarding.
- **For the founder:** should the counter PC setup (installer or onboarding checklist) apply this? The S104 runs below apply it, as the product would, so that a run measures the store and not the Recovery screen.

#### S104 run 1 (committed harness `b492b6a`, 2026-10-19 22:30 – 2026-10-20 00:49)

`evidence/phase4/s104-run1.log`, `s104-run1-summary.json`. 30 power-offs and 10 OS crashes on the throttled VM, with the P4-F1 boot settings applied.

| | Power-off | OS crash (NMI bugcheck) |
|---|---|---|
| Runs | 30 | 10 |
| Cut fired | 28 | 8 |
| Cut at a held point: inside the local transaction, after its commit, before the send, before or inside the acknowledgement write, after it | 13 | 3 |
| Cut at a seeded moment | 15 | 5 |
| A hot journal at restart (the copy before open, P1-F3, then SQLite's rollback) | 14 | 5 |
| Boot back to ssh after the cut | 9.0–27.0 s | 176–203 s |
| Acknowledged sales lost or doubled | 0 | 0 |

- **Not exercised:** seeds 3, 11 and 1003 were held at `client:after_business_commit`, a point that exists only in the `separate_outbox_txn` mutant, so the correct client never reaches it. It is dropped from later plans.
- **Harness faults (both fixed, in `b629cf3` and `c886c64`; both replayed below):**
  - **Seed 15** (power, held after the acknowledgement write, hit 2) was reported FAIL with 58 × I1. After the reboot the reverse tunnel's ssh process was alive but carried nothing, so every sync was refused and the drain never reached the server. The device store, fetched and opened on the host, was intact: integrity `ok`, all 65 bills, 58 commands pending. Nothing was lost, but the oracle could not see that. `tunnel()` now checks `/health` from the VM and retries.
  - **Seed 1002** (NMI, held inside the transaction): the run script did not reach the VM right after the previous crash's slow boot, so the client failed to start and the cut never fired. The copy is now verified.
- **In-flight sale:** in 5 runs the sale in flight at the cut was committed on the device but its reply was lost ("acked 64, server 65"). It reached the server once, at the next sync, which is the expected outcome.
- **OS crashes boot slowly:** 176–203 s, against about 13 s after a power-off, on the same VM (indicative only).

#### Leg set 1 (2026-10-20 00:53 – 06:17; one boot from `clean-ssh2`, reverted after)

Evidence: `evidence/phase4/set1-*`. Harness commits: the replays, S303, the timings and SC-27 ran on `c886c64` and `7791001`; SC-26 onwards on `7791001`. Two other-session commits landed during the run (`6e2467f`, `0865142`, research and ADR documents only); `git diff 7791001 0865142 -- prototypes/local-first-sync-spike` is empty. Logs marked `+dirty` show the untracked `harness/__pycache__/` folder only: Python's bytecode cache, not code. It is now ignored (`.gitignore` in this folder).

**Runner restart:** the first runner was a `setsid nohup` job, and it died with the session at 01:57, during SC-26. The rest of the set (SC-26, SC-24, SC-21b, TS-01c) ran again under `systemd-run --user`, on the same VM boot.

**S104 replays: PASS.**
- Seed 15 (power, held after the acknowledgement write, hit 2): 65 acknowledged, 65 on the server, a hot journal at restart, back in 11.7 s.
- Seed 1002 (NMI, held inside the local transaction): 64 and 64, a hot journal, back in 118 s.

With them, **S104: 30 power-offs and 10 OS crashes, 0 acknowledged sales lost or doubled.** The cut fired in 37 runs; 3 runs were held at a point the correct client never reaches.

**S303 (Egypt's UTC offset): Windows and PostgreSQL disagree → finding P4-F2.**
- Windows 10 build 19045.2965 holds one Egypt rule from 2023 on: summer time from the last Thursday of April at 23:59 to the last Thursday of October at 23:59 (`harness/guest/s303rules.ps1`, `set1-s303rules.out.txt`).
- In 2026 that is 2026-04-30 22:00 UTC. The tz database in the `postgres:18.6` image (`Africa/Cairo`) says 2026-04-23 22:00 UTC, the last Friday.
- They agree on the October end (2026-10-29 21:00 UTC).
- Between 24 and 30 April 2026 this PC's local time is one hour behind.
- Not checked: whether a later Windows update changes the rule (the VM has no updates).

**Finding P4-F2 — Windows' own time-zone rules cannot be trusted for Egypt's local time.** The 2026 start differs by a week on this build, and Egypt changes its rules by decree at short notice. **Founder decision (2026-10-20):** every time is stored in UTC. Local time is computed with time-zone rules that ship with the app and can be updated from the server through the config feed. Windows local time is never used for receipts or business logic.

**Counter timings** (`set1-timings.log`; 200 rounds after 10 warm-up rounds; server reachable; timings measured inside the client, ms):

| Action | p50 | p95 | max | Budget (`docs/architecture/perf-budgets.md`) |
|---|---|---|---|---|
| Start session | 131 | 211 | 452 | p95 ≤ 200, max ≤ 1,000: **p95 missed** |
| Change tier (the stand-in for "add item": a committed write to an open session) | 130 | 199 | 458 | p95 ≤ 200, max ≤ 1,000: met |
| Close session (the bill; no printing in the spike) | 296 | 411 | 617 | p95 ≤ 500, max ≤ 3,000: met (the print hand-off is not included) |
| Café-only sale | 299 | 559 | 669 | p95 ≤ 500: **missed** |
| Local commit (the `COMMIT` alone), in close session / café sale | 204 / 203 | 284 / 410 | 543 / 542 | p95 ≤ 150, max ≤ 1,000: **p95 missed** |
| Marker write, in close session / café sale | 68 / 78 | 127 / 138 | 386 / 347 | (part of the commit cost) |
| End Day | 237 | 317 | 317 | p95 ≤ 1,000: met (2 samples) |

**Finding P4-F3 — on an HDD-class disk the forced writes of each sale cost most of the budget.**
- The rollback journal with `synchronous=FULL`, plus the marker (a temporary file, its flush, and the write-through rename), makes about five forced writes per sale.
- **Founder decision (2026-10-20):** the budgets stay. The spike proposes cheaper commits that keep OQ28 (fewer forced writes per transaction; the marker in the same flush where the design allows), measures them and reports. The budgets are revisited only with the pilot PC's numbers.

**SC-27 (Windows Defender scanning while the counter sells):** the same 200 rounds, while a custom Defender scan of the client's folder ran every 20 s (32 scans).
- `Start-MpScan -ScanType FullScan` returned after 3 s, so whether a full scan ran is **not established**.
- Real-time protection was on (signatures 1.461.110.0).

| Action | p50 | p95 | p99 | max |
|---|---|---|---|---|
| Start session | 412 | 953 | 3,791 | 4,968 |
| Close session | 757 | 2,523 | 9,275 | 10,949 |
| Café-only sale | 769 | 2,669 | 7,029 | 10,879 |
| Local commit (close session) | 552 | 1,863 | 6,158 | 7,144 |
| End Day | | | | 8,427 (2 samples) |

No sale was lost or doubled, there was no false refusal, and the client recorded no event.

**Finding P4-F4 — Defender scanning the store stalls the counter for up to 11 s, far above the 3 s ceiling.** **Founder decision (2026-10-20):** write it up first. The write-up includes an option that excludes only the encrypted store and its journal by exact file path, with its security cost; it follows in the measurement leg.

**SC-26 (counter reads while a 35,000-command backlog drains): PASS.**
- A second process read open sessions, today's bills, the price list and the items every 50 ms.
- **Without sync** (120 s, 2,050 reads): p50 0.37, p95 36.3, p99 43.2, max 81.8 ms.
- **During the drain** (15,459 reads): p50 0.47, p95 34.3, p99 41.5, max 93.3 ms. No `SQLITE_BUSY` or locked error reached the reader.
- The drain took 700 syncs in 62 s. The server holds all 35,000.
- Budget: p95 ≤ 100, p99 ≤ 300, max ≤ 3,000 ms: met.

**SC-24 (start-up check on a 60-day store), cold after a reboot, 3 runs each (s):**

| Store | Size | Ready to sell (the client's start, its integrity check included) | `integrity_check` alone | `quick_check` alone |
|---|---|---|---|---|
| 30,000 commands (about 6 days at the OQ16 bound) | 13.6 MB | 43.8–45.3 | 36.0–36.5 | 34.6–36.3 |
| 100,000 commands (about 20 days) | 45.8 MB | 133.5–139.3 | 124.2–129.6 | 128.4–130.6 |
| 300,000 commands (60 days, OQ29) | 141.2 MB | 381.7–386.7 | 370.5–376.9 | 371.2–376.4 |

Budget: ready ≤ 10 s, check ≤ 5 s. **Missed at every size**, by 7× at 6 days and 75× at 60 days.

**Finding P4-F5 — a full check of the store at every start is far too slow on an HDD-class disk.**
- Both checks read about 0.38 MB/s, about 92 pages of 4 KB per second. That is the VM's 100-IOPS cap, one request per page.
- `quick_check` is no faster: the time is spent reading pages, not checking indexes.
- A real HDD with read-ahead may read faster, so these numbers are an upper bound (G0-F2). But a fragmented store on a real HDD can come near them, and even a tenth of these times breaks the budget at 60 days.
- Options to measure next (each re-runs TS-03a, sync note SC-24):
  - the full check only after an unclean shutdown (a hot journal, or the store and marker disagree) and on a schedule, relying otherwise on the cipher's per-page authentication;
  - a partial check of the hot tables at start;
  - a larger page size (fewer requests per MB).

**SC-21b, sync half (an update with sales queued on Windows): PASS.**
- Version 1 synced 10 sales and queued 10. Version 2 then started and migrated the store to schema 2. In 6 of the 7 cases the power was cut while version 2 was held at a migration step: before the copy, after the copy, mid-DDL, after the commit, before the marker, before the cleanup.
- Every case ended at schema 2 with all 25 sales on the server exactly once.
- Resends of acknowledged commands came back `duplicate`, never `conflict`. The stored bytes did not change across versions.

**TS-01c (a store copy restored on Windows):**
- **Run without the decided OQ7 policy:** the harness started the server without `CLONE_POLICY=1`.
  - **(a)** (the later sales were synced before the restore): the server refused the restored device's new sales as `seq_conflict`. That is detection, but not the decided OQ6/OQ7 handling, which quarantines them for the owner and never rejects a money fact.
  - **(b)** (they never reached the server): the erased sales were never seen, and the restored device's next sales took their sequence numbers. This is the known blind spot (OQ27), confirmed on Windows.
- **Rerun with `CLONE_POLICY=1`:** in leg set 2; the harness is fixed.
- **Windows finding:** the store and the marker could be copied while the app was running (an administrator `copy`; SQLite opens the file with read sharing). Only the cashier-account boundary (M1, TS-08) can stop that.

#### Leg set 2 (2026-10-20 08:18 – 19:50; one boot from `clean-ssh2`, reverted after)

Evidence: `evidence/phase4/set2-*` (runner `set2-runner.sh`, status `set2.status`). Every leg ran on committed harness `4ddb601`. Indicative only: one throttled VM, and most rows are one run.

**TS-01c rerun with the decided OQ7 policy (`CLONE_POLICY=1`): (a) PASS, (b) blind spot confirmed.**
- **(a)** (the later sales were synced before the restore): the restored device's next sale reused a sequence the server already held. The server quarantined the device (`sequence_reused`) for the owner's choice instead of rejecting the sales; the oracle's 3 × I1 are exactly the sales held in quarantine. The same with the copy taken while the app ran.
- **(b)** (they never reached the server): nothing to detect; the restored device's next sales take the erased sequence numbers (OQ27 blind spot), on Windows as on Linux.

**P4-F3 commit variants, one run each (200 rounds, ms, total inside the client):**

| Journal / marker | Close bill p50 / p95 / max | Café sale p50 / p95 / max | Start p95 | Commit p95 (close) |
|---|---|---|---|---|
| delete / file (phase 0–3 design) | 276 / 457 / 570 | 279 / 399 / 539 | 211 | 316 |
| delete / slots | 269 / 489 / 697 | 277 / 528 / 5,598 | 261 | 375 |
| truncate / file | 266 / 1,459 / 2,722 | 259 / 1,228 / 2,308 | 672 | 911 |
| truncate / slots | 229 / 360 / 1,380 | 223 / 337 / 1,919 | 188 | 266 |
| persist / file | 287 / 475 / 535 | 279 / 459 / 578 | 220 | 346 |
| persist / slots | 260 / 358 / 1,843 | 258 / 401 / 1,756 | 199 | 296 |

- `slots`: the marker is two 128-byte MAC'd slots written in place with one flush, instead of a temporary file, its flush and a write-through rename.
- The spread between single runs is larger than the differences (truncate / file's p95 is four times truncate / slots'), so nothing is ranked from this table. No variant reaches the commit p95 ≤ 150 ms.
- **Linux checks per variant (`evidence/phase4/p4f3-*`, harness `901f3b8`):** the phase 1 kill matrix PASS for all six. Tamper 38 of 38 for delete / file and delete / slots. For the four truncate and persist variants, 28 of 38: the 10 wrong-key rows reported `client.db-journal` as a stray file, with the store unchanged and every attempt refused and recorded. Those two modes keep the journal file by design, so the file existed before the probe. The check was fixed in `4ddb601` (a journal file is a stray only if the probe changed it), but the four variants' tamper suite was not rerun after it: **Rerun after set 3 (2026-10-21, `evidence/phase4/set4prep-tamper-*`): 38 of 38 for all four.** See "Linux checks after set 3" below.
- **Next (founder, 2026-10-20):** set 3 repeats the three leading options (truncate / slots, persist / slots, delete / file) alternately, three rounds of 400.

**SC-27 with the P4-F4 exclusion options (200 rounds each, ms).** A custom Defender scan of the client's `runs` folder (every earlier run's store included) every 20 s, and a `FullScan` request. As in set 1, `Start-MpScan -ScanType FullScan` returned after 2–6 s, so whether a full scan ran is **not established**.

| Option | Custom scans | Close bill p50 / p95 / p99 / max | Café sale p50 / p95 / p99 / max | Start p99 |
|---|---|---|---|---|
| No exclusion | 19 | 515 / 1,153 / 6,490 / 8,579 | 528 / 938 / 4,178 / 9,869 | 2,186 |
| Exact paths: the store and its journal only | 25 | 684 / 1,334 / 2,370 / 6,053 | 678 / 1,320 / 3,349 / 5,366 | 1,401 |
| Contextual: the same paths, only when the app's `python.exe` opens them | 21 | 515 / 1,421 / 3,017 / 4,781 | 508 / 2,628 / 7,428 / 34,218 | 1,457 |

- No sale lost or doubled, no false refusal, in all three.
- Neither exclusion brings the tail under the 3 s ceiling. The scan still reads every other file in the folder (the other runs' stores, the marker, the logs) on the same 100-IOPS disk, and an exclusion does not remove that disk load (inference; per-file I/O not traced). The 34 s café sale under the contextual option is one commit, in one run.
- The reference without any scan (delete / file above): close bill max 570 ms, with real-time protection on. Real-time protection alone costs little here; the stalls come with a scan running while the counter sells.
- Platform 4.18.26090.9, so contextual exclusions are supported (they need 4.18.2205.7 or later). Both options were removed after their run (`defender-excl.ps1 remove`).
- The write-up for the founder (the security cost, and scan scheduling as the other lever) is in the phase 4 report.

**SC-24 options (P4-F5): ready times INVALID, rerun in set 3.**
- The probe (`harness/guest/sc24probe.py`) and the option 4 run timed "ready" as the first reply to `stats`. But `stats` runs `integrity_check` itself, so every row includes a full check: partial and unclean came out at 45 s (30k) and 380–386 s (300k), the full check's own time. Fixed in `7862d0f`: the ready signal is the light `marker` op, and sc24b also measures `full` and `quick` start modes.
- The page-size rows (full check, 30k store, cold): 16 KB 17.0–18.7 s, 64 KB 11.0–12.1 s, against 36 s at 4 KB in set 1. The second check in `stats` read a warm cache, so these are close to the real numbers; set 3 measures them again.

**SC-24 option 4 (background check) found a defect: fixed in `7862d0f`.**
- On the 300k store the background copy refused the store in both runs, and every later sale was refused (1,079 instant refusals in 90 minutes). The background copy shared the counter's own connection across threads, and apsw raises `ThreadingViolationError` when two threads use one connection at once; the client treated that as a store fault.
- The fix: the copy uses its own read-only connection, and a lock (`store_mx`) keeps each backup step from overlapping a counter write. A stress case (no idle wait, 400-page steps, a sale every 20 ms) was added to `harness/bgcheck.py`; 3 runs PASS on Linux.
- On the 30k store the copy completed (3,329 pages in 41.4 s, cold) and the check of the copy took 0.1 s (the copy was still in the OS cache). Its ready time is invalid for the reason above.
- The oracle's I1 rows in this leg are the pre-built store's commands, which were synced to the builder's own database (`sc24`), not to this run's server: a harness artefact, not a loss.

**TS-07b (real Windows clock edits) → finding P4-F6.** The client ran with `REALCLOCK=1` (Windows' own clocks: `GetTickCount64`, `QueryPerformanceCounter`, the `BootId` counter). An administrator set the time ±1 h with `Set-Date -Adjust` while the cashier's client ran.

| Case | Edit | Real time | Billed | Event recorded |
|---|---|---|---|---|
| Session running, app open | +1 h / −1 h | 3 min | 3 min / 3 min | `wall_clock_moved` +3600 / −3600 |
| Session closed during the edit window, app open | +1 h / −1 h | 3 min | 3 min / 3 min | `wall_clock_moved` +3600 / −3600 |
| Edit, then a restart before the app's next one-minute check | +1 h | 5 min | **65 min** | none |
| The same | −1 h | 5 min | **−55 min** | none |

- **Finding P4-F6 — a clock edit followed by a restart bills an open session wrongly, even negatively, without any event.**
  - Across a restart the monotonic clock starts again from zero, so the client measures the outage with the wall clock (last-alive checkpoint to now, D1-B). An edit made less than a minute before the restart is never seen, because the client compares the clocks once a minute.
  - The cashier account cannot read Windows' time-change or boot events: `wevtutil` answers "Access is denied" for both.
  - This is phase 5 territory (trusted time). Candidates for the founder: never bill a negative gap and hold a large one for the cashier's confirmation, with an owner flag; catch the edit at once with `WM_TIMECHANGE`, which "the system will broadcast … when the application changes the system time" ([Win32 docs](https://learn.microsoft.com/en-us/windows/win32/sysinfo/wm-timechange), fetched 2026-10-20); and compare with server time at the next contact.

**S301/S302 (clocks and the boot marker across a restart, a shutdown, a power-off), 10 rounds each.**

| Transition | Rounds | `BootId` +1 | Tick and QPC restart from zero | A marker kept in memory survives |
|---|---|---|---|---|
| Restart (`shutdown /r`) | 10 | 10 | 10 | 0 |
| Shutdown requested as Fast Startup (`shutdown /s /hybrid`, off 30 s); what the VM did instead is not established | 10 | 10 | 10 | 0 |
| Power-off (`virsh destroy`, off 30 s) | 10 | 10 | 10 | 0 |
| `shutdown /s /full` | 10 | did not shut down | — | — |
| Hibernate (`shutdown /h`) | 10 | did not shut down | — | — |

- **The registry `BootId` counter rose by exactly one at every boot measured** and did not move on any clock edit (TS-07b). A boot time computed as wall clock minus uptime is not reliable on its own: it moved once without a boot, from rounding.
- **"PC was off" is NOT verified for a true full shutdown.** It holds here for a restart and a hard power-off only. **Update (set 4, 2026-10-22): verified** — 5 plain `shutdown /s /t 0` (exit code 0, the VM powered off, 30 s off): `BootId` +1 every time, the in-memory marker lost every time (see "Leg set 4" below).
  - The `/full` leg did not shut the VM down in any round. Likely cause, to confirm after set 3: Microsoft's documented `shutdown` syntax has no `/full` parameter, and a plain `shutdown /s` is already a full shutdown ("Full shutdown is the default when you use Shutdown.exe", [KB 3211190](https://learn.microsoft.com/en-us/troubleshoot/windows-client/setup-upgrade-and-drivers/fast-startup-causes-system-hibernation-shutdown-fail); [shutdown command reference](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/shutdown), both fetched 2026-10-20). The harness did not record the command's error output, so this is not yet established.
  - The `/hybrid` leg asks for a Fast Startup shutdown, but the VM's firmware supports neither hibernation nor Fast Startup (`powercfg /a`), so what it actually did is not established either.
  - After set 3: rerun the leg with `shutdown /s /t 0` and keep the command's output.
- **Fast Startup and hibernate are not covered on this VM;** they go to the pilot PC (below).
- The cashier account cannot read the Kernel-Boot event 27 either ("Access is denied").

**Pilot-PC checks (things this VM cannot show; run on the first pilot café's PC before a release reaches it):**
- **Fast Startup (founder, 2026-10-20).** Microsoft: "Fast Startup is enabled by default in Windows", and with it "the kernel session is not closed, but it is hibernated" at Shut down; "The Fast Startup setting doesn't apply to Restart" ([KB 3211190](https://learn.microsoft.com/en-us/troubleshoot/windows-client/setup-upgrade-and-drivers/fast-startup-causes-system-hibernation-shutdown-fail), applies to Windows 10, ms.date 2026-02-12). The system "appears to the user as though a full shutdown (S5) has occurred, even though the system has actually gone through S4" ([System power states](https://learn.microsoft.com/en-us/windows/win32/power/system-power-states), ms.date 2025-07-14). So a cashier's normal Shut down is a kernel hibernation.
  - **To test:** with Fast Startup on, Start menu Shut down and power on again; does `BootId` rise; do the tick count and QPC restart or carry on; does the founder's "PC was off" versus "app was closed" split still hold; and is a session open across it billed for the real time off.
  - **The risk to check (inference, not measured):** if `BootId` does not rise, the client treats the shutdown as "app was closed while the PC was on" and measures the gap with the monotonic clock (D1-B), which may not count the time the PC was off, so an open session would be under-billed.
  - **If it breaks the split:** a candidate install-checklist item is turning Fast Startup off (Power Options, "Turn on fast startup", or `powercfg /h off`, which also removes hibernation). Microsoft's KB adds that "Disabling Fast Startup is not recommended"; the cost to weigh is a slower cold boot.
- **Hibernate,** if the PC offers it: the same questions.
- **The disk's own write cache** (S104 above: QEMU does not emulate a disk that acknowledges a flush it did not do).
- **Every device timing** (`docs/architecture/perf-budgets.md`: the pilot PC replaces the VM proxy), including P4-F3's commit cost and P4-F5's start check on a real HDD or SSD.
- **Defender's scheduled-scan settings** chosen for P4-F4, once decided.

#### Leg set 3 (2026-10-20 19:50 – 22:00, and the S309 rerun 2026-10-21 04:36 – 12:41)

Evidence: `evidence/phase4/set3-*`. SC-24 options ran on `8dfdc86+dirty`: the dirt was set 2's evidence and README, which were being written during the leg; the spike's code was identical to `7862d0f` (`git diff 7862d0f 8dfdc86` on this folder is empty). Every later leg logged a clean tree (`b6b7150`; the S309 rerun `0b4dbbe`, whose spike folder equals `b6b7150`'s). Indicative only: one throttled VM.

**S309 of set 3: INTERRUPTED (host suspend/shutdown).** The runner was stopped by systemd at 2026-10-21 00:24, when the host went down; the host came back at 04:33. The leg's log is empty and nothing from it is used (`set3.status`). The VM was reverted to `clean-ssh2` once, and S309 was rerun from the start on a fresh boot (`set3-s309b-*`).

**SC-24 options (P4-F5), cold after a reboot, 2 runs; "ready" = the first reply to the light `marker` op, timed inside the VM (s):**

| Start check | 30k store (13.6 MB) | 300k store (141.2 MB, 60 days) |
|---|---|---|
| full | 45.3 / 76.8 | 384.7 / 378.8 |
| quick | 43.6 / 44.8 | 376.8 / 373.8 |
| partial (page 1 + the hot tables) | 7.7 / 8.0 | 8.1 / 8.4 |
| unclean (partial after a clean exit) | 8.2 / 8.6 | 17.1 / 9.0 |
| full, 16 KB pages | 17.3 / 15.0 | — |
| full, 64 KB pages | 9.8 / 9.5 | — |

- Partial and unclean do not grow with the store: about 8 s at 6 and at 60 days, under the 10 s ready budget on this disk. Larger pages speed up the full check but it still scales with the store.
- Two outliers are not explained: full at 30k (76.8 s) and unclean at 300k (17.1 s).

**SC-24 option 4 (background check), cold, a café sale every 5 s (ready timed from the host, so it includes the ssh call and process launch and is not comparable with the table above):**

| Store | Ready | Copy + check of the copy | Sales during the copy |
|---|---|---|---|
| 30k | 13.2 / 12.8 s | 5.7 + 0.1 / 5.4 + 0.1 s, ok | 2 sales, max 313 / 319 ms |
| 300k | 12.6 / 12.4 s | 69.8 + 0.5 / 72.3 + 0.6 s, ok | 11 sales, p50 0.82 / 1.21 s, max 2.65 / 2.94 s |

- **The set 2 threading fix holds on Windows:** the 300k store ends "ok" in both runs (set 2 refused it).
- **Sales slow down while the copy runs** (p50 about 1 s, max 2.9 s: under the 3 s ceiling, over the 500 ms café budget). **Likely cause, to confirm in set 4:** the copy reads through its own connection, and SQLite restarts a backup at its next step whenever the source "is modified by an external process or via a database connection other than the one being used by the backup operation" ([sqlite3_backup](https://www.sqlite.org/c3ref/backup_finish.html)), so each sale probably restarts the copy and the copy file is written again. Set 3 did not count restarts.
- **Set 4 (founder, 2026-10-20):** fix 4 alone, the copy steps on the counter's own connection and thread between operations, so the counter's writes update the copy instead of restarting it; restarts counted for fix 4 and for today's copy; pass = café sale p95 ≤ 500 ms while the check runs, and the check completes on the 300k store. A copy into memory is **rejected (security):** SQLite3MC's encryption "can support only databases based on ordinary files, not memory based databases" (SQLite3MC docs, Architecture, Virtual File System), so the copy would be the whole store in plaintext, pageable to `pagefile.sys`.

**P4-F3 commit options, three alternating rounds of 400 (ms, total inside the client):**

| Option | Round | Close bill p50 / p95 / max | Café sale p50 / p95 / max | Start p95 | Commit p95 (close / café) |
|---|---|---|---|---|---|
| truncate / slots | r1 | 210 / 281 / 469 | 199 / 270 / 690 | 119 | 208 / 198 |
| | r2 | 241 / 405 / 530 | 229 / 409 / 861 | 198 | 299 / 305 |
| | r3 | 190 / 228 / 291 | 179 / 218 / 368 | 98 | 187 / 176 |
| persist / slots | r1 | 269 / 523 / 2,046 | 259 / 468 / 1,536 | 246 | 411 / 407 |
| | r2 | 250 / 326 / 570 | 229 / 297 / 513 | 149 | 265 / 237 |
| | r3 | 238 / 279 / 330 | 228 / 259 / 311 | 128 | 239 / 225 |
| delete / file (phase 0–3 design) | r1 | 305 / 595 / 1,487 | 298 / 579 / 1,601 | 262 | 411 / 384 |
| | r2 | 264 / 317 / 486 | 258 / 309 / 2,138 | 141 | 235 / 223 |
| | r3 | 266 / 317 / 658 | 259 / 318 / 390 | 134 | 235 / 223 |

- No sale lost or doubled in any round.
- **truncate / slots** has the lowest p50 in every round and the lowest p95 in two of three; it meets start p95 ≤ 200 and café sale p95 ≤ 500 in all three. delete / file missed the café sale budget in round 1.
- **No option meets commit p95 ≤ 150 ms** (truncate / slots 176–305). The budget stays until the pilot PC's numbers (founder, 2026-10-20).
- **Tamper:** at the time of set 3, truncate / slots was among the four variants whose tamper suite was not passed (not rerun after the `4ddb601` fix). The rerun after set 3 passed 38 of 38 (below), so truncate / slots is the proposed commit option for set 4's S104 run, pending the founder's decision.

**S309 (the one-minute heartbeat for 8 h, a sale every 30 s), rerun: no violation, nothing failed, but the ceiling was broken twice.**

| Op | n | p50 | p95 | p99 | max |
|---|---|---|---|---|---|
| Heartbeat (`tick`, a committed write) | 480 | 16 | 197 | 500 | **4,712** |
| Café sale | 960 | 241 | 459 | 1,023 | **4,864** |
| Sync (every 20 sales) | 48 | 163 | 221 | 562 | 562 |

- **Two operations broke the 3 s ceiling:** the 24th heartbeat (about 23 minutes after the start) at 4.7 s, and the 474th sale (about 4 h in) at 4.9 s. In the sale, the time was spent inside the transaction before the commit (4,756 ms; commit 219 ms, marker 107 ms), so it waited on reads, not on its forced writes. The cause is **not identified** (candidates: Windows' own work on the same throttled disk, such as Defender or maintenance tasks; not traced).
- 10 of the 12 sales over 1 s came in the first 28 minutes after the boot; after that, sale p95 was 278 ms.
- **The bytes-written measurement failed:** every `WriteTransferCount` reading came back empty (the query ran in the cashier's session; why it returned nothing is not investigated), so S309's write volume is **not measured**.

**Open question OQ32 (founder, 2026-10-20; owner: the sync ADR; carried in phase 5's list in the sync note).** A store fault found while offline stops the counter: today's design (OQ31) refuses every sale until the device reloads from the server, so an offline venue sells only on paper until its internet returns, against principle 2 ("The counter never waits"); principle 1 ("Every pound leaves a trail") is the constraint any way of selling on must keep. Candidate to evaluate: a fresh store that keeps selling, with the salvage store kept for upload; what happens to open sessions, bill numbering (continue above the MAC'd marker, never reuse), the lease and the lost-range count, and what the fresh store needs before its first sale (catalogue, prices, PIN verifiers). Also: whether PIN verifiers and the lease copied from a damaged store are trusted on the page HMAC alone or only as a server-signed copy, and how the owner is told the venue sells on a rebuilt store. A question only: OQ31 point 7 (no offline selling on a fresh, empty store) and the `sell_on_fresh` mutant stay in force until the sync ADR decides, and that decision goes back to the founder. Not tested in phase 4. Full text: sync note OQ32.

#### Linux checks after set 3 (2026-10-21, host only; founder go 2026-10-21)

Evidence: `evidence/phase4/set4prep-*`. They ran on `3be7a5c` plus the uncommitted set 4 changes to `sut/client.py` and `harness/p4.py` (`set4prep.status` records the tree at each start): the restart count, the `BG_MODE=counter` copy (off by default), and two client mutants. The default code paths are unchanged.

**Tamper for the four truncate and persist variants: 38 of 38 each** (`TAMPER_JOURNAL` × `MARKER_MODE`: truncate / file, persist / file, persist / slots, truncate / slots). The wrong-key rows now report no stray file: the journal these modes keep is no longer counted when the probe did not change it (the `4ddb601` fix).

**Regression on the patched client: PASS.** `harness/bgcheck.py` 6 of 6 cases; phase 0 self-test gate PASS; phase 1 kill matrix gate PASS.

**The background-check window test (`harness/bgwindow.py`; founder, 2026-10-20): PASS, 5 cells × 5 seeds, all 4 mutants caught.**
- **The question:** the background check finds the store damaged after the counter has already sold on it. What happens to the sales made in that window?
- **Pass rule (founder): no sale is lost silently.** Every acknowledged sale ends on the server once (applied normally if a sync carried it; otherwise through the salvage, which reads only rows that pass the page HMAC, flagged "salvaged" for the owner), or inside a reported lost range (`store_fault_unreadable`, counted from the MAC'd marker) with an owner alert. No sale is acknowledged once the fault is known; the damaged store is not written to between the fault and the contact.

| Cell | What is damaged, when | Window sales (seed 1) | Outcome |
|---|---|---|---|
| end_online | a minutes page new sales never write to, before the start; a sync every 3 sales | 3 | the third sale's sync read the damaged page first: the operation failed, sales stopped; the 3 sales were already on the server through that sync (the salvage upload came back "duplicate"; not flagged) |
| end_offline | the same page; server down | 10 | the background copy hit the page (page 256 of 258): all 10 salvaged, applied once, flagged |
| salepages_start_offline | the last leaf of the bills and of the minutes table (where new sales write), before the start | 0 | the first sale read the damage and was refused; nothing acknowledged, nothing to lose |
| salepages_window_offline | every outbox page and the last bills leaf, after 10 window sales, while the app runs | 10 | 9 salvaged and flagged; **1 unreadable, counted in a reported lost range with the owner alert**; 0 silent |
| salepages_window_online | the same, syncing every 3 sales | 10 | 9 synced normally, 1 salvaged and flagged |

- **Mutants:** `bg_fault_ignored` (sells on after the fault), `rebootstrap_no_salvage`, `salvage_hides_lost` (declares no lost range), `salvage_silent` (server applies salvaged sales without the flag): all caught.
- **Two things the window test shows besides the rule:**
  - With today's copy (its own connection), the copy restarts at every sale, so it completes only in an idle gap long enough for the whole copy; the test sells 10 sales close together and then pauses. On a busy counter the background check may not finish for a long time (set 4 counts restarts).
  - A normal operation that reads a damaged page (a sale, a sync) finds the fault on its own, before the background check, and stops sales the same way.
- **Harness faults found and fixed on the way** (`set4prep-bgwindow-run1-harness-fault.log` is the second attempt, after the first two fixes: 2 of 5 cells failed; the first attempt, stopped once its first cells failed every seed with an empty window, was overwritten by it): the "late page" was the minutes table's rightmost leaf, where new sales write (now: the highest page that is not the rightmost leaf); the window was one sale long (the copy finished in the first gap: now 10 sales, then a pause); "unchanged" was compared with the store before the window (now from the first sign of the fault); and a sale carried by a sync that did not reply was required to be flagged (it may have been applied normally by that batch: now exempt).

#### Set 4 preparation: the short Linux check (2026-10-21; founder go)

Evidence: `evidence/phase4/set4-linuxcheck-*`; the tree was `1ab30a5` plus the set 4 harness changes (`set4-linuxcheck.status`).

| `harness/bgcheck.py` case | Fix 4 (`BG_MODE=counter`) | Today's copy (`BG_MODE=thread`) |
|---|---|---|
| background, damaged page | found after 15 sales, sales stopped; 0 restarts | found after 1 sale |
| partial (control) | the damage is not seen (expected) | the same |
| full; background_unclean after a kill | refused at start | the same |
| background, clean store | "ok" after 31 sales; 0 restarts | "ok" after 4 sales |
| background, clean, stress (no idle wait, a sale every 20 ms) | "ok" after 8 sales; **0 restarts** | "ok" after 97 sales; **31 restarts** |

- **The restart cause is confirmed on Linux:** today's copy, on its own connection, restarted 31 times in 97 sales; fix 4, on the counter's own connection, never restarted.
- **The trade-off:** on an idle counter fix 4 finishes later, because it copies only in short idle slices on the counter's own thread. Set 4 measures both on the 300k store.
- **The S104 configuration under the phase 1 kill matrix: PASS** (truncate / slots, `START_CHECK=background`, `BG_MODE=counter`).
- **Requirement for the counter-shell spec (founder, 2026-10-21):** fix 4 reported the damaged page as `CorruptError: not an error`, which is SQLite's wording for that path. Such text must never reach a cashier or the owner. A detected store fault is reported in the product's own words: what happened, that sales have stopped, and what to do next. SQLite's text goes only to the diagnostic log.

#### Leg set 4 (2026-10-21 19:54 – 23:46, interrupted; resumed as set 4b 2026-10-22 15:32 – 17:46)

Evidence: `evidence/phase4/set4-*`, `set4b-runner.sh`, `set4.status`. Harness `7e1a2d3` (set 4) and `4718d33` (set 4b, whose spike folder equals `7e1a2d3`'s); clean tree both times. The runner was stopped by systemd at 23:46 when the host went down; the VM was then used by the catalogue session (S42) and left on `clean-ssh2`.

**Fix 4 against today's copy, 300k store, cold (sc24c; restarts counted):**

| Copy | Sale profile | Runs | Restarts | Check | Sales during the check |
|---|---|---|---|---|---|
| today's (own connection) | every 5 s | 2 | **9 / 1** | ok: copy 82.3 / 29.7 s + check 0.6 / 0.5 s | 12 / 4 sales; p50 1.58 / 2.66 s; **max 3.34 / 5.41 s** |
| fix 4 (counter's connection) | every 5 s | 2 | 0 / 0 | ok: copy 26.7 / 28.1 s + check 0.9 / 1.2 s | 6 / 6 sales; p50 347 / 449 ms; max 741 / 842 ms |
| fix 4 | every 1 s | 2 | 0 / 0 | **never finished**: 73 % of the pages (25,728 / 35,176 and 26,176 / 35,915) in the 90-minute cap | 4,296 / 4,115 sales; p50 163 / 164 ms; p95 707 / 776 ms; **max 6,310 / 11,117 ms** |
| today's | every 1 s | — | — | **INTERRUPTED** (host down at 23:46): not used | — |
| fix 4, 30k store | every 1 s | — | — | not run | — |

- **The restart cause is confirmed on Windows:** today's copy restarted with the sales and broke the 3 s ceiling (3.3 s, 5.4 s); fix 4 never restarted and finished the check in 27–28 s with a sale every 5 s.
- **Fix 4 fails a sale every second:** with its 1 s idle gate a sale every second leaves the copy almost no idle time, so the check never finishes, and single sales took 6.3 s and 11.1 s. The run kept only aggregate timings, so the slow sales cannot be split (queue wait, copy step, Windows) from this data.
- **Founder (2026-10-22), option A:** no single till sells once a second (the estimate is one sale every ~18 s on average), so the busy profile is replaced by a rush (bursts of 5–10 sales 2–3 s apart, then 30–120 s of quiet); fix 4 is measured under it with today's gate (1 s, 64 pages) and a short one (0.2 s, 16 pages), and the sale-every-5-s case again with at least 200 sales; every sale over 500 ms gets its split. Pass: café sale p95 ≤ 500 ms, nothing over 3 s, every check finishes within the quiet periods.

**S104 on truncate / slots: did not start (harness fault).** Before S104 the harness restarts the VM (`prep_crash`); it waited a fixed 40 s after `shutdown /r` and took the first ssh answer as the new boot. On the throttled disk the old boot was still answering, so the tunnel was opened on a VM that then went down ("reverse tunnel did not carry traffic after retries"). No cut was made, no store touched. Fixed for set 5: every restart waits until `BootId` changes (hard 15-minute limit, both values logged).

**S30x, the shutdown diagnosis:**
- **`shutdown /s /t 0`, 5 rounds: PASS.** Exit code 0, the VM powered off every time; `BootId` +1 every time (7→8 … 11→12), the in-memory marker lost every time. So **"PC was off" is verified for a true full shutdown** (`shutdown.exe /s` is a full shutdown by default, KB 3211190; Shut down from the Start menu with Fast Startup on is the pilot-PC check).
- **`/full` once: INVALID.** It ran while the VM was still restarting from the failed S104 start, so the command never reached Windows ("Connection refused"). Rerun in set 5.

**First 30 minutes after a cold boot (boot watch × 3): timings INVALID — the disk was not throttled.** The S30x power cycles start a new qemu process, which does not carry the live throttle, and nothing re-applied it (libvirt read back 0 IOPS and 0 bytes/s afterwards). Sales ran at p50 15–19 ms, max 204 ms: not the HDD-class PC. Set 5 re-applies the throttle after every start and every timing leg reads it back before measuring. What remains usable:
- **Write volume (does not depend on disk speed):** the counter process wrote about 6.1 MB in 30 minutes (about 12 MB an hour) at a sale every 30 s and the one-minute heartbeat, read as administrator.
- **What Windows ran after boot (indicative, unthrottled):** Defender's engine (`msmpeng`) did most of the disk I/O in boot 1, `svchost` in boot 2; no Defender scan was flagged as running; `TrustedInstaller` ran for about the first 4 minutes; scheduled tasks seen: Windows Update `ScanForUpdates`, `ProgramDataUpdater`, Edge Update, Windows Error Reporting `QueueReporting`.
- **The boot trace (boot 3) never reached the host,** and the harness did not record why; set 5 keeps every trace step's output and fails the leg if the export is missing.
- **Harness bug:** the write-volume series recorded one reading every 0.2 s instead of one every 10 sales (it compared a time with a sale count); the readings themselves are right. Fixed for set 5.

#### Set 5 preparation (2026-10-22; founder approval 2026-10-22)

Harness and client changes for the fix 4 follow-up (founder, option A) and the run rules; Linux check `evidence/phase4/set5-linuxcheck-*` (tree `4718d33` plus these changes): `harness/repeatcheck.py` PASS (checks back to back: 5 completed, 0 restarts, every operation reported its queue wait and the copy step it waited behind), `harness/bgcheck.py` 6 of 6 in both copy modes, phase 0 self-test gate PASS.
- **Diagnosis:** every operation reports its queue wait and the copy step it waited behind; every copy step is timed; checks can run back to back (`BG_REPEAT=1`) with a log per check.
- **The `sc24r` leg:** the rush profile (bursts of 5–10 sales 2–3 s apart, then 30–120 s of quiet; seeded) or a sale every N s, at least 200 sales, checks back to back, the boot-watch sampler alongside. Per check: finished or not, its duration, the sales that overlapped it (an unfinished check fails the setting). Per sale over 500 ms: queue wait, copy step, transaction, commit, and the sampler's view of Windows at that moment. Pass (founder): café sale p95 ≤ 500 ms, nothing over 3 s, every check finishes within the quiet periods.
- **Run guards (founder):** a restart waits for a new `BootId` (hard 15-minute limit, both values logged); every tunnel retry is logged with its time and error and counted per leg; a `BootId` change the harness did not ask for fails the leg; every timing leg reads the disk throttle back from libvirt before it measures, and S30x re-applies it after every start; the boot trace keeps each step's output and fails if the export is missing. The overnight runner stops at the first fault, with no retry, and leaves the VM and the stores as they are.
- **Founder trigger (2026-10-22):** if, after these fixes, the realistic rush still breaks the sale ceiling (p95 > 500 ms or any sale > 3 s), a `/research` on counter-store alternatives opens.

#### Leg set 5 (2026-10-22 – 23): S104 on truncate / slots, three attempts, and the seed-1006 replays

Evidence: `evidence/phase4/set5-*` (status `set5.status`, attempts `set5-attempt{1,2,3}-*`, replays `set5-replays-*`, the salvage `set5-attempt3-salvage.md`). Founder rules: stop at the first fault, no automatic retries, every attempt's logs kept.

| Attempt | Harness | What happened | Cuts passed before it ended |
|---|---|---|---|
| 1 (2026-10-22 18:43 – 20:28) | `c93b4f6` | **harness fault:** during the 3rd OS crash's 3-minute reboot an ssh "up?" probe hung past 30 s and `wait_boot` raised. Fixed in `48b1252` (a hung probe is "not up yet" inside the 15-minute limit; `BootId` must rise by exactly the one boot the harness caused) | 30 power-offs + 2 OS crashes, 0 violations |
| 2 (2026-10-22 23:18 – 23-10-23 00:44) | `48b1252` | **INTERRUPTED:** the host was rebooted from the KDE logout dialog at 00:44 (the sleep inhibit did not cover shutdown; it now does) | 28 power-offs, 0 violations |
| 3 (2026-10-23 03:04 – 05:28) | `94f53c3` (spike folder = `48b1252`) | **STORE FAILURE:** the 6th OS crash (seed 1006, held at `client:after_mark` #1) left the store unopenable: after the reboot the client refused it (`store_unusable_at_start`, "database disk image is malformed"); detected, not silent | 30 power-offs + 5 OS crashes, 0 violations |

**The damaged store (attempt 3, seed 1006).** The VM's file and the fetched copy are identical (SHA-256). Page 1 of 81 fails decryption and authentication, so no statement opens the file, and the product's salvage (A), which reads by query, would recover nothing. The client had acknowledged 44 sales; 2 of them (`s1006-a42`, `s1006-a43`) had not reached the server. **Lab salvage on a copy** (page 1 replaced by page 1 of a fresh store from the same code and test key, read-only with `writable_schema = ON`): all 81 pages decrypt and authenticate, and **all 44 acknowledged sales come back**, the 2 unsynced ones included (bills, and the outbox as pending). The `minutes` table and `integrity_check` still report damage: page 1's real header and free-page list are lost. So no money was physically lost; (A) as built would have reported the 2 as a lost range with an owner alert. The founder recorded the rebuild-page-1 salvage as option (C) for the sync ADR (sync note OQ31, with a schema-version guard: a reference built for another schema version is never used).

**The seed-1006 replays (founder, 2026-10-23): the failure did not reproduce.** The same cut (OS crash held at `client:after_mark` #1), 5 times in each setup, each replay in its own fresh VM folder:

| Setup | Replays | Acknowledged / on the server (each) | Store refused or a violation |
|---|---|---|---|
| truncate / slots + background check (fix 4): attempt 3's setup | 5 | 65 / 65 | **0 of 5** |
| truncate / slots, no background check | 5 | 65 / 65 | 0 of 5 |
| delete / file + background check (fix 4) | 5 | 65 / 65 | 0 of 5 |
| delete / file, no background check (the phase 0–3 design) | 5 | 65 / 65 | 0 of 5 |

- **Try 1 of the replays (kept):** r1 of the first setup passed; r2 was **invalid** — every replay used the same seed, so the same test key and the same VM folder, and r2 started on r1's leftover store (`UNIQUE constraint failed: bills.action_id` on its first sale). The run was stopped; try 2 gives every replay its own folder and refuses a folder that already exists.
- **Reading:** the failure is not deterministic at this cut. With attempt 3's own cut, its setup has failed once in 6 tries (attempt 3 plus 5 replays). Today's design has 0 failures in 15 OS crashes (S104 run 1's 10 and these 5), but without the background check in run 1. **The cause is not known.**
- **Sources (2026-10-23):** SQLite's atomic-commit document (§7.6) says truncate mode "is not followed by a system call (ex: fsync()) to synchronize the change to disk. It might be safer if it did", and suggests another journaling mode when a database must survive an operating-system crash during the truncation. SQLite assumes sector writes are not atomic (§2). SQLite3MC authenticates every page as a whole ("A single corrupted byte at the beginning of an encrypted database page will usually make the whole page content unusable", issue #86), so a torn page 1 makes the whole file unopenable where a plain page would stay partly readable. Microsoft's `FlushFileBuffers` page does not say whether a file's size change is made durable (not sourceable there); the NTFS overview promises file-system consistency after a crash, not file contents.
- **Status:** truncate / slots stays **not adopted** (founder) until the cause is known; the rush and every-5-s legs, `/full` and the throttled boot watches have not run.
