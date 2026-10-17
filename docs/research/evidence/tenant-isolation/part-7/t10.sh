#!/usr/bin/env bash
# run inside the container: is any audit extension available?
echo "available audit extensions (count):"
psql -X -U postgres -At -c "select count(*) from pg_available_extensions where name like '%audit%'"
echo "pkglibdir files matching audit:"
ls "$(pg_config --pkglibdir)" | grep -ci audit
echo "all available extensions:"
psql -X -U postgres -At -c "select string_agg(name, ' ' order by name) from pg_available_extensions"
