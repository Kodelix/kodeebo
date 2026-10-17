-- C1: every table in the app schema that has a tenant_id column: RLS enabled, forced, policy count, owner, owner flags
SELECT c.relname AS tbl, c.relrowsecurity AS enabled, c.relforcerowsecurity AS forced,
       (SELECT count(*) FROM pg_policy p WHERE p.polrelid = c.oid) AS policies,
       pg_get_userbyid(c.relowner) AS owner,
       CASE WHEN NOT c.relrowsecurity THEN 'FAIL: RLS not enabled'
            WHEN NOT c.relforcerowsecurity THEN 'FAIL: not FORCE (owner bypasses)'
            WHEN NOT EXISTS (SELECT 1 FROM pg_policy p WHERE p.polrelid = c.oid) THEN 'WARN: no policy (deny all)'
            ELSE 'ok' END AS verdict
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'app' AND c.relkind IN ('r','p')
  AND EXISTS (SELECT 1 FROM pg_attribute a WHERE a.attrelid = c.oid AND a.attname = 'tenant_id' AND NOT a.attisdropped)
ORDER BY 1;
-- C2: roles that bypass RLS or are superuser, and runtime-role ownership of tenant tables
SELECT rolname, rolsuper, rolbypassrls FROM pg_roles WHERE rolname IN ('kodeebo_app','kodeebo_owner','postgres') ORDER BY 1;
SELECT c.relname AS owned_by_runtime_role FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
 WHERE n.nspname='app' AND c.relkind='r' AND pg_get_userbyid(c.relowner)='kodeebo_app';
-- C3: views over tenant tables that are not security_invoker
SELECT c.relname AS view, coalesce(c.reloptions::text,'(none)') AS reloptions,
       CASE WHEN c.reloptions::text LIKE '%security_invoker=true%' THEN 'ok' ELSE 'FAIL: runs as view owner' END AS verdict
FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='app' AND c.relkind='v' ORDER BY 1;
-- C4: SECURITY DEFINER functions without a pinned search_path (none created in this probe; query shape only)
SELECT p.proname FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
 WHERE n.nspname='app' AND p.prosecdef AND NOT coalesce(p.proconfig::text LIKE '%search_path=%', false);
-- C5 (added in run 3): unique indexes on tenant tables whose FIRST key column is not tenant_id (sync-note F128: such a key lets another tenant probe ids)
SELECT c.relname AS tbl, i.indexrelid::regclass AS unique_index,
       CASE WHEN a.attname = 'tenant_id' THEN 'ok' ELSE 'FAIL: first column is ' || coalesce(a.attname,'(expression)') END AS verdict
FROM pg_index i JOIN pg_class c ON c.oid = i.indrelid JOIN pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum = i.indkey[0]
WHERE n.nspname = 'app' AND i.indisunique AND EXISTS (SELECT 1 FROM pg_attribute t WHERE t.attrelid = c.oid AND t.attname = 'tenant_id' AND NOT t.attisdropped)
ORDER BY 1, 2;
