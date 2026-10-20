create table app.orders(id uuid primary key, tenant_id uuid not null references app.tenants(id));
