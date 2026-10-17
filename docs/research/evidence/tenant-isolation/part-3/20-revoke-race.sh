#!/bin/bash
# Part 3 evidence T7: does a revocation take effect for a command that is already in flight? PostgreSQL 18.6, READ COMMITTED (default).
# Case 1: the command path only inserts an inbox row (the composite FK takes a KEY SHARE lock on the devices row).
# Case 2: the command path (apply_cmd) first reads the devices row FOR SHARE.
# Run: bash 20-revoke-race.sh > 20-revoke-race.out 2>&1   (needs 00-setup.sql applied; 10-tests.sql may have run before)
P="docker exec -i ti-p3-pg psql -U postgres -d ti_p3 -X -q -At -v ON_ERROR_STOP=1"
TA=aaaaaaaa-0000-4000-8000-000000000001; BA1=a1a1a1a1-0000-4000-8000-000000000001; DA1=d1d1d1d1-0000-4000-8000-0000000000a1
now() { date +%H:%M:%S.%N | cut -c1-12; }
reset() { echo "UPDATE s.devices SET status='active', revoked_at=NULL WHERE id='$DA1'" | $P; }
revoke() {  # prints elapsed seconds of the revoke statement and the wall time it finished
  local t0=$(date +%s.%N)
  printf "BEGIN; SET LOCAL ROLE ti_dash; SELECT set_config('app.tenant_id','$TA',true) \\\\gset\nUPDATE s.devices SET status='revoked', revoked_at=now() WHERE id='$DA1';\nCOMMIT;\n" | $P >/dev/null
  local t1=$(date +%s.%N)
  echo "  revoke finished at $(now), took $(echo "$t1 - $t0" | bc) s"
}

echo "=== Case 1: inbox INSERT only (FK takes KEY SHARE on devices row)"
reset
( printf "BEGIN; SET LOCAL ROLE ti_device;\nSELECT set_config('app.tenant_id','$TA',true), set_config('app.branch_id','$BA1',true), set_config('app.device_id','$DA1',true) \\\\gset\nINSERT INTO s.inbox(tenant_id,device_id,command_id,device_seq,branch_id,payload_hash,outcome) VALUES ('$TA','$DA1',gen_random_uuid(),10,'$BA1','\\\\x00','applied');\nSELECT pg_sleep(3);\nCOMMIT;\n" | $P >/dev/null; echo "  in-flight command committed at $(now)" ) &
sleep 1
echo "  revoke starts at $(now)"
revoke
wait
echo "  final device status: $(echo "SELECT status FROM s.devices WHERE id='$DA1'" | $P); inbox rows for seq 10: $(echo "SELECT count(*) FROM s.inbox WHERE device_seq=10" | $P)"

echo "=== Case 2: apply_cmd (reads the devices row FOR SHARE first)"
reset
( printf "BEGIN; SET LOCAL ROLE ti_device;\nSELECT set_config('app.tenant_id','$TA',true), set_config('app.branch_id','$BA1',true), set_config('app.device_id','$DA1',true) \\\\gset\nSELECT s.apply_cmd(jsonb_build_object('command_id','20000000-0000-4000-8000-000000000001','device_seq',4,'body','{\"k\":\"sale\"}'::jsonb));\nSELECT pg_sleep(3);\nCOMMIT;\n" | $P; echo "  in-flight apply_cmd committed at $(now)" ) &
sleep 1
echo "  revoke starts at $(now)"
revoke
wait
echo "  next command after the revoke committed:"
printf "BEGIN; SET LOCAL ROLE ti_device;\nSELECT set_config('app.tenant_id','$TA',true), set_config('app.branch_id','$BA1',true), set_config('app.device_id','$DA1',true) \\\\gset\nSELECT s.apply_cmd(jsonb_build_object('command_id','20000000-0000-4000-8000-000000000002','device_seq',5,'body','{\"k\":\"sale\"}'::jsonb));\nCOMMIT;\n" | $P
echo "  events of kind revoked_credential_used: $(echo "SELECT count(*) FROM s.device_events WHERE kind='revoked_credential_used'" | $P)"
reset
