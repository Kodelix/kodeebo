# ---- call 1 (roles, D1 migration order) ----
docker exec kodeebo-catalogue-spike-pg psql -U postgres -X -q -c "CREATE DATABASE s52"
docker exec -i kodeebo-catalogue-spike-pg psql -U postgres -X -q -d s52 -v ON_ERROR_STOP=1 <<'SQL'
-- S52 setup: ADR-0001 shape: one schema, migrator NOLOGIN owns every table, runtime role without BYPASSRLS
CREATE ROLE migrator NOLOGIN;
CREATE ROLE app_rt NOLOGIN NOBYPASSRLS;
GRANT USAGE, CREATE ON SCHEMA public TO migrator;
GRANT USAGE ON SCHEMA public TO app_rt;
SQL
mig() { echo "-- $1"; docker exec -i kodeebo-catalogue-spike-pg psql -U postgres -X -q -d s52 -v ON_ERROR_STOP=1 -1 2>&1 | sed 's/^/   /'; echo "   rc=${pipestatus[1]}"; }
mig "D1a migration catalogue:0001 applied BEFORE inventory:0001 (expect failure: referenced table missing)" <<'SQL'
SET ROLE migrator;
CREATE TABLE variant (tenant_id uuid NOT NULL, id bigint NOT NULL, PRIMARY KEY (tenant_id, id));
CREATE TABLE variant_stock_link (tenant_id uuid NOT NULL, variant_id bigint NOT NULL, stock_item_id bigint NOT NULL, qty_base bigint NOT NULL CHECK (qty_base > 0),
  PRIMARY KEY (tenant_id, variant_id, stock_item_id),
  FOREIGN KEY (tenant_id, variant_id) REFERENCES variant (tenant_id, id),
  FOREIGN KEY (tenant_id, stock_item_id) REFERENCES stock_item (tenant_id, id) ON DELETE RESTRICT);
SQL
mig "D1b inventory:0001 first (expect ok)" <<'SQL'
SET ROLE migrator;
CREATE TABLE stock_item (tenant_id uuid NOT NULL, id bigint NOT NULL, name text NOT NULL, PRIMARY KEY (tenant_id, id));
ALTER TABLE stock_item ENABLE ROW LEVEL SECURITY, FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON stock_item AS RESTRICTIVE FOR ALL
  USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
  WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);
CREATE POLICY app_rt_all ON stock_item FOR ALL TO app_rt USING (true) WITH CHECK (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON stock_item TO app_rt;
SQL
mig "D1c catalogue:0001 after inventory (expect ok; same SQL as D1a plus RLS)" <<'SQL'
SET ROLE migrator;
CREATE TABLE variant (tenant_id uuid NOT NULL, id bigint NOT NULL, PRIMARY KEY (tenant_id, id));
CREATE TABLE variant_stock_link (tenant_id uuid NOT NULL, variant_id bigint NOT NULL, stock_item_id bigint NOT NULL, qty_base bigint NOT NULL CHECK (qty_base > 0),
  PRIMARY KEY (tenant_id, variant_id, stock_item_id),
  FOREIGN KEY (tenant_id, variant_id) REFERENCES variant (tenant_id, id),
  FOREIGN KEY (tenant_id, stock_item_id) REFERENCES stock_item (tenant_id, id) ON DELETE RESTRICT);
-- contrast table only: a single-column FK on id, which ADR-0001 forbids
CREATE TABLE stock_item_bad_unique (id bigint PRIMARY KEY);
CREATE TABLE variant_stock_link_single (tenant_id uuid NOT NULL, variant_id bigint NOT NULL, stock_item_id bigint NOT NULL REFERENCES stock_item_bad_unique (id));
DO $$ DECLARE t text; BEGIN
  FOREACH t IN ARRAY ARRAY['variant','variant_stock_link','stock_item_bad_unique','variant_stock_link_single'] LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY, FORCE ROW LEVEL SECURITY', t);
    IF t <> 'stock_item_bad_unique' THEN
      EXECUTE format($p$CREATE POLICY tenant_isolation ON %I AS RESTRICTIVE FOR ALL USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)$p$, t);
    END IF;
    EXECUTE format('CREATE POLICY app_rt_all ON %I FOR ALL TO app_rt USING (true) WITH CHECK (true)', t);
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON %I TO app_rt', t);
  END LOOP; END $$;
