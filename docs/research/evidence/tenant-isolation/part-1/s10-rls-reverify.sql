-- S10: re-verify RLS facts at PostgreSQL 18.6. Run by run-s10.sh inside container ti-p1-pg as superuser (SET ROLE / SET LOCAL ROLE used to act as each role).
-- Throwaway credentials only; no product data.
\set ON_ERROR_STOP off
\pset pager off
\echo '=== version ==='
select version();

\echo '=== setup (superuser) ==='
drop database if exists s10;
drop role if exists app_rt; drop role if exists bypass_t; drop role if exists migrator;
create role migrator nologin;
create role app_rt login nosuperuser nobypassrls nocreaterole nocreatedb;
create role bypass_t login bypassrls;
create database s10 owner migrator;
\c s10 postgres
grant connect on database s10 to app_rt, bypass_t;
alter schema public owner to migrator;
grant usage on schema public to app_rt, bypass_t;
set role migrator;
create table orders (tenant_id uuid not null, id int not null, note text, primary key (tenant_id, id));
create table gunique (tenant_id uuid not null, id int primary key, code text unique);        -- unique key NOT tenant-leading
create table tunique (tenant_id uuid not null, id int primary key, code text, unique (tenant_id, code));
create table parent (tenant_id uuid not null, id int primary key, unique (tenant_id, id));
create table child_simple (tenant_id uuid not null, id int primary key, parent_id int references parent(id));       -- single-column FK
create table child_comp (tenant_id uuid not null, id int primary key, parent_id int not null,
   foreign key (tenant_id, parent_id) references parent(tenant_id, id));                                        -- tenant-leading composite FK
-- policies: NULLIF pattern from stack-reference postgres/best-practices.md s1
do $$ declare t text; begin
 foreach t in array array['orders','gunique','tunique','parent','child_simple','child_comp'] loop
  execute format('alter table %I enable row level security', t);
  execute format($p$create policy tenant_isolation on %I using (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid) with check (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid)$p$, t);
  execute format('grant select, insert, update, delete on %I to app_rt, bypass_t', t);
 end loop; end $$;
-- NOTE: FORCE is deliberately NOT set yet on orders (step T1), set on the others
alter table gunique force row level security; alter table tunique force row level security;
alter table parent force row level security; alter table child_simple force row level security; alter table child_comp force row level security;
reset role;
-- seed as superuser (bypasses RLS)
insert into orders values ('11111111-1111-4111-8111-111111111111',1,'A1'),('11111111-1111-4111-8111-111111111111',2,'A2'),('22222222-2222-4222-8222-222222222222',1,'B1');
insert into gunique values ('11111111-1111-4111-8111-111111111111',1,'shared-code');
insert into tunique values ('11111111-1111-4111-8111-111111111111',1,'shared-code');
insert into parent values ('11111111-1111-4111-8111-111111111111',100),('22222222-2222-4222-8222-222222222222',200);

\echo '=== T1: owner vs ENABLE-only vs FORCE (count of visible orders rows; tenant context set to tenant B in each tx) ==='
\echo '-- superuser sees (expect 3):'
select count(*) as superuser_sees from orders;
\echo '-- table owner (migrator), ENABLE only, context=B (expect 3 = bypass):'
begin; set local role migrator; select set_config('app.tenant_id','22222222-2222-4222-8222-222222222222',true); select count(*) as owner_enable_only from orders; rollback;
\echo '-- now FORCE on orders'
alter table orders force row level security;
\echo '-- table owner (migrator), ENABLE+FORCE, context=B (expect 1):'
begin; set local role migrator; select set_config('app.tenant_id','22222222-2222-4222-8222-222222222222',true); select count(*) as owner_forced from orders; rollback;
\echo '-- table owner (migrator), ENABLE+FORCE, NO context (expect 0):'
begin; set local role migrator; select count(*) as owner_forced_no_ctx from orders; rollback;
\echo '-- BYPASSRLS login role bypass_t, ENABLE+FORCE, context=B (expect 3):'
begin; set local role bypass_t; select set_config('app.tenant_id','22222222-2222-4222-8222-222222222222',true); select count(*) as bypassrls_sees from orders; rollback;
\echo '-- runtime role app_rt: attributes and ownership'
select rolname, rolsuper, rolbypassrls, rolcreaterole, rolcreatedb, rolcanlogin from pg_roles where rolname in ('app_rt','bypass_t','migrator') order by 1;
select c.relname, pg_get_userbyid(c.relowner) as owner from pg_class c where c.relnamespace='public'::regnamespace and c.relkind='r' order by 1;
\echo '-- app_rt, no context (expect 0), context=A (expect 2), context=B (expect 1):'
begin; set local role app_rt; select count(*) as app_rt_no_ctx from orders; rollback;
begin; set local role app_rt; select set_config('app.tenant_id','11111111-1111-4111-8111-111111111111',true); select count(*) as app_rt_ctx_A from orders; rollback;
begin; set local role app_rt; select set_config('app.tenant_id','22222222-2222-4222-8222-222222222222',true); select count(*) as app_rt_ctx_B from orders; rollback;
\echo '-- app_rt cannot enable/disable RLS or add policies (not owner; expect ownership errors):'
begin; set local role app_rt; alter table orders disable row level security; rollback;
begin; set local role app_rt; create policy x on orders using (true); rollback;
\echo '-- app_rt insert for another tenant (expect RLS violation):'
begin; set local role app_rt; select set_config('app.tenant_id','22222222-2222-4222-8222-222222222222',true); insert into orders values ('11111111-1111-4111-8111-111111111111',9,'x'); rollback;

