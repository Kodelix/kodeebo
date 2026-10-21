#!/usr/bin/env bash
PGPW=${PGPW:-$(openssl rand -hex 12)}; export PGPW  # per-run throwaway password, no literal
# S31c runner: Rc1-Rc3. Fresh throwaway postgres:18.6 (--pull=never), S30 setup.sql, free loopback ports. No downloads.
# For each case: start the JVM, wait for the claim, SIGTERM it mid-statement, sample row state every ~250 ms from the signal until the
# rows are claimable again (or 20 s). Server-side time of the transaction-timeout kill comes from `docker logs --timestamps`.
# Usage: bash run_s31c.sh > output.txt 2>&1
set -u
ROOT=/home/kiko/saas-products/kodeebo
HERE="$ROOT/docs/research/evidence/jobs-and-outbox/part-3/S31c"
S30="$ROOT/docs/research/evidence/jobs-and-outbox/part-3/S30-sql-level"
C="$ROOT/production/session-state/cache/jobs-and-outbox/part-3"
CP=$(cat "$C/runtime-classpath-s31c.txt")
freeport() { python3 -I -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1])'; }
export PGPORT_S31=$(freeport); export KPORT=$(freeport)
N=jo3-pg31c
A=aaaaaaaa-0000-4000-8000-000000000001; B=aaaaaaaa-0000-4000-8000-000000000002; Cn=aaaaaaaa-0000-4000-8000-000000000003
now_ms() { date +%s%3N; }
pq() { docker exec -i -e PGPASSWORD=$PGPW $N psql -h 127.0.0.1 -U "$1" -d postgres -X -At -v ON_ERROR_STOP=0 2>&1; }
seed() {
  docker rm -f $N >/dev/null 2>&1
  docker run --pull=never -d --name $N -p 127.0.0.1:$PGPORT_S31:5432 -e POSTGRES_PASSWORD=$PGPW postgres:18.6 >/dev/null || { echo "docker run failed"; exit 1; }
  for i in $(seq 1 60); do docker exec $N pg_isready -h 127.0.0.1 -U postgres >/dev/null 2>&1 && break; sleep 1; done; sleep 2
  docker exec -i -e PGPASSWORD=$PGPW $N psql -h 127.0.0.1 -U postgres -d postgres -X -At -v ON_ERROR_STOP=1 -v pgpw="$PGPW" < "$S30/setup.sql" >/dev/null
  docker exec -i -e PGPASSWORD=$PGPW $N psql -h 127.0.0.1 -U postgres -d postgres -X -At -v ON_ERROR_STOP=1 >/dev/null <<SQL
insert into app.tenant_status values ('$A','active'),('$B','active'),('$Cn','suspended');
insert into app.outbox (tenant_id, kind, ref) select '$A','order.created', gen_random_uuid() from generate_series(1,10);
insert into app.outbox (tenant_id, kind, ref) select '$B','order.created', gen_random_uuid() from generate_series(1,3);
SQL
}
claimable() { pq job_rt <<SQL | grep -c 'claimed'
begin;
select set_config('app.tenant_id','$A',true) is not null;
select 'claimed ' || id from (select id from app.outbox where processed_at is null order by id for update skip locked limit 100) s;
commit;
SQL
}
echo "### S31c start $(date -u +%FT%TZ); $(docker run --pull=never --rm --entrypoint postgres postgres:18.6 --version); java: $(java -version 2>&1 | head -1)"

run_case() {
  local name=$1; shift
  echo; echo "### $name: $*"
  seed
  env "$@" java -cp "$CP" App3 > "$HERE/app-$name.txt" 2>&1 &
  local pid=$!
  for i in $(seq 1 200); do grep -q "loop: body run #1" "$HERE/app-$name.txt" && break; sleep 0.1; done
  sleep 0.5
  echo "before SIGTERM: claimable rows (expect 8): $(claimable); job backends: $(echo "select state || '/' || coalesce(wait_event,'-') from pg_stat_activity where application_name='s31c-app-job' and state <> 'idle';" | pq postgres | tr '\n' ' ')"
  local k0; k0=$(now_ms)
  kill -TERM $pid; echo "SIGTERM sent at epoch_ms=$k0"
  # sampler runs in the foreground while the JVM stops; it also records JVM liveness
  local exited=""; local rows=0 b=1
  for i in $(seq 1 80); do
    rows=$(claimable); b=$(echo "select count(*) from pg_stat_activity where application_name='s31c-app-job' and state <> 'idle';" | pq postgres)
    alive=$(kill -0 $pid 2>/dev/null && echo alive || echo gone)
    [ "$alive" = gone ] && [ -z "$exited" ] && exited=$(( $(now_ms) - k0 ))
    echo "  +$(( $(now_ms) - k0 )) ms | claimable=$rows/10 | job backends not idle=$b | jvm=$alive"
    [ "$rows" -ge 10 ] && [ "$b" = 0 ] && [ "$alive" = gone ] && break
    sleep 0.15
  done
  if kill -0 $pid 2>/dev/null; then echo "JVM STILL RUNNING after sampling; sending KILL"; kill -9 $pid; fi
  wait $pid 2>/dev/null; echo "exit code: $?  (first sample that saw the JVM gone: +${exited:-n/a} ms; coarse, sampler period includes docker exec)"
  echo "-- server log lines for the timeout (docker timestamps, UTC) and JVM epoch for comparison:"
  docker logs --timestamps $N 2>&1 | grep -i "transaction timeout" | head -3
  echo "-- JVM log (epoch in @ms; SIGTERM epoch above):"
  grep -E "^\[\+" "$HERE/app-$name.txt" | cut -c1-260
}
run_case Rc1-tx1500-stop3000-shutdown4000 WORK_SEC=12 TX_TIMEOUT_MS=1500 RUNNER_STOP_MS=3000 TIMEOUT_MS=4000 GRACE_MS=500 PGPORT_S31=$PGPORT_S31 KPORT=$KPORT
run_case Rc2-tx2500-stop3000-shutdown4000 WORK_SEC=12 TX_TIMEOUT_MS=2500 RUNNER_STOP_MS=3000 TIMEOUT_MS=4000 GRACE_MS=500 PGPORT_S31=$PGPORT_S31 KPORT=$KPORT
run_case Rc3-control-tx6000-stop3000-shutdown4000 WORK_SEC=12 TX_TIMEOUT_MS=6000 RUNNER_STOP_MS=3000 TIMEOUT_MS=4000 GRACE_MS=500 PGPORT_S31=$PGPORT_S31 KPORT=$KPORT

echo; echo "### done $(date -u +%FT%TZ)"
docker rm -f $N >/dev/null 2>&1
