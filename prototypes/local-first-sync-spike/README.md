<!-- PROTOTYPE - NOT FOR PRODUCTION -->
<!-- Question: Does local-first sync ever lose or double-count money or session time under faults? (phase 0: can the harness detect it?) -->
<!-- Date: 2026-10-16 -->

# Prototype: local-first sync spike

**Status:** in-progress — phase 0 gate PASS; phase 1 gate PASS on run 2 after the OQ28 fix (run 1 failed: WAL silent loss P1-F1); phase 2 gate PASS (run 2 on committed harness `be3f49e`: 50 seeds per cell, 3,000 campaign runs, 0 violations); phase 3 in progress — SC-19 (server restore) PASS on committed harness `a65d6f8`; SC-20 (disk full) PASS on committed harness `daac687`; SC-21a (app update) next
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

`selftest` starts a throwaway `postgres:18.6` container on `127.0.0.1:56432`, builds the server and runs the correct stub and each mutant. `replay` re-runs one seed and prints its trace. `stop` removes the container. Run output goes to `runs/`, which is not committed.

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
