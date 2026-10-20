#!/usr/bin/env bash
PGPW=${PGPW:-$(openssl rand -hex 12)}; export PGPW  # per-run throwaway password; literal removed after the run (2026-10-21, see docs/research/evidence/jobs-and-outbox/README.md)
# S31b runner: case (a) Db2, then case (b) App2 runs Rb1-Rb3 with a real blocking JDBC statement. Fresh throwaway postgres:18.6
# (--pull=never), S30 setup.sql, loopback port 55432. No downloads. Usage: bash run_s31b.sh > output.txt 2>&1
set -u
ROOT=/home/kiko/saas-products/kodeebo
HERE="$ROOT/docs/research/evidence/jobs-and-outbox/part-3/S31b"
S30="$ROOT/docs/research/evidence/jobs-and-outbox/part-3/S30-sql-level"
C="$ROOT/production/session-state/cache/jobs-and-outbox/part-3"
CP=$(cat "$C/runtime-classpath-s31b.txt")
export PGPORT_S31=52149
N=jo3-pg31b
A=aaaaaaaa-0000-4000-8000-000000000001; B=aaaaaaaa-0000-4000-8000-000000000002; Cn=aaaaaaaa-0000-4000-8000-000000000003
now_ms() { date +%s%3N; }
pq() { docker exec -i -e PGPASSWORD=$PGPW $N psql -h 127.0.0.1 -U "$1" -d postgres -X -At -v ON_ERROR_STOP=0 2>&1; }
docker rm -f $N >/dev/null 2>&1
docker run --pull=never -d --name $N -p 127.0.0.1:$PGPORT_S31:5432 -e POSTGRES_PASSWORD=$PGPW postgres:18.6 >/dev/null || { echo "docker run failed"; exit 1; }
for i in $(seq 1 60); do docker exec $N pg_isready -h 127.0.0.1 -U postgres >/dev/null 2>&1 && break; sleep 1; done; sleep 2
docker exec -i -e PGPASSWORD=$PGPW $N psql -h 127.0.0.1 -U postgres -d postgres -X -At -v ON_ERROR_STOP=1 -v pgpw="$PGPW" < "$S30/setup.sql" >/dev/null
docker exec -i -e PGPASSWORD=$PGPW $N psql -h 127.0.0.1 -U postgres -d postgres -X -At -v ON_ERROR_STOP=1 >/dev/null <<SQL
insert into app.tenant_status values ('$A','active'),('$B','active'),('$Cn','suspended');
insert into app.outbox (tenant_id, kind, ref) select '$A','order.created', gen_random_uuid() from generate_series(1,10);
insert into app.outbox (tenant_id, kind, ref) select '$B','order.created', gen_random_uuid() from generate_series(1,3);
SQL
claimable() { pq job_rt <<SQL | grep -c 'claimed'
begin;
select set_config('app.tenant_id','$A',true) is not null;
select 'claimed ' || id from (select id from app.outbox where processed_at is null order by id for update skip locked limit 100) s;
commit;
SQL
}
echo "### S31b start $(date -u +%FT%TZ); $(docker exec -e PGPASSWORD=$PGPW $N psql -h 127.0.0.1 -U postgres -At -c 'select version()' | cut -c1-40); java: $(java -version 2>&1 | head -1)"

echo; echo "### (a) Db2: attempt count vs transaction_timeout=500ms, body = claim + pg_sleep(3), counter outside the DB"
timeout 120 java -cp "$CP" Db2 2>&1 | grep -v "^SLF4J\|^\[main\] INFO\|^\s*at \|^Caused by\|^\s*\.\.\. [0-9]* more"
echo "### Db2 exit=${PIPESTATUS[0]}"

run_pg() {
  local name=$1; shift
  echo; echo "### (b) $name: $*"
  env "$@" PGPORT_S31=$PGPORT_S31 java -cp "$CP" App2 > "$HERE/app-$name.txt" 2>&1 &
  local pid=$!
  for i in $(seq 1 200); do grep -q "loop: claimed" "$HERE/app-$name.txt" && break; sleep 0.1; done
  sleep 0.5
  echo "before SIGTERM: claimable rows (expect 8): $(claimable); job backends: $(echo "select state || '/' || coalesce(wait_event,'-') from pg_stat_activity where application_name='s31b-app-job' and state <> 'idle';" | pq postgres | tr '\n' ' ')"
  local k0; k0=$(now_ms); kill -TERM $pid
  for i in $(seq 1 600); do kill -0 $pid 2>/dev/null || break; sleep 0.1; done
  if kill -0 $pid 2>/dev/null; then echo "JVM STILL RUNNING 60 s after SIGTERM; sending KILL"; kill -9 $pid; fi
  echo "JVM exited $(( $(now_ms) - k0 )) ms after SIGTERM"; wait $pid 2>/dev/null; echo "exit code: $?"
  echo "row state after JVM exit, sampled each ~1 s (ms since SIGTERM | claimable rows of 10 | job backends not idle):"
  for i in $(seq 1 30); do
    n=$(claimable); b=$(echo "select count(*) from pg_stat_activity where application_name='s31b-app-job' and state <> 'idle';" | pq postgres)
    echo "  $(( $(now_ms) - k0 )) ms | $n | $b"
    [ "$n" -ge 10 ] && [ "$b" = 0 ] && break
    sleep 1
  done
  grep -E "^\[\+|ERROR|TimeoutCancellation" "$HERE/app-$name.txt" | cut -c1-230 | head -30
}
run_pg Rb1-pg12s-runnerstop2s-shutdown2s WORK_SEC=12 GRACE_MS=500 TIMEOUT_MS=2000 RUNNER_STOP_MS=2000
CCCI_MS=1000 run_pg Rb2-pg12s-runnerstop2s-shutdown2s-ccci1000 WORK_SEC=12 GRACE_MS=500 TIMEOUT_MS=2000 RUNNER_STOP_MS=2000
run_pg Rb3-pg4s-runnerstop6s-shutdown8s WORK_SEC=4 GRACE_MS=500 TIMEOUT_MS=8000 RUNNER_STOP_MS=6000

echo; echo "### done $(date -u +%FT%TZ)"
docker rm -f $N >/dev/null 2>&1