\echo '=== T2: transaction-local set_config: value after COMMIT and ROLLBACK; second set_config switches tenant; malformed value ==='
begin; set local role app_rt; select set_config('app.tenant_id','11111111-1111-4111-8111-111111111111',true); commit;
select '['||coalesce(current_setting('app.tenant_id',true),'<NULL>')||']' as ctx_after_commit_same_session;
begin; select set_config('app.tenant_id','11111111-1111-4111-8111-111111111111',true); rollback;
select '['||coalesce(current_setting('app.tenant_id',true),'<NULL>')||']' as ctx_after_rollback_same_session;
begin; set local role app_rt;
 select set_config('app.tenant_id','11111111-1111-4111-8111-111111111111',true); select count(*) as seen_after_first_set from orders;
 select set_config('app.tenant_id','22222222-2222-4222-8222-222222222222',true); select count(*) as seen_after_second_set from orders; rollback;
begin; set local role app_rt; select set_config('app.tenant_id','not-a-uuid',true); select count(*) from orders; rollback;

\echo '=== T3: unique / FK checks bypass RLS (covert channel), runtime role app_rt, context=B ==='
\echo '-- (a) unique(code) not tenant-leading: B inserts code that only A owns (expect unique violation = existence leak):'
begin; set local role app_rt; select set_config('app.tenant_id','22222222-2222-4222-8222-222222222222',true); insert into gunique values ('22222222-2222-4222-8222-222222222222',2,'shared-code'); rollback;
\echo '-- (b) unique(tenant_id, code): B inserts same code (expect success):'
begin; set local role app_rt; select set_config('app.tenant_id','22222222-2222-4222-8222-222222222222',true); insert into tunique values ('22222222-2222-4222-8222-222222222222',2,'shared-code'); rollback;
\echo '-- (c) B can not see parent 100 (expect 0 rows):'
begin; set local role app_rt; select set_config('app.tenant_id','22222222-2222-4222-8222-222222222222',true); select count(*) as b_sees_parent_100 from parent where id=100; rollback;
\echo '-- (d) single-column FK: B inserts a child pointing at A parent 100 (expect SUCCESS = cross-tenant reference accepted):'
begin; set local role app_rt; select set_config('app.tenant_id','22222222-2222-4222-8222-222222222222',true); insert into child_simple values ('22222222-2222-4222-8222-222222222222',1,100); rollback;
\echo '-- (e) single-column FK to a non-existent parent 999 (expect FK violation; difference between d and e = existence oracle):'
begin; set local role app_rt; select set_config('app.tenant_id','22222222-2222-4222-8222-222222222222',true); insert into child_simple values ('22222222-2222-4222-8222-222222222222',1,999); rollback;
\echo '-- (f) tenant-leading composite FK: B child -> A parent 100 (expect FK violation, same error as a missing parent):'
begin; set local role app_rt; select set_config('app.tenant_id','22222222-2222-4222-8222-222222222222',true); insert into child_comp values ('22222222-2222-4222-8222-222222222222',1,100); rollback;
\echo '-- (g) composite FK, B child -> B parent 200 (expect success):'
begin; set local role app_rt; select set_config('app.tenant_id','22222222-2222-4222-8222-222222222222',true); insert into child_comp values ('22222222-2222-4222-8222-222222222222',1,200); rollback;

