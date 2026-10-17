-- S70 setup: operator-access mechanisms at PostgreSQL 18.6 (tier E). Run as the bootstrap superuser against database postgres.
-- Test fixtures only: every credential here is a throw-away fixture inside a throw-away container.
\set ON_ERROR_STOP off
SELECT version();
CREATE ROLE migrator NOLOGIN;
CREATE ROLE audit_writer NOLOGIN;
CREATE ROLE support_fn NOLOGIN;
CREATE ROLE app_rt LOGIN PASSWORD 'fixture' NOSUPERUSER NOBYPASSRLS;
CREATE ROLE support_rt LOGIN PASSWORD 'fixture' NOSUPERUSER NOBYPASSRLS;
CREATE ROLE support_ro LOGIN PASSWORD 'fixture' NOSUPERUSER NOBYPASSRLS;
GRANT pg_read_all_data TO support_ro;
CREATE ROLE support_exp LOGIN PASSWORD 'fixture' VALID UNTIL '2020-01-01';
CREATE ROLE backup_rt LOGIN PASSWORD 'fixture' REPLICATION NOSUPERUSER NOBYPASSRLS;
CREATE DATABASE p7 OWNER migrator;
\c p7 postgres
SET ROLE migrator;
CREATE TABLE orders(tenant_id uuid NOT NULL, id int NOT NULL, total int, note text, PRIMARY KEY (tenant_id, id));
ALTER TABLE orders ENABLE ROW LEVEL SECURITY; ALTER TABLE orders FORCE ROW LEVEL SECURITY;
CREATE TABLE global_ref(code text PRIMARY KEY);
CREATE TABLE support_grants(id serial PRIMARY KEY, tenant_id uuid NOT NULL, operator_id text NOT NULL,
  scope text NOT NULL CHECK (scope IN ('read','write')), granted_by text NOT NULL,
  expires_at timestamptz NOT NULL, revoked_at timestamptz);
ALTER TABLE support_grants ENABLE ROW LEVEL SECURITY; ALTER TABLE support_grants FORCE ROW LEVEL SECURITY;
CREATE TABLE support_audit(seq bigserial PRIMARY KEY, at timestamptz NOT NULL DEFAULT clock_timestamp(),
  operator_id text, tenant_id uuid NOT NULL, grant_id int, action text, detail text, prev_hash bytea, hash bytea);
ALTER TABLE support_audit ENABLE ROW LEVEL SECURITY; ALTER TABLE support_audit FORCE ROW LEVEL SECURITY;
RESET ROLE;
-- tenant policy for the runtime role
CREATE POLICY app_tenant ON orders FOR ALL TO app_rt
  USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid)
  WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);
-- support read policy: tenant context AND a live grant for (tenant, operator)
CREATE POLICY support_read ON orders FOR SELECT TO support_rt, support_fn
  USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid
         AND EXISTS (SELECT 1 FROM support_grants g
                     WHERE g.tenant_id = orders.tenant_id
                       AND g.operator_id = NULLIF(current_setting('app.operator_id', true), '')
                       AND g.scope IN ('read','write') AND g.expires_at > now() AND g.revoked_at IS NULL));
