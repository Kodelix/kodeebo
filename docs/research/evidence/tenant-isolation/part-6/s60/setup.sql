-- S60 setup: roles, schema, five tables (3 correct, 3 deliberate defects), one leaking view
CREATE ROLE kodeebo_owner LOGIN NOBYPASSRLS;
CREATE ROLE kodeebo_app   LOGIN NOBYPASSRLS;
CREATE SCHEMA app AUTHORIZATION kodeebo_owner;
GRANT USAGE ON SCHEMA app TO kodeebo_app;
SET ROLE kodeebo_owner;
CREATE TABLE app.orders  (id int PRIMARY KEY, tenant_id uuid NOT NULL, branch_id uuid NOT NULL, total int);   -- correct: ENABLE + FORCE + policy
CREATE TABLE app.items   (id int PRIMARY KEY, tenant_id uuid NOT NULL, name text);                           -- defect 1: ENABLE without FORCE
CREATE TABLE app.notes   (id int PRIMARY KEY, tenant_id uuid NOT NULL, body text);                           -- defect 2: no RLS at all
CREATE TABLE app.locked  (id int PRIMARY KEY, tenant_id uuid NOT NULL);                                      -- ENABLE + FORCE, no policy (deny all)
CREATE TABLE app.cash    (id int PRIMARY KEY, tenant_id uuid NOT NULL, branch_id uuid NOT NULL, amount int); -- correct: tenant AND branch policy
ALTER TABLE app.orders ENABLE ROW LEVEL SECURITY; ALTER TABLE app.orders FORCE ROW LEVEL SECURITY;
ALTER TABLE app.items  ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.locked ENABLE ROW LEVEL SECURITY; ALTER TABLE app.locked FORCE ROW LEVEL SECURITY;
ALTER TABLE app.cash   ENABLE ROW LEVEL SECURITY; ALTER TABLE app.cash FORCE ROW LEVEL SECURITY;
CREATE POLICY t ON app.orders USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid)
                              WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);
CREATE POLICY t ON app.items  USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid)
                              WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid);
CREATE POLICY tb ON app.cash  USING (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid
                                     AND branch_id = nullif(current_setting('app.branch_id', true), '')::uuid)
                              WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true), '')::uuid
                                     AND branch_id = nullif(current_setting('app.branch_id', true), '')::uuid);
-- a reporting view WITHOUT security_invoker (default): runs with the view owner's rights
CREATE VIEW app.items_report AS SELECT tenant_id, count(*) AS n FROM app.items GROUP BY tenant_id;
CREATE VIEW app.items_report_safe WITH (security_invoker = true) AS SELECT tenant_id, count(*) AS n FROM app.items GROUP BY tenant_id;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA app TO kodeebo_app;
RESET ROLE;
-- seed as superuser (bypasses RLS): tenants A=...a, B=...b; branches 1 and 2 of tenant A
INSERT INTO app.orders VALUES (1,'aaaaaaaa-0000-0000-0000-00000000000a','b1000000-0000-0000-0000-000000000001',10),
                              (2,'bbbbbbbb-0000-0000-0000-00000000000b','b2000000-0000-0000-0000-000000000002',20);
INSERT INTO app.items  VALUES (1,'aaaaaaaa-0000-0000-0000-00000000000a','a-item'),(2,'bbbbbbbb-0000-0000-0000-00000000000b','b-item');
INSERT INTO app.notes  VALUES (1,'aaaaaaaa-0000-0000-0000-00000000000a','a-note'),(2,'bbbbbbbb-0000-0000-0000-00000000000b','b-note');
INSERT INTO app.locked VALUES (1,'aaaaaaaa-0000-0000-0000-00000000000a');
INSERT INTO app.cash   VALUES (1,'aaaaaaaa-0000-0000-0000-00000000000a','b1000000-0000-0000-0000-000000000001',100),
                              (2,'aaaaaaaa-0000-0000-0000-00000000000a','b2000000-0000-0000-0000-000000000002',200);
