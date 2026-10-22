# ---- call 1 (part A) ----
docker exec -i kodeebo-catalogue-spike-pg psql -U postgres -X -v ON_ERROR_STOP=0 -e <<'SQL' 2>&1
-- S41 part A: bigint quantities in integer base units (mg, ml, count), PostgreSQL 18.6
\pset footer off
CREATE DATABASE s41a;
\c s41a
CREATE TABLE movement (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY, qty_base bigint NOT NULL, value_piasters bigint NOT NULL);
-- A1 largest stock a tenant could plausibly hold, in mg: 9,223,372 t fits
SELECT 9223372036854775807::bigint AS bigint_max, (9223372036854775807 / 1000 / 1000 / 1000) AS max_tonnes_in_mg;
-- A2 overflow on insert and on arithmetic raises, never wraps
INSERT INTO movement (qty_base, value_piasters) VALUES (9223372036854775807 + 1, 0);
SELECT 9223372036854775807::bigint * 2;
SELECT (5000000000::bigint) * (5000000000::bigint);
-- A3 SUM(bigint) returns numeric: no overflow across many rows, but the result type is not bigint
INSERT INTO movement (qty_base, value_piasters) VALUES (9223372036854775807, 1), (9223372036854775807, 1);
SELECT sum(qty_base) AS s, pg_typeof(sum(qty_base)) AS sum_type, pg_typeof(sum(value_piasters)) AS sum_type_value FROM movement;
SELECT sum(qty_base)::bigint FROM movement;
TRUNCATE movement;
-- A4 integer division truncates toward zero (matters for negative reversal movements)
SELECT 7/2 AS pos, (-7)/2 AS neg_trunc, div(-7, 2) AS div_fn, mod(-7, 2) AS mod_neg, floor((-7)::numeric/2) AS floor_neg;
-- A5 dose cost: 33,333 piasters per 1,000,000 mg bag, 18,000 mg dose; numeric then explicit rounding
SELECT 33333::bigint * 18000 / 1000000 AS trunc_bigint, round(33333::numeric * 18000 / 1000000) AS half_up_numeric, round(-(33333::numeric * 18000 / 1000000)) AS half_away_negative;
-- A6 a reversal copies the stored movement with the sign flipped: sum returns to exactly 0
INSERT INTO movement (qty_base, value_piasters) SELECT -18000, -600 FROM generate_series(1, 10000);
INSERT INTO movement (qty_base, value_piasters) SELECT -qty_base, -value_piasters FROM movement;
SELECT count(*), sum(qty_base) AS qty_sum, sum(value_piasters) AS value_sum FROM movement;
-- A7 CHECK constraint keeps the unit factor positive
CREATE TABLE unit (id int PRIMARY KEY, factor_to_base bigint NOT NULL CHECK (factor_to_base > 0), whole_number boolean NOT NULL);
INSERT INTO unit VALUES (1, 0, true);
INSERT INTO unit VALUES (2, 1000, false);
SQL
# ---- call 2 (part B setup) ----
docker exec kodeebo-catalogue-spike-pg psql -U postgres -X -q -c "CREATE DATABASE s41c"; docker exec -i kodeebo-catalogue-spike-pg psql -U postgres -X -q -d s41c -v ON_ERROR_STOP=1 <<'SQL'
-- S41 part B setup: sub-recipe cycle refusal on PostgreSQL 18.6 (server side; the counter receives flattened recipes only)
CREATE TABLE recipe (tenant_id uuid NOT NULL, id bigint NOT NULL, name text NOT NULL, PRIMARY KEY (tenant_id, id));
CREATE TABLE stock_item (tenant_id uuid NOT NULL, id bigint NOT NULL, PRIMARY KEY (tenant_id, id));
CREATE TABLE recipe_line (
  tenant_id uuid NOT NULL, recipe_id bigint NOT NULL, line_no int NOT NULL,
  component_recipe_id bigint, stock_item_id bigint, qty_base bigint NOT NULL CHECK (qty_base > 0),
  PRIMARY KEY (tenant_id, recipe_id, line_no),
  CHECK ((component_recipe_id IS NULL) <> (stock_item_id IS NULL)),
  FOREIGN KEY (tenant_id, recipe_id) REFERENCES recipe (tenant_id, id),
  FOREIGN KEY (tenant_id, component_recipe_id) REFERENCES recipe (tenant_id, id),
  FOREIGN KEY (tenant_id, stock_item_id) REFERENCES stock_item (tenant_id, id));
