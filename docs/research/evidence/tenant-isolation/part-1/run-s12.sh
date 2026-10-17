#!/usr/bin/env bash
# S12: transaction-local tenant context behind PgBouncer in transaction pool mode with pool size 1.
# Needs: container ti-p1-pg running with database s10 from run-s10.sh (tables orders etc., role app_rt).
# PgBouncer is run from a third-party image (edoburu/pgbouncer, digest recorded in the output); test tool only, not a pin.
# usage: bash run-s12.sh [conf-dir]   (conf-dir must be outside docs/ for the ini; default /tmp is NOT used - see caller)
set -u
CONF="${1:?conf dir}"
BPORT=57434
PGHOST=127.0.0.1; PGPORT=57433
A=11111111-1111-4111-8111-111111111111; B=22222222-2222-4222-8222-222222222222
cli() { docker run --rm --network host -e PGPASSWORD=ti_p1_app postgres:18.6 psql -h 127.0.0.1 -p "$BPORT" -U app_rt -d s10 -X -q -t -A "$@"; }
docker exec -i ti-p1-pg psql -U postgres -X -q -c "alter role app_rt password 'ti_p1_app'" >/dev/null
# pg_hba of the image uses scram for TCP; PgBouncer logs in to the server as app_rt with the password below, clients use trust.
mkdir -p "$CONF"
cat > "$CONF/pgbouncer.ini" <<EOF
[databases]
s10 = host=$PGHOST port=$PGPORT dbname=s10 user=app_rt password=ti_p1_app
[pgbouncer]
listen_addr = 127.0.0.1
listen_port = $BPORT
auth_type = trust
auth_file = /etc/pgbouncer/userlist.txt
pool_mode = transaction
default_pool_size = 1
max_client_conn = 20
ignore_startup_parameters = extra_float_digits
unix_socket_dir =
logfile = /tmp/pgbouncer.log
pidfile = /tmp/pgbouncer.pid
EOF
printf "\"app_rt\" \"ti_p1_app\"\n" > "$CONF/userlist.txt"
chmod 644 "$CONF/pgbouncer.ini" "$CONF/userlist.txt"
echo "== S12 start $(date -u +%FT%TZ)"
docker image inspect edoburu/pgbouncer:latest --format 'image {{.RepoDigests}} created {{.Created}}'
docker rm -f ti-p1-pgb >/dev/null 2>&1
docker run -d --name ti-p1-pgb --network host --entrypoint pgbouncer -v "$CONF":/etc/pgbouncer:ro edoburu/pgbouncer:latest /etc/pgbouncer/pgbouncer.ini >/dev/null
sleep 2
docker logs ti-p1-pgb 2>&1 | head -5
echo "-- version via SHOW VERSION (admin console not enabled); binary version:"
docker run --rm --entrypoint pgbouncer edoburu/pgbouncer:latest --version | head -2

echo "-- T1: tx-local context, then a NEW client on the (single) server connection with no context"
cli -c "select 'client1 backend pid ' || pg_backend_pid()" -c "begin; select set_config('app.tenant_id','$A',true); select 'client1 sees ' || count(*) from orders; commit;"
cli -c "select 'client2 backend pid ' || pg_backend_pid()" -c "select 'client2 setting after client1 tx = [' || coalesce(current_setting('app.tenant_id',true),'<NULL>') || ']'" -c "select 'client2 sees (no context) ' || count(*) from orders"

echo "-- T2: UNSAFE session-level SET (is_local=false) in client 1, then client 3 on the same server connection"
cli -c "select set_config('app.tenant_id','$A',false)" -c "select 'client1 sees ' || count(*) from orders"
cli -c "select 'client3 backend pid ' || pg_backend_pid()" -c "select 'client3 setting = [' || coalesce(current_setting('app.tenant_id',true),'<NULL>') || ']'" -c "select 'client3 sees (never set a context) ' || count(*) from orders"
echo "-- T2b: SET (statement) at session level behaves the same way?"
cli -c "set app.tenant_id = '$B'" -c "select 'client1 sees ' || count(*) from orders"
cli -c "select 'client4 setting = [' || coalesce(current_setting('app.tenant_id',true),'<NULL>') || ']'" -c "select 'client4 sees ' || count(*) from orders"

echo "-- T3: two concurrent clients, different tenants, pool size 1 (they must serialise; each must see only its tenant)"
( cli -c "begin; select set_config('app.tenant_id','$A',true); select pg_sleep(2); select 'tenantA client sees ' || count(*) from orders; commit;" ) &
sleep 0.5
( cli -c "begin; select set_config('app.tenant_id','$B',true); select 'tenantB client sees ' || count(*) from orders; commit;" ) &
wait

echo "-- T4: SET LOCAL (statement form) inside a transaction"
cli -c "begin; set local app.tenant_id = '$A'; select 'SET LOCAL client sees ' || count(*) from orders; commit;" -c "select 'after commit, no context sees ' || count(*) from orders"

echo "-- T5: multi-statement protocol: set_config and query in two separate simple-query round trips WITHOUT an explicit transaction (autocommit) - context must NOT survive"
cli -c "select set_config('app.tenant_id','$A',true)" -c "select 'autocommit second statement sees ' || count(*) from orders"
echo "-- PgBouncer log tail"
docker logs ti-p1-pgb 2>&1 | tail -5
docker rm -f ti-p1-pgb >/dev/null
echo "== S12 end $(date -u +%FT%TZ)"
