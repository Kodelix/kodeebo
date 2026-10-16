---
name: launch-checklist
description: "First-launch readiness across every function — engineering, security sign-off, operability, legal/privacy (PDPL/GDPR, terms, DPA), billing live keys and tax/e-invoicing, support, status page, monitoring/on-call, marketing site, analytics consent — with go/no-go sign-offs."
argument-hint: "[launch-date or 'dry-run'] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit(production/session-state/active.md), Agent, AskUserQuestion, Bash(date *), Bash(git ls-files), Bash(git ls-files *), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Bash(bash "*/.claude/skills/launch-checklist/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---
!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,rigor,workflow,project.stage,qa.level,stack,automation`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

# Launch Checklist

The **first** public launch of a product touches more than the code: the terms
a customer accepts, the live payment keys, the tax and invoice rules, who
answers support, where the status page lives, who is paged at 3 a.m., and what
the marketing site promises. This skill builds one checklist across all of those
functions, fills it from the repository and from the user's answers, spawns the
security and operability gates, and returns a go/no-go status.

It is the **first-launch** checklist. The per-release checklist for each
version — migrations, rollback, signed bundle, store requirements — is
`/release-checklist`; this one references it, it does not repeat it.

It records, it does not decide: legal, tax and accounting items are **confirmed
by counsel or an accountant**, never concluded here; sign-offs are the user's.
It sends, publishes, posts and pays **nothing**.

**Output:** `production/releases/launch-checklist-[date].md`

> **Explicit invocation only**: run only when the user asks for
> `/launch-checklist`. Do not auto-invoke on context matching.

**Scope this checklist to the project.** Emitting every item for every surface
trains the reader to skip the list, which defeats the gate:

- **`project.stage`** — items for phases this project has not reached are out of scope; say so rather than listing them unchecked.
- **`modes.rigor`** — at `minimal`, drop items whose only justification is process weight this project has opted out of (never a security, evidence, billing-correctness or privacy item).
- **`stack` line** — `distribution` (`hosted` / `self-hosted` / `hybrid`) decides the self-hosted items in sections 2, 4, 7, 9; `site` decides section 8's marketing-site items; `mobile` decides the store items. A value of `none` / `hosted` is a decision and omits the items with a stated reason. **Unset is not `none`: ask which surfaces exist; if it cannot be determined, mark the section `NOT ASSESSED — [value] unset (/setup-stack)`.** They must not produce the same output.

If an item cannot be scoped because the config is absent, mark it
`NOT ASSESSED — surface/stage unknown`. Do not silently include it.

---

## Phase 1: Parse Arguments

Read the argument for the launch date or `dry-run` mode. Dry-run generates the
checklist without creating sign-off entries or writing files. With no argument
the run is a normal one with the target date unset (`Target Launch: not set`) —
dry-run only when the argument says `dry-run`. Apply `--review` if given.

## Phase 2: Gather Project Context

- Read `project.yaml` (`project.name`, `core.version`), `CLAUDE.md` and `design/product-brief.md` for the product, pricing model, ICP and target markets
- Read the latest milestone in `production/milestones/`
- Read any existing release checklist in `production/releases/` (the launch version's `/release-checklist` result) and the latest `/security-audit` report
- Read `docs/architecture/slos.md`, `perf-budgets.md`, `docs/runbooks/`, `docs/analytics/`, `business/` (marketing, pricing, sales) and the privacy/legal documents if they exist
- Read the pricing artifacts under `design/` if present (shape: `.claude/docs/templates/pricing-model.md`)

Record FOUND / ABSENT for each input. An absent input makes its dependent items
`[?]`, not ticked and not failed.

## Phase 3: Scan Codebase Health

> **Every scan in this phase is a search for something bad, so a zero-hit result
> is ambiguous by construction: it means either "searched and found none" or
> "there was nothing to search". On a launch gate those are opposite findings,
> and a green checkbox renders them identically.**
>
> **Establish the denominator before every scan below, and report it.** Each line
> reads either `scanned [N] files, [M] hits` or
> `NOT ASSESSED — [code roots unresolved | no source files | directory empty]`.
> Never a bare tick. The code roots come from
> `bash .claude/hooks/yaml-helper.sh resolve_code_root` — an empty result means
> the check did not run.
>
> This is written once, over the whole phase, rather than under one of the
> bullets: all of them search the code roots the same way, so if only one carries
> the warning, an empty or absent root returns zero hits repeatedly and reads as
> several clean results.

- Count `TODO`, `FIXME`, `HACK` comments and their locations
- Check for leftover debug output (`console.log`, `fmt.Println`, `println`, `print(`) in production code
- Check for placeholder content (`placeholder`, `lorem ipsum`, `temp_`, `WIP_`, `TODO` strings in user-facing copy and email templates)
- Check for hardcoded test/dev values (`localhost`, `127.0.0.1`, test credentials, test-mode provider keys, `example.com` in release config)
- Check `.env*` files tracked by git (`git ls-files`) and secrets patterns in `deploy/`

**Carry the distinction into the checklist itself.** An item whose scan returned
`NOT ASSESSED` is written `- [?]`, not `- [ ]`. An unticked box says *work
remains*; a `[?]` says *nobody could check*, and only one of those is closed by
doing the work. Include the legend wherever a `[?]` appears:
`[?] = not assessed — the input to this check was absent`.

---

## Phase 4: Generate the Launch Checklist

**Read `references/1-checklist-sections.md` now and follow it** — the eleven
function sections (product and engineering incl. the security sign-off and
operability blocks; legal and privacy; billing, tax and finance; support;
status page; monitoring and on-call; infrastructure; marketing site and GTM;
analytics and consent; operations; sign-offs) are in that file, not here. Read it
again if the conversation was compacted or resumed during this phase. Header:

```markdown
# Launch Checklist: [Product Name]
Target Launch: [Date or DRY RUN]
Generated: [Date]
Editions: [hosted / self-hosted / hybrid] · Surfaces: [web, site, android, ios] · Markets: [Egypt, GCC, ...]
Review mode: [mode] · Workflow: [tier] · Stage: [project.stage]
```

Fill the section 1 counts from Phase 3 and from the files read in Phase 2;
everything else starts unticked or `[?]` until Phase 4b.

## Phase 4a: Security and Operability Gates

**Read `references/2-verdict.md` "Gates" and apply it**: in `full` review mode
spawn `security-lead` for **SL-RELEASE-SECURITY** (the security sign-off) and
`sre-lead` for **SRE-OPERABILITY** in parallel; in `lean` / `solo` record
`[GATE-ID] skipped — [mode] mode`. Record the verdicts in section 1. A skipped
gate is recorded as skipped, never as passed, and the evidence items are still
evaluated.

## Phase 4b: Confirm What Only a Person Can

**Apply `references/2-verdict.md` "Phase 4b".** One `AskUserQuestion` per
section 2–10 for the items no scan or file settled. Skipped in `autonomous` mode
and `dry-run` (said so; the status is then NOT ASSESSED). Then fill the Go / No-Go
section from the answers.

## Phase 5: Save Checklist

**Apply `references/2-verdict.md` "Go / No-Go Decision" and "Save".** Status is
READY / CONDITIONAL / NOT ASSESSED / NOT READY, first match wins. Ask "May I
write this to `production/releases/launch-checklist-[date].md`?" unless
`dry-run`; create nothing before the answer. If the user declines, close with
`BLOCKED — write declined by user`: the status stays in conversation, marked not
recorded.

## Phase 6: Next Steps

**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/launch-checklist <target> —
<status>`, Next step = the first next step below, plus Blocked on / Files in
progress / Open questions; append the Notes line. NOT READY, NOT ASSESSED or a
declined write still updates the checkpoint with the blocker.

- If `project.stage` is not `Release` (earlier stage or unset), run `/gate-check` for the Hardening → Release transition first — it is the readiness gate before launch.
- A missing `/security-audit` or `/load-test`: run them; a missing threat model: `/threat-model`; legal text and tax/e-invoicing rules not sourced: `/research` (and counsel/accountant); pricing or market claims: `/pricing-strategy`, `/market-research`.
- Coordinate sign-offs and the deployment via `/team-release`; the per-version checklist is `/release-checklist`.
- After launch: `/post-release-fix` for the first-week fix sprint, `/incident` for anything live, `/bug-triage` daily in week one.

## Collaborative Protocol

- **Record, never decide** — legal, tax, privacy and accounting items are confirmed by the named professional; a user's "yes" is recorded as the user's statement
- **Never send, post, publish, pay or submit** — status-page posts, announcements, store submissions and live test payments are done by the user; this skill drafts nothing outward-facing on its own
- **A check that did not run is reported as not run** — `[?]`, not a tick; a skipped gate is recorded as skipped; a scan with no denominator is not a result
- **Never recall a legal threshold, tax rate, fee or deadline** — cite the research note or write `NOT SOURCEABLE`
- **No secrets, live keys, bank or tax identifiers, or customer data** in the checklist — record where they live
- **No write before the user says yes** (and none in `dry-run`)