-- grants: owner side (app_rt, tenant context) creates and revokes; support side sees only its own rows
CREATE POLICY grants_owner_sel ON support_grants FOR SELECT TO app_rt USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);
CREATE POLICY grants_owner_ins ON support_grants FOR INSERT TO app_rt WITH CHECK (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);
CREATE POLICY grants_owner_upd ON support_grants FOR UPDATE TO app_rt USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);
CREATE POLICY grants_support_sel ON support_grants FOR SELECT TO support_rt, support_fn USING (operator_id = NULLIF(current_setting('app.operator_id', true), ''));
-- audit: support appends, owner reads its own tenant's rows, nobody updates or deletes
CREATE POLICY audit_ins ON support_audit FOR INSERT TO support_rt, support_fn WITH CHECK (true);
CREATE POLICY audit_owner_sel ON support_audit FOR SELECT TO app_rt USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid);
CREATE POLICY audit_chain_sel ON support_audit FOR SELECT TO audit_writer USING (true);
GRANT SELECT, INSERT, UPDATE, DELETE ON orders TO app_rt;
GRANT SELECT ON orders TO support_rt, support_fn;
GRANT SELECT, INSERT ON support_grants TO app_rt; GRANT UPDATE (revoked_at) ON support_grants TO app_rt;
GRANT USAGE ON SEQUENCE support_grants_id_seq TO app_rt;
GRANT SELECT ON support_grants TO support_rt, support_fn;
GRANT INSERT ON support_audit TO support_rt, support_fn; GRANT USAGE ON SEQUENCE support_audit_seq_seq TO support_rt, support_fn;
GRANT SELECT ON support_audit TO app_rt, audit_writer;
GRANT SELECT ON global_ref TO PUBLIC;
-- hash-chain trigger: per-tenant chain, written by a SECURITY DEFINER function owned by audit_writer
CREATE FUNCTION audit_chain() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public, pg_temp AS $$
DECLARE ph bytea;
BEGIN
  PERFORM pg_advisory_xact_lock(hashtext(NEW.tenant_id::text));
  SELECT hash INTO ph FROM public.support_audit WHERE tenant_id = NEW.tenant_id ORDER BY seq DESC LIMIT 1;
  NEW.prev_hash := ph;
  NEW.hash := sha256(convert_to(coalesce(encode(ph,'hex'),'') || '|' || NEW.seq || '|' || NEW.at::text || '|' ||
      coalesce(NEW.operator_id,'') || '|' || NEW.tenant_id::text || '|' || coalesce(NEW.action,'') || '|' || coalesce(NEW.detail,''), 'UTF8'));
  RETURN NEW;
END $$;
ALTER FUNCTION audit_chain() OWNER TO audit_writer;
CREATE TRIGGER support_audit_chain BEFORE INSERT ON support_audit FOR EACH ROW EXECUTE FUNCTION audit_chain();
CREATE FUNCTION audit_verify(p_tenant uuid) RETURNS bigint LANGUAGE plpgsql AS $$
DECLARE r record; ph bytea := NULL; h bytea;
BEGIN
  FOR r IN SELECT * FROM public.support_audit WHERE tenant_id = p_tenant ORDER BY seq LOOP
    h := sha256(convert_to(coalesce(encode(ph,'hex'),'') || '|' || r.seq || '|' || r.at::text || '|' ||
      coalesce(r.operator_id,'') || '|' || r.tenant_id::text || '|' || coalesce(r.action,'') || '|' || coalesce(r.detail,''), 'UTF8'));
    IF r.prev_hash IS DISTINCT FROM ph OR r.hash IS DISTINCT FROM h THEN RETURN r.seq; END IF;
    ph := r.hash;
  END LOOP;
  RETURN NULL;  -- NULL = chain intact
END $$;
-- one definer function per support action: read orders + append an audit row in the same transaction
CREATE FUNCTION support_orders_read(p_reason text) RETURNS SETOF orders LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, public, pg_temp AS $$
BEGIN
  INSERT INTO public.support_audit(operator_id, tenant_id, action, detail)
    VALUES (current_setting('app.operator_id', true), NULLIF(current_setting('app.tenant_id', true), '')::uuid, 'orders.read', p_reason);
  RETURN QUERY SELECT * FROM public.orders;
END $$;
ALTER FUNCTION support_orders_read(text) OWNER TO support_fn;
-- data (inserted by the superuser; FORCE RLS does not apply to superusers)
INSERT INTO orders VALUES ('aaaaaaaa-0000-0000-0000-000000000001', 1, 100, 'SECRET-A-ROW-1'), ('aaaaaaaa-0000-0000-0000-000000000001', 2, 200, 'SECRET-A-ROW-2'),
                          ('bbbbbbbb-0000-0000-0000-000000000002', 1, 300, 'SECRET-B-ROW-1');
INSERT INTO global_ref VALUES ('g1'),('g2');
SELECT rolname, rolsuper, rolbypassrls, rolreplication, rolvaliduntil FROM pg_roles WHERE rolname IN ('app_rt','support_rt','support_ro','support_exp','backup_rt','support_fn','audit_writer','migrator') ORDER BY 1;
SELECT has_function_privilege('app_rt', 'support_orders_read(text)', 'EXECUTE') AS app_rt_can_execute_before_revoke;
REVOKE ALL ON FUNCTION support_orders_read(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION support_orders_read(text) TO support_rt;
SELECT has_function_privilege('app_rt', 'support_orders_read(text)', 'EXECUTE') AS app_rt_can_execute_after_revoke,
       has_function_privilege('support_rt', 'support_orders_read(text)', 'EXECUTE') AS support_rt_can_execute;