-- variant 1: check only, no lock
CREATE FUNCTION refuse_recipe_cycle() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.component_recipe_id IS NULL THEN RETURN NEW; END IF;
  IF NEW.component_recipe_id = NEW.recipe_id OR EXISTS (
       WITH RECURSIVE reach(rid) AS (
         SELECT NEW.component_recipe_id
         UNION
         SELECT l.component_recipe_id FROM recipe_line l JOIN reach r ON l.recipe_id = r.rid
          WHERE l.tenant_id = NEW.tenant_id AND l.component_recipe_id IS NOT NULL)
       SELECT 1 FROM reach WHERE rid = NEW.recipe_id) THEN
    RAISE EXCEPTION 'recipe cycle: % -> %', NEW.recipe_id, NEW.component_recipe_id USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER recipe_line_acyclic BEFORE INSERT OR UPDATE OF component_recipe_id ON recipe_line
  FOR EACH ROW EXECUTE FUNCTION refuse_recipe_cycle();
INSERT INTO recipe SELECT '00000000-0000-0000-0000-00000000000a', g, 'r' || g FROM generate_series(1, 200) g;
INSERT INTO stock_item SELECT '00000000-0000-0000-0000-00000000000a', g FROM generate_series(1, 10) g;
SQL
echo "setup rc=$?"
# ---- call 3 (B1-B5) ----
T="'00000000-0000-0000-0000-00000000000a'"
pg() { docker exec kodeebo-catalogue-spike-pg psql -U postgres -X -q -d s41c -v ON_ERROR_STOP=0 "$@"; }
run() { echo "-- $1"; pg -c "$2" 2>&1 | sed 's/^/   /'; }
run "B1 self loop 1->1 (expect refused)" "INSERT INTO recipe_line VALUES ($T,1,1,1,NULL,1)"
run "B2 chain 1->2, 2->3 (expect accepted)" "INSERT INTO recipe_line VALUES ($T,1,1,2,NULL,1),($T,2,1,3,NULL,1)"
run "B2 closing edge 3->1 (expect refused)" "INSERT INTO recipe_line VALUES ($T,3,1,1,NULL,1)"
run "B3 diamond 10->11, 10->12, 11->13, 12->13 (expect accepted, not a cycle)" "INSERT INTO recipe_line VALUES ($T,10,1,11,NULL,1),($T,10,2,12,NULL,1),($T,11,1,13,NULL,1),($T,12,1,13,NULL,1)"
run "B4 chain 100->...->150, 50 edges (expect accepted)" "INSERT INTO recipe_line SELECT $T, g, 1, g+1, NULL, 1 FROM generate_series(100,149) g"
echo "-- B4 closing edge 150->100 (expect refused), timed"; pg -c '\timing on' -c "INSERT INTO recipe_line VALUES ($T,150,1,100,NULL,1)" 2>&1 | sed 's/^/   /'
run "B5 UPDATE repointing 2's line to 1 (expect refused)" "UPDATE recipe_line SET component_recipe_id = 1 WHERE tenant_id=$T AND recipe_id=2 AND line_no=1"
# ---- call 4 (B6) ----
T="'00000000-0000-0000-0000-00000000000a'"
pg() { docker exec kodeebo-catalogue-spike-pg psql -U postgres -X -q -d s41c -v ON_ERROR_STOP=0 "$@"; }
race() { # $1 $2 recipe ids; s1 adds $1->$2 and holds 2 s; s2 adds $2->$1 0.5 s later
  ( pg -c "BEGIN" -c "INSERT INTO recipe_line VALUES ($T,$1,1,$2,NULL,1)" -c "SELECT pg_sleep(2)" -c "COMMIT" 2>&1 | sed 's/^/   s1: /' ) &
  sleep 0.5
  pg -c '\timing on' -c "BEGIN" -c "INSERT INTO recipe_line VALUES ($T,$2,1,$1,NULL,1)" -c "COMMIT" 2>&1 | sed 's/^/   s2: /'
  wait
  pg -At -c "WITH RECURSIVE w(rid) AS (SELECT $1::bigint UNION ALL SELECT l.component_recipe_id FROM recipe_line l JOIN w ON l.recipe_id = w.rid WHERE l.tenant_id=$T AND l.component_recipe_id IS NOT NULL) CYCLE rid SET is_cycle USING path SELECT count(*) FILTER (WHERE is_cycle) FROM w" | sed "s/^/   cycle rows reachable from $1 (CYCLE clause): /"
}
echo "-- B6 race, READ COMMITTED, check without lock (20->21 vs 21->20)"; race 20 21
# ---- call 5 (B7) ----
docker exec -i kodeebo-catalogue-spike-pg psql -U postgres -X -q -d s41c -v ON_ERROR_STOP=1 <<'SQL'
-- variant 2: same check after a per-tenant transaction-level advisory lock
CREATE OR REPLACE FUNCTION refuse_recipe_cycle() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.component_recipe_id IS NULL THEN RETURN NEW; END IF;
  PERFORM pg_advisory_xact_lock(hashtextextended('recipe_graph:' || NEW.tenant_id::text, 0));
  IF NEW.component_recipe_id = NEW.recipe_id OR EXISTS (
       WITH RECURSIVE reach(rid) AS (
         SELECT NEW.component_recipe_id
         UNION
         SELECT l.component_recipe_id FROM recipe_line l JOIN reach r ON l.recipe_id = r.rid
          WHERE l.tenant_id = NEW.tenant_id AND l.component_recipe_id IS NOT NULL)
       SELECT 1 FROM reach WHERE rid = NEW.recipe_id) THEN
    RAISE EXCEPTION 'recipe cycle: % -> %', NEW.recipe_id, NEW.component_recipe_id USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END $$;
