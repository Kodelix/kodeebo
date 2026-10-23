# Seed-1006 replays (founder 2026-10-23; spike runner, gitignored): the NMI held at client:after_mark #1 (S104 set 5
# attempt 3's failing cut), N times in each setup, to isolate the cause of the store failure.
#   s104rep.py <setup> <reps>    setup = truncslots_bg | truncslots | deletefile_bg | deletefile
import json, os, sys, time
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "harness"))
import p4  # noqa: E402

SETUPS = {
    "truncslots_bg": {"JOURNAL": "truncate", "MARKER_MODE": "slots", "START_CHECK": "background", "BG_MODE": "counter",
                      "BG_IDLE_S": "0.3", "BG_STEP": "16"},
    "truncslots":    {"JOURNAL": "truncate", "MARKER_MODE": "slots"},
    "deletefile_bg": {"JOURNAL": "delete", "MARKER_MODE": "file", "START_CHECK": "background", "BG_MODE": "counter",
                      "BG_IDLE_S": "0.3", "BG_STEP": "16"},
    "deletefile":    {"JOURNAL": "delete", "MARKER_MODE": "file"},
}
setup, reps = sys.argv[1], int(sys.argv[2])
p4.prep_crash()
out = {"harness_commit": p4.git_state(), "setup": setup, "client_env": SETUPS[setup], "cut": ["nmi", 1006,
       "client:after_mark", 1], "runs": []}
print(f"seed-1006 replay, setup {setup}, {reps} runs, commit {out['harness_commit']}", flush=True)
for i in range(1, reps + 1):
    t0 = time.time()
    run = p4.WinRun(1006, ("nmi", None, "client:after_mark", 1), label=f"p4-s104rep-{setup}-r{i}")
    run.client_env.update(SETUPS[setup])
    # every rep in its own VM folder: the same seed gives the same test key, so a reused folder (r2 of the first try)
    # opened the previous rep's store; the folder must not exist before the rep starts
    run.vdir = f"{p4.WDIR}\\runs\\rep-{setup}-r{i}"
    if "YES" in p4.sh("cs", f"if exist {run.vdir} (echo YES) else (echo NO)", timeout=30):
        raise RuntimeError(f"the VM folder {run.vdir} already exists before rep {i}")
    try:
        r = run.go()
    except Exception as e:  # a store the oracle cannot open is a RESULT here (attempt 3's failure), not a harness fault
        if "malformed" not in str(e) and "not a database" not in str(e):
            raise
        r = {"fired": run.fired, "acked": None, "server_sales": None, "hot_journal_at_restart": getattr(run, "hot_journal", None),
             "boot_s": getattr(run, "boot_s", None), "violations": [["STORE", f"the store could not be opened after the cut: {e}"]]}
    ev = os.path.join(run.dir, "client.db.events.jsonl")
    refusals = [ln.strip() for ln in open(ev)] if os.path.exists(ev) else []
    row = {"rep": i, "fired": r["fired"], "acked": r["acked"], "server_sales": r["server_sales"],
           "hot_journal_at_restart": r["hot_journal_at_restart"], "boot_s": r["boot_s"],
           "violations": r["violations"][:3], "store_events": refusals[:3], "seconds": round(time.time() - t0)}
    out["runs"].append(row)
    print(f"  {setup} r{i}: fired {bool(r['fired'])} acked {r['acked']} server {r['server_sales']} hot journal "
          f"{r['hot_journal_at_restart']} boot {r['boot_s']} s violations {len(r['violations'])} "
          f"{r['violations'][:1]} events {refusals[:1]} ({row['seconds']} s)", flush=True)
out["failures"] = sum(1 for x in out["runs"] if x["violations"] or x["store_events"])
with open(os.path.join(p4.RUNS, f"p4-s104rep-{setup}-summary.json"), "w") as f:
    json.dump(out, f, indent=1, default=str)
print(f"seed-1006 replay {setup}: {out['failures']} of {reps} runs with a violation or a store refusal")
