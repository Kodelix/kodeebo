#!/bin/bash
# migration-lint.sh — observations about SQL migration files. Never a verdict.
#
# Usage: migration-lint.sh <file>...
# Prints one line per finding: "<LEVEL>: <file>: <observation>"
#   DANGER  — data loss or long table lock is likely
#   WARN    — needs a deliberate decision (expand/contract, backfill plan)
#   MISSING — a required companion (down migration) is absent
# Exit status is always 0: callers (validate-commit, validate-migration) decide
# what to do with the observations. Rules: .claude/rules/migrations.md.
#
# Recognised layouts: goose (`-- +goose Up` / `-- +goose Down` in one file),
# golang-migrate / dbmate style (`NNNN_name.up.sql` + `NNNN_name.down.sql`),
# Flyway (`V<n>__name.sql`, with optional `U<n>__name.sql` undo).

[ "$#" -eq 0 ] && exit 0

# tenancy.model gates the tenant_id / RLS observations: schema-per-tenant,
# db-per-tenant and single-tenant isolate without a tenant_id column. Unset
# means unknown, so the shared-schema checks still run. Read with awk, not
# Python: this runs on every migration Write/Edit.
tenancy=""
for cfg in project.local.yaml project.yaml; do
    [ -f "$cfg" ] || continue
    tenancy=$(awk '
        /^tenancy:[[:space:]]*(#.*)?$/ { in_t=1; next }
        /^[^[:space:]#]/               { in_t=0 }
        in_t && /^[[:space:]]+model:/ {
            sub(/^[[:space:]]*model:[[:space:]]*/, ""); sub(/[[:space:]]*#.*$/, "")
            gsub(/["\047]/, ""); print; exit
        }' "$cfg" | tr -d '\r ')
    [ -n "$tenancy" ] && break
done

for f in "$@"; do
    [ -f "$f" ] || continue
    case "$f" in *.sql|*.SQL) ;; *) continue ;; esac
    base=$(basename "$f")

    # --- down migration present? ------------------------------------------
    case "$base" in
        *.down.sql) ;;   # is itself a down
        *.up.sql)
            down="${f%.up.sql}.down.sql"
            [ -f "$down" ] || echo "MISSING: $f: no matching down migration ($down)"
            ;;
        V[0-9]*__*.sql)
            ver=${base#V}; ver=${ver%%__*}
            ls "$(dirname "$f")"/U"${ver}"__*.sql >/dev/null 2>&1 \
              || echo "WARN: $f: Flyway migration without an undo (U${ver}__*.sql); production is forward-only, but dev rollback needs one"
            ;;
        *)
            if grep -qi -- '-- +goose Up' "$f"; then
                grep -qi -- '-- +goose Down' "$f" || echo "MISSING: $f: goose migration has no '-- +goose Down' section"
            fi
            ;;
    esac

    # Down migrations legitimately drop what the up created; only scan ups.
    case "$base" in *.down.sql|U[0-9]*__*.sql) continue ;; esac
    # For goose, only the Up section.
    body=$(awk 'tolower($0) ~ /-- \+goose down/ {exit} {print}' "$f" \
           | sed 's/--.*$//' | tr '\n' ' ' | tr -s ' ')
    upper=$(printf '%s' "$body" | tr '[:lower:]' '[:upper:]')

    case "$upper" in *"DROP TABLE"*|*"DROP COLUMN"*|*"DROP SCHEMA"*|*"DROP DATABASE"*)
        echo "DANGER: $f: drops a table/column/schema — needs user approval, a backup step, and must be the contract phase of expand→contract" ;; esac
    case "$upper" in *"TRUNCATE"*)
        echo "DANGER: $f: TRUNCATE deletes data — needs user approval and a backup step" ;; esac
    case "$upper" in *"DELETE FROM"*)
        printf '%s' "$upper" | grep -qE 'DELETE FROM [^;]*WHERE' \
          || echo "DANGER: $f: DELETE without WHERE" ;; esac

    # Tables created in this same migration are empty and unseen by the running
    # version: indexing or altering them cannot lock live traffic.
    created=$(printf '%s' "$upper" | grep -oE 'CREATE TABLE (IF NOT EXISTS )?[A-Z0-9_."]+' \
              | awk '{print $NF}' | tr -d '"' | sed 's/.*\.//')
    is_new() { printf '%s\n' "$created" | grep -qxF "$(printf '%s' "$1" | tr -d '"' | sed 's/.*\.//')"; }
    live_idx=""
    for t in $(printf '%s' "$upper" | grep -oE 'CREATE (UNIQUE )?INDEX [^;]* ON (ONLY )?[A-Z0-9_."]+' \
               | grep -v 'INDEX CONCURRENTLY' | awk '{print $NF}'); do
        is_new "$t" || live_idx="$live_idx $t"
    done
    [ -n "$live_idx" ] && echo "WARN: $f: CREATE INDEX without CONCURRENTLY on existing table(s):$live_idx — locks writes (CONCURRENTLY cannot run inside a transaction; mark the migration non-transactional)"
    live_alter=""
    for t in $(printf '%s' "$upper" | grep -oE 'ALTER TABLE (IF EXISTS )?(ONLY )?[A-Z0-9_."]+' | awk '{print $NF}'); do
        is_new "$t" || live_alter="$live_alter $t"
    done
    printf '%s' "$upper" | grep -qE 'ALTER COLUMN [^ ]+ (SET DATA )?TYPE' \
      && echo "WARN: $f: ALTER COLUMN TYPE may rewrite the table under an exclusive lock — use expand→migrate→contract"
    if printf '%s' "$upper" | grep -qE 'ADD COLUMN [^,;]* NOT NULL' \
       && ! printf '%s' "$upper" | grep -qE 'ADD COLUMN [^,;]* NOT NULL[^,;]* DEFAULT|ADD COLUMN [^,;]* DEFAULT[^,;]* NOT NULL'; then
        echo "WARN: $f: ADD COLUMN NOT NULL without DEFAULT fails on non-empty tables"
    fi
    # Per statement: a foreign key added by ALTER TABLE to a table that already
    # exists. Inline REFERENCES in CREATE TABLE, or on a table created above,
    # scans nothing.
    live_fk=""
    while IFS= read -r stmt; do
        t=$(printf '%s' "$stmt" | grep -oE 'ALTER TABLE (IF EXISTS )?(ONLY )?[A-Z0-9_."]+' | awk '{print $NF}')
        [ -n "$t" ] || continue
        printf '%s' "$stmt" | grep -qE 'FOREIGN KEY|REFERENCES' || continue
        printf '%s' "$stmt" | grep -q 'NOT VALID' && continue
        is_new "$t" || live_fk="$live_fk $t"
    done <<STMTS
$(printf '%s' "$upper" | tr ';' '\n')
STMTS
    [ -n "$live_fk" ] && echo "WARN: $f: foreign key added to existing table(s):$live_fk without NOT VALID scans under lock — add NOT VALID, then VALIDATE CONSTRAINT separately"
    printf '%s' "$upper" | grep -qE 'RENAME (COLUMN|TO)' \
      && echo "WARN: $f: RENAME breaks the running version and self-hosted installs mid-upgrade — use expand→contract"
    if [ "$tenancy" = shared-schema-rls ] || [ -z "$tenancy" ]; then
    if printf '%s' "$upper" | grep -qE 'CREATE TABLE' \
       && ! printf '%s' "$upper" | grep -q 'TENANT_ID'; then
        echo "WARN: $f: new table without tenant_id — confirm it is genuinely global (not tenant-owned)"
    fi
    if printf '%s' "$upper" | grep -qE 'CREATE TABLE' \
       && printf '%s' "$upper" | grep -q 'TENANT_ID' \
       && ! printf '%s' "$upper" | grep -q 'ROW LEVEL SECURITY'; then
        echo "WARN: $f: tenant-owned table without ENABLE ROW LEVEL SECURITY (required for tenancy.model shared-schema-rls)"
    fi
    fi
    if printf '%s' "$upper" | grep -qE '(^|[^A-Z_])(BIG)?SERIAL([^A-Z_]|$)'; then
        echo "WARN: $f: SERIAL id — fine internally, never expose it in the API (use UUIDv7/ULID public ids)"
    fi
    if ! printf '%s' "$upper" | grep -q 'LOCK_TIMEOUT'; then
        if [ -n "$live_alter$live_idx" ]; then
            echo "WARN: $f: no SET lock_timeout while altering/indexing existing table(s):$live_alter$live_idx — a blocked ALTER queues every query behind it"
        fi
    fi
    printf '%s' "$upper" | grep -qE '(^|[^A-Z_])(FLOAT[0-9]*|REAL|DOUBLE PRECISION)([^A-Z_]|$)' \
      && printf '%s' "$upper" | grep -qE 'PRICE|AMOUNT|TOTAL|BALANCE|COST' \
      && echo "WARN: $f: money-like column with a floating type — use bigint minor units + currency"
done
exit 0
