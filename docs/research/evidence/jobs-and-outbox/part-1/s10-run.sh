#!/usr/bin/env bash
PGPW=${PGPW:-$(openssl rand -hex 12)}; export PGPW  # per-run throwaway password; literal removed after the run (2026-10-21, see docs/research/evidence/jobs-and-outbox/README.md)
# S10 (jobs-and-outbox part 1): work-list claim, retry/backoff/dead state, at-most-one runner and wake-up behaviour
# on postgres:18.6 (local image, --pull=never; no download). SQL only, driven by psql inside the container.
# Run: bash docs/research/evidence/jobs-and-outbox/part-1/s10-run.sh > docs/research/evidence/jobs-and-outbox/part-1/s10-output.txt 2>&1
# Roles are a reduced model of ADR-0001 (restrictive tenant_isolation without TO + permissive per-role policies, FORCE RLS,
# no BYPASSRLS), not the production migration. Container is removed at the end; raw per-session outputs are kept in raw/.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
RAW="$HERE/s10-raw"; mkdir -p "$RAW"
A=aaaaaaaa-0000-0000-0000-000000000001
B=bbbbbbbb-0000-0000-0000-000000000002
N=jbp1
P() { local role=$1; shift; docker exec -i -e PGAPPNAME="${APP:-p1}" $N psql -X -q -v ON_ERROR_STOP=0 -v VERBOSITY=verbose -v A=$A -v B=$B -U "$role" -d kdb "$@"; }
H() { echo; echo "=== $* ==="; }

docker rm -f $N >/dev/null 2>&1
echo "### date $(date -u +%FT%TZ)  image postgres:18.6 $(docker image inspect postgres:18.6 --format '{{.Id}}' | cut -c1-19)"
docker run -d --pull=never --name $N -e POSTGRES_PASSWORD=$PGPW postgres:18.6 >/dev/null || { echo "docker run failed"; exit 1; }
for i in $(seq 1 60); do
  c=$(docker logs $N 2>&1 | grep -c "database system is ready to accept connections")
  [ "$c" -ge 2 ] && break; sleep 1
done
docker exec $N psql -U postgres -Atc "select version()"

H "SETUP (as postgres)"
docker exec -i $N psql -X -q -U postgres <<'SQL'
create database kdb;
\c kdb
create role migrator nologin;
create role app_rt login; create role job_rt login; create role platform_rt login;
create role ro_rt login; create role sel_only_rt login;
create schema app authorization migrator;
grant usage on schema app to app_rt, job_rt, platform_rt, ro_rt, sel_only_rt;
set role migrator;
create function app.cur_tenant() returns uuid language sql stable as $$ select nullif(current_setting('app.tenant_id', true), '')::uuid $$;
-- TD work list (design 2-a)
create table app.outbox(
  tenant_id uuid not null, id bigint generated always as identity, kind text not null,
  payload jsonb not null default '{}', traceparent text,
  status text not null default 'pending' check (status in ('pending','done','dead')),
  run_at timestamptz not null default now(), attempts int not null default 0, max_attempts int not null default 4,
  last_error text, primary key (tenant_id, id));
