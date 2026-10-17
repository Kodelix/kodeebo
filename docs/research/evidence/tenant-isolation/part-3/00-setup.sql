-- Part 3 evidence: schema for device binding + tenant-scoped sync state, PostgreSQL 18.6
-- Run as superuser in database ti_p3. Roles are NOLOGIN stand-ins for the real runtime roles (another part owns the role design).
\set ON_ERROR_STOP on
DROP SCHEMA IF EXISTS s CASCADE;
DO $$ DECLARE r text; BEGIN
  FOREACH r IN ARRAY ARRAY['ti_owner','ti_device','ti_dash','ti_ops','ti_auth'] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r) THEN EXECUTE format('CREATE ROLE %I NOLOGIN', r); END IF;
  END LOOP;
END $$;
CREATE SCHEMA s AUTHORIZATION ti_owner;
GRANT USAGE ON SCHEMA s TO ti_device, ti_dash, ti_ops, ti_auth;
SET ROLE ti_owner;
SET search_path = s, pg_catalog;

CREATE FUNCTION ctx(name text) RETURNS uuid LANGUAGE sql STABLE AS
  $$ SELECT NULLIF(current_setting('app.' || name, true), '')::uuid $$;

CREATE TABLE tenants  (id uuid PRIMARY KEY);
CREATE TABLE branches (tenant_id uuid NOT NULL REFERENCES tenants(id), id uuid NOT NULL, PRIMARY KEY (tenant_id, id));
CREATE TABLE devices (
  tenant_id uuid NOT NULL, id uuid NOT NULL, branch_id uuid NOT NULL,
  status text NOT NULL CHECK (status IN ('pending','active','revoked')),
  last_seen_at timestamptz, revoked_at timestamptz,
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, id, branch_id),
  FOREIGN KEY (tenant_id, branch_id) REFERENCES branches(tenant_id, id));
-- credential: key_id is a random opaque id (globally unique, carries no tenant meaning); public key only
CREATE TABLE device_credentials (
  key_id uuid PRIMARY KEY, tenant_id uuid NOT NULL, device_id uuid NOT NULL, branch_id uuid NOT NULL,
  alg text NOT NULL, public_key bytea NOT NULL,
  state text NOT NULL CHECK (state IN ('active','retired','revoked')),
  FOREIGN KEY (tenant_id, device_id, branch_id) REFERENCES devices(tenant_id, id, branch_id));
CREATE UNIQUE INDEX one_active_credential ON device_credentials (tenant_id, device_id) WHERE state = 'active';

CREATE TABLE sync_cursor (tenant_id uuid NOT NULL, device_id uuid NOT NULL, last_seq bigint NOT NULL,
  PRIMARY KEY (tenant_id, device_id), FOREIGN KEY (tenant_id, device_id) REFERENCES devices(tenant_id, id));
CREATE TABLE inbox (
  tenant_id uuid NOT NULL, device_id uuid NOT NULL, command_id uuid NOT NULL, device_seq bigint NOT NULL, branch_id uuid NOT NULL,
  payload_hash bytea NOT NULL, outcome text NOT NULL, received_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, device_id, command_id),
  UNIQUE (tenant_id, device_id, device_seq),
  FOREIGN KEY (tenant_id, device_id, branch_id) REFERENCES devices(tenant_id, id, branch_id));
CREATE TABLE device_events (
  tenant_id uuid NOT NULL, id bigint GENERATED ALWAYS AS IDENTITY, branch_id uuid NOT NULL, device_id uuid NOT NULL,
  kind text NOT NULL CHECK (kind IN ('id_mismatch','revoked_credential_used','payload_mismatch','seq_conflict','server_behind_device','clone_suspected','restore_suspected')),
  detail jsonb NOT NULL DEFAULT '{}', created_at timestamptz NOT NULL DEFAULT now(), acknowledged_at timestamptz,
  PRIMARY KEY (tenant_id, id),
  FOREIGN KEY (tenant_id, device_id, branch_id) REFERENCES devices(tenant_id, id, branch_id));
