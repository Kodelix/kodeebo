-- run as kodeebo_owner (table owner, NOBYPASSRLS): FORCE matters
\echo '== O1 owner, no context: orders (FORCE) vs items (not FORCE)'
SELECT 'orders' t, count(*) FROM app.orders UNION ALL SELECT 'items', count(*) FROM app.items;
