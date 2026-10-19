#!/usr/bin/env bash
# Run 2 of S31: fixes the seed INSERT of run 1 (see s31_last_owner.run1-WRONG.*).
# S31 - last-owner guard under concurrency, PostgreSQL 18.6 (image postgres:18.6, already local, --pull=never, --network none).
# Evidence script for research note staff-auth-and-roles.part-3. Date run: 2026-10-19.
# Scenarios (each tenant has two owners A and B; two sessions each try to remove a different owner at the same time):
#  1 application-style count check, no lock          -> expected race: 0 owners
#  2 same, but first lock the tenant row FOR UPDATE   -> expected: 1 owner, second refused
#  3 deferred constraint trigger, no lock (a test-only pg_sleep after the count widens the window) -> expected race: 0 owners
#  4 deferred constraint trigger that takes pg_advisory_xact_lock(tenant) before counting          -> expected: 1 owner, second refused
#  5 the owner role row cannot be edited or deleted (BEFORE trigger); another role can
set -u
N=s31pg
docker rm -f $N >/dev/null 2>&1
docker run -d --rm --pull=never --network none --name $N -e POSTGRES_HOST_AUTH_METHOD=trust postgres:18.6 >/dev/null || exit 1
for i in $(seq 1 60); do docker exec $N pg_isready -U postgres >/dev/null 2>&1 && break; sleep 1; done
sleep 2
P="docker exec -i $N psql -U postgres -v ON_ERROR_STOP=0 -X -q -t -A"
$P -c "select version()"
$P <<'SQL'
CREATE TABLE tenants(id int PRIMARY KEY);
CREATE TABLE staff_roles(tenant_id int REFERENCES tenants, staff text, role text, PRIMARY KEY(tenant_id, staff, role));
INSERT INTO tenants VALUES (1),(2),(3),(4);
INSERT INTO staff_roles SELECT id,s,'owner' FROM tenants, (VALUES ('A'),('B')) v(s);

-- scenario 3: deferred constraint trigger, no lock
CREATE FUNCTION chk_nolock() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF (SELECT count(*) FROM staff_roles WHERE tenant_id = OLD.tenant_id AND role='owner') < 1 THEN
    RAISE EXCEPTION 'last owner (tenant %)', OLD.tenant_id;
  END IF;
  PERFORM pg_sleep(1.5);  -- TEST ONLY: widen the window between check and commit
  RETURN NULL;
END $$;
-- scenario 4: same with a per-tenant advisory lock taken before the count
CREATE FUNCTION chk_lock() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_advisory_xact_lock(OLD.tenant_id);
  IF (SELECT count(*) FROM staff_roles WHERE tenant_id = OLD.tenant_id AND role='owner') < 1 THEN
    RAISE EXCEPTION 'last owner (tenant %)', OLD.tenant_id;
  END IF;
  PERFORM pg_sleep(1.5);  -- TEST ONLY: same window as scenario 3
  RETURN NULL;
END $$;
CREATE CONSTRAINT TRIGGER t3 AFTER DELETE ON staff_roles DEFERRABLE INITIALLY DEFERRED FOR EACH ROW
  WHEN (OLD.role='owner' AND OLD.tenant_id=3) EXECUTE FUNCTION chk_nolock();
CREATE CONSTRAINT TRIGGER t4 AFTER DELETE ON staff_roles DEFERRABLE INITIALLY DEFERRED FOR EACH ROW
  WHEN (OLD.role='owner' AND OLD.tenant_id=4) EXECUTE FUNCTION chk_lock();
SQL

app_style() { # $1 tenant $2 staff $3 lock(0/1)
  local lock=""; [ "$3" = 1 ] && lock="SELECT 1 FROM tenants WHERE id=$1 FOR UPDATE;"
  $P <<SQL
BEGIN;
$lock
SELECT (count(*) > 1) AS ok FROM staff_roles WHERE tenant_id=$1 AND role='owner' \gset
SELECT pg_sleep(1.5);
\if :ok
  DELETE FROM staff_roles WHERE tenant_id=$1 AND staff='$2' AND role='owner';
  \echo '[t$1 $2] check passed, deleted'
\else
  \echo '[t$1 $2] REFUSED: last owner'
\endif
COMMIT;
SQL
}
trig_style() { # $1 tenant $2 staff
  $P <<SQL
BEGIN;
DELETE FROM staff_roles WHERE tenant_id=$1 AND staff='$2' AND role='owner';
COMMIT;
\echo '[t$1 $2] commit statement finished'
SQL
}
run_pair() { "$@" A & local p1=$!; "$@" B & local p2=$!; wait $p1 $p2; }
echo "== scenario 1: app-style check, no lock"
(app_style 1 A 0 & app_style 1 B 0 & wait)
echo "owners left t1: $($P -c "select count(*) from staff_roles where tenant_id=1 and role='owner'")"
echo "== scenario 2: app-style check, tenant row FOR UPDATE"
(app_style 2 A 1 & app_style 2 B 1 & wait)
echo "owners left t2: $($P -c "select count(*) from staff_roles where tenant_id=2 and role='owner'")"
echo "== scenario 3: deferred constraint trigger, no lock"
(trig_style 3 A 2>&1 & trig_style 3 B 2>&1 & wait)
echo "owners left t3: $($P -c "select count(*) from staff_roles where tenant_id=3 and role='owner'")"
echo "== scenario 4: deferred constraint trigger + advisory lock"
(trig_style 4 A 2>&1 & trig_style 4 B 2>&1 & wait)
echo "owners left t4: $($P -c "select count(*) from staff_roles where tenant_id=4 and role='owner'")"
echo "== scenario 5: system owner role is immutable"
$P <<'SQL'
CREATE TABLE roles(tenant_id int, id text, is_owner bool, perms text[], PRIMARY KEY(tenant_id,id));
INSERT INTO roles VALUES (1,'owner',true,'{*}'),(1,'manager',false,'{void,discount}');
CREATE FUNCTION roles_guard() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF OLD.is_owner THEN RAISE EXCEPTION 'the owner role cannot be changed or deleted'; END IF;
  IF TG_OP='DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
END $$;
CREATE TRIGGER g BEFORE UPDATE OR DELETE ON roles FOR EACH ROW EXECUTE FUNCTION roles_guard();
UPDATE roles SET perms='{void}' WHERE id='owner';
DELETE FROM roles WHERE id='owner';
UPDATE roles SET is_owner=false WHERE id='owner';
UPDATE roles SET perms='{void}' WHERE id='manager';
SELECT 'manager perms now: '||perms::text FROM roles WHERE id='manager';
SQL
docker rm -f $N >/dev/null 2>&1
