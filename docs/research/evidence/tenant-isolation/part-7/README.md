# Part 7 evidence (tenant-isolation operator access) — tier E

Date 2026-10-17, image `postgres:18.6` (server banner in each output file). All credentials in these files are throw-away fixtures in a throw-away container.

| File | What |
|---|---|
| `s70-setup.sql` | roles, tables, policies, hash-chain trigger, definer function (shared by both runs) |
| `s70-tests.sql`, `run-s70.sh`, `s70-output.txt` | first run; PARTLY A WRONG TEST — see `s70-WRONG-TEST-note.txt`. Also holds T7 (pg_read_all_data), T8/T8b (VALID UNTIL), T9 (REPLICATION base backup) |
| `s70-WRONG-TEST-note.txt` | which lines of the first run are confounded and which stay valid |
| `s71-tests.sql`, `run-s71.sh`, `t10.sh`, `s71-output.txt` | corrected rerun (grant lifecycle, audit rollback, hash chain, expiry inside a transaction, extension list) |

Run: `bash run-s71.sh` (needs Docker and the `postgres:18.6` image).
