-- S20 setup (throwaway container bt2-pg, postgres:18.6). No real data, throwaway passwords.
-- Shape follows ADR-0001: restrictive tenant policy + one permissive policy per role; PL table reachable
-- only through SECURITY DEFINER functions owned by auth_lookup (NOLOGIN); CP table read by platform_rt.
create role migrator nologin;
create role auth_lookup nologin;
create role app_rt login password 'bt2_throwaway' nosuperuser nobypassrls;
create role job_rt login password 'bt2_throwaway' nosuperuser nobypassrls;
create role platform_rt login password 'bt2_throwaway' nosuperuser nobypassrls;
create schema app authorization migrator;
create schema auth authorization auth_lookup;
grant usage on schema app to app_rt, job_rt, platform_rt, auth_lookup;
grant usage on schema auth to app_rt, job_rt;
alter role app_rt set search_path = app, pg_catalog;
alter role job_rt set search_path = app, pg_catalog;
alter role platform_rt set search_path = app, pg_catalog;

set role migrator;
create table app.orders (id bigserial primary key, tenant_id uuid not null, note text not null);
create table app.outbox (id bigserial primary key, tenant_id uuid not null, kind text not null, ref uuid not null,
                         attempts int not null default 0, processed_at timestamptz);
create table app.inbox_dedup (tenant_id uuid not null, message_id text not null, primary key (tenant_id, message_id));
create table app.sessions (token_hash text primary key, tenant_id uuid not null, user_id uuid not null);   -- class PL
create table app.tenant_status (tenant_id uuid primary key, status text not null);                          -- class CP

do $$ declare t text; begin
  foreach t in array array['orders','outbox','inbox_dedup','sessions','tenant_status'] loop
    execute format('alter table app.%I enable row level security', t);
    execute format('alter table app.%I force row level security', t);
  end loop; end $$;

-- restrictive tenant predicate (TD: every role; PL and CP: every runtime role except the lookup / platform role)
create policy tenant_isolation on app.orders as restrictive for all
  using (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid)
  with check (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);
create policy tenant_isolation on app.outbox as restrictive for all
  using (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid)
  with check (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);
create policy tenant_isolation on app.inbox_dedup as restrictive for all
  using (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid)
  with check (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);
create policy tenant_isolation on app.sessions as restrictive for all to app_rt, job_rt, platform_rt
  using (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid)
  with check (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);
create policy tenant_isolation on app.tenant_status as restrictive for all to app_rt, job_rt
  using (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid)
  with check (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);

-- one permissive policy per role (no USING (true) on tenant tables)
create policy p_app on app.orders as permissive for all to app_rt using (tenant_id is not null) with check (tenant_id is not null);
create policy p_job on app.orders as permissive for all to job_rt using (tenant_id is not null) with check (tenant_id is not null);
create policy p_app on app.outbox as permissive for all to app_rt using (tenant_id is not null) with check (tenant_id is not null);
create policy p_job on app.outbox as permissive for all to job_rt using (tenant_id is not null) with check (tenant_id is not null);
create policy p_job on app.inbox_dedup as permissive for all to job_rt using (tenant_id is not null) with check (tenant_id is not null);
create policy p_app on app.sessions as permissive for select to app_rt using (tenant_id is not null);
create policy p_auth on app.sessions as permissive for all to auth_lookup using (true) with check (true);
create policy p_plat on app.tenant_status as permissive for all to platform_rt using (true) with check (true);
reset role;

grant select, insert on app.orders, app.outbox to app_rt;
grant select, insert, update, delete on app.orders, app.outbox, app.inbox_dedup to job_rt;
grant select on app.tenant_status to job_rt, platform_rt;
grant select on app.sessions to app_rt;
grant select, delete on app.sessions to auth_lookup;
grant usage on all sequences in schema app to app_rt, job_rt;

set role auth_lookup;
create function auth.session_lookup(p_hash text) returns table (tenant_id uuid, user_id uuid)
  language sql stable security definer set search_path = pg_catalog, app
  as $$ select s.tenant_id, s.user_id from app.sessions s where s.token_hash = p_hash $$;
create function auth.closure_end_sessions() returns bigint
  language plpgsql security definer set search_path = pg_catalog, app
  as $$
  declare t uuid := nullif(current_setting('app.tenant_id', true), '')::uuid; n bigint;
  begin
    if t is null then raise exception 'no tenant context' using errcode = '42501'; end if;
    delete from app.sessions where tenant_id = t;
    get diagnostics n = row_count;
    return n;
  end $$;
reset role;
revoke execute on all functions in schema auth from public;
grant execute on function auth.session_lookup(text) to app_rt;
grant execute on function auth.closure_end_sessions() to job_rt;

select rolname, rolsuper, rolbypassrls from pg_roles where rolname in ('app_rt','job_rt','platform_rt','migrator','auth_lookup') order by 1;
