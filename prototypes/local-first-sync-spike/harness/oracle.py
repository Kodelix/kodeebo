# PROTOTYPE - NOT FOR PRODUCTION
# Question: Does local-first sync ever lose or double-count money or session time under faults? (phase 0 oracle)
# Date: 2026-10-16
#
# Independent oracle: it never imports SUT code. It recomputes what each action should
# have produced from the driver's intent log, then checks the client store and the server
# ledger after quiescence. Invariants: docs/research/local-first-sync.md § 5.1.5 ([E] 5.1)
# and § 9.1.1 (I10).
import hashlib
import json
from collections import Counter, defaultdict


def expected_total(a):
    # Written separately from the client on purpose: same business rule, independent code.
    if "expected_piasters" in a:  # SC-23: the driver's own price model (device price list at each moment)
        return a["expected_piasters"]
    minutes = a["end_min"] - a["start_min"]
    session_piasters = (minutes * a["rate_per_hour"] + 30) // 60
    return session_piasters + a["cafe_piasters"]


def check(intent, acked, client, server, quiesced, integrity, allowed_missing=frozenset()):
    """Return a list of (invariant, detail) violations. Empty list = run passes. allowed_missing: action ids
    the server reported as an unrecoverable range (SC-19); check_restore judges whether that loss was legitimate."""
    v = []
    actions = {a["action_id"]: a for a in intent}
    local_bills = set(client["bills"])
    must_exist = set(acked) | local_bills  # acknowledged, or durably recorded on the device

    sales, payments = defaultdict(list), defaultdict(list)
    for row in server["ledger"]:
        (sales if row["kind"] == "sale" else payments)[row["action_id"]].append(row)

    # I1 - no acknowledged or locally recorded action is lost
    for aid in sorted(must_exist):
        if not sales.get(aid) and aid not in allowed_missing:
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


def expected_hash(a):
    # Canonical command payload, written independently of the client: sorted keys, no spaces.
    total = expected_total(a)
    body = {"action_id": a["action_id"], "session_id": a["session_id"],
            "minutes": list(range(a["start_min"], a["end_min"])), "sale_piasters": total, "payment_piasters": total}
    return hashlib.sha256(json.dumps(body, sort_keys=True, separators=(",", ":")).encode()).hexdigest()


def check_restore(intent, seq_of, server, restores, before, device_cfg, max_archived, retain_days=60):
    """SC-19 (server restored from backup). Returns (violations, allowed_missing).
    seq_of: action id -> device sequence (from the sale replies); restores: [{"epoch", "cursor_after", "h_before"}];
    before: device identity snapshot taken before the restore, seq -> (command_id, payload_hash);
    device_cfg: (epoch, version, price) on the device after quiescence; max_archived: highest verified-restore
    watermark the driver posted. OQ29: the device may prune only below it AND older than retain_days."""
    v = []
    actions = {a["action_id"]: a for a in intent}
    by_seq = {s_: aid for aid, s_ in seq_of.items() if s_ is not None}
    lost = set()
    for e in server["reconcile"]:
        if e["outcome"] == "lost_range":
            lost |= set(range(e["lost_from"], e["lost_to"] + 1))
            if not e["owner_alert"]:
                v.append(("R3", f"lost range {e['lost_from']}-{e['lost_to']} recorded without an owner alert"))
    # R2 - a reported loss is legitimate only if the device was allowed to prune it (OQ29): below a verified
    # watermark AND older than retain_days on the last day of the run
    today = max([a.get("day", 0) for a in intent] or [0])
    for x in sorted(lost):
        a = actions.get(by_seq.get(x))
        if x >= max_archived:
            v.append(("R2", f"seq {x} lost although no verified backup holds it (watermark {max_archived})"))
            break
        if a is not None and a.get("day", 0) >= today - retain_days:
            v.append(("R2", f"seq {x} lost although it is only {today - a.get('day', 0)} days old"))
            break
    # R3 - the server detects every restore itself: a reconciliation event in the new epoch, and a resend or lost
    # range whenever its restored cursor was below what the device held acknowledged
    for r in restores:
        ev = [e for e in server["reconcile"] if e["epoch"] == r["epoch"]]
        if not ev:
            v.append(("R3", f"no reconciliation event after restore to epoch {r['epoch']}"))
        elif r["cursor_after"] < r["h_before"] and not any(e["outcome"] in ("resend", "lost_range") for e in ev):
            v.append(("R3", f"restore {r['epoch']}: cursor {r['cursor_after']} < device {r['h_before']} not detected"))
    # R4 - identity: every command on the server has the original command id and the canonical payload hash
    inbox = {r["seq"]: r for r in server["inbox"]}
    for s_, (cid, h) in before.items():
        row = inbox.get(s_)
        if row and (row["command_id"] != cid or row["payload_hash"] != h):
            v.append(("R4", f"seq {s_} came back as {row['command_id']} / {row['payload_hash'][:8]}, was {cid} / {h[:8]}"))
    for s_, row in inbox.items():
        aid = by_seq.get(s_)
        if aid in actions and row["payload_hash"] != expected_hash(actions[aid]):
            v.append(("R4", f"seq {s_} payload hash differs from the canonical payload of {aid}"))
    # R5 - config feed converges after a restore rewound it
    srv = (server["meta"][0]["epoch"], server["config"][0]["version"], server["config"][0]["price"])
    if tuple(device_cfg) != srv:
        v.append(("R5", f"device config {tuple(device_cfg)} != server {srv}"))
    allowed = {by_seq[x] for x in lost if x in by_seq}
    return v, allowed
