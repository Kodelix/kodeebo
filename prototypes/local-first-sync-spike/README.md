<!-- PROTOTYPE - NOT FOR PRODUCTION -->
<!-- Question: Does local-first sync ever lose or double-count money or session time under faults? (phase 0: can the harness detect it?) -->
<!-- Date: 2026-10-16 -->

# Prototype: local-first sync spike

**Status:** in-progress — phase 0 gate PASS; phase 1 gate PASS on run 2 after the OQ28 fix (run 1 failed: WAL silent loss P1-F1); phase 2 next
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
| 3 | Compound faults, reordering, partial batch, restored backup, cloned disk, re-bootstrap; tamper TS-01, TS-02, TS-03b, TS-06a, TS-07a, TS-09, TS-10 | 0 violations; ≥ 3,000 runs (30,000 stretch) |
| 4 | Windows 10/11 durability and tamper legs | per § 9.1 / § 9.1.1 |
| 5 | Day-close totals and tampered clocks | per § 9.1 |

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

`selftest` starts a throwaway `postgres:18.6` container on `127.0.0.1:56432`, builds the server and runs the correct stub and each mutant. `replay` re-runs one seed and prints its trace. `stop` removes the container. Run output goes to `runs/`, which is not committed.

## Shortcuts taken

- **Deferred to later phases:** encryption (phase 1); network faults and Toxiproxy (phase 2); concurrent retry and reordering (phase 2–3); Windows (phase 4); real billing and clock rules (phase 5).
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

**Conditions:** phase 1 on harness `7309208` plus uncommitted phase 1 changes, on the same host as phase 0, with the encrypted store on NVMe. Kill-matrix speed was about 0.35 s per run, indicative only.

**Conditions (phase 0):** harness commit `72bebbe` for run 3 (`11ace09+dirty` for runs 1–2), seeds 1–300 for the correct stub and seeds 1 to the catching seed for each mutant, one fault per run, 8 actions per run, and a single tenant and device.
