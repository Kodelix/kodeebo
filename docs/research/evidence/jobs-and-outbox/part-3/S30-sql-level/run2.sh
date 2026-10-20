#!/usr/bin/env bash
PGPW=${PGPW:-$(openssl rand -hex 12)}; export PGPW  # per-run throwaway password; literal removed after the run (2026-10-21, see docs/research/evidence/jobs-and-outbox/README.md)
# S30b: corrected process-kill test. Written after run.sh's T6 (output.txt) turned out to kill the client while the server
# backend was inside pg_sleep (not representative: see F3xx). Same container image, same setup.sql, new container jo3-pg2.
# T6b: victim is IDLE IN TRANSACTION (typical worker: effect work happens in the JVM between statements) -> kill -9 the client.
# T6c: victim is inside a long server-side statement, killed, with client_connection_check_interval unset (default) -> observe 15 s.
# T6d: same as T6c with client_connection_check_interval=1000ms set at connection start -> observe.
# No downloads. Usage: bash run2.sh > output2.txt 2>&1
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
C=jo3-pg2
A=aaaaaaaa-0000-4000-8000-000000000001
export PGPASSWORD=$PGPW
now_ms() { date +%s%3N; }
pq() { docker exec -i -e PGPASSWORD=$PGPW -e PGAPPNAME="${2:-jo3}" $C psql -h 127.0.0.1 -U "$1" -d postgres -X -At -v ON_ERROR_STOP=0 2>&1; }
claimable() { pq job_rt <<SQL | grep -c 'claimed'
begin;
select set_config('app.tenant_id','$A',true) is not null;
select 'claimed ' || id from (select id from app.outbox where processed_at is null order by id for update skip locked limit 100) s;
commit;
SQL
}
backends() { echo "select count(*) from pg_stat_activity where application_name='$1';" | pq postgres; }

echo "### S30b start $(date -u +%FT%TZ)"
docker rm -f $C >/dev/null 2>&1
docker run --pull=never -d --name $C -e POSTGRES_PASSWORD=$PGPW postgres:18.6 >/dev/null || { echo "docker run failed"; exit 1; }
for i in $(seq 1 60); do docker exec $C pg_isready -h 127.0.0.1 -U postgres >/dev/null 2>&1 && break; sleep 1; done
sleep 2
docker exec -e PGPASSWORD=$PGPW $C psql -h 127.0.0.1 -U postgres -At -c "select version()"
docker exec -i -e PGPASSWORD=$PGPW $C psql -h 127.0.0.1 -U postgres -d postgres -X -At -v ON_ERROR_STOP=1 -v pgpw="$PGPW" < "$HERE/setup.sql" >/dev/null
docker exec -i -e PGPASSWORD=$PGPW $C psql -h 127.0.0.1 -U postgres -d postgres -X -At -v ON_ERROR_STOP=1 <<SQL >/dev/null
insert into app.outbox (tenant_id, kind, ref) select '$A','order.created', gen_random_uuid() from generate_series(1,10);
SQL
echo "rows claimable in A before any victim: $(claimable)"

# victim function: $1 label, $2 appname, $3 mode (idle|sleep), $4 PGOPTIONS
victim() {
  local label=$1 app=$2 mode=$3 opts=$4
  echo; echo "### $label"
  local tail_sql
  if [ "$mode" = idle ]; then tail_sql="-- idle in transaction after the claim"; else tail_sql="select pg_sleep(60);"; fi
  ( printf "begin;\nselect set_config('app.tenant_id','$A',true) is not null;\nselect 'V claimed ' || id from (select id from app.outbox where processed_at is null order by id for update skip locked limit 3) s;\n%s\n" "$tail_sql"; sleep 90 ) \
    | docker exec -i -e PGPASSWORD=$PGPW -e PGAPPNAME="$app" -e PGOPTIONS="$opts" $C sh -c 'echo PID:$$; exec psql -h 127.0.0.1 -U job_rt -d postgres -X -At' > "$HERE/t6_$app.txt" 2>&1 &
  sleep 2
  local pid; pid=$(grep -o 'PID:[0-9]*' "$HERE/t6_$app.txt" | cut -d: -f2)
  cat "$HERE/t6_$app.txt"
  echo "backends $app before kill: $(backends $app); rows claimable by a competitor now: $(claimable) (expect 7)"
  echo "backend state: $(echo "select state || ' / ' || coalesce(wait_event,'-') from pg_stat_activity where application_name='$app';" | pq postgres)"
  local k0; k0=$(now_ms)
  docker exec $C kill -9 "$pid"; echo "kill -9 sent to client pid $pid"
  local limit=$5 n=0 b=1
  while [ $(( $(now_ms) - k0 )) -lt "$limit" ]; do
    b=$(backends $app)
    if [ "$b" = 0 ]; then break; fi
    sleep 0.1
  done
  echo "backends $app after: $b, elapsed_ms=$(( $(now_ms) - k0 )) (poll includes docker exec overhead)"
  echo "rows claimable after: $(claimable) (10 means the victim's 3 rows are free again)"
}

victim "T6b victim idle in transaction, default settings, observe up to 15 s" t6b idle "" 15000
victim "T6c victim inside pg_sleep(60), default client_connection_check_interval (0), observe up to 15 s" t6c sleep "" 15000
victim "T6d victim inside pg_sleep(60), client_connection_check_interval=1000ms set at connect, observe up to 15 s" t6d sleep "-c client_connection_check_interval=1000" 15000
echo; echo "-- setting reference: default and unit of client_connection_check_interval on this server"
echo "select name || '=' || setting || coalesce(unit,'') from pg_settings where name in ('client_connection_check_interval','idle_in_transaction_session_timeout','transaction_timeout','tcp_keepalives_idle','tcp_keepalives_interval','tcp_keepalives_count','tcp_user_timeout');" | pq postgres
echo; echo "### done $(date -u +%FT%TZ)"
docker rm -f $C >/dev/null 2>&1
