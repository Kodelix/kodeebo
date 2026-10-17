-- S21 setup (throwaway container ti-p2-pg, postgres:18.6). No real data, throwaway password.
create role migrator nologin;
create role app_rt login password 'ti_p2_throwaway' nosuperuser nobypassrls;
create schema app authorization migrator;
set role migrator;
create table app.orders (id bigserial primary key, tenant_id uuid not null, note text not null);
alter table app.orders enable row level security;
alter table app.orders force row level security;
create policy tenant_iso on app.orders
  using      (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid)
  with check (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);
reset role;
grant usage on schema app to app_rt;
grant select, insert, update, delete on app.orders to app_rt;
grant usage on sequence app.orders_id_seq to app_rt;
alter role app_rt set search_path = app;
-- seed as superuser (bypasses RLS): tenant A = 3 rows, tenant B = 5 rows
insert into app.orders (tenant_id, note)
  select '11111111-1111-4111-8111-111111111111', 'a' || g from generate_series(1,3) g;
insert into app.orders (tenant_id, note)
  select '22222222-2222-4222-8222-222222222222', 'b' || g from generate_series(1,5) g;
select rolname, rolsuper, rolbypassrls from pg_roles where rolname in ('app_rt','migrator') order by 1;
