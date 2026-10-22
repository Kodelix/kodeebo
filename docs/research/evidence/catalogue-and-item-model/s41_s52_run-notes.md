# S20, S41, S52 run notes (2026-10-22)

Run by the main session on the founder's instruction (2026-10-21/22: "run S20, S41 and S52 now"). Host: Linux 7.2.9, shell zsh (the Bash tool's shell; `${pipestatus[1]}` in `s52_catalogue_inventory_fk.sh` is zsh syntax). No download: every image and binary was already on the machine.

## Environment

- **PostgreSQL:** `postgres:18.6` (`sha256:74935e72241653ca55e0414067e6d8763aceb8a810eb51b452253ec3dcfc4336`), reporting `PostgreSQL 18.6 (Debian 18.6-1.pgdg13+2) on x86_64-pc-linux-gnu`. Own throwaway container, started with
  `docker run -d --name kodeebo-catalogue-spike-pg -e POSTGRES_HOST_AUTH_METHOD=trust postgres:18.6` (no port published; reached only through `docker exec`), stopped (not removed) after the runs. The sync spike's `lfs-spike-pg` was not touched.
- **SQLite (stand-in):** host `sqlite3` 3.54.0 (2026-10-09). **These legs are a stand-in until the desktop runtime ADR fixes the counter's SQLite version and binding.**
- **Python:** 3.14.8, `python3 -I`, stdlib only (S20).

## Files and how they ran

| File | Ran as | Output | Reproduced |
|---|---|---|---|
| `s20_bundle_allocation.py` | `python3 -I -` from stdin | `s20_bundle_allocation.output.txt` | the saved file rerun on 2026-10-22: byte-identical output |
| `s41_quantities_and_cycles.sh` | six separate tool calls, in the order of the `# ---- call N` markers | `s41_quantities_and_cycles.output.txt` | not rerun (timings would differ) |
| `s41_sqlite_standin.sql` | `sqlite3 :memory: <<'SQL'` | `s41_sqlite_standin.output.txt` | the saved file rerun: byte-identical |
| `s52_catalogue_inventory_fk.sh` | three separate tool calls, in marker order | `s52_catalogue_inventory_fk.output.txt` | not rerun |
| `s52_sqlite_standin.sql` | `sqlite3 :memory: <<'SQL'` | `s52_sqlite_standin.output.txt` | the saved file rerun: byte-identical |

The `# ---- call N` lines in the `.sh` and `.output.txt` files are separators added when saving; everything between them is the command text as run and the output as returned. In the PostgreSQL outputs, trailing spaces at line ends (psql column padding) were trimmed when transcribing; no other character was changed. The SQLite legs exit with status 1 because `.bail off` lets later statements run after an expected error.

## Attempts that did not produce the saved evidence

- S41 part A ran once before with a missing `FROM movement` in the A3 queries (database `s41`); it was rerun in full as saved (database `s41a`). An attempt to drop `s41` first was refused by the permission layer.
- S41 part B: a first attempt piped the script into `bash` through `docker exec -i`, which consumed the script's own stdin and produced no output (database `s41b` may have been created empty); a second attempt through `bash -c "$(…)"` was refused by the permission layer. Part B then ran as the saved calls 2–6 in database `s41c`. The second race (B7) uses recipe ids 30/31 instead of reusing 20/21, because deleting the B6 rows was not attempted again.
- S52: one batch containing `DROP CONSTRAINT`, `DELETE` and `REVOKE` statements was refused by the permission layer before running; the saved calls 2–3 replace it with a new contrast table (`link_id_only`) and a second runtime role (`catalogue_rt`) that never had a grant. The first contrast tables (`stock_item_bad_unique`, `variant_stock_link_single`) from call 1 are unused.
- **Name clash:** the throwaway role `catalogue_rt` in S52 call 2 stands for "a Catalogue-side runtime role with no grant on Inventory's table". It is unrelated to ADR-0009's `catalogue_rt` (the role that runs the PostgreSQL system-catalogue checks C1–C8, TR-CATALOGUE-RT). Kodeebo has no per-module runtime roles; the result it shows (the foreign-key check runs with the table owner's rights, so the inserting role needs no privilege on the referenced table) holds for `app_rt` and `device_rt` alike.
- The first SQLite stand-in invocation (`sqlite3 -bail off :memory:`) failed on argument parsing before running anything.
- **`s52_sqlite_standin.sql` "E7" is a leftover label, not a test.** Its heading says "deleting a linked stock item", but the only statement after it inserts a link row (`('a', 1, 6)`); no delete ran, consistent with D5 being skipped. The ADR cites E1–E6 only.

## Not run

- **S41 query-plan leg** (EXPLAIN of the stock list under RLS): advisory only (performance gate), not run.
- **S52 D5** (delete a stock item that a link references): skipped by the founder (2026-10-22). Source instead: PostgreSQL 18 documentation, CREATE TABLE, `REFERENCES … ON DELETE` (https://www.postgresql.org/docs/18/sql-createtable.html, read 2026-10-22, page footer "PostgreSQL 18.6 Documentation", tier 1): the default referential action is `NO ACTION`, which raises an error when a deletion would leave a referencing row without its referenced row; `RESTRICT` raises an error even when the state after the action would not violate the constraint. The call-1 migration declares `ON DELETE RESTRICT` on the link's stock-item key.
