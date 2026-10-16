#!/usr/bin/env bash
# b-s101-run.sh: PostgreSQL 18.6 probes for inbox dedupe, per-device ordering under concurrent retries, quarantine, RLS+unique.
# Usage: b-s101-run.sh <container> ; run from any directory. Throwaway container, throwaway password, localhost only.
set -u
C="${1:?container}"
D="$(cd "$(dirname "$0")" && pwd)"
P() { docker exec -i -e PGOPTIONS="-c search_path=probe" "$C" psql -X -q -U postgres -d postgres -v ON_ERROR_STOP=0 "$@"; }
T1=11111111-1111-1111-1111-111111111111   # tenant 1
T2=22222222-2222-2222-2222-222222222222   # tenant 2
DV=aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa   # device
date -u +"run at %FT%TZ"; P -tAc "select version()"
P < "$D/b-s101-setup.sql" >/dev/null 2>&1 && echo "setup ok"
P -c "insert into probe.device_cursor(tenant_id,device_id) values ('$T1','$DV'),('$T2','$DV');"

echo "=== T1: replay returns the stored outcome; different payload under same command id is detected"
P <<SQL
SET search_path=probe;
SELECT apply_cmd('$T1','$DV','c0000000-0000-0000-0000-000000000001',1,5000,'\xaa');
SELECT apply_cmd('$T1','$DV','c0000000-0000-0000-0000-000000000001',1,5000,'\xaa');   -- replay
SELECT apply_cmd('$T1','$DV','c0000000-0000-0000-0000-000000000001',1,9999,'\xbb');   -- same id, other payload
SELECT apply_cmd('$T1','$DV','c0000000-0000-0000-0000-000000000009',3,100,'\xcc');    -- gap (seq 3, last=1)
SELECT apply_cmd('$T1','$DV','c0000000-0000-0000-0000-000000000002',2,-1,'\xdd');     -- poison: negative amount -> rejected, cursor advances
SELECT apply_cmd('$T1','$DV','c0000000-0000-0000-0000-000000000009',3,100,'\xcc');    -- later command is no longer blocked
SELECT device_id, last_applied_seq FROM device_cursor WHERE tenant_id='$T1';
SELECT device_seq, outcome, response FROM inbox ORDER BY device_seq;   -- (RLS: superuser sees all)
SQL

echo "=== T2: concurrent identical command: the second INSERT blocks until the first commits (no 409 needed at DB level)"
P <<SQL
SET search_path=probe;
TRUNCATE inbox, apply_log; UPDATE device_cursor SET last_applied_seq=0;
SQL
( P -c "BEGIN; SELECT probe.apply_cmd('$T1','$DV','c0000000-0000-0000-0000-0000000000a1',1,700,'\xee'); SELECT pg_sleep(3); COMMIT;" > $D/.b-s101-a.out 2>&1 ) &
sleep 1
s=$(date +%s.%N)
P -tAc "SELECT probe.apply_cmd('$T1','$DV','c0000000-0000-0000-0000-0000000000a1',1,700,'\xee');" > $D/.b-s101-b.out 2>&1
e=$(date +%s.%N)
wait
echo "session A: $(grep -h applied $D/.b-s101-a.out | head -1)"
echo "session B (concurrent duplicate) result: $(cat $D/.b-s101-b.out)  waited_seconds=$(awk -v a="$s" -v b="$e" 'BEGIN{printf "%.1f", b-a}')"
rm -f $D/.b-s101-a.out $D/.b-s101-b.out

echo "=== T3: 5 sequence numbers, each sent 6 times, 30 concurrent psql sessions in shuffled order, retried until no gap"
P -c "set search_path=probe; TRUNCATE inbox, apply_log; UPDATE device_cursor SET last_applied_seq=0;"
for round in 1 2 3 4 5 6 7 8 9 10; do
  for i in $(seq 1 5); do for k in 1 2 3 4 5 6; do echo $i; done; done | shuf | \
  while read s; do
    ( P -tAc "SELECT probe.apply_cmd('$T1','$DV','c0000000-0000-0000-0000-00000000010$s',$s,$((s*100)),'\x0$s');" >/dev/null 2>&1 ) &
  done
  wait
