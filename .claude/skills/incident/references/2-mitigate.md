# /incident - Phase 2: Mitigate

> Phase 2 of `SKILL.md`. The goal is to stop the damage, not to explain it.
> The skill proposes; the user (or the named operator) runs. Nothing here is
> executed on production by the skill.

## 1. Find the runbook

Search `docs/runbooks/` for the alert name, symptom, journey or component
(`Grep` the "Linked alerts" and "Symptoms" lines of each runbook, template:
`.claude/docs/templates/runbook.md`).

- **Found:** read it; follow its Diagnosis and Mitigation sections, in its order,
  stating each step before the user runs it. Note its **Last verified** date; a
  runbook never exercised since the system changed is flagged ("last exercised
  [date]") and used with care.
- **Not found:** say "no runbook for this" and record it as a prevention action
  (an alert without a runbook is not merged: `observability-standard.md`). Work from
  the options in §2 and the deploy rules instead.
- Anything marked DESTRUCTIVE in a runbook (`-v`, DROP, FLUSHALL, force-push,
  deleting volumes, restore over live data) needs the user to name the target and
  confirm before it is run.

## 2. Mitigation options

List only the ones that apply to what the five facts say, each with expected
effect, risk, who executes and how it is verified. Ask which to apply
(`AskUserQuestion`, multiSelect allowed; include "none yet - need more facts").

| Option | When | Constraint |
|---|---|---|
| **Roll back the last deploy** (hosted) | a deploy/config change precedes the start | previous image digests retained; zero-downtime order (start old/new -> health -> switch -> stop). Production migrations are forward-only: roll back the app only if the migration shipped with it was expand-only and the previous app version is compatible (`migrations.md`, `deploy.md`); otherwise say so and pick another option |
| **Turn the feature off** | a flag / kill switch / config exists | confirm the flag's blast radius first |
| **Scale or restart** | saturation (CPU, connections, memory, queue lag) with a known headroom path | restarting without cause hides evidence: capture traces/log queries first |
| **Rate-limit, block or WAF-rule** a path or tenant | one caller or route is the source | per-tenant effect named; audit the action |
| **Pause a job, consumer or webhook delivery** | a poison message, runaway job or provider storm | events are queued, not dropped; record where they wait |
| **Provider degraded mode / failover** | a third-party outage | the spec's degraded mode (integration spec §6); what users see |
| **Halt a mobile staged rollout**; keep the previous build live | a bad mobile build | mitigate server-side where possible |
| **Self-hosted release problem** | a bad self-hosted build | stop distributing the release (update channel), publish guidance; fix via `/hotfix` |
| **Restore from backup** | data loss or corruption | **DESTRUCTIVE if over live data.** Restore into a scratch instance first, verify, then decide; never over live data without the user naming the target and instance |

Capture before you change: note the trace IDs, a log query and the dashboard
panel that show the problem (links, UTC), so a mitigation does not erase the
evidence the postmortem needs.

## 3. Apply and verify

1. State the exact step and who runs it; the user confirms it ran and when (UTC).
   Append to the timeline: time, action, who, expected effect.
2. Verify against the **SLI**, not impressions: the journey's error rate/latency on
   the dashboard back toward range; a probe of the affected request (read-only);
   queue lag falling. If the user reports the numbers, record them. Without data:
   `effect NOT VERIFIED` - the incident stays `Active`.
3. A mitigation that works -> Status `Mitigated`, time recorded, and the temporary
   parts listed as **open items** (flag left off, rollback not rolled forward,
   scaled-up capacity). A mitigation that does not -> record it as failed, go back
   to §2.

## 4. Security-flavoured incidents (fixed order)

`security-lead` commands. The order, so evidence is not destroyed:

1. **Contain**: disable the path that leaks or is exploited (flag, route block,
   tenant isolation) - do not delete data.
2. **Preserve evidence** before rotating or deleting anything, **time-boxed**
   (15 minutes by default, set shorter by the user when the credential is in active
   abuse): audit-log export, relevant logs and traces, snapshots; location recorded
   in the record's Breach Notification section (not the content). The box ends, and
   rotation proceeds, with whatever was captured; forensics never delay rotation.
3. **Rotate** exposed credentials and keys (then remove from history);
   record what was rotated and when, never the value.
4. **Scope**: which tenants, which records, since when - from the append-only audit
   log, not memory. `NOT KNOWN` until established.
5. **Notify** per the duties `privacy-compliance-specialist` and counsel confirm;
   the user decides and sends. Nothing about the weakness goes in a public message
   until the fix reaches every affected edition (`/hotfix`).

Customer-facing posts for a security incident are held to the minimum that the
duties require and are approved by `security-lead`.