create index outbox_due on app.outbox (tenant_id, run_at) where status = 'pending';
alter table app.outbox enable row level security; alter table app.outbox force row level security;
create policy tenant_isolation on app.outbox as restrictive for all using (tenant_id = app.cur_tenant()) with check (tenant_id = app.cur_tenant());
create policy app_ins on app.outbox as permissive for insert to app_rt with check (tenant_id = app.cur_tenant());
create policy app_sel on app.outbox as permissive for select to app_rt using (tenant_id = app.cur_tenant());
create policy job_sel on app.outbox as permissive for select to job_rt using (tenant_id = app.cur_tenant());
create policy job_upd on app.outbox as permissive for update to job_rt using (tenant_id = app.cur_tenant()) with check (tenant_id = app.cur_tenant());
create policy ro_sel  on app.outbox as permissive for select to ro_rt using (tenant_id = app.cur_tenant());
create policy selonly_sel on app.outbox as permissive for select to sel_only_rt using (tenant_id = app.cur_tenant());
grant insert, select on app.outbox to app_rt;
grant select, update on app.outbox to job_rt;
grant select on app.outbox to ro_rt;
grant select, update on app.outbox to sel_only_rt;
-- CP pending-work list (design 2-d): platform_rt reads all, others only their tenant
create table app.tenant_work(tenant_id uuid primary key, due_at timestamptz not null, pending bigint not null default 0);
create index tenant_work_due on app.tenant_work (due_at);
alter table app.tenant_work enable row level security; alter table app.tenant_work force row level security;
create policy tenant_isolation on app.tenant_work as restrictive for all to app_rt, job_rt, ro_rt, sel_only_rt using (tenant_id = app.cur_tenant()) with check (tenant_id = app.cur_tenant());
create policy pf_all on app.tenant_work as permissive for select to platform_rt using (true);
create policy app_all on app.tenant_work as permissive for all to app_rt using (tenant_id = app.cur_tenant()) with check (tenant_id = app.cur_tenant());
create policy job_all on app.tenant_work as permissive for all to job_rt using (tenant_id = app.cur_tenant()) with check (tenant_id = app.cur_tenant());
grant select on app.tenant_work to platform_rt;
grant select, insert, update, delete on app.tenant_work to app_rt, job_rt;
-- recurring-job schedule (no RLS: lock semantics only)
create table app.job_schedule(name text primary key, next_run_at timestamptz not null, runs int not null default 0);
grant select, update on app.job_schedule to job_rt;
reset role;
insert into app.job_schedule values ('retention', now() - interval '1 minute', 0);
\du+
select relname, relrowsecurity as rls, relforcerowsecurity as forced from pg_class where relnamespace = 'app'::regnamespace and relkind='r' order by 1;
SQL

H "SEED as app_rt: tenant A 6 rows, tenant B 3 rows, tenant_work row for A (committed)"
P app_rt <<'SQL'
begin; select set_config('app.tenant_id', :'A', true) \gset
insert into app.outbox(tenant_id, kind) select :'A'::uuid, 'k' || g from generate_series(1,6) g;
insert into app.tenant_work values (:'A'::uuid, now(), 6);
commit;
begin; select set_config('app.tenant_id', :'B', true) \gset
insert into app.outbox(tenant_id, kind) select :'B'::uuid, 'k' || g from generate_series(1,3) g;
commit;
SQL

H "T1a job_rt claim, NO tenant context (expect 0 rows)"
P job_rt <<'SQL'
begin;
select count(*) as rows_claimed_no_ctx from (select id from app.outbox where status='pending' and run_at<=now() order by run_at limit 10 for update skip locked) s;
rollback;
SQL

H "T1b job_rt claim in scope A (expect 6) and in scope B (expect 3)"
P job_rt <<'SQL'
begin; select set_config('app.tenant_id', :'A', true) \gset
select count(*) as scope_A from (select id from app.outbox where status='pending' and run_at<=now() order by run_at limit 10 for update skip locked) s;
rollback;
begin; select set_config('app.tenant_id', :'B', true) \gset
select count(*) as scope_B from (select id from app.outbox where status='pending' and run_at<=now() order by run_at limit 10 for update skip locked) s;
rollback;
SQL

H "T1c FOR UPDATE by a role with SELECT privilege only (ro_rt)"
P ro_rt <<'SQL'
begin; select set_config('app.tenant_id', :'A', true) \gset
select id from app.outbox where status='pending' order by run_at limit 3 for update skip locked;
rollback;
SQL

H "T1d FOR UPDATE by a role with SELECT+UPDATE privilege but only a SELECT policy (sel_only_rt)"
P sel_only_rt <<'SQL'
begin; select set_config('app.tenant_id', :'A', true) \gset
select count(*) as for_update_rows from (select id from app.outbox where status='pending' order by run_at limit 3 for update skip locked) s;
update app.outbox set last_error='x' where tenant_id = app.cur_tenant();
rollback;
SQL

