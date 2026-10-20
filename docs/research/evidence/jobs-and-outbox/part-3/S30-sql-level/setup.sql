-- S30 setup (throwaway container jo3-pg, postgres:18.6). No real data, throwaway passwords.
-- Shape reused from docs/research/evidence/backend-track-part-2/S20-go-pgx/setup.sql (ADR-0001: restrictive tenant policy
-- + one permissive policy per role). Changes for this note: outbox gets a traceparent column; a TD "effects" table stands
-- in for the business effect; no PL table, no SECURITY DEFINER functions (not needed for the claim and sweep).
create role migrator nologin;
create role app_rt login password :'pgpw' nosuperuser nobypassrls;
create role job_rt login password :'pgpw' nosuperuser nobypassrls;
create role platform_rt login password :'pgpw' nosuperuser nobypassrls;
create schema app authorization migrator;
grant usage on schema app to app_rt, job_rt, platform_rt;
alter role app_rt set search_path = app, pg_catalog;
alter role job_rt set search_path = app, pg_catalog;
alter role platform_rt set search_path = app, pg_catalog;

set role migrator;
create table app.outbox (id bigserial primary key, tenant_id uuid not null, kind text not null, ref uuid not null,
                         traceparent text, attempts int not null default 0, processed_at timestamptz);
create table app.inbox_dedup (tenant_id uuid not null, message_id text not null, primary key (tenant_id, message_id));
create table app.effects (id bigserial primary key, tenant_id uuid not null, note text not null);
create table app.tenant_status (tenant_id uuid primary key, status text not null);   -- class CP

do $$ declare t text; begin
  foreach t in array array['outbox','inbox_dedup','effects','tenant_status'] loop
    execute format('alter table app.%I enable row level security', t);
    execute format('alter table app.%I force row level security', t);
  end loop; end $$;

create policy tenant_isolation on app.outbox as restrictive for all
  using (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid)
  with check (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);
create policy tenant_isolation on app.inbox_dedup as restrictive for all
  using (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid)
  with check (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);
create policy tenant_isolation on app.effects as restrictive for all
  using (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid)
  with check (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);
create policy tenant_isolation on app.tenant_status as restrictive for all to app_rt, job_rt
  using (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid)
  with check (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

create policy p_app on app.outbox as permissive for all to app_rt using (tenant_id is not null) with check (tenant_id is not null);
create policy p_job on app.outbox as permissive for all to job_rt using (tenant_id is not null) with check (tenant_id is not null);
create policy p_job on app.inbox_dedup as permissive for all to job_rt using (tenant_id is not null) with check (tenant_id is not null);
create policy p_job on app.effects as permissive for all to job_rt using (tenant_id is not null) with check (tenant_id is not null);
create policy p_plat on app.tenant_status as permissive for all to platform_rt using (true) with check (true);
reset role;

grant select, insert on app.outbox to app_rt;
grant select, insert, update, delete on app.outbox, app.inbox_dedup, app.effects to job_rt;
grant select on app.tenant_status to job_rt, platform_rt;
grant usage on all sequences in schema app to app_rt, job_rt;

select rolname, rolsuper, rolbypassrls from pg_roles where rolname in ('app_rt','job_rt','platform_rt','migrator') order by 1;
