-- Part 3 evidence: functional tests T1-T6, T9 against 00-setup.sql (PostgreSQL 18.6). Errors are expected in some blocks and are the point of the test.
-- Run: cat 10-tests.sql | docker exec -i ti-p3-pg psql -U postgres -d ti_p3 > 10-tests.out 2>&1
\set ON_ERROR_STOP off
\pset pager off
\set TA 'aaaaaaaa-0000-4000-8000-000000000001'
\set TB 'bbbbbbbb-0000-4000-8000-000000000001'
\set BA1 'a1a1a1a1-0000-4000-8000-000000000001'
\set BA2 'a2a2a2a2-0000-4000-8000-000000000002'
\set BB1 'b1b1b1b1-0000-4000-8000-000000000001'
\set DA1 'd1d1d1d1-0000-4000-8000-0000000000a1'
\set DA2 'd2d2d2d2-0000-4000-8000-0000000000a2'
\set DB1 'd3d3d3d3-0000-4000-8000-0000000000b1'

\echo '=== T1 pre-context lookup: ti_device cannot read credentials directly, only through auth_device(key_id)'
BEGIN; SET LOCAL ROLE ti_device;
SELECT count(*) FROM s.device_credentials;                                             -- expect: permission denied
COMMIT;
BEGIN; SET LOCAL ROLE ti_device;
SELECT tenant_id, branch_id, device_id, device_status, cred_state FROM s.auth_device('c1c1c1c1-0000-4000-8000-000000000001');  -- expect: 1 row A / a1 / dA1
SELECT count(*) AS rows_for_unknown_key FROM s.auth_device('99999999-0000-4000-8000-000000000009');                            -- expect: 0
COMMIT;

\echo '=== T2 apply_cmd: identity from context (credential of device dA1), payload ids are only claims'
BEGIN; SET LOCAL ROLE ti_device;
SELECT set_config('app.tenant_id', :'TA', true), set_config('app.branch_id', :'BA1', true), set_config('app.device_id', :'DA1', true) \gset
\echo 'a) payload repeats the right ids, seq 1'
SELECT s.apply_cmd(jsonb_build_object('tenant_id', :'TA', 'branch_id', :'BA1', 'device_id', :'DA1', 'command_id', '10000000-0000-4000-8000-000000000001', 'device_seq', 1, 'body', '{"k":"sale","total":5000}'::jsonb));
\echo 'b) payload has no ids at all, seq 2'
SELECT s.apply_cmd(jsonb_build_object('command_id', '10000000-0000-4000-8000-000000000002', 'device_seq', 2, 'body', '{"k":"sale","total":7000}'::jsonb));
\echo 'c) payload claims tenant B, branch b1 and device dB1 (valid credential is dA1), seq 3'
SELECT s.apply_cmd(jsonb_build_object('tenant_id', :'TB', 'branch_id', :'BB1', 'device_id', :'DB1', 'command_id', '10000000-0000-4000-8000-000000000003', 'device_seq', 3, 'body', '{"k":"sale","total":1}'::jsonb));
\echo 'd) payload claims the right tenant but another branch of tenant A (a2)'
SELECT s.apply_cmd(jsonb_build_object('tenant_id', :'TA', 'branch_id', :'BA2', 'device_id', :'DA1', 'command_id', '10000000-0000-4000-8000-000000000004', 'device_seq', 3, 'body', '{"k":"sale","total":1}'::jsonb));
\echo 'e) payload claims right tenant and branch but the other device of tenant A (dA2)'
SELECT s.apply_cmd(jsonb_build_object('tenant_id', :'TA', 'branch_id', :'BA1', 'device_id', :'DA2', 'command_id', '10000000-0000-4000-8000-000000000005', 'device_seq', 3, 'body', '{"k":"sale","total":1}'::jsonb));
\echo 'f) replay of command 1, identical body'
SELECT s.apply_cmd(jsonb_build_object('command_id', '10000000-0000-4000-8000-000000000001', 'device_seq', 1, 'body', '{"k":"sale","total":5000}'::jsonb));
\echo 'g) command 1 again with a different body (altered amount)'
SELECT s.apply_cmd(jsonb_build_object('command_id', '10000000-0000-4000-8000-000000000001', 'device_seq', 1, 'body', '{"k":"sale","total":9000}'::jsonb));
\echo 'h) new command id under used seq 2 (clone or restore)'
SELECT s.apply_cmd(jsonb_build_object('command_id', '10000000-0000-4000-8000-000000000008', 'device_seq', 2, 'body', '{"k":"sale","total":1234}'::jsonb));
\echo 'i) money fact the server flags: seq 3 with needs_review (permission revoked earlier)'
SELECT s.apply_cmd(jsonb_build_object('command_id', '10000000-0000-4000-8000-000000000009', 'device_seq', 3, 'body', '{"k":"sale","total":4200,"needs_review":"permission_revoked"}'::jsonb));
COMMIT;
\echo 'j) no context at all (authentication layer forgot to set it): must fail closed'
BEGIN; SET LOCAL ROLE ti_device;
SELECT s.apply_cmd(jsonb_build_object('command_id', '10000000-0000-4000-8000-000000000010', 'device_seq', 4, 'body', '{}'::jsonb));
ROLLBACK;
\echo '--- superuser view of what was written'
SELECT command_id, device_seq, tenant_id, device_id, branch_id, outcome FROM s.inbox ORDER BY device_seq;
SELECT id, tenant_id, device_id, kind, detail FROM s.device_events ORDER BY id;
SELECT id, tenant_id, branch_id, device_id, reason, status FROM s.review_queue ORDER BY id;
SELECT 'events under tenant B' AS what, count(*) FROM s.device_events WHERE tenant_id = :'TB';