H "T1e two workers, same tenant: s1 claims 3 and holds 3 s, s2 starts 1 s later (expect disjoint ids)"
( APP=claimer1 P job_rt <<'SQL' > "$RAW/t1e-s1.txt" 2>&1
begin; select set_config('app.tenant_id', :'A', true) \gset
select 's1' as who, array_agg(id order by id) as ids from (select id from app.outbox where status='pending' and run_at<=now() order by run_at, id limit 3 for update skip locked) s;
select pg_sleep(3);
commit;
SQL
) &
sleep 1
APP=claimer2 P job_rt <<'SQL'
begin; select set_config('app.tenant_id', :'A', true) \gset
select 's2' as who, array_agg(id order by id) as ids from (select id from app.outbox where status='pending' and run_at<=now() order by run_at, id limit 3 for update skip locked) s;
rollback;
SQL
wait
cat "$RAW/t1e-s1.txt"

H "T1f crashed claimer: s3 claims all 6 and sleeps; its backend is terminated at 1 s; s4 claims at once after (expect 6)"
( APP=claimer3 P job_rt <<'SQL' > "$RAW/t1f-s3.txt" 2>&1
begin; select set_config('app.tenant_id', :'A', true) \gset
select 's3' as who, count(*) as claimed from (select id from app.outbox where status='pending' order by run_at limit 10 for update skip locked) s;
select pg_sleep(5);
SQL
) &
sleep 1
docker exec $N psql -U postgres -d kdb -Atc "select 'terminated claimer3: ' || pg_terminate_backend(pid) from pg_stat_activity where application_name='claimer3'"
sleep 0.3
APP=claimer4 P job_rt <<'SQL'
begin; select set_config('app.tenant_id', :'A', true) \gset
select 's4' as who, count(*) as claimed_after_crash from (select id from app.outbox where status='pending' order by run_at limit 10 for update skip locked) s;
rollback;
SQL
wait
echo "--- s3 raw output:"; cat "$RAW/t1f-s3.txt"

H "T1g cross-tenant: in scope A as app_rt, count visible rows and try to insert a row for tenant B"
P app_rt <<'SQL'
begin; select set_config('app.tenant_id', :'A', true) \gset
select count(*) as visible_in_scope_A from app.outbox;
insert into app.outbox(tenant_id, kind) values (:'B'::uuid, 'forged');
rollback;
SQL

H "T1h business write + outbox row + tenant_work upsert in one app_rt transaction: ROLLBACK then COMMIT"
P app_rt <<'SQL'
begin; select set_config('app.tenant_id', :'A', true) \gset
insert into app.outbox(tenant_id, kind) values (:'A'::uuid, 'tx-test');
insert into app.tenant_work values (:'A'::uuid, now(), 1) on conflict (tenant_id) do update set pending = app.tenant_work.pending + 1;
rollback;
begin; select set_config('app.tenant_id', :'A', true) \gset
select count(*) as tx_test_rows_after_rollback, (select pending from app.tenant_work) as pending_after_rollback from app.outbox where kind='tx-test';
commit;
SQL

H "T1i hot-row contention in design 2-d: s5 upserts tenant_work (DO UPDATE) and holds 1.5 s; s6 starts 0.5 s later (waited seconds for s6's upsert)"
( APP=w5 P app_rt <<'SQL' > "$RAW/t1i-s5.txt" 2>&1
begin; select set_config('app.tenant_id', :'A', true) \gset
insert into app.tenant_work values (:'A'::uuid, now(), 1) on conflict (tenant_id) do update set pending = app.tenant_work.pending + 1;
select pg_sleep(1.5);
commit;
SQL
) &
sleep 0.5
P app_rt <<'SQL'
begin; select set_config('app.tenant_id', :'A', true) \gset
select clock_timestamp() as t0 \gset
insert into app.tenant_work values (:'A'::uuid, now(), 1) on conflict (tenant_id) do update set pending = app.tenant_work.pending + 1;
select round(extract(epoch from clock_timestamp() - :'t0'::timestamptz)::numeric, 2) as DO_UPDATE_waited_s;
commit;
SQL
wait
H "T1j same, but the hint row already exists and the writers use ON CONFLICT DO NOTHING"
( APP=w7 P app_rt <<'SQL' > "$RAW/t1j-s7.txt" 2>&1
begin; select set_config('app.tenant_id', :'A', true) \gset
insert into app.tenant_work values (:'A'::uuid, now(), 1) on conflict (tenant_id) do nothing;
select pg_sleep(1.5);
commit;
SQL
) &
sleep 0.5
P app_rt <<'SQL'
begin; select set_config('app.tenant_id', :'A', true) \gset
select clock_timestamp() as t0 \gset
insert into app.tenant_work values (:'A'::uuid, now(), 1) on conflict (tenant_id) do nothing;
select round(extract(epoch from clock_timestamp() - :'t0'::timestamptz)::numeric, 2) as DO_NOTHING_waited_s;
commit;
SQL
wait

