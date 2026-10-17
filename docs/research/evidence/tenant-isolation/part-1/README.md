# Evidence: tenant-isolation part 1 (spikes S10-S12)

Run 2026-10-16 ~21:56-21:59 UTC (container clock) on this host, Docker 29.9.1. Containers started by this session: `ti-p1-pg` (`postgres:18.6`, 127.0.0.1:57433, throwaway password) and `ti-p1-pgb` (PgBouncer 1.26.0 from the third-party image `edoburu/pgbouncer@sha256:9c78945868a6a142c7fc40ccd843bbe5a606df163c7ffce4de70e0d628d696a2`, host network, port 57434). Both removed afterwards. No product data, no real secrets (passwords are throwaway test values).

| Spike | Script | Output | Status |
|---|---|---|---|
| S10 RLS facts, FK/unique channels, views, catalogue queries | `run-s10.sh`, `s10-rls-reverify.sql` | `s10-output.txt` | valid |
| S11 footprint, provisioning, fan-out, dumps (N=100, T=30) | `run-s11.sh` (`bash run-s11.sh 100 30`) | `s11-output.txt` | valid except the RLS dump sub-test, which is a WRONG TEST (table names `t1..t3`, errors discarded): `s11-WRONG-TEST-note.txt` |
| S11b RLS per-tenant dump, corrected | `run-s11b.sh` | `s11b-output.txt` | valid |
| S12 run 1 PgBouncer transaction mode | `run-s12.sh` (first version) | `s12-run1-WRONG-TEST-output.txt`, `s12-conf/pgbouncer.run1-WRONG.ini`, `s12-run1-WRONG-TEST-note.txt` | wrong test: PgBouncer rejected the user (no `auth_file`); no result |
| S12 run 2 | `run-s12.sh` (current, with `auth_file`) | `s12-output.txt` | valid for T1-T3; T4/T5 are confounded by the deliberate session-level SET of T2b on the same server connection |
| S12b clean rerun | `run-s12b.sh` | `s12b-output.txt` | valid |

Commands: `bash run-s10.sh`; `bash run-s11.sh 100 30 > s11-output.txt 2>&1`; `bash run-s11b.sh > s11b-output.txt 2>&1`; `bash run-s12.sh <abs path to s12-conf> > s12-output.txt 2>&1`; `bash run-s12b.sh <abs path to s12-conf> > s12b-output.txt 2>&1`. S12 needs the database `s10` from S10.
