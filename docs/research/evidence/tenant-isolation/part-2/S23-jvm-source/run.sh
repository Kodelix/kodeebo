#!/usr/bin/env bash
# S23: read HikariCP 7.1.0, Exposed 1.5.1 and pgjdbc 42.7.14 sources (tier 3) from Maven Central source jars.
# Usage: bash run.sh > output.txt 2>&1   Downloads into a fresh mktemp dir; this script lives elsewhere.
set -u
D=$(mktemp -d); trap 'rm -rf "$D"' EXIT; M=https://repo1.maven.org/maven2
echo "### date (UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
get() { # name path
  mkdir -p "$D/$1"; curl -sS -o "$D/$1.jar" "$M/$2" && unzip -q -o "$D/$1.jar" -d "$D/$1" && echo "### $1: $(find "$D/$1" -type f | wc -l) files  <- $M/$2"
}
get hikari  com/zaxxer/HikariCP/7.1.0/HikariCP-7.1.0-sources.jar
get expcore org/jetbrains/exposed/exposed-core/1.5.1/exposed-core-1.5.1-sources.jar
get expjdbc org/jetbrains/exposed/exposed-jdbc/1.5.1/exposed-jdbc-1.5.1-sources.jar
get pgjdbc  org/postgresql/postgresql/42.7.14/postgresql-42.7.14-sources.jar
echo; echo "===== HikariCP ProxyConnection.close(): what happens to an open transaction / dirty state"
f=$(find "$D/hikari" -name ProxyConnection.java); sed -n "$(grep -n 'public final void close' $f | cut -d: -f1),+45p" $f
echo; echo "===== HikariCP ProxyConnection: dirty bits and resetting"
grep -n "DIRTY_BIT\|isCommitStateDirty\|resetConnectionState\|dirtyBits" $f | head -40
echo; echo "===== HikariCP PoolBase.resetConnectionState"
f2=$(find "$D/hikari" -name PoolBase.java); sed -n "$(grep -n 'void resetConnectionState' $f2 | cut -d: -f1),+50p" $f2
echo; echo "===== HikariCP: connectionInitSql use, and any DISCARD/RESET"
grep -rn "connectionInitSql\|DISCARD\|RESET ALL" "$D/hikari" --include=*.java | grep -v "^.*://" | head -20
echo; echo "===== Exposed: where the current transaction lives (ThreadLocal vs coroutine context)"
grep -rn "ThreadLocal\|ThreadContextElement\|asContextElement\|CoroutineContext.Element\|TransactionContextElement\|TransactionScope" "$D/expcore" "$D/expjdbc" --include=*.kt | head -50
echo; echo "===== Exposed: names of suspend transaction entry points"
grep -rn "fun .*suspendTransaction\|fun .*newSuspendedTransaction\|fun .*inTopLevelSuspendTransaction\|fun <T> transaction\|fun <T> inTopLevelTransaction" "$D/expcore" "$D/expjdbc" --include=*.kt | head -30
echo; echo "===== Exposed: deprecation annotations near suspended transactions"
grep -rn -B3 "fun .*newSuspendedTransaction\|fun .*inTopLevelSuspendTransaction" "$D/expjdbc" "$D/expcore" --include=*.kt | grep -i "deprecated\|ReplaceWith" | head
echo; echo "===== Exposed: transaction exec() and connection-level API to run set_config"
grep -rn "fun exec(" "$D/expcore" --include=Transaction.kt | head
echo; echo "===== pgjdbc: reset on connection close / DISCARD / setLocal"
grep -rn "DISCARD\|RESET ALL" "$D/pgjdbc" --include=*.java | head
echo; echo "===== pgjdbc: prepareThreshold default"
grep -rn "PREPARE_THRESHOLD" "$D/pgjdbc" --include=PGProperty.java | head -3
sed -n "$(grep -n 'PREPARE_THRESHOLD(' $(find $D/pgjdbc -name PGProperty.java) | head -1 | cut -d: -f1),+10p" $(find "$D/pgjdbc" -name PGProperty.java)

echo; echo "===== Exposed TransactionContextElement.kt (head)"
head -75 "$D/expcore/org/jetbrains/exposed/v1/core/transactions/suspend/TransactionContextElement.kt"
echo; echo "===== Exposed suspendTransaction (KDoc + signature)"
f=$(find "$D/expjdbc" -path '*jdbc/transactions/Transactions.kt'); sed -n "$(( $(grep -n 'suspend fun <T> suspendTransaction' $f | cut -d: -f1) - 30 )),+45p" $f
echo; echo "===== Exposed experimental newSuspendedTransaction (head)"
sed -n 1,50p "$(find "$D/expjdbc" -name Suspended.kt)"
echo; echo "===== Exposed: JdbcTransaction.exec and connection access"
grep -n "fun <T : Any> exec\|fun exec\|val connection\|fun connection" "$(find "$D/expjdbc" -name JdbcTransaction.kt)" | head
echo; echo "===== pgjdbc QueryExecutorImpl around DISCARD ALL / RESET ALL handling"
sed -n 2495,2515p "$D/pgjdbc/org/postgresql/core/v3/QueryExecutorImpl.java"
sed -n 2540,2565p "$D/pgjdbc/org/postgresql/core/v3/QueryExecutorImpl.java"
echo "### done2 $(date -u +%Y-%m-%dT%H:%M:%SZ)"
