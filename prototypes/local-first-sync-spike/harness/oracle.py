# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does local-first sync ever lose or double-count money or session time under faults? (phase 0 oracle)
# Date: 2026-10-16
#
# Independent oracle: it never imports SUT code. It recomputes what each action should
# have produced from the driver's intent log, then checks the client store and the server
# ledger after quiescence. Invariants: docs/research/local-first-sync.md § 5.1.5 ([E] 5.1)
# and § 9.1.1 (I10).
from collections import Counter, defaultdict


def expected_total(a):
    # Written separately from the client on purpose: same business rule, independent code.
    minutes = a["end_min"] - a["start_min"]
    session_piasters = (minutes * a["rate_per_hour"] + 30) // 60
    return session_piasters + a["cafe_piasters"]


def check(intent, acked, client, server, quiesced, integrity):
    """Return a list of (invariant, detail) violations. Empty list = run passes."""
    v = []
    actions = {a["action_id"]: a for a in intent}
    local_bills = set(client["bills"])
    must_exist = set(acked) | local_bills  # acknowledged, or durably recorded on the device

    sales, payments = defaultdict(list), defaultdict(list)
    for row in server["ledger"]:
        (sales if row["kind"] == "sale" else payments)[row["action_id"]].append(row)

    # I1 - no acknowledged or locally recorded action is lost
    for aid in sorted(must_exist):
        if not sales.get(aid):
            why = "acknowledged" if aid in acked else "recorded on the device"
            v.append(("I1", f"{aid} {why} but missing on the server"))

    # I2 - each action id has at most one effect
    for aid, rows in sales.items():
        if len(rows) > 1:
            v.append(("I2", f"{aid} has {len(rows)} sale rows"))
    for aid, rows in payments.items():
        if len(rows) > 1:
            v.append(("I2", f"{aid} has {len(rows)} payment rows"))

    # I8 - no phantom effects: nothing on the server the device never recorded or acknowledged
    for aid in sorted(set(sales) | set(payments)):
        if aid not in actions:
            v.append(("I8", f"{aid} on the server was never submitted"))
        elif aid not in must_exist:
            v.append(("I8", f"{aid} on the server but neither acknowledged nor recorded on the device"))
    for f in server["flags"]:
        v.append(("I8", f"server flag {f['kind']} for {f['command_id']} seq {f['seq']}"))

    # I3 - conservation: server amounts equal what the business rule says
    want_sum = got_sum = 0
    for aid, rows in sales.items():
        if aid not in actions:
            continue
        want = expected_total(actions[aid])
        for r in rows:
            got_sum += r["amount_piasters"]
            if r["amount_piasters"] != want:
                v.append(("I3", f"{aid} sale {r['amount_piasters']} != expected {want}"))
        for p in payments.get(aid, []):
            if p["amount_piasters"] != want:
                v.append(("I3", f"{aid} payment {p['amount_piasters']} != expected {want}"))
    for aid in must_exist & set(sales):
        want_sum += expected_total(actions[aid])
    if got_sum != want_sum:
        v.append(("I3", f"server sales total {got_sum} != expected {want_sum}"))

    # I4 - per-device order: server apply order follows the device sequence
    seqs = [r["seq"] for r in server["ledger"] if r["kind"] == "sale"]
    for prev, cur in zip(seqs, seqs[1:]):
        if cur <= prev:
            v.append(("I4", f"apply order seq {cur} after seq {prev}"))
            break

    # I5 - each session minute billed once, and every played minute billed
    by_session = defaultdict(list)
    for m in server["minutes"]:
        by_session[m["action_id"]].append(m["minute_idx"])
    for aid, idxs in by_session.items():
        dup = [i for i, n in Counter(idxs).items() if n > 1]
        if dup:
            v.append(("I5", f"{aid} minutes billed more than once: {dup[:5]}"))
        if aid in actions:
            a = actions[aid]
            if set(idxs) != set(range(a["start_min"], a["end_min"])):
                v.append(("I5", f"{aid} billed minutes differ from the session"))

    # I7 - convergence (liveness, reported separately)
    if not quiesced:
        v.append(("I7", "outbox did not drain after faults stopped"))

    # I9 - local store integrity
    if integrity != "ok":
        v.append(("I9", f"PRAGMA integrity_check: {integrity}"))

    # I10 - tamper is visible: hook only in phase 0 (no tamper scenario runs yet)
    return v