done
P <<SQL
SET search_path=probe;
SELECT 'cursor', last_applied_seq FROM device_cursor WHERE tenant_id='$T1';
SELECT 'apply_log rows', count(*), 'distinct seq', count(DISTINCT device_seq) FROM apply_log WHERE tenant_id='$T1';
SELECT 'order check: global_order ascending equals device_seq ascending?',
       (SELECT bool_and(a.device_seq < b.device_seq) FROM apply_log a JOIN apply_log b ON b.global_order = (SELECT min(global_order) FROM apply_log WHERE global_order > a.global_order) );
SELECT global_order, device_seq, amount_piasters FROM apply_log ORDER BY global_order;
SQL

echo "=== T4: tenant scoping of the key (RLS role). Global-unique key leaks existence across tenants; tenant-leading key does not"
# A <tenant> <sql>: one psql process per statement, role kodeebo_app, tenant set from the session setting
A() { local t="$1"; shift; echo "-- [tenant ${t:0:2}] $*"; P -c "SET ROLE kodeebo_app" -c "SELECT set_config('app.tenant_id','$t',false)" -tA -c "$*" 2>&1 | grep -v '^SET$' | grep -v "^$t$" ; }
A $T1 "INSERT INTO inbox_bad_global VALUES ('c0000000-0000-0000-0000-00000000dead','$T1')"
echo "# tenant 2 inserts the same command_id into the GLOBAL-unique table; per-statement process so SET ROLE needs re-issue in the same call"
P -c "SET ROLE kodeebo_app" -c "SELECT set_config('app.tenant_id','$T2',false)" -c "INSERT INTO inbox_bad_global VALUES ('c0000000-0000-0000-0000-00000000dead','$T2')" 2>&1 | grep -v '^SET$\|set_config\|^---\|^ [0-9a-f]\{8\}-\|^(1 row)\|^$'
echo "# same with ON CONFLICT DO NOTHING RETURNING (0 rows returned, no indication of why):"
P -c "SET ROLE kodeebo_app" -c "SELECT set_config('app.tenant_id','$T2',false)" -c "INSERT INTO inbox_bad_global VALUES ('c0000000-0000-0000-0000-00000000dead','$T2') ON CONFLICT DO NOTHING RETURNING *" 2>&1 | grep -v '^SET$\|set_config\|^---\|^ [0-9a-f]\{8\}-\|^(1 row)\|^$'
echo "# tenant 2 reads the global table (RLS hides tenant 1 row):"
P -c "SET ROLE kodeebo_app" -c "SELECT set_config('app.tenant_id','$T2',false)" -c "SELECT count(*) AS visible_rows FROM inbox_bad_global" 2>&1 | tail -4
echo "# tenant-leading inbox key: tenant 1 then tenant 2 use the SAME command id:"
P -c "SET ROLE kodeebo_app" -c "SELECT set_config('app.tenant_id','$T1',false)" -c "INSERT INTO inbox VALUES ('$T1','$DV','c0000000-0000-0000-0000-00000000beef',50,'\\x01','applied','{}') RETURNING command_id" 2>&1 | tail -4
P -c "SET ROLE kodeebo_app" -c "SELECT set_config('app.tenant_id','$T2',false)" -c "INSERT INTO inbox VALUES ('$T2','$DV','c0000000-0000-0000-0000-00000000beef',50,'\\x01','applied','{}') RETURNING command_id" 2>&1 | tail -4
echo "# tenant 2 context writes a row carrying tenant 1 id (expect RLS WITH CHECK violation):"
P -c "SET ROLE kodeebo_app" -c "SELECT set_config('app.tenant_id','$T2',false)" -c "INSERT INTO inbox VALUES ('$T1','$DV','c0000000-0000-0000-0000-00000000cafe',51,'\\x01','applied','{}')" 2>&1 | tail -2
echo "# ON CONFLICT DO UPDATE aimed at tenant 1 row from tenant 2 context:"
P -c "SET ROLE kodeebo_app" -c "SELECT set_config('app.tenant_id','$T2',false)" -c "INSERT INTO inbox VALUES ('$T1','$DV','c0000000-0000-0000-0000-00000000beef',50,'\\x01','applied','{}') ON CONFLICT (tenant_id, device_id, command_id) DO UPDATE SET response='{\"hijack\":true}'" 2>&1 | tail -2
echo "# final check as superuser: tenant 1 beef row response unchanged:"
P -tAc "SELECT tenant_id, response FROM inbox WHERE command_id='c0000000-0000-0000-0000-00000000beef' ORDER BY 1"
