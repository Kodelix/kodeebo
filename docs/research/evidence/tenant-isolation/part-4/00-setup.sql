-- S40a setup: per-branch scoping on PostgreSQL 18.6. Run as superuser (postgres) in a throwaway container.
CREATE ROLE migrator NOLOGIN;
CREATE ROLE app_rt LOGIN PASSWORD 'ti_p4_throwaway' NOSUPERUSER NOBYPASSRLS NOCREATEROLE NOCREATEDB;
CREATE ROLE bypass_t LOGIN PASSWORD 'ti_p4_throwaway' BYPASSRLS;
CREATE SCHEMA s AUTHORIZATION migrator;
GRANT USAGE ON SCHEMA s TO app_rt, bypass_t;
GRANT CREATE ON SCHEMA s TO bypass_t;

SET ROLE migrator;
SET search_path = s;
CREATE TABLE tenants  (id uuid PRIMARY KEY, name text NOT NULL);
CREATE TABLE branches (id uuid PRIMARY KEY, tenant_id uuid NOT NULL REFERENCES tenants(id), name text NOT NULL, UNIQUE (tenant_id, id));
CREATE TABLE staff    (id uuid PRIMARY KEY, tenant_id uuid NOT NULL, role text NOT NULL CHECK (role IN ('owner','manager','cashier')), UNIQUE (tenant_id, id));
CREATE TABLE staff_branches (tenant_id uuid NOT NULL, staff_id uuid NOT NULL, branch_id uuid NOT NULL,
  PRIMARY KEY (tenant_id, staff_id, branch_id),
  FOREIGN KEY (tenant_id, staff_id)  REFERENCES staff(tenant_id, id),
  FOREIGN KEY (tenant_id, branch_id) REFERENCES branches(tenant_id, id));
CREATE TABLE items (id uuid PRIMARY KEY, tenant_id uuid NOT NULL, name text NOT NULL);       -- tenant-wide catalogue, not branch-scoped
CREATE TABLE bills (id uuid PRIMARY KEY, tenant_id uuid NOT NULL, branch_id uuid NOT NULL, total numeric NOT NULL, created_at timestamptz NOT NULL,
  UNIQUE (tenant_id, branch_id, id), FOREIGN KEY (tenant_id, branch_id) REFERENCES branches(tenant_id, id));
CREATE TABLE bills_v2 (LIKE bills INCLUDING ALL);   -- same shape, scope derived in the database from staff_branches
ALTER TABLE bills_v2 ADD FOREIGN KEY (tenant_id, branch_id) REFERENCES branches(tenant_id, id);
CREATE TABLE bill_lines (tenant_id uuid NOT NULL, branch_id uuid NOT NULL, bill_id uuid NOT NULL, line_no int NOT NULL, amount numeric NOT NULL,
  PRIMARY KEY (bill_id, line_no), FOREIGN KEY (tenant_id, branch_id, bill_id) REFERENCES bills(tenant_id, branch_id, id));
CREATE INDEX ON bills (tenant_id, branch_id, created_at);
CREATE INDEX ON bills_v2 (tenant_id, branch_id, created_at);

