# S42: stock movements written with the bill line, on the counter reference VM

> PROTOTYPE - NOT FOR PRODUCTION. Throwaway (`.claude/rules/prototype-code.md`); nothing here is imported by production code.

**Status:** concluded 2026-10-22 — **FAIL** (see Findings). Run 05:08–06:23 on HEAD `9af8a89` (`+dirty` = this folder's own untracked files), VM reverted to `clean-ssh2` and shut off at the end.

## Hypothesis

ADR-0014 (item model) records a sale's stock movements in the same local transaction as its bill line, from the device's flattened recipe copy (research `docs/research/catalogue-and-item-model.md`, part 4 C1, Q12 / S42). This holds only if that transaction stays inside the counter budget on the 4 GB HDD-class reference profile: **p95 ≤ 200 ms and max ≤ 1 s** ("Start session, add item", `docs/architecture/perf-budgets.md`), under the founder's 3 s ceiling. A void, which copies the stored movements with the sign flipped, must meet the same budget.

Pass per cell (kind × N): p95 ≤ 200 ms and no operation over 1,000 ms (`over_1s` = 0 in the summary). Correction, 2026-10-22: the script's field `pass_p95_200_max_3000` was written against the 3 s ceiling before the budget row was re-read; the verdict uses `p95_ms` and `over_1s`, and `over_3s` is reported for the ceiling. The cost of the movements is read as the p95 over N = 0 (bill line and outbox row only).

## What runs

- **Where:** the shared Windows 10 VM `kodeebo-win10`, snapshot `clean-ssh2`, disk throttle 100 IOPS + 80 MiB/s (the same steps as the sync spike's `harness/p4.sh`, read only). Founder, 2026-10-22: the VM is free for S42. `clean-ssh2` is restored at the end of every run (EXIT trap).
- **Runtime:** Python 3.14.8 embeddable + `apsw-sqlite3mc` 3.54.0.0 (SQLite 3.54.0), copied from `prototypes/local-first-sync-spike/tools/win-python-3.14.8/` (read only; nothing downloaded). This is the sync spike's stand-in, not the product runtime: the desktop runtime ADR picks the counter's engine.
- **Store:** the sync client's settings (SQLite3MC chacha20 with a per-run raw test key that is never saved, `journal_mode=DELETE`, `synchronous=FULL`, `temp_store=MEMORY`) plus STRICT tables and `foreign_keys=ON` (S41, S52).
- **History:** 50,000 past sale lines (about 300,000 movements) written first, then the store is reopened.
- **Timed run:** N = 0, 1, 5, 10, 20, 40 movements per sale; 400 sales per N in shuffled blocks (each block has every N once, seed 42); one void block (one void per N) after every fourth sale block, 100 voids per N; 1 s between operations. A timed operation is `BEGIN IMMEDIATE` → read the flattened recipe → insert the bill line, N movements and one outbox command → `COMMIT`.
- **Checks after the run:** every sale line has exactly N movements; every void nets its line to zero; `quick_check` before and after.

## How to run

```bash
systemd-run --user --unit=s42-catalogue --working-directory="$PWD/prototypes/catalogue-movement-spike" bash s42.sh
```

Progress: `runs/s42.status` (one line per step, `DONE` at the end), `runs/s42.log`. Results: `runs/s42-summary.json`, `runs/s42-results.csv`, `runs/s42-run.out`.

## Findings

Python 3.14.8, apsw 3.54.0.0, SQLite 3.54.0 (SQLite3MC), chacha20, `journal_mode=DELETE`, `synchronous=FULL`, STRICT, `foreign_keys=ON`; 50,000 history lines seeded in 17 s; store 29.9 MB at the end (53,000 lines, 313,358 movements); timed run 4,189 s. Invariants: 0 sales with a wrong movement count, 0 voids not netting to zero; `quick_check` ok before and after. First operation after reopening: 360 ms. Times in ms; source `runs/s42-summary.json`, raw `runs/s42-results.csv`.

| Kind | N | Count | p50 | p95 | p99 | Max | > 1 s | > 3 s | p95 over N = 0 |
|---|---|---|---|---|---|---|---|---|---|
| sale | 0 | 400 | 57.9 | 498.4 | 710.3 | 3,586.4 | 3 | 1 | — |
| sale | 1 | 400 | 96.6 | 538.8 | 671.7 | 1,490.1 | 3 | 0 | +40.3 |
| sale | 5 | 400 | 149.4 | 711.2 | 1,329.7 | 2,674.2 | 7 | 0 | +212.7 |
| sale | 10 | 400 | 239.1 | 902.1 | 1,458.5 | 1,864.5 | 16 | 0 | +403.7 |
| sale | 20 | 400 | 318.2 | 950.6 | 1,453.2 | 12,639.6 | 14 | 4 | +452.2 |
| sale | 40 | 400 | 519.6 | 1,260.7 | 2,711.0 | 5,627.8 | 86 | 4 | +762.3 |
| void | 0 | 100 | 57.4 | 549.2 | 816.3 | 1,411.5 | 1 | 0 | — |
| void | 1 | 100 | 106.5 | 637.7 | 788.4 | 2,604.4 | 1 | 0 | +88.5 |
| void | 5 | 100 | 158.8 | 732.5 | 1,063.0 | 1,699.1 | 2 | 0 | +183.4 |
| void | 10 | 100 | 226.6 | 1,067.2 | 1,703.9 | 8,808.5 | 6 | 1 | +518.1 |
| void | 20 | 100 | 337.5 | 1,099.9 | 2,854.7 | 3,330.4 | 7 | 1 | +550.7 |
| void | 40 | 100 | 535.5 | 2,108.7 | 3,324.2 | 11,266.9 | 26 | 3 | +1,559.6 |

- **S42-F1 — FAIL in every cell, including N = 0.** No cell meets p95 ≤ 200 ms and max ≤ 1 s. A sale with no movements (bill line + outbox row) already has p95 498 ms and one 3.6 s operation: the store and disk configuration fails the budget before any movement is written. This matches the sync spike's open phase 4 findings on the same VM (no journal variant met commit p95 ≤ 150 ms; S309b broke the 3 s ceiling twice; `prototypes/local-first-sync-spike/README.md`).
- **S42-F2 — movements add cost on top.** p95 grows by about +40 ms (N = 1), +213 ms (N = 5), +404 ms (N = 10), +762 ms (N = 40); p50 grows from 58 ms to 520 ms. Voids grow faster at N = 40 (+1.56 s p95). Outliers up to 12.6 s (sale, N = 20) and 11.3 s (void, N = 40) cross the 3 s ceiling.
- **S42-F3 — not measured here:** the `truncate` journal and slot variant the sync spike proposes for S104, a WAL store, writing movements in a separate transaction off the cashier's path, and a native runtime instead of Python. Python overhead is included in every number.
