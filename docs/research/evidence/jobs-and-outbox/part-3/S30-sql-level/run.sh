#!/usr/bin/env bash
PGPW=${PGPW:-$(openssl rand -hex 12)}; export PGPW  # per-run throwaway password; literal removed after the run (2026-10-21, see docs/research/evidence/jobs-and-outbox/README.md)
# S30: SQL-level checks for jobs-and-outbox part 3, run with psql INSIDE a throwaway postgres:18.6 container.
# NOT through Exposed/HikariCP/pgjdbc (those artifacts are not in any local cache; see F3xx and PENDING S31).
# No downloads: docker run --pull=never, psql from the image. Writes only under docs/research/evidence/.
# Usage: bash run.sh > output.txt 2>&1
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
C=jo3-pg
A=aaaaaaaa-0000-4000-8000-000000000001
B=aaaaaaaa-0000-4000-8000-000000000002
Cn=aaaaaaaa-0000-4000-8000-000000000003
export PGPASSWORD=$PGPW
now_ms() { date +%s%3N; }
# psql as role $1, SQL on stdin
pq() { docker exec -i -e PGPASSWORD=$PGPW -e PGAPPNAME="${2:-jo3}" $C psql -h 127.0.0.1 -U "$1" -d postgres -X -At -v ON_ERROR_STOP=0 2>&1; }
# claim script for tenant $1, limit $2, label $3, sleep seconds $4
claim_sql() { cat <<SQL
begin;
select set_config('app.tenant_id','$1',true) is not null as scope_set;
select '$3 claimed ' || id from (select id from app.outbox where processed_at is null order by id for update skip locked limit $2) s;
select pg_sleep($4);
commit;
SQL
}

echo "### S30 start $(date -u +%FT%TZ)"
docker rm -f $C >/dev/null 2>&1
docker run --pull=never -d --name $C -e POSTGRES_PASSWORD=$PGPW postgres:18.6 >/dev/null || { echo "docker run failed"; exit 1; }
for i in $(seq 1 60); do docker exec $C pg_isready -h 127.0.0.1 -U postgres >/dev/null 2>&1 && break; sleep 1; done
sleep 2
echo "### versions"; docker exec -e PGPASSWORD=$PGPW $C psql -h 127.0.0.1 -U postgres -At -c "select version()"; docker --version
docker exec -i -e PGPASSWORD=$PGPW $C psql -h 127.0.0.1 -U postgres -d postgres -X -At -v ON_ERROR_STOP=1 -v pgpw="$PGPW" < "$HERE/setup.sql"
docker exec -i -e PGPASSWORD=$PGPW $C psql -h 127.0.0.1 -U postgres -d postgres -X -At -v ON_ERROR_STOP=1 <<SQL
insert into app.tenant_status values ('$A','active'),('$B','active'),('$Cn','suspended');
insert into app.outbox (tenant_id, kind, ref, traceparent) select '$A','order.created', gen_random_uuid(), null from generate_series(1,10);
insert into app.outbox (tenant_id, kind, ref, traceparent) select '$B','order.created', gen_random_uuid(), null from generate_series(1,3);
SQL

echo; echo "### T1a job_rt, NO tenant context: outbox count, skip-locked claim, tenant_status count (expect 0, 0 rows, 0)"
pq job_rt <<SQL
begin;
select 'outbox rows visible: ' || count(*) from app.outbox;
select 'claim rows: ' || count(*) from (select id from app.outbox for update skip locked limit 5) s;
select 'tenant_status rows visible to job_rt: ' || count(*) from app.tenant_status;
commit;
SQL
echo "### T1b platform_rt, no context: list tenant ids (expect 3), then read outbox (expect permission denied)"
pq platform_rt <<SQL
select 'tenant: ' || tenant_id || ' ' || status from app.tenant_status order by tenant_id;
select count(*) from app.outbox;
SQL
echo "### T1c app_rt no context: tenant_status (no grant, expect permission denied)"
pq app_rt <<SQL
select count(*) from app.tenant_status;
SQL

echo; echo "### T2 two workers, same tenant A (10 rows): W1 claims 6 and holds 4 s, W2 starts 1 s later and claims up to 6"
claim_sql $A 6 W1 4 | pq job_rt w1 > "$HERE/t2_w1.txt" &
P1=$!
sleep 1
claim_sql $A 6 W2 0 | pq job_rt w2 > "$HERE/t2_w2.txt"
wait $P1
cat "$HERE/t2_w1.txt" "$HERE/t2_w2.txt" | grep claimed
W1N=$(grep -c 'W1 claimed' "$HERE/t2_w1.txt"); W2N=$(grep -c 'W2 claimed' "$HERE/t2_w2.txt")
OVER=$(comm -12 <(grep 'W1 claimed' "$HERE/t2_w1.txt" | awk '{print $3}' | sort) <(grep 'W2 claimed' "$HERE/t2_w2.txt" | awk '{print $3}' | sort) | wc -l)
echo "T2 result: W1=$W1N W2=$W2N overlap=$OVER"

