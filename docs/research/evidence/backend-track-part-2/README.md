# Evidence for docs/research/backend-track.part-2-data-jobs.md (tier E)

Run on 2026-10-18, host Linux, Go 1.27.2, OpenJDK 21.0.12.1, Docker 29.9.1, `postgres:18.6` (Debian 18.6-1.pgdg13+2). Throwaway containers and passwords, no real data.
Caches and fetched jars are under `production/session-state/cache/backend-track/part-2/` (gitignored; delete at merge).

| Dir | What | Status |
|---|---|---|
| `S20-go-pgx/` | pgx 5.11.0: ADR-0002 helper, SECURITY DEFINER calls, `transaction_timeout`, streaming COPY TO STDOUT under RLS, outbox claim per tenant, idempotent consumer. `setup.sql` and `seed.sql` are shared by S22. | complete, all 10 tests pass. The first-ever run downloaded the Go toolchain into the module cache (374 MB, see F209). |
| `S21-versions-osv/` | Go proxy and Maven Central metadata, OSV queries, fetch of three small jars (1.5 MB). | complete |
| `S22-jdbc-hikari/` | HikariCP 7.1.0 + pgjdbc 42.7.14 at JDBC level (not Exposed). | **ABORTED RUN, kept as is.** Results J0 to J5a printed; after J4c (writer error mid-COPY) the next statements on the pool failed, J5b waited for a worker that had failed, the script hit its 400 s `timeout` (exit 124) and the JVM and container were killed by hand afterwards. `output.txt` therefore has no `### done` line. J5b and J5c (JDBC outbox claim and sweep) did not run: PENDING - S22b. The failure after J4c may be a defect of the spike (no eviction of the connection after the copy error) as well as of the driver stack; see F213. |