SQL
T="'00000000-0000-0000-0000-00000000000a'"
pg() { docker exec kodeebo-catalogue-spike-pg psql -U postgres -X -q -d s41c -v ON_ERROR_STOP=0 "$@"; }
race() {
  ( pg -c "BEGIN" -c "INSERT INTO recipe_line VALUES ($T,$1,1,$2,NULL,1)" -c "SELECT pg_sleep(2)" -c "COMMIT" 2>&1 | sed 's/^/   s1: /' ) &
  sleep 0.5
  pg -c '\timing on' -c "BEGIN" -c "INSERT INTO recipe_line VALUES ($T,$2,1,$1,NULL,1)" -c "COMMIT" 2>&1 | sed 's/^/   s2: /'
  wait
  pg -At -c "WITH RECURSIVE w(rid) AS (SELECT $1::bigint UNION ALL SELECT l.component_recipe_id FROM recipe_line l JOIN w ON l.recipe_id = w.rid WHERE l.tenant_id=$T AND l.component_recipe_id IS NOT NULL) CYCLE rid SET is_cycle USING path SELECT count(*) FILTER (WHERE is_cycle) FROM w" | sed "s/^/   cycle rows reachable from $1 (CYCLE clause): /"
}
echo "-- B7 race with the per-tenant lock (30->31 vs 31->30)"; race 30 31
echo "-- B7b a different tenant is not blocked by tenant a's lock"
docker exec kodeebo-catalogue-spike-pg psql -U postgres -X -q -d s41c -c "INSERT INTO recipe VALUES ('00000000-0000-0000-0000-00000000000b', 1, 'b1'), ('00000000-0000-0000-0000-00000000000b', 2, 'b2')"
( pg -c "BEGIN" -c "INSERT INTO recipe_line VALUES ($T,40,1,41,NULL,1)" -c "SELECT pg_sleep(2)" -c "COMMIT" >/dev/null 2>&1 ) &
sleep 0.5
pg -c '\timing on' -c "INSERT INTO recipe_line VALUES ('00000000-0000-0000-0000-00000000000b',1,1,2,NULL,1)" 2>&1 | sed 's/^/   tenant b: /'
wait
# ---- call 6 (B8) ----
docker exec -i kodeebo-catalogue-spike-pg psql -U postgres -X -d s41c -v ON_ERROR_STOP=0 <<'SQL' 2>&1
\pset footer off
-- B8 flatten recipe 10 (diamond 10->11, 10->12 x2, 11->13, 12->13) to stock items at publish; integer quantities; CYCLE guard
INSERT INTO recipe_line VALUES ('00000000-0000-0000-0000-00000000000a',11,2,NULL,1,18000),('00000000-0000-0000-0000-00000000000a',12,2,NULL,2,250),('00000000-0000-0000-0000-00000000000a',13,1,NULL,1,2000),('00000000-0000-0000-0000-00000000000a',13,2,NULL,3,1);
UPDATE recipe_line SET qty_base = 2 WHERE tenant_id='00000000-0000-0000-0000-00000000000a' AND recipe_id=10 AND line_no=2;
WITH RECURSIVE f(rid, comp, stock, mult) AS (
  SELECT l.recipe_id, l.component_recipe_id, l.stock_item_id, l.qty_base FROM recipe_line l
   WHERE l.tenant_id='00000000-0000-0000-0000-00000000000a' AND l.recipe_id = 10
  UNION ALL
  SELECT l.recipe_id, l.component_recipe_id, l.stock_item_id, f.mult * l.qty_base
    FROM recipe_line l JOIN f ON l.recipe_id = f.comp WHERE l.tenant_id='00000000-0000-0000-0000-00000000000a')
  CYCLE rid SET is_cycle USING path
SELECT stock AS stock_item_id, sum(mult) AS qty_base_per_sale, pg_typeof(sum(mult)) AS sum_type
  FROM f WHERE stock IS NOT NULL AND NOT is_cycle GROUP BY stock ORDER BY stock;
-- expected: item 1 = 18000 (via 11) + 2000 (10->11->13) + 2*2000 (10->12 x2 ->13) = 24000; item 2 = 2*250 = 500; item 3 = 1 + 2 = 3
SQL
