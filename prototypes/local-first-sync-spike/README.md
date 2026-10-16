<!-- PROTOTYPE - NOT FOR PRODUCTION -->
<!-- Question: Does local-first sync ever lose or double-count money or session time under faults? (phase 0: can the harness detect it?) -->
<!-- Date: 2026-10-16 -->

# Prototype: local-first sync spike

**Status:** in-progress — phase 0 gate PASS (2026-10-16); phase 1 next
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

### Phase 0 — harness and mutation self-test: gate PASS (run 2, 2026-10-16)

**Kill table** (run 2; evidence in `evidence/phase0-run2-*`):

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

**Conditions:** harness commit `11ace09+dirty` (the spike folder is not committed yet), seeds 1–300 for the correct stub and seeds 1 to the catching seed for each mutant, one fault per run, 8 actions per run, and a single tenant and device.
