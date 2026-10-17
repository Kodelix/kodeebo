-- run as kodeebo_app (runtime role, NOBYPASSRLS, owns nothing). \echo marks each test.
\echo '== R1 no tenant context at all: orders / items / cash must return 0 rows'
SELECT 'orders' t, count(*) FROM app.orders UNION ALL SELECT 'items', count(*) FROM app.items UNION ALL SELECT 'cash', count(*) FROM app.cash;
\echo '== R2 context unset vs empty string (set earlier in a committed txn leaves ''): still 0 rows, no error'
BEGIN; SELECT set_config('app.tenant_id','',true); SELECT count(*) AS orders_empty_ctx FROM app.orders; COMMIT;
BEGIN; SET LOCAL app.tenant_id = 'aaaaaaaa-0000-0000-0000-00000000000a'; COMMIT;
SELECT current_setting('app.tenant_id', true) AS after_commit_value; SELECT count(*) AS orders_after_commit FROM app.orders;
\echo '== R3 INSERT with no context fails WITH CHECK'
INSERT INTO app.orders VALUES (9,'aaaaaaaa-0000-0000-0000-00000000000a','b1000000-0000-0000-0000-000000000001',1);
\echo '== R4 tenant A context: sees A only; cannot insert/update/delete B rows; cannot read B by id'
BEGIN; SET LOCAL app.tenant_id = 'aaaaaaaa-0000-0000-0000-00000000000a';
SELECT id, tenant_id FROM app.orders ORDER BY id;
SELECT id FROM app.orders WHERE id = 2;
INSERT INTO app.orders VALUES (3,'bbbbbbbb-0000-0000-0000-00000000000b','b2000000-0000-0000-0000-000000000002',5);
UPDATE app.orders SET total = 0 WHERE id = 2;
DELETE FROM app.orders WHERE id = 2;
UPDATE app.orders SET tenant_id = 'bbbbbbbb-0000-0000-0000-00000000000b' WHERE id = 1;
ROLLBACK;
\echo '== R5 forced policy with no policy denies even with context (locked)'
BEGIN; SET LOCAL app.tenant_id = 'aaaaaaaa-0000-0000-0000-00000000000a'; SELECT count(*) AS locked_rows FROM app.locked; ROLLBACK;
\echo '== R6 branch scope: tenant A + branch 1 sees only branch 1 cash; tenant A without branch sees none; wrong branch sees none'
BEGIN; SET LOCAL app.tenant_id='aaaaaaaa-0000-0000-0000-00000000000a'; SET LOCAL app.branch_id='b1000000-0000-0000-0000-000000000001'; SELECT id, branch_id FROM app.cash; ROLLBACK;
BEGIN; SET LOCAL app.tenant_id='aaaaaaaa-0000-0000-0000-00000000000a'; SELECT count(*) AS cash_no_branch FROM app.cash; ROLLBACK;
BEGIN; SET LOCAL app.tenant_id='aaaaaaaa-0000-0000-0000-00000000000a'; SET LOCAL app.branch_id='b1000000-0000-0000-0000-000000000001';
INSERT INTO app.cash VALUES (7,'aaaaaaaa-0000-0000-0000-00000000000a','b2000000-0000-0000-0000-000000000002',1); ROLLBACK;
\echo '== R7 defect 2 (no RLS): tenant A context still reads B notes'
BEGIN; SET LOCAL app.tenant_id='aaaaaaaa-0000-0000-0000-00000000000a'; SELECT id, body FROM app.notes ORDER BY id; ROLLBACK;
\echo '== R8 defect via view: items direct (RLS) vs items_report (no security_invoker) vs items_report_safe, tenant A context'
BEGIN; SET LOCAL app.tenant_id='aaaaaaaa-0000-0000-0000-00000000000a';
SELECT 'direct' src, count(*) FROM app.items;
SELECT 'view_default' src, tenant_id, n FROM app.items_report ORDER BY tenant_id;
SELECT 'view_security_invoker' src, tenant_id, n FROM app.items_report_safe ORDER BY tenant_id; ROLLBACK;
\echo '== R9 runtime role cannot disable RLS or switch role'
SET row_security = off; SELECT count(*) AS items_row_security_off FROM app.items;
ALTER TABLE app.orders DISABLE ROW LEVEL SECURITY;
SET ROLE kodeebo_owner;
