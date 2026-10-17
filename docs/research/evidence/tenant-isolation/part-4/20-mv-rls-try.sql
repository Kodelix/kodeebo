-- run as superuser: can row security be enabled on a materialized view?
SET search_path = s;
ALTER MATERIALIZED VIEW mv_branch_totals OWNER TO migrator;
SET ROLE migrator;
ALTER TABLE mv_branch_totals ENABLE ROW LEVEL SECURITY;
RESET ROLE;
SELECT relname, relkind, relrowsecurity FROM pg_class WHERE relname='mv_branch_totals';