\echo '=== T3 who can read and write what'
\echo '--- ti_dash as tenant B sees nothing of tenant A'
BEGIN; SET LOCAL ROLE ti_dash; SELECT set_config('app.tenant_id', :'TB', true) \gset
SELECT (SELECT count(*) FROM s.inbox) inbox, (SELECT count(*) FROM s.device_events) events, (SELECT count(*) FROM s.review_queue) review;
UPDATE s.review_queue SET status = 'accepted' WHERE id = 1;       -- expect UPDATE 0
COMMIT;
\echo '--- ti_dash as tenant A: reads, decides one review item, cannot edit the fact, cannot delete'
BEGIN; SET LOCAL ROLE ti_dash; SELECT set_config('app.tenant_id', :'TA', true) \gset
SELECT (SELECT count(*) FROM s.inbox) inbox, (SELECT count(*) FROM s.device_events) events, (SELECT count(*) FROM s.review_queue) review;
UPDATE s.review_queue SET status = 'accepted', decided_at = now(), decision_note = 'ok' WHERE id = 1;   -- expect UPDATE 1
COMMIT;
BEGIN; SET LOCAL ROLE ti_dash; SELECT set_config('app.tenant_id', :'TA', true) \gset
UPDATE s.review_queue SET fact = '{}' WHERE id = 2;                -- expect permission denied for column
ROLLBACK;
BEGIN; SET LOCAL ROLE ti_dash; SELECT set_config('app.tenant_id', :'TA', true) \gset
DELETE FROM s.review_queue WHERE id = 2;                           -- expect permission denied
ROLLBACK;
\echo '--- ti_device as dA1: insert-only on events/review/offline; cannot read the review queue or events; cannot delete inbox'
BEGIN; SET LOCAL ROLE ti_device; SELECT set_config('app.tenant_id', :'TA', true), set_config('app.branch_id', :'BA1', true), set_config('app.device_id', :'DA1', true) \gset
SELECT count(*) FROM s.review_queue;                               -- expect permission denied
ROLLBACK;
BEGIN; SET LOCAL ROLE ti_device; SELECT set_config('app.tenant_id', :'TA', true), set_config('app.branch_id', :'BA1', true), set_config('app.device_id', :'DA1', true) \gset
UPDATE s.device_events SET acknowledged_at = now();                -- expect permission denied
ROLLBACK;
BEGIN; SET LOCAL ROLE ti_device; SELECT set_config('app.tenant_id', :'TA', true), set_config('app.branch_id', :'BA1', true), set_config('app.device_id', :'DA1', true) \gset
DELETE FROM s.inbox;                                               -- expect permission denied
ROLLBACK;