H "T1k CP due-list query by platform_rt over 10,000 tenant_work rows (50 due)"
docker exec -i $N psql -X -q -U postgres -d kdb <<'SQL'
insert into app.tenant_work select gen_random_uuid(), case when g <= 50 then now() - interval '1 minute' else now() + interval '1 hour' end, 1 from generate_series(1,10000) g;
analyze app.tenant_work;
SQL
P platform_rt <<'SQL'
select count(*) as tenants_visible from app.tenant_work;
explain (analyze, buffers, timing off) select tenant_id from app.tenant_work where due_at <= now();
SQL
echo "--- same query as app_rt in scope A (restrictive policy applies to it)"
P app_rt <<'SQL'
begin; select set_config('app.tenant_id', :'A', true) \gset
select count(*) as visible_to_app_rt from app.tenant_work;
rollback;
SQL

H "T1l idle claim poll for one tenant with 200,000 done rows (A) + 100,000 (B) and 20 due pending rows (A): plan and time"
docker exec -i $N psql -X -q -U postgres -d kdb <<'SQL'
insert into app.outbox(tenant_id, kind, status, run_at) select 'aaaaaaaa-0000-0000-0000-000000000001'::uuid, 'old', 'done', now() - interval '1 day' from generate_series(1,200000);
insert into app.outbox(tenant_id, kind, status, run_at) select 'bbbbbbbb-0000-0000-0000-000000000002'::uuid, 'old', 'done', now() - interval '1 day' from generate_series(1,100000);
analyze app.outbox;
SQL
P job_rt <<'SQL'
begin; select set_config('app.tenant_id', :'A', true) \gset
explain (analyze, buffers, timing off) select id from app.outbox where status='pending' and run_at<=now() order by run_at limit 10 for update skip locked;
rollback;
SQL

H "T2 retry with exponential backoff, attempt limit and dead state (base 30 s, cap 3600 s, max_attempts 4; 'time passing' simulated by setting run_at=now())"
P app_rt <<'SQL'
begin; select set_config('app.tenant_id', :'A', true) \gset
insert into app.outbox(tenant_id, kind, max_attempts) values (:'A'::uuid, 'retry-demo', 4);
commit;
SQL
for i in 1 2 3 4 5; do
echo "--- failure $i"
P job_rt <<'SQL'
begin; select set_config('app.tenant_id', :'A', true) \gset
select count(*) as claimable_now from (select id from app.outbox where kind='retry-demo' and status='pending' and run_at<=now() for update skip locked) s;
update app.outbox set
  attempts = attempts + 1, last_error = 'boom',
  status = case when attempts + 1 >= max_attempts then 'dead' else 'pending' end,
  run_at = now() + interval '1 second' * least(30 * power(2, attempts), 3600)
where kind='retry-demo' and status='pending'
returning attempts, status, round(extract(epoch from run_at - now())) as next_in_s;
update app.outbox set run_at = now() where kind='retry-demo' and status='pending';
commit;
SQL
done

