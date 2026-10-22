-- S41 SQLite leg: STAND-IN, host sqlite3 3.54.0, until the desktop runtime ADR fixes the counter's SQLite version
.bail off
.headers on
.mode list
SELECT sqlite_version() AS version;
-- C1 expression overflow: SQLite turns an overflowing integer product into REAL silently
SELECT 9223372036854775807 * 2 AS product, typeof(9223372036854775807 * 2) AS type;
SELECT 9223372036854775807 + 1 AS plus_one, typeof(9223372036854775807 + 1) AS type;
-- C2 an ordinary (non-STRICT) table stores that REAL without complaint
CREATE TABLE movement_loose (qty_base INTEGER NOT NULL);
INSERT INTO movement_loose VALUES (9223372036854775807 * 2);
SELECT qty_base, typeof(qty_base) FROM movement_loose;
-- C3 a STRICT table refuses it
CREATE TABLE movement (qty_base INTEGER NOT NULL, value_piasters INTEGER NOT NULL) STRICT;
INSERT INTO movement VALUES (9223372036854775807 * 2, 0);
INSERT INTO movement VALUES (1.5, 0);
INSERT INTO movement VALUES ('18000', 0);
SELECT qty_base, typeof(qty_base) FROM movement;
DELETE FROM movement;
-- C4 sum() raises on integer overflow; total() returns REAL
INSERT INTO movement VALUES (9223372036854775807, 0), (1, 0);
SELECT sum(qty_base) FROM movement;
SELECT total(qty_base), typeof(total(qty_base)) FROM movement;
DELETE FROM movement;
-- C5 integer division truncates toward zero (same as PostgreSQL)
SELECT 7/2 AS pos, -7/2 AS neg_trunc, -7 % 2 AS mod_neg;
-- C6 reversal copies stored rows with the sign flipped: sum back to exactly 0
WITH RECURSIVE g(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM g WHERE n < 10000) INSERT INTO movement SELECT -18000, -600 FROM g;
INSERT INTO movement SELECT -qty_base, -value_piasters FROM movement;
SELECT count(*), sum(qty_base), sum(value_piasters), typeof(sum(qty_base)) FROM movement;
