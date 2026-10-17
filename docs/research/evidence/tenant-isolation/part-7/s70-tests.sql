-- S70 tests (tier E). Each \c is a REAL login (SCRAM over TCP, not SET ROLE). PGPASSWORD is the fixture value.
\set ON_ERROR_STOP off
\set A '\'aaaaaaaa-0000-0000-0000-000000000001\''
\set B '\'bbbbbbbb-0000-0000-0000-000000000002\''
\echo === T0 identity checks
\c p7 support_rt
SELECT current_user, session_user;
\echo === T1 support_rt, tenant A context, operator op1, NO grant -> expect 0 rows
BEGIN; SELECT set_config('app.tenant_id', :A, true), set_config('app.operator_id','op1',true);
SELECT count(*) AS rows_visible FROM orders; COMMIT;
\echo === T2a owner (app_rt, ctx A) creates a 1-hour read grant for op1 on A
\c p7 app_rt
BEGIN; SELECT set_config('app.tenant_id', :A, true);
INSERT INTO support_grants(tenant_id, operator_id, scope, granted_by, expires_at) VALUES (:A, 'op1', 'read', 'ownerA', now() + interval '1 hour');
\echo --- owner tries to create a grant for tenant B while in ctx A -> expect RLS error
INSERT INTO support_grants(tenant_id, operator_id, scope, granted_by, expires_at) VALUES (:B, 'op1', 'read', 'ownerA', now() + interval '1 hour');
COMMIT;
\echo === T2b support_rt with the grant: ctx A -> expect 2 rows; ctx B (grant is for A only) -> expect 0 rows
\c p7 support_rt
BEGIN; SELECT set_config('app.tenant_id', :A, true), set_config('app.operator_id','op1',true);
SELECT count(*) AS rows_ctx_A_with_grant, string_agg(note, ',') FROM orders; COMMIT;
BEGIN; SELECT set_config('app.tenant_id', :B, true), set_config('app.operator_id','op1',true);
SELECT count(*) AS rows_ctx_B_grant_is_for_A FROM orders; COMMIT;
\echo === T3a write attempts by support_rt (read-only role) -> expect permission denied
BEGIN; SELECT set_config('app.tenant_id', :A, true), set_config('app.operator_id','op1',true);
UPDATE orders SET total = 0; DELETE FROM orders; INSERT INTO orders VALUES (:A, 9, 1, 'x'); ROLLBACK;
\echo === T3b support_rt cannot read grants of others, cannot change grants, cannot touch audit
BEGIN; SELECT set_config('app.operator_id','op1',true);
SELECT count(*) AS grants_visible_to_op1 FROM support_grants;
UPDATE support_grants SET expires_at = now() + interval '10 years'; ROLLBACK;
SELECT * FROM support_audit; UPDATE support_audit SET detail='x'; DELETE FROM support_audit; TRUNCATE support_audit;
\echo === T4a forged operator id: support_rt acting as 'op2' who holds a grant for A
\c p7 postgres
INSERT INTO support_grants(tenant_id, operator_id, scope, granted_by, expires_at) VALUES ('aaaaaaaa-0000-0000-0000-000000000001', 'op2', 'read', 'ownerA', now() + interval '1 hour');
\c p7 support_rt
BEGIN; SELECT set_config('app.tenant_id', :A, true), set_config('app.operator_id','op2',true);
SELECT count(*) AS rows_when_support_rt_claims_op2 FROM orders; COMMIT;
\echo === T4b owner revokes op1 (UPDATE revoked_at) -> op1 sees 0 on the next transaction
\c p7 app_rt
BEGIN; SELECT set_config('app.tenant_id', :A, true);
UPDATE support_grants SET revoked_at = now() WHERE operator_id = 'op1' AND tenant_id = :A; UPDATE support_grants SET expires_at = now() WHERE operator_id='op1'; COMMIT;
\c p7 support_rt
BEGIN; SELECT set_config('app.tenant_id', :A, true), set_config('app.operator_id','op1',true);
SELECT count(*) AS rows_after_revoke FROM orders; COMMIT;
\echo === T4c expired grant (expires_at in the past) for op3 -> 0 rows
\c p7 postgres
INSERT INTO support_grants(tenant_id, operator_id, scope, granted_by, expires_at) VALUES ('aaaaaaaa-0000-0000-0000-000000000001', 'op3', 'read', 'ownerA', now() - interval '1 minute');
\c p7 support_rt
BEGIN; SELECT set_config('app.tenant_id', :A, true), set_config('app.operator_id','op3',true);
SELECT count(*) AS rows_with_expired_grant FROM orders; COMMIT;
\echo === T5 SECURITY DEFINER function owned by support_fn (a role that has a gated policy)
\echo --- T5a op2 (valid grant on A), ctx A: rows returned and one audit row appended
BEGIN; SELECT set_config('app.tenant_id', :A, true), set_config('app.operator_id','op2',true);
SELECT count(*) AS rows_from_function FROM support_orders_read('ticket-1'); COMMIT;
\echo --- T5b same call but the client ROLLS BACK: is the audit row kept?
BEGIN; SELECT set_config('app.tenant_id', :A, true), set_config('app.operator_id','op2',true);
SELECT count(*) AS rows_from_function FROM support_orders_read('ticket-2-rolled-back'); ROLLBACK;
\echo --- T5c ctx unset (no tenant): the definer-owner policy is evaluated -> expect 0 rows
BEGIN; SELECT set_config('app.operator_id','op2',true);
SELECT count(*) AS rows_no_tenant_ctx FROM support_orders_read('ticket-3-no-ctx'); ROLLBACK;
\echo --- T5d app_rt (no EXECUTE) calls the function -> expect permission denied
\c p7 app_rt
SELECT * FROM support_orders_read('x');
\echo === T6 owner reads its own tenant's audit rows; hash chain verify; then tamper as superuser
\c p7 app_rt
BEGIN; SELECT set_config('app.tenant_id', :A, true);
SELECT seq, operator_id, action, detail, left(encode(hash,'hex'),12) AS hash12 FROM support_audit ORDER BY seq; COMMIT;
BEGIN; SELECT set_config('app.tenant_id', :B, true); SELECT count(*) AS tenant_B_sees_audit_rows FROM support_audit; COMMIT;
\c p7 postgres
SELECT audit_verify('aaaaaaaa-0000-0000-0000-000000000001') AS first_bad_seq_before_tamper;
UPDATE support_audit SET detail = 'edited-by-superuser' WHERE seq = (SELECT min(seq) FROM support_audit);
SELECT audit_verify('aaaaaaaa-0000-0000-0000-000000000001') AS first_bad_seq_after_tamper;
\echo --- deleting the LAST row is not detected by the chain alone (no later row points at it)
INSERT INTO support_audit(operator_id, tenant_id, action, detail) VALUES ('op9','aaaaaaaa-0000-0000-0000-000000000001','probe','tail');
DELETE FROM support_audit WHERE detail = 'tail';
SELECT audit_verify('aaaaaaaa-0000-0000-0000-000000000001') AS first_bad_seq_after_tail_delete_still_reports_older_tamper;
\echo === T7 pg_read_all_data member (support_ro, NOBYPASSRLS): RLS still applies; a non-RLS table is read in full
\c p7 support_ro
BEGIN; SELECT set_config('app.tenant_id', :A, true), set_config('app.operator_id','op2',true);
SELECT count(*) AS orders_rows_for_support_ro FROM orders; SELECT count(*) AS global_ref_rows FROM global_ref; COMMIT;
