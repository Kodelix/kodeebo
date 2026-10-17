#!/bin/bash
# Part 3 evidence T8: what a restore to an earlier point does to server-originated state (a LOGICAL snapshot via pg_dump/pg_restore, PostgreSQL 18.6).
# This illustrates snapshot semantics only. It is NOT a PITR run (no WAL archive, no timelines): PITR is PENDING - S33.
# Run: bash 30-restore-illustration.sh > 30-restore-illustration.out 2>&1
C="docker exec -i ti-p3-pg"
Q() { $C psql -U postgres -d "$1" -X -q -At -F ' | ' -c "$2"; }
TA=aaaaaaaa-0000-4000-8000-000000000001; BA1=a1a1a1a1-0000-4000-8000-000000000001; DA1=d1d1d1d1-0000-4000-8000-0000000000a1
$C psql -U postgres -X -q -c "DROP DATABASE IF EXISTS ti_p3_restore"
echo "--- snapshot taken at T1"
$C pg_dump -U postgres -Fc -d ti_p3 -f /tmp/ti_p3_t1.dump
echo "--- after T1 (server-originated changes a device cannot resend): revoke dA1, enrol dA3 + credential, owner decides review item 2, a new security event"
Q ti_p3 "UPDATE s.devices SET status='revoked', revoked_at=now() WHERE id='$DA1'"
Q ti_p3 "UPDATE s.device_credentials SET state='revoked' WHERE device_id='$DA1'"
Q ti_p3 "INSERT INTO s.devices(tenant_id,id,branch_id,status) VALUES ('$TA','d4d4d4d4-0000-4000-8000-0000000000a3','$BA1','active')"
Q ti_p3 "INSERT INTO s.device_credentials VALUES ('c3c3c3c3-0000-4000-8000-000000000003','$TA','d4d4d4d4-0000-4000-8000-0000000000a3','$BA1','ES256','\\x03','active')"
Q ti_p3 "UPDATE s.review_queue SET status='accepted', decision_note='after snapshot' WHERE id=2"
Q ti_p3 "INSERT INTO s.device_events(tenant_id,branch_id,device_id,kind) VALUES ('$TA','$BA1','$DA1','clone_suspected')"
echo "--- live database (before the restore)"
Q ti_p3 "SELECT 'devices', id, status FROM s.devices WHERE tenant_id='$TA' ORDER BY id"
Q ti_p3 "SELECT 'review item 2', status FROM s.review_queue WHERE id=2"
Q ti_p3 "SELECT 'clone_suspected events', count(*) FROM s.device_events WHERE kind='clone_suspected'"
$C psql -U postgres -X -q -c "CREATE DATABASE ti_p3_restore"
$C pg_restore -U postgres -d ti_p3_restore /tmp/ti_p3_t1.dump
echo "--- restored database (state at T1)"
Q ti_p3_restore "SELECT 'devices', id, status FROM s.devices WHERE tenant_id='$TA' ORDER BY id"
Q ti_p3_restore "SELECT 'credential of dA1', state FROM s.device_credentials WHERE device_id='$DA1'"
Q ti_p3_restore "SELECT 'credential c3 present', count(*) FROM s.device_credentials WHERE key_id='c3c3c3c3-0000-4000-8000-000000000003'"
Q ti_p3_restore "SELECT 'review item 2', status FROM s.review_queue WHERE id=2"
Q ti_p3_restore "SELECT 'clone_suspected events', count(*) FROM s.device_events WHERE kind='clone_suspected'"
echo "--- roles, grants, policies after restore (policies are in the dump; roles are cluster-level and were not dumped)"
Q ti_p3_restore "SELECT count(*) AS policies FROM pg_policies WHERE schemaname='s'"
Q ti_p3_restore "SELECT relname, relrowsecurity, relforcerowsecurity FROM pg_class WHERE relnamespace='s'::regnamespace AND relkind='r' ORDER BY relname"
