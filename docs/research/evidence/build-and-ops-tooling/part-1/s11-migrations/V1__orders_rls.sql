SET lock_timeout = '5s';
CREATE TABLE app.orders (tenant_id uuid NOT NULL, id uuid PRIMARY KEY, note text);
ALTER TABLE app.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.orders FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON app.orders AS RESTRICTIVE
  USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);
CREATE POLICY app_rt_all ON app.orders AS PERMISSIVE FOR ALL TO app_rt USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON app.orders TO app_rt;