CREATE TABLE offline_periods (
  tenant_id uuid NOT NULL, id bigint GENERATED ALWAYS AS IDENTITY, branch_id uuid NOT NULL, device_id uuid NOT NULL,
  started_device_time timestamptz NOT NULL, ended_device_time timestamptz NOT NULL, first_seq bigint NOT NULL, last_seq bigint NOT NULL,
  reported_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id),
  FOREIGN KEY (tenant_id, device_id, branch_id) REFERENCES devices(tenant_id, id, branch_id));
CREATE TABLE review_queue (
  tenant_id uuid NOT NULL, id bigint GENERATED ALWAYS AS IDENTITY, branch_id uuid NOT NULL, device_id uuid NOT NULL,
  command_id uuid, reason text NOT NULL, fact jsonb NOT NULL,
  status text NOT NULL DEFAULT 'open' CHECK (status IN ('open','accepted','corrected')),
  created_at timestamptz NOT NULL DEFAULT now(), decided_by uuid, decided_at timestamptz, decision_note text,
  PRIMARY KEY (tenant_id, id),
  FOREIGN KEY (tenant_id, device_id, branch_id) REFERENCES devices(tenant_id, id, branch_id));
CREATE TABLE verified_restore_watermark (
  tenant_id uuid NOT NULL, device_id uuid NOT NULL, branch_id uuid NOT NULL,
  hwm_seq bigint NOT NULL, backup_id text NOT NULL, verified_at timestamptz NOT NULL,
  PRIMARY KEY (tenant_id, device_id),
  FOREIGN KEY (tenant_id, device_id, branch_id) REFERENCES devices(tenant_id, id, branch_id));
CREATE FUNCTION wm_monotonic() RETURNS trigger LANGUAGE plpgsql AS
  $$ BEGIN IF NEW.hwm_seq < OLD.hwm_seq THEN RAISE EXCEPTION 'watermark may not decrease (% -> %)', OLD.hwm_seq, NEW.hwm_seq; END IF; RETURN NEW; END $$;
CREATE TRIGGER wm_monotonic BEFORE UPDATE ON verified_restore_watermark FOR EACH ROW EXECUTE FUNCTION wm_monotonic();

-- RLS on everything, forced for the owner as well
DO $$ DECLARE t text; BEGIN
  FOREACH t IN ARRAY ARRAY['devices','device_credentials','sync_cursor','inbox','device_events','offline_periods','review_queue','verified_restore_watermark'] LOOP
    EXECUTE format('ALTER TABLE s.%I ENABLE ROW LEVEL SECURITY', t);
    EXECUTE format('ALTER TABLE s.%I FORCE ROW LEVEL SECURITY', t);
  END LOOP; END $$;

-- ti_device: bound to (tenant, branch, device) from the credential context
CREATE POLICY dev_devices_sel ON devices FOR SELECT TO ti_device USING (tenant_id = ctx('tenant_id') AND id = ctx('device_id') AND branch_id = ctx('branch_id'));
CREATE POLICY dev_devices_upd ON devices FOR UPDATE TO ti_device USING (tenant_id = ctx('tenant_id') AND id = ctx('device_id') AND branch_id = ctx('branch_id'))
  WITH CHECK (tenant_id = ctx('tenant_id') AND id = ctx('device_id') AND branch_id = ctx('branch_id'));
CREATE POLICY dev_cursor ON sync_cursor FOR ALL TO ti_device USING (tenant_id = ctx('tenant_id') AND device_id = ctx('device_id'))
  WITH CHECK (tenant_id = ctx('tenant_id') AND device_id = ctx('device_id'));
CREATE POLICY dev_inbox ON inbox FOR ALL TO ti_device USING (tenant_id = ctx('tenant_id') AND device_id = ctx('device_id') AND branch_id = ctx('branch_id'))
  WITH CHECK (tenant_id = ctx('tenant_id') AND device_id = ctx('device_id') AND branch_id = ctx('branch_id'));
