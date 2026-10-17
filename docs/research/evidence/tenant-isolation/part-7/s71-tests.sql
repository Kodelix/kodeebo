-- S71: corrected run of S70 (tier E). Real SCRAM logins. See s70-WRONG-TEST-note.txt for what was wrong in the first run.
\set ON_ERROR_STOP off
\set A '\'aaaaaaaa-0000-0000-0000-000000000001\''
\set B '\'bbbbbbbb-0000-0000-0000-000000000002\''
\echo === T1 support_rt ctx A operator op1, NO grant: expect 0
\c p7 support_rt
BEGIN; SELECT set_config('app.tenant_id', :A, true), set_config('app.operator_id','op1',true);
SELECT count(*) AS T1_rows_no_grant FROM orders; COMMIT;
\echo === T2a owner ctx A creates a 1-hour read grant for op1 (own transaction, committed)
\c p7 app_rt
BEGIN; SELECT set_config('app.tenant_id', :A, true);
INSERT INTO support_grants(tenant_id, operator_id, scope, granted_by, expires_at) VALUES (:A, 'op1', 'read', 'ownerA', now() + interval '1 hour');
COMMIT;
\echo === T2a2 owner ctx A tries a grant for tenant B (separate transaction): expect RLS error
BEGIN; SELECT set_config('app.tenant_id', :A, true);
INSERT INTO support_grants(tenant_id, operator_id, scope, granted_by, expires_at) VALUES (:B, 'op1', 'read', 'ownerA', now() + interval '1 hour');
ROLLBACK;
\echo === T2a3 owner tries to EXTEND a grant (UPDATE expires_at): expect permission denied (only revoked_at is updatable)
BEGIN; SELECT set_config('app.tenant_id', :A, true);
UPDATE support_grants SET expires_at = now() + interval '10 years'; ROLLBACK;
\echo === T2b support_rt with the grant: ctx A expect 2; ctx B expect 0 (grant is for A)
\c p7 support_rt
BEGIN; SELECT set_config('app.tenant_id', :A, true), set_config('app.operator_id','op1',true);
SELECT count(*) AS T2b_rows_ctx_A_with_grant FROM orders; COMMIT;
BEGIN; SELECT set_config('app.tenant_id', :B, true), set_config('app.operator_id','op1',true);
SELECT count(*) AS T2b_rows_ctx_B_grant_is_for_A FROM orders; COMMIT;
\echo === T3b support_rt sees only its own grant rows and cannot change them or touch audit
BEGIN; SELECT set_config('app.operator_id','op1',true);
SELECT count(*) AS T3b_grants_visible_to_op1 FROM support_grants;
UPDATE support_grants SET expires_at = now() + interval '10 years'; ROLLBACK;
BEGIN; SELECT set_config('app.operator_id','nobody',true); SELECT count(*) AS T3b_grants_visible_to_nobody FROM support_grants; COMMIT;
\echo === T4b owner revokes op1 with the allowed UPDATE (revoked_at only): op1 sees 0 on the next transaction
\c p7 app_rt
BEGIN; SELECT set_config('app.tenant_id', :A, true);
UPDATE support_grants SET revoked_at = now() WHERE operator_id = 'op1' AND tenant_id = :A; COMMIT;
\c p7 support_rt
BEGIN; SELECT set_config('app.tenant_id', :A, true), set_config('app.operator_id','op1',true);
SELECT count(*) AS T4b_rows_after_revoke FROM orders; COMMIT;
\echo === T4a forged operator id: grant held by op2 (inserted by superuser), support_rt claims op2
\c p7 postgres
INSERT INTO support_grants(tenant_id, operator_id, scope, granted_by, expires_at) VALUES ('aaaaaaaa-0000-0000-0000-000000000001', 'op2', 'read', 'ownerA', now() + interval '1 hour');
\c p7 support_rt
BEGIN; SELECT set_config('app.tenant_id', :A, true), set_config('app.operator_id','op2',true);
SELECT count(*) AS T4a_rows_when_support_rt_claims_op2 FROM orders; COMMIT;
\echo === T5 definer function. Audit count first (superuser), then T5a commit, T5b rollback
\c p7 postgres
SELECT count(*) AS audit_rows_before FROM support_audit;
\c p7 support_rt
BEGIN; SELECT set_config('app.tenant_id', :A, true), set_config('app.operator_id','op2',true);
SELECT count(*) AS T5a_rows_from_function FROM support_orders_read('ticket-1'); COMMIT;
\c p7 postgres
SELECT count(*) AS audit_rows_after_T5a_commit FROM support_audit;
\c p7 support_rt
BEGIN; SELECT set_config('app.tenant_id', :A, true), set_config('app.operator_id','op2',true);
SELECT count(*) AS T5b_rows_from_function FROM support_orders_read('ticket-2-client-rolls-back'); ROLLBACK;
\c p7 postgres
SELECT count(*) AS audit_rows_after_T5b_rollback FROM support_audit;
\echo === T5c operator without a live grant (op3 has none) calls the function with ctx A: audit row written, 0 rows returned?
\c p7 support_rt
BEGIN; SELECT set_config('app.tenant_id', :A, true), set_config('app.operator_id','op3',true);
SELECT count(*) AS T5c_rows_op3_no_grant FROM support_orders_read('ticket-3-no-grant'); COMMIT;
\c p7 postgres
SELECT count(*) AS audit_rows_after_T5c FROM support_audit;
\echo === T5d app_rt calls the function: expect permission denied
\c p7 app_rt
SELECT * FROM support_orders_read('x');
\echo === T6 owner reads the audit rows of its own tenant; tenant B sees none
BEGIN; SELECT set_config('app.tenant_id', :A, true);
SELECT seq, operator_id, action, detail, left(encode(hash,'hex'),12) AS hash12 FROM support_audit ORDER BY seq; COMMIT;
BEGIN; SELECT set_config('app.tenant_id', :B, true); SELECT count(*) AS T6_tenant_B_sees_audit_rows FROM support_audit; COMMIT;
\c p7 postgres
SELECT audit_verify('aaaaaaaa-0000-0000-0000-000000000001') AS T6_first_bad_seq_before_tamper;
UPDATE support_audit SET detail = 'edited-by-superuser' WHERE seq = (SELECT min(seq) FROM support_audit);
SELECT audit_verify('aaaaaaaa-0000-0000-0000-000000000001') AS T6_first_bad_seq_after_tamper;
\echo === T11 expiry inside a long transaction. Grant for op5 expires in 3 s. Policy uses now() (transaction start).
INSERT INTO support_grants(tenant_id, operator_id, scope, granted_by, expires_at) VALUES ('aaaaaaaa-0000-0000-0000-000000000001', 'op5', 'read', 'ownerA', now() + interval '3 seconds');
\c p7 support_rt
BEGIN; SELECT set_config('app.tenant_id', :A, true), set_config('app.operator_id','op5',true);
SELECT count(*) AS T11a_now_before_expiry FROM orders;
SELECT pg_sleep(5);
SELECT count(*) AS T11a_now_after_expiry_same_txn FROM orders; COMMIT;
BEGIN; SELECT set_config('app.tenant_id', :A, true), set_config('app.operator_id','op5',true);
SELECT count(*) AS T11a_now_next_txn FROM orders; COMMIT;
\echo === T11b same test after changing the policy to clock_timestamp()
\c p7 postgres
ALTER POLICY support_read ON orders USING (tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid
  AND EXISTS (SELECT 1 FROM support_grants g WHERE g.tenant_id = orders.tenant_id AND g.operator_id = NULLIF(current_setting('app.operator_id', true), '')
              AND g.scope IN ('read','write') AND g.expires_at > clock_timestamp() AND g.revoked_at IS NULL));
INSERT INTO support_grants(tenant_id, operator_id, scope, granted_by, expires_at) VALUES ('aaaaaaaa-0000-0000-0000-000000000001', 'op6', 'read', 'ownerA', now() + interval '3 seconds');
\c p7 support_rt
BEGIN; SELECT set_config('app.tenant_id', :A, true), set_config('app.operator_id','op6',true);
SELECT count(*) AS T11b_clock_before_expiry FROM orders;
SELECT pg_sleep(5);
SELECT count(*) AS T11b_clock_after_expiry_same_txn FROM orders; COMMIT;
