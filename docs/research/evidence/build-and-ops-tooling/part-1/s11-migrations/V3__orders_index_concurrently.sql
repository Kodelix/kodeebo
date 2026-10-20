CREATE INDEX CONCURRENTLY orders_tenant_idx ON app.orders (tenant_id, id);
