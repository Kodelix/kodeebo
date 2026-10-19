# PROTOTYPE - NOT FOR PRODUCTION
# Probe (desktop G5-F4 limit): after a failed hot-journal replay, does every later start copy the store aside again?
# Same damage as tamper row hot_journal_page1_flip; then three starts; lists the recovery copies and their hashes.
import os
import shutil
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "harness"))
import tamper as t  # noqa: E402

for cipher in t.CIPHERS:
    d = os.path.join(t.ROOT, "runs", "probe-repeat-copy", cipher)
    shutil.rmtree(d, ignore_errors=True)
    db, _ = t.build(d, cipher, "clean")
    c = t.Client(db, cipher, t.KEY, fp="migrate:mid_ddl:1", cache_pages=5, extra_env={"SCHEMA_VERSION": "2"})
    c.p.wait()
    j = db + "-journal"
    pre = {"client.db": t.sha(db), "client.db-journal": None}
    t.flip(j, t.journal_page1_offset(j) + 200)
    pre["client.db-journal"] = t.sha(j)
    print(f"{cipher}: pre-open store {pre['client.db'][:12]} journal {pre['client.db-journal'][:12]}")
    for start in (1, 2, 3):
        r = t.probe_after(db, cipher, t.KEY)
        rec = db + ".recovery"
        copies = sorted(os.listdir(rec), key=int) if os.path.isdir(rec) else []
        desc = []
        for x in copies:
            p = os.path.join(rec, x)
            desc.append(f"{x}:store={t.sha(os.path.join(p, 'client.db'))[:12]}"
                        + (f",journal={t.sha(os.path.join(p, 'client.db-journal'))[:12]}"
                           if os.path.exists(os.path.join(p, "client.db-journal")) else ",journal=none"))
        print(f"  start {start}: store={(r['stats'] or {}).get('store')} journal_left={os.path.exists(j)} "
              f"store_now={t.sha(db)[:12]} copies={len(copies)} [{'; '.join(desc)}]")
