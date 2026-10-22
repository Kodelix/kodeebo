# PROTOTYPE - NOT FOR PRODUCTION
# Set 5 Linux check (founder, 2026-10-22): fix 4 with BG_REPEAT=1 and TIMING=1 on a small store. Expected: checks run
# back to back (checks_done rises, check_log has start/end/copy/check), every operation reports its queue wait and
# the copy step it waited behind, bg_state reports the in-progress check's start and the VM-style wall clock.
import json
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import tamper as t  # noqa: E402

OUT = os.path.join(t.ROOT, "runs", "repeatcheck")


def main():
    db = t.fresh(OUT)
    c = t.Client(db, "chacha20", t.KEY)
    for i in range(1500):
        assert (c.send(t.sale(i, minutes=120)) or {}).get("ok")
    c.exit()
    c = t.Client(db, "chacha20", t.KEY, extra_env={"START_CHECK": "background", "BG_MODE": "counter", "BG_REPEAT": "1",
                                                   "BG_IDLE_S": "0.2", "BG_STEP": "16", "TIMING": "1"})
    c.send({"op": "marker"})
    rows = []
    for burst in range(6):  # a small rush: 5 sales 0.1 s apart, then 3 s of quiet
        for k in range(5):
            r = c.send(t.sale(20000 + burst * 10 + k, minutes=5)) or {}
            rows.append({k_: (r.get("ms") or {}).get(k_) for k_ in ("total", "queued", "step_ms")} | {"ok": r.get("ok")})
            time.sleep(0.1)
        time.sleep(3)
    bg = c.send({"op": "bg_state"}) or {}
    c.exit()
    ok = (all(x["ok"] for x in rows) and all(x["queued"] is not None and x["step_ms"] is not None for x in rows)
          and (bg.get("checks_done") or 0) >= 2 and bg.get("check_log") and bg.get("restarts") == 0
          and "now_wall" in bg and "copy_started_rel" in bg and not bg.get("fault"))
    print(json.dumps({"checks_done": bg.get("checks_done"), "check_log": bg.get("check_log"), "restarts": bg.get("restarts"),
                      "steps": bg.get("steps"), "step_buckets": bg.get("step_buckets"),
                      "max_queued_ms": max(x["queued"] for x in rows), "max_step_ms": max(x["step_ms"] for x in rows),
                      "fields": sorted(bg)[:40]}, indent=1))
    print("repeatcheck:", "PASS" if ok else "FAIL")


if __name__ == "__main__":
    main()
