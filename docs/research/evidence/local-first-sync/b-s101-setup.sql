-- b-s101-setup.sql: device-to-server inbox, per-device cursor, apply log, quarantine (probe schema, throwaway)
-- Money is integer piasters. Tenant-leading keys everywhere. RLS enforced for role kodeebo_app.
DROP SCHEMA IF EXISTS probe CASCADE;
CREATE SCHEMA probe;
SET search_path = probe;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='kodeebo_app') THEN
    CREATE ROLE kodeebo_app NOLOGIN;
  END IF;
END $$;

CREATE TABLE device_cursor (
  tenant_id uuid NOT NULL,
  device_id uuid NOT NULL,
  last_applied_seq bigint NOT NULL DEFAULT 0,
  epoch int NOT NULL DEFAULT 1,
  PRIMARY KEY (tenant_id, device_id)
);

-- the inbox / dedupe record: one row per (tenant, device, command)
CREATE TABLE inbox (
  tenant_id uuid NOT NULL,
  device_id uuid NOT NULL,
  command_id uuid NOT NULL,
  device_seq bigint NOT NULL,
  payload_sha256 bytea NOT NULL,
  outcome text NOT NULL CHECK (outcome IN ('applied','rejected')),
  response jsonb NOT NULL,
  received_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, device_id, command_id),
  UNIQUE (tenant_id, device_id, device_seq)
);

-- ordered effects (stand-in for ledger rows)
CREATE TABLE apply_log (
  global_order bigint GENERATED ALWAYS AS IDENTITY,
  tenant_id uuid NOT NULL,
  device_id uuid NOT NULL,
  device_seq bigint NOT NULL,
  amount_piasters bigint NOT NULL CHECK (amount_piasters >= 0),
  PRIMARY KEY (tenant_id, device_id, device_seq)
);

-- a deliberately WRONG inbox keyed on command_id alone (to show the cross-tenant leak)
CREATE TABLE inbox_bad_global (
  command_id uuid PRIMARY KEY,
  tenant_id uuid NOT NULL
);

-- apply one command. Compare-and-set on the cursor orders per device; the inbox row dedupes.
-- returns: 'applied' | 'duplicate' | 'gap' | 'rejected'
CREATE FUNCTION apply_cmd(p_tenant uuid, p_device uuid, p_cmd uuid, p_seq bigint,
                          p_amount bigint, p_hash bytea) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE
  n int;
  stored record;
BEGIN
  -- 1. duplicate by command id? (replay returns the stored outcome)
  SELECT outcome, response, payload_sha256 INTO stored
    FROM inbox WHERE tenant_id=p_tenant AND device_id=p_device AND command_id=p_cmd;
  IF FOUND THEN
    IF stored.payload_sha256 <> p_hash THEN RETURN 'payload_mismatch'; END IF;
    RETURN 'duplicate:' || stored.outcome;
  END IF;

  -- 2. compare-and-set the cursor: succeeds only for exactly last+1.
  UPDATE device_cursor SET last_applied_seq = p_seq
   WHERE tenant_id=p_tenant AND device_id=p_device AND last_applied_seq = p_seq - 1;
  GET DIAGNOSTICS n = ROW_COUNT;
  IF n = 0 THEN
    -- either someone else applied this seq concurrently (then the inbox row exists now) or a gap
    SELECT outcome INTO stored FROM inbox
      WHERE tenant_id=p_tenant AND device_id=p_device AND device_seq=p_seq;
    IF FOUND THEN RETURN 'duplicate_seq:' || stored.outcome; END IF;
    RETURN 'gap';
  END IF;

  -- 3. business effect in the SAME transaction; a failing effect is quarantined, cursor still advances
  BEGIN
    INSERT INTO apply_log(tenant_id, device_id, device_seq, amount_piasters)
      VALUES (p_tenant, p_device, p_seq, p_amount);
    INSERT INTO inbox VALUES (p_tenant,p_device,p_cmd,p_seq,p_hash,'applied','{"ok":true}');
    RETURN 'applied';
  EXCEPTION WHEN check_violation THEN
    INSERT INTO inbox VALUES (p_tenant,p_device,p_cmd,p_seq,p_hash,'rejected','{"ok":false,"reason":"negative_amount"}');
    RETURN 'rejected';
  END;
END $$;

GRANT USAGE ON SCHEMA probe TO kodeebo_app;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA probe TO kodeebo_app;
GRANT EXECUTE ON FUNCTION apply_cmd TO kodeebo_app;

-- RLS on the inbox (tenant from a session setting, missing_ok = true so unset denies rows)
ALTER TABLE inbox ENABLE ROW LEVEL SECURITY;
ALTER TABLE inbox_bad_global ENABLE ROW LEVEL SECURITY;
CREATE POLICY t ON inbox USING (tenant_id = nullif(current_setting('app.tenant_id', true),'')::uuid)
  WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true),'')::uuid);
CREATE POLICY t ON inbox_bad_global USING (tenant_id = nullif(current_setting('app.tenant_id', true),'')::uuid)
  WITH CHECK (tenant_id = nullif(current_setting('app.tenant_id', true),'')::uuid);