CREATE POLICY dev_events_ins ON device_events FOR INSERT TO ti_device WITH CHECK (tenant_id = ctx('tenant_id') AND device_id = ctx('device_id') AND branch_id = ctx('branch_id'));
CREATE POLICY dev_offline_ins ON offline_periods FOR INSERT TO ti_device WITH CHECK (tenant_id = ctx('tenant_id') AND device_id = ctx('device_id') AND branch_id = ctx('branch_id'));
CREATE POLICY dev_review_ins ON review_queue FOR INSERT TO ti_device WITH CHECK (tenant_id = ctx('tenant_id') AND device_id = ctx('device_id') AND branch_id = ctx('branch_id'));
CREATE POLICY dev_wm_sel ON verified_restore_watermark FOR SELECT TO ti_device USING (tenant_id = ctx('tenant_id') AND device_id = ctx('device_id'));
-- ti_dash: owner dashboard, tenant-scoped only (per-branch roles are another part's job)
CREATE POLICY dash_devices ON devices FOR ALL TO ti_dash USING (tenant_id = ctx('tenant_id')) WITH CHECK (tenant_id = ctx('tenant_id'));
CREATE POLICY dash_cred ON device_credentials FOR ALL TO ti_dash USING (tenant_id = ctx('tenant_id')) WITH CHECK (tenant_id = ctx('tenant_id'));
CREATE POLICY dash_inbox ON inbox FOR ALL TO ti_dash USING (tenant_id = ctx('tenant_id')) WITH CHECK (tenant_id = ctx('tenant_id'));
CREATE POLICY dash_events ON device_events FOR ALL TO ti_dash USING (tenant_id = ctx('tenant_id')) WITH CHECK (tenant_id = ctx('tenant_id'));
CREATE POLICY dash_offline ON offline_periods FOR SELECT TO ti_dash USING (tenant_id = ctx('tenant_id'));
CREATE POLICY dash_review ON review_queue FOR ALL TO ti_dash USING (tenant_id = ctx('tenant_id')) WITH CHECK (tenant_id = ctx('tenant_id'));
CREATE POLICY dash_wm ON verified_restore_watermark FOR SELECT TO ti_dash USING (tenant_id = ctx('tenant_id'));
-- ti_ops: backup-verification job, cross-tenant by nature, an explicit policy instead of BYPASSRLS
CREATE POLICY ops_wm ON verified_restore_watermark FOR ALL TO ti_ops USING (true) WITH CHECK (true);
-- ti_auth: owner of the pre-context lookup function
CREATE POLICY auth_cred ON device_credentials FOR SELECT TO ti_auth USING (true);
CREATE POLICY auth_devices ON devices FOR SELECT TO ti_auth USING (true);

-- grants
REVOKE ALL ON ALL TABLES IN SCHEMA s FROM PUBLIC;
GRANT SELECT ON devices TO ti_device;  GRANT UPDATE (last_seen_at) ON devices TO ti_device;
GRANT SELECT, INSERT, UPDATE ON sync_cursor TO ti_device;
GRANT SELECT, INSERT ON inbox TO ti_device;
GRANT INSERT ON device_events, offline_periods, review_queue TO ti_device;   -- insert only: no SELECT, UPDATE, DELETE
GRANT SELECT ON verified_restore_watermark TO ti_device;
GRANT SELECT ON branches, tenants TO ti_device, ti_dash;
GRANT SELECT, INSERT ON devices, device_credentials TO ti_dash; GRANT UPDATE (status, revoked_at) ON devices TO ti_dash; GRANT UPDATE (state) ON device_credentials TO ti_dash;
GRANT SELECT, INSERT ON inbox TO ti_dash;
GRANT SELECT ON device_events, offline_periods, review_queue, verified_restore_watermark TO ti_dash;
GRANT UPDATE (acknowledged_at) ON device_events TO ti_dash;
GRANT UPDATE (status, decided_by, decided_at, decision_note) ON review_queue TO ti_dash;
GRANT SELECT, INSERT, UPDATE ON verified_restore_watermark TO ti_ops;
GRANT SELECT ON device_credentials, devices TO ti_auth;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA s TO ti_device, ti_dash;   -- identity columns

-- pre-context lookup: the only global read; returns the bindings for one key_id
CREATE FUNCTION auth_device(p_key_id uuid) RETURNS TABLE (tenant_id uuid, branch_id uuid, device_id uuid, device_status text, cred_state text, alg text, public_key bytea)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = pg_catalog, s AS
$$ SELECT c.tenant_id, c.branch_id, c.device_id, d.status, c.state, c.alg, c.public_key
   FROM s.device_credentials c JOIN s.devices d ON d.tenant_id = c.tenant_id AND d.id = c.device_id WHERE c.key_id = p_key_id $$;
REVOKE ALL ON FUNCTION auth_device(uuid) FROM PUBLIC; GRANT EXECUTE ON FUNCTION auth_device(uuid) TO ti_device;
RESET ROLE;
ALTER FUNCTION s.auth_device(uuid) OWNER TO ti_auth;   -- superuser step: the function must run as the role that has the all-rows policy
SET ROLE ti_owner;
SET search_path = s, pg_catalog;

-- ingest: identity comes ONLY from the three settings the authentication layer sets from the credential; payload ids are claims
-- v2: SET search_path added after run 1 failed with 'relation "inbox" does not exist' (see 00-setup.run1-wrong.sql, 10-tests.run1-wrong.out)
CREATE FUNCTION apply_cmd(p_cmd jsonb) RETURNS text LANGUAGE plpgsql SET search_path = s, pg_catalog AS $$
DECLARE t uuid := ctx('tenant_id'); b uuid := ctx('branch_id'); d uuid := ctx('device_id');
        st text; last bigint; seq bigint := (p_cmd->>'device_seq')::bigint; cid uuid := (p_cmd->>'command_id')::uuid;
        h bytea := sha256(convert_to((p_cmd->'body')::text, 'UTF8')); old inbox%ROWTYPE;
BEGIN
  IF t IS NULL OR b IS NULL OR d IS NULL THEN RAISE EXCEPTION 'no device context (fail closed)'; END IF;
  SELECT status INTO st FROM devices WHERE tenant_id = t AND id = d FOR SHARE;
  IF st IS DISTINCT FROM 'active' THEN
    INSERT INTO device_events(tenant_id, branch_id, device_id, kind, detail) VALUES (t, b, d, 'revoked_credential_used', jsonb_build_object('status', st));
    RETURN 'refused:device_not_active';
  END IF;
  IF (p_cmd ? 'tenant_id' AND (p_cmd->>'tenant_id') IS DISTINCT FROM t::text)
  OR (p_cmd ? 'branch_id' AND (p_cmd->>'branch_id') IS DISTINCT FROM b::text)
  OR (p_cmd ? 'device_id' AND (p_cmd->>'device_id') IS DISTINCT FROM d::text) THEN
    INSERT INTO device_events(tenant_id, branch_id, device_id, kind, detail)
      VALUES (t, b, d, 'id_mismatch', jsonb_build_object('claimed_tenant', p_cmd->>'tenant_id', 'claimed_branch', p_cmd->>'branch_id', 'claimed_device', p_cmd->>'device_id', 'command_id', cid));
    RETURN 'refused:id_mismatch';
  END IF;
  SELECT * INTO old FROM inbox WHERE tenant_id = t AND device_id = d AND command_id = cid;
  IF FOUND THEN
    IF old.payload_hash = h THEN RETURN 'duplicate:' || old.outcome; END IF;
    INSERT INTO device_events(tenant_id, branch_id, device_id, kind, detail) VALUES (t, b, d, 'payload_mismatch', jsonb_build_object('command_id', cid, 'seq', seq, 'kept_payload', p_cmd->'body'));
    INSERT INTO review_queue(tenant_id, branch_id, device_id, command_id, reason, fact) VALUES (t, b, d, cid, 'payload_mismatch', p_cmd->'body');
    RETURN 'flagged:payload_mismatch';
  END IF;
  INSERT INTO sync_cursor(tenant_id, device_id, last_seq) VALUES (t, d, 0) ON CONFLICT DO NOTHING;
  SELECT last_seq INTO last FROM sync_cursor WHERE tenant_id = t AND device_id = d FOR UPDATE;
  IF seq <= last THEN
    INSERT INTO device_events(tenant_id, branch_id, device_id, kind, detail) VALUES (t, b, d, 'seq_conflict', jsonb_build_object('command_id', cid, 'seq', seq, 'kept_payload', p_cmd->'body'));
    INSERT INTO review_queue(tenant_id, branch_id, device_id, command_id, reason, fact) VALUES (t, b, d, cid, 'seq_conflict', p_cmd->'body');
    RETURN 'flagged:seq_conflict';
  ELSIF seq > last + 1 THEN RETURN 'gap'; END IF;
  INSERT INTO inbox(tenant_id, device_id, command_id, device_seq, branch_id, payload_hash, outcome) VALUES (t, d, cid, seq, b, h, 'applied');
  UPDATE sync_cursor SET last_seq = seq WHERE tenant_id = t AND device_id = d;
  IF p_cmd->'body' ? 'needs_review' THEN
    INSERT INTO review_queue(tenant_id, branch_id, device_id, command_id, reason, fact) VALUES (t, b, d, cid, p_cmd->'body'->>'needs_review', p_cmd->'body');
  END IF;
  RETURN 'applied';
END $$;
GRANT EXECUTE ON FUNCTION apply_cmd(jsonb) TO ti_device;
RESET ROLE;

-- seed (superuser): tenants A, B; A has branches a1, a2 and devices dA1 (a1), dA2 (a2); B has b1 and dB1
INSERT INTO s.tenants VALUES ('aaaaaaaa-0000-4000-8000-000000000001'), ('bbbbbbbb-0000-4000-8000-000000000001');
INSERT INTO s.branches VALUES ('aaaaaaaa-0000-4000-8000-000000000001','a1a1a1a1-0000-4000-8000-000000000001'),
  ('aaaaaaaa-0000-4000-8000-000000000001','a2a2a2a2-0000-4000-8000-000000000002'),
  ('bbbbbbbb-0000-4000-8000-000000000001','b1b1b1b1-0000-4000-8000-000000000001');
INSERT INTO s.devices(tenant_id,id,branch_id,status) VALUES
 ('aaaaaaaa-0000-4000-8000-000000000001','d1d1d1d1-0000-4000-8000-0000000000a1','a1a1a1a1-0000-4000-8000-000000000001','active'),
 ('aaaaaaaa-0000-4000-8000-000000000001','d2d2d2d2-0000-4000-8000-0000000000a2','a2a2a2a2-0000-4000-8000-000000000002','active'),
 ('bbbbbbbb-0000-4000-8000-000000000001','d3d3d3d3-0000-4000-8000-0000000000b1','b1b1b1b1-0000-4000-8000-000000000001','active');
INSERT INTO s.device_credentials VALUES
 ('c1c1c1c1-0000-4000-8000-000000000001','aaaaaaaa-0000-4000-8000-000000000001','d1d1d1d1-0000-4000-8000-0000000000a1','a1a1a1a1-0000-4000-8000-000000000001','ES256','\x01','active'),
 ('c2c2c2c2-0000-4000-8000-000000000002','bbbbbbbb-0000-4000-8000-000000000001','d3d3d3d3-0000-4000-8000-0000000000b1','b1b1b1b1-0000-4000-8000-000000000001','ES256','\x02','active');
