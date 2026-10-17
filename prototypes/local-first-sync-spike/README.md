<!-- PROTOTYPE - NOT FOR PRODUCTION -->
<!-- Question: Does local-first sync ever lose or double-count money or session time under faults? (phase 0: can the harness detect it?) -->
<!-- Date: 2026-10-16 -->

# Prototype: local-first sync spike

**Status:** in-progress — phase 0 gate PASS; phase 1 gate PASS on run 2 after the OQ28 fix (run 1 failed: WAL silent loss P1-F1); phase 2 gate PASS (run 2 on committed harness `be3f49e`: 50 seeds per cell, 3,000 campaign runs, 0 violations); phase 3 in progress — SC-19 (server restore) PASS on committed harness `a65d6f8`; SC-20 (disk full) PASS on committed harness `daac687`; SC-21a (app update) PASS on committed harness `128cdea`; SC-22 (two instances) PASS on committed harness `db53f27` (tamper suite fixed in `74fac52`); SC-23 (prices while offline, widened rule 2, no-price-list refusal) PASS on committed harness `8cc8df6`; SC-25a (7-day backlog over cut windows) dev run PASS on uncommitted harness
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
| 3 | Compound faults, reordering, partial batch, restored backup, cloned disk, re-bootstrap; tamper TS-01, TS-02, TS-03b, TS-06a, TS-07a, TS-09, TS-10; added cases SC-19 (first), SC-20, SC-21a, SC-22, SC-23, SC-25a and SC-25b mechanics (table below) | 0 violations; ≥ 3,000 runs (30,000 stretch); tamper pass signals; each added case's pass signal |
| 4 | Windows 10/11 durability and tamper legs; added cases SC-21b, SC-24, SC-26, SC-27 | per § 9.1 / § 9.1.1 / § 9.1.2; measured against `docs/architecture/perf-budgets.md` (founder ceiling: no counter action over 3 s, worst case, on the 4 GB reference PC) |
| 5 | Day-close totals and tampered clocks; SC-25b with the real N5 rules | per § 9.1 / § 9.1.2 |
| PowerSync track | Does PowerSync fit (sync note Part A, S1–S4)? **Order (founder, 2026-10-17):** after the phase 3 gate passes, not in parallel. S2–S4 on Linux right after the gate; S1 on Windows inside phase 4. No adoption before counsel reads the FSL licence (sync note OQ2: the tech/IP counsel brief, drafted after the PowerSync track reports) | Part A's pass conditions |

**Phase 4 VM (founder, 2026-10-16):**
- **Baseline:** the shared Windows VM's baseline is snapshot **`clean-ssh2`**, not `clean`.
- **What it contains:** Windows 10 22H2 with no cumulative updates; Edge/WebView2 self-updated to 155; OpenSSH with key-only access (the desktop spike's dedicated key in `prototypes/desktop-client-spike/.keys/`, host key pinned); cashier auto-logon; and the 100 IOPS + 80 MiB/s disk throttle.
- **Rules:** coordinate with the desktop spike before using the VM, and restore `clean-ssh2` after each run.

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

**Finding P3-F7 — on a slow link the batch size must grow back slowly.** In the first dev attempt the client doubled its batch after every success. On the 3 KB/s uplink it went 50 → 25 → 12 → 24 → 25: each success jumped straight back to a size that timed out again, so most syncs failed. With additive increase and multiplicative decrease the batch settles at the link's capacity (11–25 commands) and the window keeps draining.

**Finding P3-F8 (harness) — after a lost reply, drain progress is on the device, not on the server cursor.** The first version of R23 measured the server cursor and flagged the slow window as stuck. It was not: it followed a cut where the server had committed a batch whose reply was lost, so its first successful batches were all `duplicate`. The device advanced and the server cursor did not. R23 now measures the device's acknowledged mark.

**Observation:** a variant of `drop_on_send` that also advanced the acknowledged mark would be healed by SC-19's reconciliation: the server, behind the device, asks for a resend from the retained bills. That is why the planted defect deletes the outbox rows without moving the mark.

**Not covered:**
- **ETA's 24-hour late-submission route:** the spike has no ETA channel.
- **Drain time on the HDD reference PC or a real venue link:** phase 4 and S105.
- **Several devices draining at once:** server load is S201.
