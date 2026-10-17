# Evidence: tenant isolation part 3 (tier E)

Date: 2026-10-17. Container `ti-p3-pg` (own, removed after the run), image `postgres:18.6` (sha256:74935e72241653ca55e0414067e6d8763aceb8a810eb51b452253ec3dcfc4336), `PostgreSQL 18.6 (Debian 18.6-1.pgdg13+2)`, bound to 127.0.0.1:56543, database `ti_p3`. No other container or file of other sessions was touched.

| File | What | Command |
|---|---|---|
| `00-setup.run1-wrong.sql`, `00-setup.run1-wrong.out` | **Wrong run (kept).** `apply_cmd` had no `SET search_path`; every call failed with `relation "inbox" does not exist` (see finding F327). | `cat 00-setup.run1-wrong.sql \| docker exec -i ti-p3-pg psql -U postgres -d ti_p3` |
| `10-tests.run1-wrong.sql`, `10-tests.run1-wrong.out` | **Wrong run (kept).** T2 to T4 therefore proved nothing; T5 contained a typo (`10**9` is not valid SQL). T5 and T6 results in this file are valid but are superseded by run 2. | same pattern |
| `00-setup.sql`, `00-setup.out` | Run 2 schema, policies, grants, `auth_device()` and `apply_cmd()`, seed (2 tenants, 3 branches, 3 devices, 2 credentials). | `cat 00-setup.sql \| docker exec -i ti-p3-pg psql -U postgres -d ti_p3` |
| `10-tests.sql`, `10-tests.out` | T1 pre-context lookup, T2 payload-vs-credential, T3 read/write matrix, T4 forged inserts and composite FK, T5 watermark, T6 fail-closed. | `cat 10-tests.sql \| docker exec -i ti-p3-pg psql -U postgres -d ti_p3` |
| `20-revoke-race.sh`, `20-revoke-race.out` | T7 revocation while a command is in flight. `bc` is not installed on the host, so the "took" figure is empty; elapsed time is read from the printed wall-clock times. | `bash 20-revoke-race.sh` |
| `30-restore-illustration.sh`, `30-restore-illustration.out` | T8 logical snapshot restore (pg_dump/pg_restore) of the same schema, showing which server-originated facts a rewound database loses. Not a PITR run. | `bash 30-restore-illustration.sh` |

What these runs do **not** show: any cryptography (signatures, TPM), the real runtime roles, a connection pool, PITR with WAL archiving, concurrency beyond two sessions, or Kotlin/Exposed behaviour. Re-run when the PostgreSQL pin changes.
