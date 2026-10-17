-- S40a tests: run as the real LOGIN role app_rt (NOSUPERUSER NOBYPASSRLS, not owner).
SET search_path = s;
\echo == T0 role attributes (login, not SET ROLE)
SELECT current_user, rolsuper, rolbypassrls FROM pg_roles WHERE rolname = current_user;

\echo == T1 owner of tenant A (branch_all=on): all three A branches, nothing of B
BEGIN; SET LOCAL app.tenant_id='00000000-0000-0000-0000-00000000000a'; SET LOCAL app.branch_all='on';
SELECT branch_id, count(*) FROM bills GROUP BY 1 ORDER BY 1;
SELECT branch_id, n, total FROM report_branch_totals ORDER BY 1;
SELECT count(*) AS bills_of_tenant_b FROM bills WHERE tenant_id='00000000-0000-0000-0000-00000000000b';
COMMIT;

\echo == T2 manager of A1 only (branch_ids=A1)
BEGIN; SET LOCAL app.tenant_id='00000000-0000-0000-0000-00000000000a'; SET LOCAL app.branch_ids='00000000-0000-0000-0000-0000000000a1';
SELECT branch_id, count(*) FROM bills GROUP BY 1 ORDER BY 1;
\echo -- client-supplied filter naming A2 (the "client-sent branch id"):
SELECT count(*) AS rows_when_client_asks_for_A2 FROM bills WHERE branch_id='00000000-0000-0000-0000-0000000000a2';
SELECT count(*) AS rows_when_client_asks_for_tenant_B FROM bills WHERE tenant_id='00000000-0000-0000-0000-00000000000b';
\echo -- tenant-wide catalogue still visible:
SELECT count(*) AS items_visible FROM items;
\echo -- aggregate report (security_invoker view): only A1
SELECT branch_id, n, total FROM report_branch_totals ORDER BY 1;
\echo -- plain (non-invoker) view owned by migrator:
SELECT count(*) AS plain_view_rows FROM report_plain;
\echo -- branches list: tenant-wide (names of sibling branches are visible)
SELECT count(*) AS branches_visible FROM branches;
COMMIT;

\echo == T2b manager A1 writes: INSERT into A2 must fail
BEGIN; SET LOCAL app.tenant_id='00000000-0000-0000-0000-00000000000a'; SET LOCAL app.branch_ids='00000000-0000-0000-0000-0000000000a1';
INSERT INTO bills VALUES (gen_random_uuid(),'00000000-0000-0000-0000-00000000000a','00000000-0000-0000-0000-0000000000a2',1,now());
ROLLBACK;
\echo == T2c manager A1: INSERT into A1 works; UPDATE moving a row from A1 to A2 must fail
BEGIN; SET LOCAL app.tenant_id='00000000-0000-0000-0000-00000000000a'; SET LOCAL app.branch_ids='00000000-0000-0000-0000-0000000000a1';
INSERT INTO bills VALUES (gen_random_uuid(),'00000000-0000-0000-0000-00000000000a','00000000-0000-0000-0000-0000000000a1',1,now());
ROLLBACK;
BEGIN; SET LOCAL app.tenant_id='00000000-0000-0000-0000-00000000000a'; SET LOCAL app.branch_ids='00000000-0000-0000-0000-0000000000a1';
UPDATE bills SET branch_id='00000000-0000-0000-0000-0000000000a2' WHERE id = (SELECT id FROM bills LIMIT 1);
ROLLBACK;
\echo == T2d manager A1: DELETE of A2 rows hits 0 rows
BEGIN; SET LOCAL app.tenant_id='00000000-0000-0000-0000-00000000000a'; SET LOCAL app.branch_ids='00000000-0000-0000-0000-0000000000a1';
DELETE FROM bills WHERE branch_id='00000000-0000-0000-0000-0000000000a2';
ROLLBACK;
\echo == T2e composite FK: bill_lines naming A2 for a bill of A1 must fail even for the owner
BEGIN; SET LOCAL app.tenant_id='00000000-0000-0000-0000-00000000000a'; SET LOCAL app.branch_all='on';
INSERT INTO bill_lines SELECT tenant_id,'00000000-0000-0000-0000-0000000000a2',id,99,1 FROM bills WHERE branch_id='00000000-0000-0000-0000-0000000000a1' LIMIT 1;
ROLLBACK;

\echo == T2f manager of A1 and A2 (two assignments)
BEGIN; SET LOCAL app.tenant_id='00000000-0000-0000-0000-00000000000a'; SET LOCAL app.branch_ids='00000000-0000-0000-0000-0000000000a1,00000000-0000-0000-0000-0000000000a2';
SELECT branch_id, count(*) FROM bills GROUP BY 1 ORDER BY 1;
COMMIT;

\echo == T3 fail closed: tenant set but no branch setting; and nothing set; and empty branch_ids
BEGIN; SET LOCAL app.tenant_id='00000000-0000-0000-0000-00000000000a';
SELECT count(*) AS no_branch_setting FROM bills;
COMMIT;
BEGIN; SELECT count(*) AS nothing_set FROM bills; COMMIT;
BEGIN; SET LOCAL app.tenant_id='00000000-0000-0000-0000-00000000000a'; SET LOCAL app.branch_ids='';
SELECT count(*) AS empty_branch_ids FROM bills; COMMIT;
\echo -- malformed branch list
BEGIN; SET LOCAL app.tenant_id='00000000-0000-0000-0000-00000000000a'; SET LOCAL app.branch_ids='not-a-uuid';
SELECT count(*) FROM bills;
ROLLBACK;
\echo -- branch_all set to something other than on
BEGIN; SET LOCAL app.tenant_id='00000000-0000-0000-0000-00000000000a'; SET LOCAL app.branch_all='true';
SELECT count(*) AS branch_all_true FROM bills; COMMIT;

