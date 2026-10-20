# Evidence: jobs-and-outbox

Evidence for `docs/research/jobs-and-outbox.md`. Part 1 is `part-1/` (S10, S11), part 2 is `part-2/` (S20–S22, see its own README) and part 3 is `part-3/` (S30, S30b, S31, S31b, S32, S33). Outputs are kept as each run produced them, wrong runs included and labelled in the note.

## Scripts edited after the run (2026-10-21)

The runs used a fixed literal password for their throwaway local `postgres:18.6` containers and for the `app_rt`, `job_rt` and `platform_rt` test roles. No real credential was involved; the containers were bound to loopback and removed by the scripts. gitleaks flagged the literal at commit time, so the founder chose to remove it from every script rather than allowlist it. The only change:

- **Shell runners** (`part-1/s10-run.sh`; `part-3/S30-sql-level/run.sh`, `run2.sh`; `part-3/S31-exposed-ktor/run_all.sh`, `run_app.sh`; `part-3/S31b/run_s31b.sh`): line 2 sets `PGPW` from the environment, or generates it with `openssl rand -hex 12`, and exports it. Every use of the literal is now `$PGPW`, and the `setup.sql` callers pass it with `-v pgpw="$PGPW"`.
- **`part-3/S30-sql-level/setup.sql`**: the role passwords are `:'pgpw'` (a psql variable).
- **`part-3/S31-exposed-ktor/S31.kt`, `part-3/S31b/S31b.kt`**: the Hikari password is read from `PGPW` (the runners export it). Rebuilding needs the jars listed in the note (F320); the cache that held them was deleted after the merge.

The outputs were produced by the original scripts and are unchanged; they never printed the password. Nothing else in the scripts changed, and the scripts were not re-run after the edit (syntax-checked with `bash -n` only).