SQL
docker exec kodeebo-catalogue-spike-pg psql -U postgres -X -q -d s52 -c "\dt"
# ---- call 2 (contrast table, second runtime role, seed) ----
docker exec -i kodeebo-catalogue-spike-pg psql -U postgres -X -q -d s52 -v ON_ERROR_STOP=1 -1 <<'SQL'
SET ROLE migrator;
-- contrast only: what an id-only key would allow (ADR-0001 forbids it)
ALTER TABLE stock_item ADD CONSTRAINT stock_item_id_only UNIQUE (id);
CREATE TABLE link_id_only (tenant_id uuid NOT NULL, variant_id bigint NOT NULL, stock_item_id bigint NOT NULL REFERENCES stock_item (id));
ALTER TABLE link_id_only ENABLE ROW LEVEL SECURITY, FORCE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON link_id_only AS RESTRICTIVE FOR ALL USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid) WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);
CREATE POLICY app_rt_all ON link_id_only FOR ALL TO app_rt USING (true) WITH CHECK (true);
GRANT SELECT, INSERT ON link_id_only TO app_rt;
RESET ROLE;
-- a second runtime role that was never granted anything on stock_item
CREATE ROLE catalogue_rt NOLOGIN NOBYPASSRLS;
GRANT USAGE ON SCHEMA public TO catalogue_rt;
SET ROLE migrator;
CREATE POLICY catalogue_rt_all ON variant FOR ALL TO catalogue_rt USING (true) WITH CHECK (true);
CREATE POLICY catalogue_rt_all ON variant_stock_link FOR ALL TO catalogue_rt USING (true) WITH CHECK (true);
GRANT SELECT, INSERT ON variant, variant_stock_link TO catalogue_rt;
RESET ROLE;
-- seed as the bootstrap superuser (bypasses RLS): tenant A owns stock 1, 2 and variant 1; tenant B owns stock 901
INSERT INTO stock_item VALUES ('00000000-0000-0000-0000-00000000000a', 1, 'coffee beans'), ('00000000-0000-0000-0000-00000000000a', 2, 'milk'), ('00000000-0000-0000-0000-00000000000b', 901, 'b item');
INSERT INTO variant VALUES ('00000000-0000-0000-0000-00000000000a', 1);
SQL
echo "seed rc=$?"
# ---- call 3 (D2-D7 as runtime roles) ----
as() { echo "-- $2"; docker exec kodeebo-catalogue-spike-pg psql -U postgres -X -q -A -t -d s52 -v ON_ERROR_STOP=0 -c "SET ROLE $1" -c "SELECT set_config('app.tenant_id', '00000000-0000-0000-0000-00000000000a', false) IS NULL" -c "$3" 2>&1 | grep -v '^f$' | sed 's/^/   /'; }
as app_rt "D2 tenant A links its variant 1 to its own stock item 1 (expect ok)" "INSERT INTO variant_stock_link VALUES ('00000000-0000-0000-0000-00000000000a', 1, 1, 18000) RETURNING 'inserted'"
as app_rt "D3 tenant A links to tenant B's stock id 901, composite FK (expect refused)" "INSERT INTO variant_stock_link VALUES ('00000000-0000-0000-0000-00000000000a', 1, 901, 1)"
as app_rt "D3b tenant A links to nonexistent id 902, composite FK (expect refused, same message shape as D3)" "INSERT INTO variant_stock_link VALUES ('00000000-0000-0000-0000-00000000000a', 1, 902, 1)"
as app_rt "D4 contrast, id-only FK: tenant A links to B's 901 under FORCE RLS" "INSERT INTO link_id_only VALUES ('00000000-0000-0000-0000-00000000000a', 1, 901) RETURNING 'inserted: cross-tenant link stored'"
as app_rt "D4b contrast, id-only FK: nonexistent 902" "INSERT INTO link_id_only VALUES ('00000000-0000-0000-0000-00000000000a', 1, 902)"
as app_rt "D4c tenant A sees B's row 901? (count)" "SELECT count(*) FROM stock_item WHERE id = 901"
as catalogue_rt "D6 role with no privilege on stock_item: SELECT stock_item (expect permission denied)" "SELECT count(*) FROM stock_item"
as catalogue_rt "D6b same role inserts variant 2 + link to A's stock 1 (expect ok: RI check runs as owner)" "WITH v AS (INSERT INTO variant VALUES ('00000000-0000-0000-0000-00000000000a', 2) RETURNING id) INSERT INTO variant_stock_link SELECT '00000000-0000-0000-0000-00000000000a', id, 1, 250 FROM v RETURNING 'inserted'"
as catalogue_rt "D6c same role links to nonexistent 902 (expect refused by FK)" "INSERT INTO variant_stock_link VALUES ('00000000-0000-0000-0000-00000000000a', 2, 902, 250)"
as app_rt "D7 tenant A writes a link row tagged with tenant B (expect refused by WITH CHECK)" "INSERT INTO variant_stock_link VALUES ('00000000-0000-0000-0000-00000000000b', 1, 901, 1)"
