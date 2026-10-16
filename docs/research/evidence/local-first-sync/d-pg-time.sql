\echo '== version / tz data'
select version();
show timezone;
select name, abbrev, utc_offset, is_dst from pg_timezone_names where name = 'Africa/Cairo';
\echo '== Egypt 2026 transitions as PostgreSQL sees them (session TimeZone Africa/Cairo)'
set timezone = 'Africa/Cairo';
select ts at time zone 'UTC' as utc, ts as cairo_local from (values
 ('2026-04-23 21:30+00'::timestamptz), ('2026-04-23 22:00+00'), ('2026-04-23 22:30+00'),
 ('2026-10-29 20:30+00'), ('2026-10-29 21:00+00'), ('2026-10-29 21:30+00'), ('2026-10-29 22:00+00')) t(ts);
\echo '== local-time input in the nonexistent hour (spring) and the repeated hour (autumn)'
select '2026-04-24 00:30'::timestamptz at time zone 'UTC' as nonexistent_0030_as_utc;
select '2026-10-29 23:30'::timestamptz at time zone 'UTC' as repeated_2330_as_utc;

\echo '== elapsed across the autumn change: UTC difference vs naive local-clock difference'
select ('2026-10-29 21:40+00'::timestamptz - '2026-10-29 20:30+00'::timestamptz) as true_elapsed,
       (('2026-10-29 21:40+00'::timestamptz at time zone 'Africa/Cairo') - ('2026-10-29 20:30+00'::timestamptz at time zone 'Africa/Cairo')) as naive_local_diff;
\echo '== elapsed across the spring change'
select ('2026-04-23 22:30+00'::timestamptz - '2026-04-23 21:30+00'::timestamptz) as true_elapsed,
       (('2026-04-23 22:30+00'::timestamptz at time zone 'Africa/Cairo') - ('2026-04-23 21:30+00'::timestamptz at time zone 'Africa/Cairo')) as naive_local_diff;
\echo '== now() is transaction start; clock_timestamp() is the moment of the call (use the latter or statement time for "server received")'
begin; select now() as t0; select pg_sleep(1); select now() as now_after_1s, (clock_timestamp() - now()) >= interval '1 second' as clock_ts_advanced; commit;
\echo '== business day: a 2026-10-29 shift running past midnight, Egypt local cut-off 04:00 (config value in real life)'
select (ts at time zone 'Africa/Cairo' - interval '4 hours')::date as business_day, ts at time zone 'Africa/Cairo' as local_ts
from (values ('2026-10-29 21:30+00'::timestamptz), ('2026-10-30 00:30+00'), ('2026-10-30 01:30+00')) t(ts);
\echo '== billing algorithm A in SQL over the same 5007 vectors (bigint math)'
create table raw(j jsonb);
insert into raw select pg_read_file('/tmp/d-billing-vectors.json')::jsonb;
copy (
 with c as (select (e->>'id')::int id, (e->>'min_billable_minutes')::bigint minm, (e->>'increment_minutes')::bigint inc, e->>'mode' mode, e->'segments' segs from raw, jsonb_array_elements(j) e),
 agg as (select id, minm, inc, mode, sum((s->>'elapsed_ms')::bigint) total, sum((s->>'elapsed_ms')::bigint*(s->>'rate_pph')::bigint) num, (segs->-1->>'rate_pph')::bigint lastrate from c, jsonb_array_elements(segs) s group by id,minm,inc,mode,segs),
 r as (select *, greatest(total, minm*60000) f, inc*60000 unit from agg),
 r2 as (select *, greatest(minm*60000, case mode when 'up' then ((f+unit-1)/unit)*unit when 'down' then (f/unit)*unit else ((2*f+unit)/(2*unit))*unit end) rr from r)
 select id || ',' || floor((2*(num+(rr-total)*lastrate)+3600000)::numeric/(2*3600000))::bigint from r2 order by id
) to '/tmp/d-billing-out-sql.txt';
