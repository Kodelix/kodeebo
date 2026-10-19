-- S20 seed, run as the container superuser (bypasses RLS). Tenants: A 1,000,000 orders; B 1,000 orders.
insert into app.orders (tenant_id, note) select '11111111-1111-4111-8111-111111111111', 'a' || g from generate_series(1, 1000000) g;
insert into app.orders (tenant_id, note) select '22222222-2222-4222-8222-222222222222', 'b' || g from generate_series(1, 1000) g;
insert into app.outbox (tenant_id, kind, ref)
  select v.t::uuid, 'receipt.issue', gen_random_uuid()
  from (values ('11111111-1111-4111-8111-111111111111'), ('22222222-2222-4222-8222-222222222222'), ('33333333-3333-4333-8333-333333333333')) v(t),
       generate_series(1, 10);
insert into app.tenant_status (tenant_id, status)
  values ('11111111-1111-4111-8111-111111111111', 'active'), ('22222222-2222-4222-8222-222222222222', 'active'),
         ('33333333-3333-4333-8333-333333333333', 'active');
insert into app.tenant_status (tenant_id, status)
  select ('00000000-0000-4000-8000-' || lpad(g::text, 12, '0'))::uuid, 'active' from generate_series(1, 200) g;
insert into app.sessions (token_hash, tenant_id, user_id) values
  ('tok-a1', '11111111-1111-4111-8111-111111111111', gen_random_uuid()),
  ('tok-a2', '11111111-1111-4111-8111-111111111111', gen_random_uuid()),
  ('tok-b1', '22222222-2222-4222-8222-222222222222', gen_random_uuid());
analyze;
select (select count(*) from app.orders) as orders, (select count(*) from app.outbox) as outbox, (select count(*) from app.tenant_status) as tenants;