\echo == T4 a second SET LOCAL in the same transaction silently widens the scope (application must set once)
BEGIN; SET LOCAL app.tenant_id='00000000-0000-0000-0000-00000000000a'; SET LOCAL app.branch_ids='00000000-0000-0000-0000-0000000000a1';
SELECT count(*) AS before_second_set FROM bills;
SET LOCAL app.branch_all='on';
SELECT count(*) AS after_second_set FROM bills;
COMMIT;

\echo == T5 variant 2: scope derived from staff_branches via app.staff_id (no branch list from the token)
\echo -- manager A1 (staff 05a1)
BEGIN; SET LOCAL app.tenant_id='00000000-0000-0000-0000-00000000000a'; SET LOCAL app.staff_id='00000000-0000-0000-0000-0000000005a1';
SELECT branch_id, count(*) FROM bills_v2 GROUP BY 1 ORDER BY 1; COMMIT;
\echo -- manager A1+A2 (staff 05a2)
BEGIN; SET LOCAL app.tenant_id='00000000-0000-0000-0000-00000000000a'; SET LOCAL app.staff_id='00000000-0000-0000-0000-0000000005a2';
SELECT branch_id, count(*) FROM bills_v2 GROUP BY 1 ORDER BY 1; COMMIT;
\echo -- a manager tries to grant himself branch A3 (actor_role=manager): must fail
BEGIN; SET LOCAL app.tenant_id='00000000-0000-0000-0000-00000000000a'; SET LOCAL app.staff_id='00000000-0000-0000-0000-0000000005a1'; SET LOCAL app.actor_role='manager';
INSERT INTO staff_branches VALUES ('00000000-0000-0000-0000-00000000000a','00000000-0000-0000-0000-0000000005a1','00000000-0000-0000-0000-0000000000a3');
ROLLBACK;
\echo -- owner removes manager 05a1 assignment; the very next transaction of that manager sees nothing (no token refresh involved)
BEGIN; SET LOCAL app.tenant_id='00000000-0000-0000-0000-00000000000a'; SET LOCAL app.actor_role='owner';
DELETE FROM staff_branches WHERE staff_id='00000000-0000-0000-0000-0000000005a1'; COMMIT;
BEGIN; SET LOCAL app.tenant_id='00000000-0000-0000-0000-00000000000a'; SET LOCAL app.staff_id='00000000-0000-0000-0000-0000000005a1';
SELECT count(*) AS after_unassign FROM bills_v2; COMMIT;
\echo -- same staff id presented under tenant B context: nothing
BEGIN; SET LOCAL app.tenant_id='00000000-0000-0000-0000-00000000000b'; SET LOCAL app.staff_id='00000000-0000-0000-0000-0000000005a2';
SELECT count(*) AS staff_of_A_under_tenant_B FROM bills_v2; COMMIT;

\echo == T6 materialized view owned by a BYPASSRLS role: read under tenant B context
BEGIN; SET LOCAL app.tenant_id='00000000-0000-0000-0000-00000000000b';
SELECT tenant_id, branch_id, n FROM mv_branch_totals ORDER BY 1,2; COMMIT;
\echo -- is row security even available on a materialized view? (as the owner, in a superuser session this is tried in 20-mv-rls-try.sql)

\echo == T7 timing: EXPLAIN ANALYZE branch-scoped aggregate, variant 1 (list) vs variant 2 (subquery), 3 runs each; owner (branch_all) for reference
\echo -- variant 1, manager A1
BEGIN; SET LOCAL app.tenant_id='00000000-0000-0000-0000-00000000000a'; SET LOCAL app.branch_ids='00000000-0000-0000-0000-0000000000a1';
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF, SUMMARY ON) SELECT count(*), sum(total) FROM bills WHERE created_at > now() - interval '1 day';
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF, SUMMARY ON) SELECT count(*), sum(total) FROM bills WHERE created_at > now() - interval '1 day';
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF, SUMMARY ON) SELECT count(*), sum(total) FROM bills WHERE created_at > now() - interval '1 day';
COMMIT;
\echo -- variant 2, staff 05a2 (A1+A2)
BEGIN; SET LOCAL app.tenant_id='00000000-0000-0000-0000-00000000000a'; SET LOCAL app.staff_id='00000000-0000-0000-0000-0000000005a2';
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF, SUMMARY ON) SELECT count(*), sum(total) FROM bills_v2 WHERE created_at > now() - interval '1 day';
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF, SUMMARY ON) SELECT count(*), sum(total) FROM bills_v2 WHERE created_at > now() - interval '1 day';
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF, SUMMARY ON) SELECT count(*), sum(total) FROM bills_v2 WHERE created_at > now() - interval '1 day';
COMMIT;
\echo -- owner, variant 1 (branch_all)
BEGIN; SET LOCAL app.tenant_id='00000000-0000-0000-0000-00000000000a'; SET LOCAL app.branch_all='on';
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF, SUMMARY ON) SELECT count(*), sum(total) FROM bills WHERE created_at > now() - interval '1 day';
EXPLAIN (ANALYZE, COSTS OFF, TIMING OFF, SUMMARY ON) SELECT count(*), sum(total) FROM bills WHERE created_at > now() - interval '1 day';
COMMIT;