\echo '=== T4 forged inserts and the composite foreign key'
BEGIN; SET LOCAL ROLE ti_device; SELECT set_config('app.tenant_id', :'TA', true), set_config('app.branch_id', :'BA1', true), set_config('app.device_id', :'DA1', true) \gset
INSERT INTO s.device_events(tenant_id, branch_id, device_id, kind) VALUES (:'TB', :'BB1', :'DB1', 'seq_conflict');   -- expect RLS violation
ROLLBACK;
BEGIN; SET LOCAL ROLE ti_device; SELECT set_config('app.tenant_id', :'TA', true), set_config('app.branch_id', :'BA1', true), set_config('app.device_id', :'DA1', true) \gset
INSERT INTO s.device_events(tenant_id, branch_id, device_id, kind) VALUES (:'TA', :'BA2', :'DA1', 'seq_conflict');   -- expect RLS violation (branch a2)
ROLLBACK;
BEGIN; SET LOCAL ROLE ti_device; SELECT set_config('app.tenant_id', :'TA', true), set_config('app.branch_id', :'BA1', true), set_config('app.device_id', :'DA1', true) \gset
INSERT INTO s.inbox(tenant_id, device_id, command_id, device_seq, branch_id, payload_hash, outcome) VALUES (:'TA', :'DA2', gen_random_uuid(), 1, :'BA2', '\x00', 'applied');  -- expect RLS violation (device dA2)
ROLLBACK;
\echo '--- policy is tenant-only for ti_dash, so the composite FK must catch a branch the device does not belong to'
BEGIN; SET LOCAL ROLE ti_dash; SELECT set_config('app.tenant_id', :'TA', true) \gset
INSERT INTO s.inbox(tenant_id, device_id, command_id, device_seq, branch_id, payload_hash, outcome) VALUES (:'TA', :'DA1', gen_random_uuid(), 50, :'BA2', '\x00', 'applied');  -- expect FK violation (dA1 belongs to a1)
ROLLBACK;
BEGIN; SET LOCAL ROLE ti_dash; SELECT set_config('app.tenant_id', :'TA', true) \gset
INSERT INTO s.inbox(tenant_id, device_id, command_id, device_seq, branch_id, payload_hash, outcome) VALUES (:'TA', :'DB1', gen_random_uuid(), 51, :'BB1', '\x00', 'applied');  -- expect FK violation (dB1 belongs to tenant B)
ROLLBACK;
\echo '--- a refusal for an UNKNOWN credential has no tenant, so device_events (tenant/branch/device NOT NULL + FK) cannot hold it'
INSERT INTO s.device_events(tenant_id, branch_id, device_id, kind) VALUES (gen_random_uuid(), gen_random_uuid(), gen_random_uuid(), 'id_mismatch');   -- expect FK violation

\echo '=== T5 verified-restore watermark: ops writes across tenants (explicit policy, no BYPASSRLS), devices read their own row only, monotonic'
BEGIN; SET LOCAL ROLE ti_ops;
INSERT INTO s.verified_restore_watermark VALUES (:'TA', :'DA1', :'BA1', 100, 'backup-2026-10-16', now()), (:'TB', :'DB1', :'BB1', 40, 'backup-2026-10-16', now());
UPDATE s.verified_restore_watermark SET hwm_seq = 120 WHERE device_id = :'DA1';     -- expect UPDATE 1
COMMIT;
BEGIN; SET LOCAL ROLE ti_ops;
UPDATE s.verified_restore_watermark SET hwm_seq = 90 WHERE device_id = :'DA1';      -- expect exception: may not decrease
ROLLBACK;
BEGIN; SET LOCAL ROLE ti_device; SELECT set_config('app.tenant_id', :'TA', true), set_config('app.branch_id', :'BA1', true), set_config('app.device_id', :'DA1', true) \gset
SELECT device_id, hwm_seq FROM s.verified_restore_watermark;                        -- expect 1 row (dA1)
UPDATE s.verified_restore_watermark SET hwm_seq = 999;                              -- expect permission denied
ROLLBACK;
BEGIN; SET LOCAL ROLE ti_device; SELECT set_config('app.tenant_id', :'TA', true), set_config('app.branch_id', :'BA2', true), set_config('app.device_id', :'DA2', true) \gset
SELECT count(*) AS dA2_sees FROM s.verified_restore_watermark;                      -- expect 0
ROLLBACK;
BEGIN; SET LOCAL ROLE ti_dash; SELECT set_config('app.tenant_id', :'TB', true) \gset
SELECT tenant_id, device_id, hwm_seq FROM s.verified_restore_watermark;             -- expect only tenant B's row
ROLLBACK;
\echo '--- ti_dash cannot write the watermark'
BEGIN; SET LOCAL ROLE ti_dash; SELECT set_config('app.tenant_id', :'TA', true) \gset
UPDATE s.verified_restore_watermark SET hwm_seq = 10**9;                            -- expect permission denied
ROLLBACK;

\echo '=== T6 fail closed: unset context, and context that was set locally in an earlier transaction'
BEGIN; SET LOCAL ROLE ti_device; SELECT set_config('app.tenant_id', :'TA', true) \gset
COMMIT;
BEGIN; SET LOCAL ROLE ti_device;
SELECT current_setting('app.tenant_id', true) AS tenant_setting_after_commit;
SELECT count(*) AS inbox_rows_visible FROM s.inbox;                                  -- expect 0
INSERT INTO s.device_events(tenant_id, branch_id, device_id, kind) VALUES (:'TA', :'BA1', :'DA1', 'seq_conflict');   -- expect RLS violation
ROLLBACK;
