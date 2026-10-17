<!-- PROTOTYPE - NOT FOR PRODUCTION -->
<!-- Question: Can A (Compose Desktop), B (Electron) or C (Tauri 2) do the counter's duties on the 4 GB reference VM? -->
<!-- Date: 2026-10-16 -->

# One app, three runtimes: what every spike app must do

A, B and C implement **exactly this**, so their numbers compare. Anything a runtime cannot do is recorded, not worked around silently.

## Identity

| | A | B | C |
|---|---|---|---|
| Runtime | Compose Multiplatform Desktop 1.12.2, Kotlin 2.4.21, JDK 21 (jlink runtime) | Electron 44.8.0 | Tauri 2.12.x |
| `<rt>` | `a` | `b` | `c` |
| Product name | `KodeeboSpikeA` | `KodeeboSpikeB` | `KodeeboSpikeC` |
| Installer | per-user MSI (jpackage) | per-user (NSIS or the tool's per-user target) | per-user NSIS |

Data folder: `%LOCALAPPDATA%\KodeeboSpike\<rt>\` (created on first run).

## Modes (command-line argument)

| Mode | What it does | Output |
|---|---|---|
| *(none)* — GUI | A window "Kodeebo spike <RT>" with a 200-row list ("Station N — 0:MM — EGP X.00", Latin text only in round 1) and a **Close bill** button. When the **first frame is painted**, append one line to `ready.txt` | `ready.txt`: `pid=<pid> proc_start_ms=<epoch ms from the OS> first_frame_ms=<epoch ms>` |
| `--close-bench N` | No window. Runs N "close bill" operations back to back, each = one DB transaction + one RAW print (below); times each with a monotonic clock | `bench-<epoch>.txt`: one line per run `i db_ms print_ms total_ms`, then `max`, `p95`, `p50` |
| `--close-bench N --warmup` | Same, but first runs the **warm-up** (below) and records its time; the N timed runs start after it | as above, plus a first line `warmup_ms=<ms> parts=<open_store,load_print,dummy_tx ms>` |
| `--print-once` | No window. One RAW print of the golden receipt | exit 0 on success, non-zero otherwise; one line appended to `print.txt`: `ok` or the error |
| `--kill-loop` | No window. Repeats the DB transaction forever (no print); after every commit it overwrites `killloop.txt` with the running count | killed from outside (`taskkill /F`) |
| `--check` | Opens the store, runs `PRAGMA integrity_check` and the consistency checks | one line appended to `check.txt`: `integrity=<ok or text> bills=<n> lines=<n> payments=<n> outbox=<n> consistent=<true/false>` (or `open-failed: <error>`) |

**All output goes to files in the data folder, never stdout:** the packaged apps are GUI-subsystem programs with no console (A's jlink runtime has no `java.exe`; Electron and Tauri release builds have no console either).

## The store (same in all three)

- SQLite with **SQLite3 Multiple Ciphers**, default cipher of the binding. The raw 32-byte key is applied **by the binding while it opens the connection**, through the binding's documented key API (A: `SQLiteMCConfig.Builder().withHexKey(bytes)`), never as a later statement: a `PRAGMA hexkey` sent after the driver's own open steps works only on a new file (finding A-F1). Then **verify with a read** (`SELECT count(*) FROM sqlite_master`), because SQLite3MC accepts a wrong key silently (research F110).
- Headless modes catch every error, append it to `error.txt` and exit 1 (A-F2: an uncaught exception makes A's launcher block on a dialog).
- Key: 32 random bytes in `key.bin` beside `store.db` (shortcut: no DPAPI/TPM in round 1).
- `PRAGMA journal_mode=DELETE` (rollback journal, as the sync spike decided), `PRAGMA synchronous=FULL`, `PRAGMA temp_store=MEMORY`.
- Schema: `bill(id INTEGER PRIMARY KEY, opened_ms, closed_ms, total_piastres)`, `bill_line(id, bill_id, name, qty, price_piastres)`, `payment(id, bill_id, method, amount_piastres)`, `outbox(seq INTEGER PRIMARY KEY, bill_id, payload)`.
- **One "close bill" transaction** = `BEGIN IMMEDIATE`; insert 1 bill, 5 lines, 1 payment, 1 outbox row; `COMMIT`.
- **Consistent** = every bill has exactly 5 lines, 1 payment and 1 outbox row, and `total_piastres` equals the sum of its lines.

## Warm-up (founder, 2026-10-17)

Before the counter screen would appear: (1) open the store (key applied, verified); (2) load the print path: whatever native library the binding needs, then `OpenPrinterW("KSPIKE-SINK")` + `ClosePrinter` (no job); (3) one dummy transaction: `BEGIN IMMEDIATE`, insert one row into the bill table, `ROLLBACK`. The warm-up time belongs to the **start-up budget**; the question is whether the first sale after it stays under the 3 s ceiling after a reboot.

## First-print instrumentation (founder, 2026-10-17)

Every bench appends one line per run for **runs 1 to 3** to `phases-<epoch>.txt`: the time of each step of the close (`db`, `load_native` (first use only), `open_printer`, `start_doc`, `write`, `end_doc`, `close_printer`) and the **process's own read and write bytes** before and after (Win32 `GetProcessIoCounters`). Read bytes ÷ the throttle's measured sequential rate (~12 MiB/s, G0-F2) gives the share of a slow first sale that is sequential reading.

## The print (same in all three)

- Bytes: the research golden stream `docs/research/evidence/desktop-client-technology/p3-out/receipt_80mm_test_576dots.escpos.bin` (20,250 bytes), shipped next to the app as `receipt.bin`, sent unchanged.
- Path: Win32 `OpenPrinterW("KSPIKE-SINK")` → `StartDocPrinterW` (datatype `RAW`) → `StartPagePrinter` → `WritePrinter` (all bytes, check the count) → `EndPagePrinter` → `EndDocPrinterW` → `ClosePrinter`, off the UI thread.
- `print_ms` ends when `EndDocPrinter` returns (the job is queued); spooler delivery to the sink is checked separately by the harness.

## What is *not* in round 1

Arabic text in the UI, updates, signing, DPAPI/TPM, sync, N5, tamper legs.
