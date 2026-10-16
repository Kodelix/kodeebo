# Tier-E probe: naive sequence cursor vs xmin-horizon cursor on PostgreSQL 18.6.
# Throwaway container, no published port, removed at the end. Run: python3 -I c-cursor-probe.py
import subprocess, time, sys, os
IMG = "postgres:18.6-alpine3.23"
NAME = "kodeebo-c-probe"
def sh(*a, **k):
    return subprocess.run(a, capture_output=True, text=True, **k)
sh("docker", "rm", "-f", NAME)
r = sh("docker", "run", "-d", "--rm", "--name", NAME, "-e", "POSTGRES_PASSWORD=probe", IMG)
print("container:", r.stdout.strip()[:12], r.stderr.strip())
for _ in range(60):
    if sh("docker", "exec", NAME, "pg_isready", "-U", "postgres").returncode == 0:
        # entrypoint restarts server once; wait for second ready
        time.sleep(3)
        if sh("docker", "exec", NAME, "pg_isready", "-U", "postgres").returncode == 0:
            break
    time.sleep(1)
def q(sql):
    r = sh("docker", "exec", NAME, "psql", "-U", "postgres", "-X", "-A", "-t", "-c", sql)
    return (r.stdout + r.stderr).strip()
class Sess:
    def __init__(self):
        self.p = subprocess.Popen(["docker", "exec", "-i", NAME, "psql", "-U", "postgres", "-X", "-A", "-t", "-q"],
                                  stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    def run(self, sql):
        self.p.stdin.write(sql + "\n"); self.p.stdin.flush()
    def close(self):
        self.p.stdin.close(); self.p.wait(timeout=20)
print("version:", q("select version()"))
q("create table ev(id bigserial primary key, tx xid8 not null default pg_current_xact_id(), body text)")
# Session A opens a transaction and gets id=1 but does not commit yet.
A = Sess(); A.run("begin; insert into ev(body) values ('A-slow');"); time.sleep(1)
# Session B inserts id=2 and commits.
q("insert into ev(body) values ('B-fast')")
# Reader 1: naive cursor on id.
naive_cursor = 0
rows = q(f"select id from ev where id > {naive_cursor} order by id")
print("naive read #1 sees ids:", rows.split() , "-> cursor =", max(map(int, rows.split())))
naive_cursor = int(rows.split()[-1])
# Reader 2: horizon cursor. Rows with tx < xmin(snapshot) are final: every transaction below xmin has finished.
snap = q("select pg_current_snapshot()")
print("snapshot at read #1 (xmin:xmax:xip):", snap)
horizon1 = q("select pg_snapshot_xmin(pg_current_snapshot())")
rows_h = q(f"select id from ev where tx < '{horizon1}'::xid8 order by id")
print("horizon read #1 (tx < xmin) sees ids:", rows_h.split(), "| horizon =", horizon1)
# A commits.
A.run("commit;"); time.sleep(1); A.close()
rows = q(f"select id from ev where id > {naive_cursor} order by id")
print("naive read #2 (id >", naive_cursor, ") sees ids:", rows.split() or "NOTHING  -> id 1 is permanently skipped")
horizon2 = q("select pg_snapshot_xmin(pg_current_snapshot())")
rows_h = q(f"select id from ev where tx >= '{horizon1}'::xid8 and tx < '{horizon2}'::xid8 order by id")
print("horizon read #2 (", horizon1, "<= tx <", horizon2, ") sees ids:", rows_h.split())
print("all rows:", q("select id, tx, body from ev order by id").replace("\n", " ; "))
# Sequence gap on rollback
q("create sequence s")
B = Sess(); B.run("begin; select nextval('s'); rollback;"); time.sleep(1); B.close()
print("nextval after a rolled-back nextval:", q("select nextval('s')"), "(first call returned 1 inside the rolled-back txn; 1 here would mean reuse)")
sh("docker", "rm", "-f", NAME)
