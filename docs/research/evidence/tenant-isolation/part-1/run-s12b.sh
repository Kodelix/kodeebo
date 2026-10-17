#!/usr/bin/env bash
# S12b: clean re-run of the SET LOCAL / autocommit / rollback cases of S12 on a FRESH PgBouncer (fresh server connection), because
# in run 2 (s12-output.txt) tests T4 and T5 ran after the deliberately unsafe session-level SET of T2b on the same server connection,
# so their "sees 1" results were the leaked tenant-B session value, not "no context" (see the S12 note in the research file).
# Needs the conf dir written by run-s12.sh. usage: bash run-s12b.sh <conf-dir>
set -u
CONF="${1:?conf dir}"
BPORT=57434
A=11111111-1111-4111-8111-111111111111; B=22222222-2222-4222-8222-222222222222
cli() { docker run --rm --network host -e PGPASSWORD=ti_p1_app postgres:18.6 psql -h 127.0.0.1 -p "$BPORT" -U app_rt -d s10 -X -q -t -A "$@"; }
echo "== S12b start $(date -u +%FT%TZ)"
docker rm -f ti-p1-pgb >/dev/null 2>&1
docker run -d --name ti-p1-pgb --network host --entrypoint pgbouncer -v "$CONF":/etc/pgbouncer:ro edoburu/pgbouncer:latest /etc/pgbouncer/pgbouncer.ini >/dev/null
sleep 2
docker logs ti-p1-pgb 2>&1 | grep "process up"
echo "-- T0: fresh server connection: setting and visible rows with no context (expect <NULL> and 0)"
cli -c "select 'pid ' || pg_backend_pid(), 'setting=[' || coalesce(current_setting('app.tenant_id',true),'<NULL>') || ']'" -c "select 'sees ' || count(*) from orders"
echo "-- T4: SET LOCAL (statement form) in a transaction, then a following autocommit statement"
cli -c "begin; set local app.tenant_id = '$A'; select 'SET LOCAL client sees ' || count(*) from orders; commit;" -c "select 'after commit setting=[' || coalesce(current_setting('app.tenant_id',true),'<NULL>') || '] sees ' || count(*) from orders"
echo "-- T5: set_config(...,true) in autocommit (no explicit transaction), then second statement"
cli -c "select set_config('app.tenant_id','$A',true)" -c "select 'autocommit second statement setting=[' || coalesce(current_setting('app.tenant_id',true),'<NULL>') || '] sees ' || count(*) from orders"
echo "-- T6: ROLLBACK path: set_config in a rolled-back transaction, then a new client"
cli -c "begin; select set_config('app.tenant_id','$A',true); rollback;"
cli -c "select 'new client after rollback setting=[' || coalesce(current_setting('app.tenant_id',true),'<NULL>') || '] sees ' || count(*) from orders"
echo "-- T7: client disconnects in the middle of a transaction (killed psql via timeout) after set_config, then a new client"
timeout 1 docker run --rm --network host -e PGPASSWORD=ti_p1_app postgres:18.6 psql -h 127.0.0.1 -p "$BPORT" -U app_rt -d s10 -X -q -t -A -c "begin; select set_config('app.tenant_id','$A',true); select pg_sleep(5); commit;" >/dev/null 2>&1
sleep 1
cli -c "select 'new client after aborted client setting=[' || coalesce(current_setting('app.tenant_id',true),'<NULL>') || '] sees ' || count(*) from orders"
echo "-- T8: malformed context in a transaction behind the pooler (expect error 22P02), then a new client"
cli -c "begin; select set_config('app.tenant_id','not-a-uuid',true); select count(*) from orders; commit;" 2>&1 | head -3
cli -c "select 'new client after error setting=[' || coalesce(current_setting('app.tenant_id',true),'<NULL>') || '] sees ' || count(*) from orders"
docker rm -f ti-p1-pgb >/dev/null
echo "== S12b end $(date -u +%FT%TZ)"
