#!/usr/bin/env bash
PGPW=${PGPW:-$(openssl rand -hex 12)}; export PGPW  # per-run throwaway password; literal removed after the run (2026-10-21, see docs/research/evidence/jobs-and-outbox/README.md)
# S31 app-only runner (run 3): X7-X9, App runs R1-R5, on freshly seeded rows (the Db part is skipped because its sweep marks every row processed). Fresh throwaway postgres:18.6 (--pull=never), S30 setup.sql, loopback port 55431.
# JVM classes were built by build.sh. No downloads. Usage: bash run_all.sh > output.txt 2>&1
set -u
ROOT=/home/kiko/saas-products/kodeebo
HERE="$ROOT/docs/research/evidence/jobs-and-outbox/part-3/S31-exposed-ktor"
S30="$ROOT/docs/research/evidence/jobs-and-outbox/part-3/S30-sql-level"
C="$ROOT/production/session-state/cache/jobs-and-outbox/part-3"
CP=$(cat "$C/runtime-classpath.txt")
export PGPORT_S31=55431
N=jo3-pg31
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

echo "### S31 start $(date -u +%FT%TZ); java: $(java -version 2>&1 | head -1)"
seed
echo "### (Db part skipped in this script: it consumes the outbox rows, see run2 note)"

# run name, env assignments ; kills with TERM (or KILL when SIG=KILL) once the loop has claimed rows
run_app() {
  local name=$1; shift
  local sig=${SIG:-TERM}
  echo; echo "### $name: $* SIG=$sig"
  env "$@" PGPORT_S31=$PGPORT_S31 java -cp "$CP" App > "$HERE/app-$name.txt" 2>&1 &
  local pid=$! l0; l0=$(now_ms)
  for i in $(seq 1 200); do grep -q "loop: claimed" "$HERE/app-$name.txt" && break; sleep 0.1; done
  sleep 0.5
  echo "backend state before signal: $(echo "select state from pg_stat_activity where application_name='s31-app-job' and state is not null and pid <> pg_backend_pid();" | pq postgres | tr '\n' ' ') ; claimable rows now: $(claimable)"
  local k0; k0=$(now_ms)
  kill -$sig $pid
  echo "signal $sig sent at +$((k0 - l0)) ms after launch"
  if [ "$sig" = KILL ]; then
    for i in $(seq 1 100); do n=$(claimable); [ "$n" -ge 10 ] && break; sleep 0.1; done
    echo "after SIGKILL: claimable=$n after $(( $(now_ms) - k0 )) ms (poll includes docker exec overhead); jvm alive: $(kill -0 $pid 2>/dev/null && echo yes || echo no)"
    echo "backends s31-app-job after: $(echo "select count(*) from pg_stat_activity where application_name='s31-app-job';" | pq postgres)"
  else
    for i in $(seq 1 400); do kill -0 $pid 2>/dev/null || break; sleep 0.1; done
    if kill -0 $pid 2>/dev/null; then echo "JVM STILL RUNNING 40 s after SIGTERM; sending KILL"; kill -9 $pid; fi
    echo "JVM exited $(( $(now_ms) - k0 )) ms after the signal"
  fi
  wait $pid 2>/dev/null; echo "exit code: $?"
  grep -v "^SLF4J" "$HERE/app-$name.txt" | grep -E "^\[\+|loop|pool|Hikari.*(shutdown|Shutdown)|Exception|exposed" | cut -c1-220 | head -40
}

run_app R1-B2-delay-defaults MODE=B2 WORK=delay WORK_SEC=3 CLOSE_AT=stopped
run_app R2-B1-delay MODE=B1 WORK=delay WORK_SEC=3 CLOSE_AT=stopped
run_app R3-B1-delay-poolclose-at-stopping MODE=B1 WORK=delay WORK_SEC=3 CLOSE_AT=stopping
run_app R4-B1-block8s-timeout2s MODE=B1 WORK=block WORK_SEC=8 GRACE_MS=500 TIMEOUT_MS=2000 CLOSE_AT=stopped
run_app R4b-B2-block8s-runnerstop2s MODE=B2 WORK=block WORK_SEC=8 GRACE_MS=500 TIMEOUT_MS=2000 RUNNER_STOP_MS=2000 CLOSE_AT=stopped
SIG=KILL run_app R5-B2-block60s-kill9 MODE=B2 WORK=block WORK_SEC=60 CLOSE_AT=stopped

echo; echo "### done $(date -u +%FT%TZ)"
docker rm -f $N >/dev/null 2>&1