echo; echo "### T3 dedup row and effect in ONE transaction (tenant A, message m1)"
echo "-- T3a forced failure after both inserts (division by zero), then COMMIT (becomes rollback)"
pq job_rt <<SQL
begin;
select set_config('app.tenant_id','$A',true) is not null;
insert into app.inbox_dedup (tenant_id, message_id) values ('$A','m1');
insert into app.effects (tenant_id, note) values ('$A','effect of m1');
select 1/0;
commit;
SQL
echo "-- after T3a (new transaction, scope A): dedup rows and effect rows (expect 0 and 0)"
pq job_rt <<SQL
begin;
select set_config('app.tenant_id','$A',true) is not null;
select 'dedup rows: ' || count(*) from app.inbox_dedup;
select 'effect rows: ' || count(*) from app.effects;
commit;
SQL
echo "-- T3b success path (expect COMMIT, then 1 and 1)"
pq job_rt <<SQL
begin;
select set_config('app.tenant_id','$A',true) is not null;
insert into app.inbox_dedup (tenant_id, message_id) values ('$A','m1');
insert into app.effects (tenant_id, note) values ('$A','effect of m1');
commit;
begin;
select set_config('app.tenant_id','$A',true) is not null;
select 'dedup rows: ' || count(*) from app.inbox_dedup;
select 'effect rows: ' || count(*) from app.effects;
commit;
SQL
echo "-- T3c redelivery of m1: insert ... on conflict do nothing returning; effect only when a row came back (expect 0 rows -> skip)"
pq job_rt <<SQL
begin;
select set_config('app.tenant_id','$A',true) is not null;
with d as (insert into app.inbox_dedup (tenant_id, message_id) values ('$A','m1') on conflict do nothing returning 1)
insert into app.effects (tenant_id, note) select '$A','effect of m1 AGAIN' from d;
select 'effect rows after redelivery: ' || count(*) from app.effects;
commit;
SQL
echo "-- T3d plain duplicate insert without ON CONFLICT (expect SQLSTATE 23505 text)"
pq job_rt <<SQL
\set VERBOSITY verbose
begin;
select set_config('app.tenant_id','$A',true) is not null;
insert into app.inbox_dedup (tenant_id, message_id) values ('$A','m1');
rollback;
SQL
echo "-- T3e dedup row for tenant A written while scope is B (expect RLS WITH CHECK violation)"
pq job_rt <<SQL
begin;
select set_config('app.tenant_id','$B',true) is not null;
insert into app.inbox_dedup (tenant_id, message_id) values ('$A','m9');
rollback;
SQL

echo; echo "### T4 traceparent round trip (stored by app_rt in scope A, read and marked by job_rt in scope A)"
TP='00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01'
pq app_rt <<SQL
begin;
select set_config('app.tenant_id','$A',true) is not null;
insert into app.outbox (tenant_id, kind, ref, traceparent) values ('$A','order.created', gen_random_uuid(), '$TP');
commit;
SQL
pq job_rt <<SQL
begin;
select set_config('app.tenant_id','$A',true) is not null;
select 'read back: ' || traceparent || ' equal=' || (traceparent = '$TP') from app.outbox where traceparent is not null;
update app.outbox set processed_at = now(), attempts = attempts + 1 where traceparent = '$TP';
select 'unprocessed left in A: ' || count(*) from app.outbox where processed_at is null;
commit;
SQL

echo; echo "### T5 transaction_timeout (set first, locally, 500 ms) on a claim transaction that then sleeps 3 s"
T0=$(now_ms)
pq job_rt t5 <<SQL
begin;
select set_config('transaction_timeout','500ms',true) is not null;
select set_config('app.tenant_id','$A',true) is not null;
select 'T5 claimed ' || id from (select id from app.outbox where processed_at is null order by id for update skip locked limit 3) s;
select pg_sleep(3);
select 'T5 survived the sleep (unexpected)';
commit;
SQL
echo "T5 elapsed_ms=$(( $(now_ms) - T0 ))"
echo "-- T5 follow-up: a new session claims A (expect the same 3 ids claimable again; lock released)"
claim_sql $A 3 T5b 0 | pq job_rt | grep -E 'claimed'

echo; echo "### T6 process kill: client claims 3 rows in scope A, holds, is SIGKILLed; second session polls for the rows"
docker exec -e PGPASSWORD=$PGPW -e PGAPPNAME=jo3-killme -e SQL="begin; select set_config('app.tenant_id','$A',true) is not null; select 'K claimed ' || id from (select id from app.outbox where processed_at is null order by id for update skip locked limit 3) s; select pg_sleep(120); commit;" $C sh -c 'psql -h 127.0.0.1 -U job_rt -d postgres -X -At -c "$SQL" & echo PID:$!; wait' > "$HERE/t6_victim.txt" 2>&1 &
VP=$!
sleep 2
cat "$HERE/t6_victim.txt"
PID=$(grep -o 'PID:[0-9]*' "$HERE/t6_victim.txt" | cut -d: -f2)
echo "-- before kill: backends named jo3-killme, and a competing claim (expect 3 fewer claimable rows in A)"
echo "select 'backends jo3-killme: ' || count(*) from pg_stat_activity where application_name='jo3-killme';" | pq postgres
echo "select 'locked-by-victim rows (pg_locks tuple locks held by jo3-killme): ' || count(*) from pg_locks l join pg_stat_activity a using (pid) where a.application_name='jo3-killme' and l.locktype in ('transactionid','tuple');" | pq postgres
claim_sql $A 20 C1 0 | pq job_rt | grep -c 'C1 claimed' | sed 's/^/competing claim before kill got rows: /'
K0=$(now_ms)
docker exec $C kill -9 "$PID"
echo "kill -9 sent to client pid $PID"
for i in $(seq 1 100); do
  N=$(claim_sql $A 20 C2 0 | pq job_rt | grep -c 'C2 claimed')
  [ "$N" -ge 8 ] && break
  sleep 0.1
done
echo "T6 first poll that saw the victim's rows again: rows=$N after_ms=$(( $(now_ms) - K0 )) (includes docker exec overhead per poll)"
echo "select 'backends jo3-killme after: ' || count(*) from pg_stat_activity where application_name='jo3-killme';" | pq postgres
wait $VP 2>/dev/null

echo; echo "### done $(date -u +%FT%TZ)"
docker rm -f $C >/dev/null 2>&1