H "T3a recurring job, row-lock runner: s8 and s9 both look for the due 'retention' row (s9 starts 0.5 s after s8)"
( APP=r8 P job_rt <<'SQL' > "$RAW/t3a-s8.txt" 2>&1
begin;
select 's8' as who, name from app.job_schedule where next_run_at <= now() for update skip locked;
select pg_sleep(1.5);
update app.job_schedule set next_run_at = next_run_at + interval '1 day', runs = runs + 1 where name='retention';
commit;
SQL
) &
sleep 0.5
P job_rt <<'SQL'
begin;
select 's9' as who, name from app.job_schedule where next_run_at <= now() for update skip locked;
rollback;
SQL
wait
cat "$RAW/t3a-s8.txt"
P job_rt <<'SQL'
select 's10 after commit' as who, count(*) as due_rows from app.job_schedule where next_run_at <= now();
select name, runs, round(extract(epoch from next_run_at - now())/3600) as next_in_hours from app.job_schedule;
SQL

H "T3b recurring job, advisory runner: s11 holds pg_try_advisory_xact_lock(42) 1.5 s, s12 tries at 0.5 s, s13 tries after commit"
( APP=r11 P job_rt <<'SQL' > "$RAW/t3b-s11.txt" 2>&1
begin; select 's11' as who, pg_try_advisory_xact_lock(42) as got; select pg_sleep(1.5); commit;
SQL
) &
sleep 0.5
P job_rt <<'SQL'
begin; select 's12' as who, pg_try_advisory_xact_lock(42) as got; rollback;
SQL
wait
cat "$RAW/t3b-s11.txt"
P job_rt <<'SQL'
begin; select 's13 after commit' as who, pg_try_advisory_xact_lock(42) as got; rollback;
SQL

H "T3c advisory lock holder killed: s14 holds the xact lock, is terminated at 1 s; s15 tries right after"
( APP=r14 P job_rt <<'SQL' > "$RAW/t3c-s14.txt" 2>&1
begin; select 's14' as who, pg_try_advisory_xact_lock(44) as got; select pg_sleep(5);
SQL
) &
sleep 1
docker exec $N psql -U postgres -d kdb -Atc "select 'terminated r14: ' || pg_terminate_backend(pid) from pg_stat_activity where application_name='r14'"
sleep 0.3
P job_rt <<'SQL'
begin; select 's15' as who, pg_try_advisory_xact_lock(44) as got; rollback;
SQL
wait

H "T3d session-level advisory lock survives ROLLBACK in a live session (s16 lives 3 s; s17 tries at 1 s and again after s16 ends)"
( APP=r16 P job_rt <<'SQL' > "$RAW/t3d-s16.txt" 2>&1
begin; select 's16' as who, pg_try_advisory_lock(43) as got; rollback; select pg_sleep(3);
SQL
) &
sleep 1
P job_rt <<'SQL'
select 's17 while s16 alive' as who, pg_try_advisory_lock(43) as got;
SQL
wait
cat "$RAW/t3d-s16.txt"
P job_rt <<'SQL'
select 's18 after s16 ended' as who, pg_try_advisory_lock(43) as got;
SQL

H "T4 LISTEN/NOTIFY: N0 notifies before anyone listens; L listens, then sits in a 3 s transaction; N then sends rolled-back, committed and duplicate notifications while L is in its transaction"
P job_rt <<'SQL'
notify kjobs, 'before-listen';
SQL
( APP=lis P job_rt <<'SQL' > "$RAW/t4-listener.txt" 2>&1
\echo L: listening
listen kjobs;
select pg_sleep(0.5);
begin;
select pg_sleep(3);
\echo L: end of 3 s transaction, committing now
commit;
\echo L: committed
select 1 as probe_after_commit;
select 2 as probe_2;
SQL
) &
sleep 1.3
P job_rt <<'SQL'
begin; notify kjobs, 'rolled-back'; rollback;
notify kjobs, 'committed-while-L-in-tx';
begin; notify kjobs, 'dup'; notify kjobs, 'dup'; notify kjobs, 'dup2'; commit;
select pg_notification_queue_usage() as queue_usage_fraction;
SQL
wait
cat "$RAW/t4-listener.txt"

H "CLEANUP"
docker rm -f $N >/dev/null && echo "container removed"
