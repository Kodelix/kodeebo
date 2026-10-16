# /incident - Phase 1: Declare

> Phase 1 of `SKILL.md`. Fast and short: one question at a time, accept
> "don't know" and move on. Read it again if the conversation was compacted or
> resumed.

## 1. Parse the argument

| Argument | Meaning |
|---|---|
| `<description>` | New incident. Use it as the first line of the record |
| `update [file]` | Continue: read the record (default: the one marked `Active`/`Mitigated` in `production/incidents/incident-*.md`, or named in `production/session-state/active.md`) and the last timeline entry; resume at the phase it implies |
| `resolve [file]` | Go to Phase 6 for that record |
| `--sev 1..4` | The user's severity; still confirmed in step 3 |
| none | Ask: "What are customers experiencing right now?" |

If several records are `Active`, list them and ask which; never guess.

## 2. The five facts (ask only what is not already known)

Ask them in one `AskUserQuestion` round where options help, otherwise plain
text. `NOT KNOWN` is a valid answer and is recorded as such.

1. **What do customers experience?** (symptom in customer words; which journey - login, core action, payment, licence activation, data export, webhooks)
2. **Since when?** (UTC; detected via: SLO burn-rate alert / cause alert / customer report / internal / provider notice)
3. **Who is affected?** All tenants / a plan / named enterprise tenants / one tenant / unknown; **hosted**, **self-hosted (which versions)**, or both; surfaces (API, web, Android, iOS, webhooks, jobs)
4. **Could data be exposed, lost or corrupted?** `Suspected` (default until ruled out), `Confirmed`, or `No - ruled out by <named evidence>`. Cross-tenant data, credentials or tokens count as exposure
5. **What changed recently?** Deploy, migration, config or flag change, certificate, provider status, traffic spike (check the deploy log and the provider status page; do not rely on memory)

Read what exists before asking: `docs/architecture/slos.md` (journey IDs, error
budgets), `docs/runbooks/`, recent `git log` on the release branch/tag, the
latest `production/hotfixes/` and `production/qa/` entries.

## 3. Severity (proposed, confirmed by the user)

Propose from the `sre-lead` ladder; quote the rule matched. `qa-lead` owns bug
severity; **incident severity is the user's call with `sre-lead`**. SEV1-SEV4 here
are S1-S4 in the incident template.

| Level | Rule |
|---|---|
| **SEV1 (S1)** | data loss, cross-tenant exposure, or full outage of a critical journey (also: billing or licensing broken for most customers; credential exposure) |
| **SEV2 (S2)** | partial outage, or SLO fast-burn alert firing; a major journey degraded for a tenant segment |
| **SEV3 (S3)** | degraded with a workaround |
| **SEV4 (S4)** | no customer impact |

When uncertain between two levels, propose the higher and say it can be lowered
once facts arrive. `AskUserQuestion` - "I read this as SEV[n] because [rule]. Confirm?"
with the four levels as options.

**Acknowledgement and update cadence per severity**: the ladder requires one,
but this repository fixes no numbers. Look in `docs/runbooks/` and
`docs/architecture/slos.md` for an incident policy. If none states them, ask the user
(and `sre-lead` if wanted) to set the first-update and ongoing-update intervals now,
and record them as "set by [name] at [UTC]". Do not invent a cadence.

## 4. Roles

Three roles (`sre-lead`): **Incident Commander** (decides, owns the record),
**Communications** (customer messages, approves facts for each post),
**Operations** (executes mitigation and diagnosis). Ask who holds each. A solo
operator holds all three; the record says so, and the skill still separates the
steps. Name roles, not people, in anything that leaves the record.

**Security-flavoured** (data exposure Suspected or Confirmed, cross-tenant,
credential exposure, active exploitation): command passes to **`security-lead`**
now. Say it plainly, spawn `security-lead` for the containment order (see
`2-mitigate.md` §4), start the template's **Breach Notification** section, and
involve `privacy-compliance-specialist` for notification duties and deadlines
(Egypt PDPL / GDPR). Those duties and deadlines are **not** stated from memory:
record "regulator notification: required? / deadline / owner" as `NOT KNOWN` until
they supply it.

## 5. Create the record

Fill what is known into `.claude/docs/templates/incident-response.md`
(Severity, Status `Active`, Detected UTC, Duration `ONGOING`, Incident
Commander role, Detected via, Data exposure, Impact Summary with `NOT KNOWN` where
unknown, first Timeline row, first Customer Communication placeholder). Path:
`production/incidents/incident-[date]-[slug].md`, `[date]` from `date -u +%F`.

Ask once: "May I create `production/incidents/incident-[date]-[slug].md` now and
append timeline entries to it as the incident goes on?" - one approval covers the
appends, so mitigation is never slowed by a prompt per line. If the user says no
or wants to wait, keep the timeline in conversation, go on to Phase 2, and ask
again at the next natural pause.

Append one line to `production/session-state/active.md` so a `/clear` or crash
does not lose the incident (appends to that file are exempt from the write
prompt): `Active incident: production/incidents/incident-[date]-[slug].md - SEV[n] - [status] - last update [UTC]`.

Then say: "Declared SEV[n]. Mitigation next: what changed recently, and can we roll
it back?" and continue to Phase 2 without waiting.