-- RLS: tenant policy PERMISSIVE, branch policy RESTRICTIVE (ANDed), both for ALL commands; WITH CHECK omitted -> USING is used.
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['branches','staff','staff_branches','items','bills','bills_v2','bill_lines'] LOOP
    EXECUTE format('ALTER TABLE s.%I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('ALTER TABLE s.%I FORCE ROW LEVEL SECURITY', t);
  END LOOP;
END $$;
-- branches/staff/items/bills_*: tenant policy. (tenants has no tenant_id; not RLS here)
CREATE POLICY t_branches ON branches FOR ALL TO app_rt USING (tenant_id = NULLIF(current_setting('app.tenant_id', true),'')::uuid);
CREATE POLICY t_staff    ON staff    FOR ALL TO app_rt USING (tenant_id = NULLIF(current_setting('app.tenant_id', true),'')::uuid);
CREATE POLICY t_items    ON items    FOR ALL TO app_rt USING (tenant_id = NULLIF(current_setting('app.tenant_id', true),'')::uuid);
-- staff_branches: everyone in tenant reads; only actor_role=owner writes (defence in depth; the setting is app-set)
CREATE POLICY t_sb_sel ON staff_branches FOR SELECT TO app_rt USING (tenant_id = NULLIF(current_setting('app.tenant_id', true),'')::uuid);
CREATE POLICY t_sb_mod ON staff_branches FOR ALL    TO app_rt USING (tenant_id = NULLIF(current_setting('app.tenant_id', true),'')::uuid AND current_setting('app.actor_role', true) = 'owner');
-- bills (variant 1): scope carried in a transaction-local setting: 'on' for all branches of the tenant, else comma list of branch uuids
CREATE POLICY t_bills ON bills AS PERMISSIVE FOR ALL TO app_rt USING (tenant_id = NULLIF(current_setting('app.tenant_id', true),'')::uuid);
CREATE POLICY b_bills ON bills AS RESTRICTIVE FOR ALL TO app_rt USING (
  current_setting('app.branch_all', true) = 'on'
  OR branch_id = ANY (string_to_array(NULLIF(current_setting('app.branch_ids', true),''), ',')::uuid[]));
CREATE POLICY t_bill_lines ON bill_lines AS PERMISSIVE FOR ALL TO app_rt USING (tenant_id = NULLIF(current_setting('app.tenant_id', true),'')::uuid);
CREATE POLICY b_bill_lines ON bill_lines AS RESTRICTIVE FOR ALL TO app_rt USING (
  current_setting('app.branch_all', true) = 'on'
  OR branch_id = ANY (string_to_array(NULLIF(current_setting('app.branch_ids', true),''), ',')::uuid[]));
-- bills_v2 (variant 2): scope derived inside the database from the staff assignment table and app.staff_id
CREATE POLICY t_bills2 ON bills_v2 AS PERMISSIVE FOR ALL TO app_rt USING (tenant_id = NULLIF(current_setting('app.tenant_id', true),'')::uuid);
CREATE POLICY b_bills2 ON bills_v2 AS RESTRICTIVE FOR ALL TO app_rt USING (
  current_setting('app.branch_all', true) = 'on'
  OR branch_id IN (SELECT sb.branch_id FROM s.staff_branches sb
                   WHERE sb.tenant_id = bills_v2.tenant_id
                     AND sb.staff_id = NULLIF(current_setting('app.staff_id', true),'')::uuid));
-- reporting views
CREATE VIEW report_branch_totals WITH (security_invoker = true) AS
  SELECT tenant_id, branch_id, count(*) AS n, sum(total) AS total FROM bills GROUP BY tenant_id, branch_id;
CREATE VIEW report_plain AS
  SELECT tenant_id, branch_id, count(*) AS n, sum(total) AS total FROM bills GROUP BY tenant_id, branch_id;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA s TO app_rt;
GRANT SELECT ON bills TO bypass_t;
RESET ROLE;

-- seed as superuser (bypasses RLS). ids end in a readable hex tail.
INSERT INTO tenants VALUES ('00000000-0000-0000-0000-00000000000a','Chain A'), ('00000000-0000-0000-0000-00000000000b','Venue B');
INSERT INTO branches VALUES
 ('00000000-0000-0000-0000-0000000000a1','00000000-0000-0000-0000-00000000000a','A1'),
 ('00000000-0000-0000-0000-0000000000a2','00000000-0000-0000-0000-00000000000a','A2'),
 ('00000000-0000-0000-0000-0000000000a3','00000000-0000-0000-0000-00000000000a','A3'),
 ('00000000-0000-0000-0000-0000000000b1','00000000-0000-0000-0000-00000000000b','B1');
INSERT INTO staff VALUES
 ('00000000-0000-0000-0000-0000000005a0','00000000-0000-0000-0000-00000000000a','owner'),
 ('00000000-0000-0000-0000-0000000005a1','00000000-0000-0000-0000-00000000000a','manager'),
 ('00000000-0000-0000-0000-0000000005a2','00000000-0000-0000-0000-00000000000a','manager'),
 ('00000000-0000-0000-0000-0000000005a3','00000000-0000-0000-0000-00000000000a','cashier'),
 ('00000000-0000-0000-0000-0000000005b0','00000000-0000-0000-0000-00000000000b','owner');
INSERT INTO staff_branches VALUES
 ('00000000-0000-0000-0000-00000000000a','00000000-0000-0000-0000-0000000005a1','00000000-0000-0000-0000-0000000000a1'),
 ('00000000-0000-0000-0000-00000000000a','00000000-0000-0000-0000-0000000005a2','00000000-0000-0000-0000-0000000000a1'),
 ('00000000-0000-0000-0000-00000000000a','00000000-0000-0000-0000-0000000005a2','00000000-0000-0000-0000-0000000000a2'),
 ('00000000-0000-0000-0000-00000000000a','00000000-0000-0000-0000-0000000005a3','00000000-0000-0000-0000-0000000000a1');
INSERT INTO items SELECT gen_random_uuid(), '00000000-0000-0000-0000-00000000000a', 'item-'||g FROM generate_series(1,10) g;
INSERT INTO items SELECT gen_random_uuid(), '00000000-0000-0000-0000-00000000000b', 'item-'||g FROM generate_series(1,4) g;
-- 5000 bills per branch (3 branches of A, 1 of B) in both variants
INSERT INTO bills SELECT gen_random_uuid(), b.tenant_id, b.id, (g % 90) + 10, now() - (g || ' minutes')::interval FROM branches b, generate_series(1,5000) g;
INSERT INTO bills_v2 SELECT * FROM bills;
INSERT INTO bill_lines SELECT tenant_id, branch_id, id, 1, total FROM bills WHERE tenant_id='00000000-0000-0000-0000-00000000000a' LIMIT 20;
ANALYZE;
-- a materialized view created by a BYPASSRLS owner (a plausible reporting-job mistake)
SET ROLE bypass_t;
SET search_path = s;
CREATE MATERIALIZED VIEW mv_branch_totals AS SELECT tenant_id, branch_id, count(*) AS n, sum(total) AS total FROM bills GROUP BY tenant_id, branch_id;
RESET ROLE;
GRANT SELECT ON s.mv_branch_totals TO app_rt;
