-- comment with a semicolon; and 'quote
CREATE FUNCTION app.tenant_count(p_tenant uuid) RETURNS bigint
LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog, app AS $fn$
DECLARE n bigint;
BEGIN
  SELECT count(*) INTO n FROM app.orders WHERE tenant_id = p_tenant; -- ; inside body
  PERFORM 'a;b'::text;
  RETURN n;
END;
$fn$;
REVOKE ALL ON FUNCTION app.tenant_count(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app.tenant_count(uuid) TO app_rt;