\echo '=== T4: views: owner bypass vs security_invoker ==='
-- view owned by bypass_t (BYPASSRLS) to model "view owner bypasses RLS"
set role migrator; grant create on schema public to bypass_t; reset role;
set role bypass_t;
create view v_plain as select * from orders;
create view v_invoker with (security_invoker = true) as select * from orders;
reset role;
grant select on v_plain, v_invoker to app_rt;
set role migrator;
create view v_owner_forced as select * from orders;   -- view owned by table owner with FORCE
grant select on v_owner_forced to app_rt;
reset role;
\echo '-- app_rt context=B: view owned by BYPASSRLS role, default (expect 3 = leak); same with security_invoker=true (expect 1); view owned by the forced table owner (expect 1)'
begin; set local role app_rt; select set_config('app.tenant_id','22222222-2222-4222-8222-222222222222',true);
 select count(*) as v_plain_owner_bypassrls from v_plain;
 select count(*) as v_invoker from v_invoker;
 select count(*) as v_owner_forced from v_owner_forced; rollback;
select c.relname, c.reloptions from pg_class c where c.relname in ('v_plain','v_invoker','v_owner_forced') order by 1;

\echo '=== T5: catalogue test: tenant tables lacking ENABLE+FORCE (deliberately broken tables added) ==='
set role migrator;
create table good_t (tenant_id uuid not null, id int); alter table good_t enable row level security; alter table good_t force row level security;
create policy p on good_t using (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);
create table bad_enable_only (tenant_id uuid not null, id int); alter table bad_enable_only enable row level security;
create table bad_none (tenant_id uuid not null, id int);
create table bad_force_nopolicy (tenant_id uuid not null, id int); alter table bad_force_nopolicy enable row level security; alter table bad_force_nopolicy force row level security;
create table global_ref (code text primary key);
reset role;
\echo '-- C1: tenant-keyed tables lacking ENABLE AND FORCE (expect bad_enable_only, bad_none):'
SELECT c.oid::regclass AS tbl, c.relrowsecurity, c.relforcerowsecurity
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' AND c.relkind IN ('r','p') AND NOT c.relispartition
  AND EXISTS (SELECT 1 FROM pg_attribute a WHERE a.attrelid = c.oid AND a.attname = 'tenant_id' AND a.attnum > 0 AND NOT a.attisdropped)
  AND NOT (c.relrowsecurity AND c.relforcerowsecurity) ORDER BY 1;
\echo '-- C2: tenant-keyed tables with no permissive policy for some command (expect bad_* and bad_force_nopolicy, 4 commands each)'
SELECT c.oid::regclass AS tbl, cmd.polcmd
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace CROSS JOIN (VALUES ('r'),('a'),('w'),('d')) AS cmd(polcmd)
WHERE n.nspname = 'public' AND c.relkind IN ('r','p') AND NOT c.relispartition
  AND EXISTS (SELECT 1 FROM pg_attribute a WHERE a.attrelid = c.oid AND a.attname = 'tenant_id' AND a.attnum > 0 AND NOT a.attisdropped)
  AND NOT EXISTS (SELECT 1 FROM pg_policy p WHERE p.polrelid = c.oid AND p.polpermissive AND p.polcmd IN (cmd.polcmd, '*')) ORDER BY 1,2;
\echo '-- C3: tables WITHOUT tenant_id (must equal the allowlist; expect global_ref only)'
SELECT c.relname FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' AND c.relkind IN ('r','p') AND NOT c.relispartition
  AND NOT EXISTS (SELECT 1 FROM pg_attribute a WHERE a.attrelid = c.oid AND a.attname = 'tenant_id' AND a.attnum > 0 AND NOT a.attisdropped) ORDER BY 1;
\echo '-- C4: roles that are superuser or BYPASSRLS (expect postgres, bypass_t) and runtime-role privilege/membership check (expect no rows second query)'
SELECT rolname, rolsuper, rolbypassrls, rolcanlogin FROM pg_roles WHERE rolsuper OR rolbypassrls ORDER BY 1;
SELECT r.rolname, 'attribute' AS why FROM pg_roles r WHERE r.rolname = 'app_rt' AND (r.rolsuper OR r.rolbypassrls OR r.rolcreaterole OR r.rolcreatedb OR r.rolreplication);
\echo '-- C5: relations in public NOT owned by migrator (expect none)'
SELECT c.oid::regclass, pg_get_userbyid(c.relowner) FROM pg_class c WHERE c.relnamespace='public'::regnamespace AND c.relkind IN ('r','p','S') AND pg_get_userbyid(c.relowner) <> 'migrator';
\echo '-- C8: views without security_invoker (accept on/true case-insensitively). Expect v_plain, v_owner_forced'
SELECT c.oid::regclass AS v FROM pg_class c WHERE c.relnamespace='public'::regnamespace AND c.relkind='v'
 AND NOT EXISTS (SELECT 1 FROM unnest(coalesce(c.reloptions, array[]::text[])) o WHERE lower(o) in ('security_invoker=true','security_invoker=on','security_invoker=1','security_invoker=yes')) ORDER BY 1;
