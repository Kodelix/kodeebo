-- S52 SQLite leg: STAND-IN, host sqlite3 3.54.0, until the desktop runtime ADR fixes the counter's SQLite version
.bail off
SELECT 'version ' || sqlite_version();
CREATE TABLE stock_item (tenant_id TEXT NOT NULL, id INTEGER NOT NULL, PRIMARY KEY (tenant_id, id)) STRICT;
CREATE TABLE variant (tenant_id TEXT NOT NULL, id INTEGER NOT NULL, PRIMARY KEY (tenant_id, id)) STRICT;
CREATE TABLE link_immediate (tenant_id TEXT NOT NULL, variant_id INTEGER NOT NULL, stock_item_id INTEGER NOT NULL,
  FOREIGN KEY (tenant_id, variant_id) REFERENCES variant (tenant_id, id),
  FOREIGN KEY (tenant_id, stock_item_id) REFERENCES stock_item (tenant_id, id)) STRICT;
CREATE TABLE link_deferred (tenant_id TEXT NOT NULL, variant_id INTEGER NOT NULL, stock_item_id INTEGER NOT NULL,
  FOREIGN KEY (tenant_id, variant_id) REFERENCES variant (tenant_id, id) DEFERRABLE INITIALLY DEFERRED,
  FOREIGN KEY (tenant_id, stock_item_id) REFERENCES stock_item (tenant_id, id) DEFERRABLE INITIALLY DEFERRED) STRICT;
INSERT INTO variant VALUES ('a', 1);
SELECT '-- E1 foreign_keys pragma default: ' || (SELECT foreign_keys FROM pragma_foreign_keys);
INSERT INTO link_immediate VALUES ('a', 1, 999);
SELECT 'E1 link to missing stock item accepted with the pragma off: rows=' || count(*) FROM link_immediate;
SELECT '-- E1b foreign_key_check finds it afterwards:';
PRAGMA foreign_key_check(link_immediate);
PRAGMA foreign_keys = ON;
SELECT '-- E2 pragma on: ' || (SELECT foreign_keys FROM pragma_foreign_keys);
INSERT INTO link_immediate VALUES ('a', 1, 998);
SELECT '-- E3 feed order, immediate FK: Catalogue feed (link) before Inventory feed (stock item 5) in one transaction';
BEGIN;
INSERT INTO link_immediate VALUES ('a', 1, 5);
INSERT INTO stock_item VALUES ('a', 5);
COMMIT;
SELECT 'E3 rows link_immediate for item 5: ' || count(*) FROM link_immediate WHERE stock_item_id = 5;
SELECT '-- E4 same order, DEFERRABLE INITIALLY DEFERRED: checked at COMMIT';
BEGIN;
INSERT INTO link_deferred VALUES ('a', 1, 6);
INSERT INTO stock_item VALUES ('a', 6);
COMMIT;
SELECT 'E4 rows link_deferred for item 6: ' || count(*) FROM link_deferred WHERE stock_item_id = 6;
SELECT '-- E5 deferred, Inventory feed NOT in the same transaction: COMMIT fails';
BEGIN;
INSERT INTO link_deferred VALUES ('a', 1, 7);
COMMIT;
ROLLBACK;
SELECT 'E5 rows link_deferred for item 7: ' || count(*) FROM link_deferred WHERE stock_item_id = 7;
SELECT '-- E6 cross-tenant: tenant a link to tenant b stock item 901 (composite key)';
INSERT INTO stock_item VALUES ('b', 901);
INSERT INTO link_immediate VALUES ('a', 1, 901);
SELECT '-- E7 deleting a linked stock item (default NO ACTION) with pragma on';
INSERT INTO link_immediate VALUES ('a', 1, 6);
