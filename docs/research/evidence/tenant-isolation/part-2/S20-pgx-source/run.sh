#!/usr/bin/env bash
# S20: read pgx v5.11.0 source (tier-3 primary source) line by line instead of via a summariser.
# Usage: bash run.sh > output.txt 2>&1     Needs curl, unzip. Downloads into a fresh mktemp dir; scripts live here.
set -u
D=$(mktemp -d); trap 'rm -rf "$D"' EXIT
echo "### date (UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
curl -sS -o "$D/pgx.zip" https://proxy.golang.org/github.com/jackc/pgx/v5/@v/v5.11.0.zip && echo "### fetched proxy.golang.org pgx v5.11.0.zip sha256=$(sha256sum "$D/pgx.zip" | cut -c1-16)..."
curl -sS https://proxy.golang.org/github.com/jackc/pgx/v5/@v/v5.11.0.info; echo
unzip -q "$D/pgx.zip" -d "$D/src"; R="$D/src/github.com/jackc/pgx/v5@v5.11.0"
echo; echo "===== tx.go: BeginFunc / BeginTxFunc / beginFuncExec / Commit / Rollback"
grep -n "func BeginFunc\|func BeginTxFunc\|func beginFuncExec\|func (tx \*dbTx) Commit\|func (tx \*dbTx) Rollback\|type TxOptions" "$R/tx.go"
sed -n "$(grep -n 'func beginFuncExec' $R/tx.go | cut -d: -f1),+30p" "$R/tx.go"
echo; echo "===== tx.go: dbTx.Commit / Rollback"
sed -n "$(grep -n 'func (tx \*dbTx) Commit' $R/tx.go | cut -d: -f1),+55p" "$R/tx.go"
echo; echo "===== pgxpool/conn.go: Release"
sed -n "$(grep -n 'func (c \*Conn) Release' $R/pgxpool/conn.go | cut -d: -f1),+50p" "$R/pgxpool/conn.go"
echo; echo "===== pgxpool/tx.go: Commit / Rollback release the connection"
sed -n "$(grep -n 'func (tx \*Tx) Commit' $R/pgxpool/tx.go | cut -d: -f1),+30p" "$R/pgxpool/tx.go"
echo; echo "===== pgxpool/pool.go: hooks (config struct) and Acquire/PrepareConn/BeforeAcquire usage"
grep -n "PrepareConn\|BeforeAcquire\|AfterRelease\|AfterConnect\|BeforeClose\|ShouldPing\|ResetSession" "$R/pgxpool/pool.go"
sed -n "$(grep -n 'PrepareConn' $R/pgxpool/pool.go | head -1 | cut -d: -f1),+12p" "$R/pgxpool/pool.go"
echo; echo "===== ResetSession anywhere in the module (names only)"
grep -rn "ResetSession" "$R" --include=*.go | grep -v _test.go | head
echo; echo "===== PgBouncer / QueryExecMode / statement cache wording in pgx doc comments"
grep -n -i "pgbouncer" "$R/doc.go" "$R/conn.go" "$R/pgxpool/pool.go" "$R/extended_query_builder.go" 2>/dev/null | head -20
grep -n -i "QueryExecMode" "$R/conn.go" | head -40
sed -n "$(grep -n 'type QueryExecMode' $R/conn.go | cut -d: -f1),+55p" "$R/conn.go"
echo; echo "===== doc.go PgBouncer section"
sed -n "$(grep -n -i 'PgBouncer' $R/doc.go | head -1 | cut -d: -f1),+14p" "$R/doc.go"
echo; echo "===== stdlib: ResetSession option"
grep -n "ResetSession" "$R/stdlib/sql.go" | head
echo; echo "### done $(date -u +%Y-%m-%dT%H:%M:%SZ)"
