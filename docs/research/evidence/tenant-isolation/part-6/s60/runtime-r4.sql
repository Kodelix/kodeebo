-- run 2: R4 re-done with one transaction per statement (run 1 aborted after the first error, so UPDATE/DELETE were never evaluated: wrong test, see F-S60 note)
\echo '== R4a tenant A: read B row by id -> 0 rows'
BEGIN; SET LOCAL app.tenant_id='aaaaaaaa-0000-0000-0000-00000000000a'; SELECT id FROM app.orders WHERE id = 2; ROLLBACK;
\echo '== R4b tenant A: INSERT a row carrying tenant B -> RLS violation'
BEGIN; SET LOCAL app.tenant_id='aaaaaaaa-0000-0000-0000-00000000000a'; INSERT INTO app.orders VALUES (3,'bbbbbbbb-0000-0000-0000-00000000000b','b2000000-0000-0000-0000-000000000002',5); ROLLBACK;
\echo '== R4c tenant A: UPDATE B row -> UPDATE 0'
BEGIN; SET LOCAL app.tenant_id='aaaaaaaa-0000-0000-0000-00000000000a'; UPDATE app.orders SET total = 0 WHERE id = 2; ROLLBACK;
\echo '== R4d tenant A: DELETE B row -> DELETE 0'
BEGIN; SET LOCAL app.tenant_id='aaaaaaaa-0000-0000-0000-00000000000a'; DELETE FROM app.orders WHERE id = 2; ROLLBACK;
\echo '== R4e tenant A: move own row to tenant B (UPDATE tenant_id) -> RLS violation'
BEGIN; SET LOCAL app.tenant_id='aaaaaaaa-0000-0000-0000-00000000000a'; UPDATE app.orders SET tenant_id='bbbbbbbb-0000-0000-0000-00000000000b' WHERE id = 1; ROLLBACK;
\echo '== R4f tenant A: duplicate primary key against B row id=2 (probe via error text, sync-note F128 shape)'
BEGIN; SET LOCAL app.tenant_id='aaaaaaaa-0000-0000-0000-00000000000a'; INSERT INTO app.orders VALUES (2,'aaaaaaaa-0000-0000-0000-00000000000a','b1000000-0000-0000-0000-000000000001',1); ROLLBACK;
