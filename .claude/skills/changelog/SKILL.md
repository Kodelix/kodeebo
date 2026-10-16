---
name: changelog
description: "Generate a changelog from git commits and stories — internal (technical, linked to stories) and customer-facing (outcomes, upgrade notes) variants. Conventional Commits types incl. security and perf; breaking changes first."
argument-hint: "[version | sprint-number] [--component backend|web|android|ios|bundle|api|all]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Bash(date *), Bash(git diff *), Bash(git log *), Bash(git show *), Bash(git rev-parse *), Bash(git for-each-ref *), Bash(git tag --list), Bash(git tag --list *), Bash(git tag --sort=*), Bash(git tag -n), Bash(git tag -n *), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root), Bash(bash .claude/hooks/yaml-helper.sh resolve_code_root *), Bash(bash "*/.claude/skills/changelog/../../hooks/yaml-helper.sh" resolve_config *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,stack`

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). Every `AskUserQuestion` call and
every file write follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

# Changelog

Turns the commits and stories of a release into two documents: an **internal**
changelog (what changed technically, linked to stories, owners and upgrade
steps) and a **customer-facing** one (what customers can now do, what they must
do, what they should know). Both come from the same classified change list, so
they cannot disagree about what shipped.

It reads history; it never tags, pushes, publishes or announces. The styled
customer release notes are `/release-notes`; this skill supplies their
accurate input.

## Recent History

Recent commits: run `git log --oneline -30` first (current branch only). It is
deliberately not a bootstrap line: an injected command that fails aborts the
skill, and a repo with no commits yet must end in a verdict instead (see "If there
is no history to read" below: **BLOCKED**).

Recent tags (newest first):

!`git for-each-ref --count=5 --sort=-v:refname --format="%(refname:short)" refs/tags`

## Provenance check — before trusting the history above

**The commits above may not belong to this product.** This skill's history
blocks are auto-resolved *before* the body runs, so the read has already
happened — what this check governs is whether that output is usable, not whether
it is fetched.

1. Read the injected commit subjects above. **If there are none — the log is
   empty or git is unavailable — skip this check**: there is nothing to
   classify, and Phase 1's no-history branch is the right stop.
2. **Classify each one** as **Product** (a feature, fix, performance or security
   change, a migration, a contract change, deploy or bundle change, or a bug in
   those), **Studio / maintenance** (subjects naming skills, hooks, agents,
   studio docs, CI scaffolding of the framework, or the test plan of the
   framework itself), or **Unclear** — and treat Unclear as Studio.
3. Decide from the counts:
   - **At least one Product commit** → proceed using only those, and state how many of how many you used.
   - **Zero Product commits** → stop, using the message below.

> **Filter per commit; a repo containing maintenance work is not a wrong repo.**
> Every product on this studio accumulates commits touching `.claude/`, hooks and
> CI — the product repo *is* the studio repo. Listing those as a hard STOP fires
> on virtually every real project; the harm is those commits becoming release
> copy, and excluding them prevents that precisely.
>
> This rule is kept identical to `/release-notes`' on purpose — the two read the
> same history for different audiences, and they must not disagree about whose
> history it is. Change both together.

The genuine wrong-history signal is different: Product commits naming a product
that `design/product-brief.md` and the code roots (`resolve_code_root`) never
mention. If you see that, stop with Verdict: **BLOCKED** — history does not match
the product (name the product the commits describe).

If **no** commit in the range is this product's, say so and stop:

> "The git history in this repo does not appear to belong to [product]: 0 of the [N]
> recent commits are Product commits. The recent
> commits describe [what they actually describe]. I cannot generate a changelog
> from it — point me at the right history, or supply the change list directly."

Verdict: **BLOCKED** — stop here without generating a changelog.

**Why this is a hard stop, not a warning.** This failure is real, not
hypothetical: a batch of framework-internal commits produced customer-facing copy
reading *"Fixed an issue where progress from your last session could be lost on
launch"* — a session-hook timeout rendered as a product fix for a product with
no such feature. It was fluent, plausible, and entirely false. A reader cannot
tell the difference; only this check can.

**Do not treat the preamble's existence as evidence.** Injected output means the
command ran, never that its subject is your product.

---

Both blocks are resolved before this skill runs. Use them as the starting point
for Phase 2 rather than re-running the same commands.

---

## Phase 1: Parse Arguments

Read the argument for the target version or sprint number. If a version is
given, use the corresponding git tag. If a sprint number is given, use the sprint
date range. `--component` narrows the change list to the paths of one component
(backend, web, android, ios, self-hosted bundle, API contract); default `all`.

Verify the repository is initialized: run `git rev-parse --is-inside-work-tree`
to confirm git is available. If not a git repo, inform the user and abort
gracefully.

**If there is no history to read** — not a git repository, or no commits yet:

> "No git history found. A changelog is built from commits — commit the work
> first, or supply the change list directly."

Verdict: **BLOCKED** — stop here without generating a changelog.

---

## Phase 2: Gather Change Data

Read the git log since the last tag or release:

```
git log --format='%h %s%n%b---' [last-tag]..HEAD
```

Read bodies as well as subjects: Conventional Commits carry `BREAKING CHANGE:`
footers and `Story:` / `Task:` / `Refs:` / `Spec:` / `ADR:` / `Incident:`
references there. If no tags exist, bound the range explicitly —
`git log --oneline -n 100`. Do not fall back to the full log: on an established
repo that is thousands of lines for a changelog covering one release, and the
oldest of them are the least relevant. If 100 commits does not reach far enough
back, say so and ask for a start ref rather than widening blindly.

For each commit, list the files it touched (`git show --stat --format= <hash>`
or one `git diff --name-only [last-tag]..HEAD` grouped by commit) and map paths
to the **component / edition** it affects:

| Paths | Component / edition |
|---|---|
| `backend/`, `contracts/` | Backend + API (hosted and self-hosted) |
| `web/`, `site/` | Web app / marketing site |
| `mobile/android/` | Android · `mobile/ios/` iOS · `mobile/shared/` both mobile apps |
| `deploy/hosted/` | Hosted only |
| `deploy/self-hosted/` | Self-hosted bundle only |
| `**/migrations/**`, `*.sql` | Database migration (an upgrade step) |

Resolve the roots with `bash .claude/hooks/yaml-helper.sh resolve_code_root`; an
empty result means the path mapping did not run — components are then `unknown`
and the report says so.

Read context for the period: sprint reports in `production/sprints/`, completed
stories in `production/epics/**/story-*.md` (title, type, status), feature specs
in `design/specs/` for new features, accepted ADRs for breaking decisions, and
resolved bugs in `production/qa/bugs/` (to name a fix by the symptom customers
saw). Contract changes: diff `contracts/` against the previous release for
added, deprecated (with `Sunset` date) and removed/breaking endpoints and
fields. Plan/pricing/limit changes: `design/` pricing artifacts.

Propose the **next version by SemVer rule** (`release-manager`'s) from the
evidence: a `!` type marker or `BREAKING CHANGE:` footer, a removed contract
element, a dropped upgrade path or a data-format change → major; `feat` → minor;
otherwise patch. Show the evidence; the user decides.

---

## Phase 3: Categorize Changes

Classify every Product commit from its **Conventional Commits type** first, then
from the story it references, then from the diff when the message is vague:

| Type / marker | Category | Customer-facing? |
|---|---|---|
| `feat` | **New Features** | yes |
| `fix` | **Bug Fixes** | yes (by the symptom customers saw) |
| `perf` | **Performance** | yes, when users can notice it |
| `security` | **Security** | only as the Security entry below, never with exploit detail |
| `type!:` or a `BREAKING CHANGE:` footer | **Breaking Changes** (top of both documents) | yes, with migration steps |
| deprecation (in body, contract diff) | **Deprecations** (with `Sunset` date and replacement) | yes |
| migration files / data-format change | **Upgrade Steps** | yes for self-hosted; hosted stays internal |
| `refactor`, `test`, `docs`, `chore`, `build`, `ci`, `style`, `revert` of internal work | **Technical Debt / Internal** | **never** |
| plan, limit or price change (pricing artifacts, entitlement catalogue) | **Plan & Pricing Changes** | yes — who is affected, from when |
| anything else, or a message too vague to classify confidently | **Miscellaneous** | no, until classified |

**Known Issues**: issues the team is aware of but has not resolved (open S1–S3
in `production/qa/bugs/`), in customer terms, with a workaround if one exists.

For each commit, check whether the message carries a task reference (`Story:`,
`Task:`, `Refs:`, `Spec:`, `ADR:`, `Incident:`, `[STORY-123]`, `#NNN`). Count
commits that lack any and report `Commits without task reference: [N]` in the
Metrics.

**Security handling.** A `security` commit or a fix for a cross-tenant /
credential / authz bug is listed in the **internal** changelog with its
severity, the bug/finding ID and who is affected. In the **customer-facing**
changelog it appears only under *Security* and **only once the fix is available
to every affected customer** (hosted deployed; self-hosted bundle released) —
with severity, who is affected, the action required ("self-hosted: upgrade to
X.Y.Z") and the advisory/CVE ID if one exists. Never include exploit steps,
payloads or internal paths. If the fix is not yet available to all, leave it out
of the customer document, say so in a note to the user, and ask `security-lead`
about disclosure timing. A silent omission is not allowed: the note is
mandatory.

**Hosted-only vs self-hosted.** Tag each customer-facing entry with the
editions it applies to; do not announce a feature to self-hosted customers if it
is licence-gated or hosted-only.

---

## Phase 4: Generate Internal Changelog

```markdown
# Internal Changelog: [Version]
Date: [Date]
Sprint(s): [Sprint numbers covered, or "n/a (minimal workflow)"]
Components: [backend, web, android, ios, bundle, contract]
Commits: [Count] ([first-hash]..[last-hash]) — [N] Product of [M] total

## Breaking Changes
- [What breaks] -- [who/what is affected] -- [migration steps]
  - Commits: [hashes] · Story: [ID] · ADR: [ID] · Contract diff: [link/path]

## New Features
- [Feature Name] -- [Technical description, affected contexts and layers]
  - Edition: [hosted | self-hosted | both] · Commits: [hash1], [hash2]
  - Owner: [who implemented it] · Story: [ID] · Spec: [design/specs/...]

## Improvements
- [Improvement] -- [What changed technically and why]
  - Commits: [hashes] · Owner: [who] · Story: [ID]

## Performance
- [Surface] -- [before -> after, with the measurement or "unmeasured"] -- budget: [perf-budgets row]
  - Commits: [hashes] · Evidence: [path under production/qa/evidence/ or "none"]

## Security
- [SEC-NNN / BUG-NNNN] [Severity] -- [what was fixed, root cause, who is affected]
  - Fix available: [hosted date | bundle version | not yet released]
  - Commits: [hashes] · Owner: [who]

## Bug Fixes
- [BUG-ID] [Description of bug and root cause]
  - Fix: [What was changed] · Regression test: [path or "none"]
  - Commits: [hashes] · Owner: [who]

## Deprecations
- [What] -- deprecated since [version] -- Sunset [date] -- use [replacement]

## Plan & Pricing Changes
- [Plan / limit / price] -- [Old -> New] -- applies from [date] -- affects [who]

## Upgrade Steps
- Migrations: [files, expand/contract phase, locks, downtime]
- Config changes: [new/renamed/removed settings; `.env.example` diff]
- Self-hosted: minimum upgrade-from version [X.Y.Z]; skipped-version path [..]
- Rollback: [supported? what to restore]

## Technical Debt / Refactoring
- [What was cleaned up and why]
  - Commits: [hashes]

## Miscellaneous
- [Change that didn't fit other categories, or vague commit message]
  - Commits: [hashes]

## Known Issues
- [Issue description] -- [Severity] -- [BUG-ID] -- [ETA for fix if known]

## Metrics
- Total commits: [N] · Product commits: [N] · Studio/maintenance (excluded): [N]
- Files changed: [N]
- Lines added: [N]
- Lines removed: [N]
- Commits without task reference: [N]
- Stories referenced: [N]
```

Omit a section that has no entries, except Breaking Changes, which reads `None`
when empty. Every line links its story or commit.

---

## Phase 5: Generate Customer-Facing Changelog

Shape follows `.claude/docs/templates/changelog-template.md`.

```markdown
# What's New in [Version]

**Release Date**: [Date]
**Applies to**: [Hosted | Self-hosted | Android | iOS | Web]

## Breaking Changes
- **[What changes]**: [what customers must do, by when]

## New Features
- **[Feature Name]**: [Customer-friendly description of what they can now do.
  Focus on the outcome, not the implementation. 1-2 sentences.]

## Improvements
- **[What improved]**: [How this makes the product better for the customer.
  Be specific but avoid jargon.]

## Plan & Pricing Changes
- **[What Changed]**: [Old] -> [New]. [Who is affected, effective date, what they need to do.]

## Bug Fixes
- Fixed an issue where [describe what the customer experienced, not what was
  wrong in the code]
- Fixed [customer-visible symptom]

## Security
- [Fixed ... — severity, who is affected, action required (e.g. "self-hosted: upgrade to X.Y.Z"); advisory/CVE ID once available]

## Upgrade Notes (Self-Hosted)
- **Minimum upgrade-from version**: [X.Y.Z]
- **Migrations**: [automatic | manual steps | none] — [estimated downtime]
- **Config changes**: [new/renamed/removed settings]
- **Deprecations & removals**: [what, since which version, sunset date]
- **Rollback**: [supported? what to restore]

## Known Issues
- We are aware of [issue description in customer terms] and are working on a fix.
  [Workaround if one exists.]

---
Questions or problems? Contact [support link]. Status and incidents: [status page link].
```

Omit sections with no entries (Upgrade Notes only for self-hosted releases;
Breaking Changes only when there are some, but never omit one that exists).

---

## Phase 6: Output

Output both changelogs to the user. The internal changelog is the primary
working document. The customer-facing changelog is ready for `/release-notes`
styling and review before it is sent anywhere. Add, below them:

- **Excluded from the customer document**, with the reason for each (internal-only, security fix not yet available to all, vague message needing a decision)
- **Unclassified commits** needing the user's call
- The proposed version and its SemVer evidence

## Phase 7: Offer File Write

After presenting the changelogs, ask the user:

> "May I write this changelog to `CHANGELOG.md`?
> [A] Yes, add this entry at the top (recommended if the file already exists)
> [B] Yes, overwrite the file entirely
> [C] No — I'll copy it manually"

- Check whether `CHANGELOG.md` (repository root) exists before asking. If it does, default the recommendation to **[A]**. `[B]` names what is lost (the existing entries) and needs a second confirmation.
- If the user selects [A]: add the new internal changelog entry at the top of the existing file (newest entries first).
- If the user selects [B]: overwrite the file with the new changelog after the second confirmation.
- If the user selects [C]: stop here without writing (verdict below).
- `Edit` is used only to insert the new entry at the top of an existing
  `CHANGELOG.md`; `Write` creates a new file or replaces it after the second
  confirmation. Nothing else in the repo is edited.

Then ask separately whether to write the customer-facing version to
`production/releases/whats-new-[version].md`. Nothing is written without a yes;
no customer-facing text is sent anywhere by this skill.

After a successful write: Verdict, first match wins:
- **BLOCKED — write declined by user** — the user chose [C] or refused the write: the
  changelogs stay in conversation only and nothing is reported as saved.
- **COMPLETE WITH GAPS** — written, but unclassified commits remain (Miscellaneous
  awaiting a decision), a `security` entry was withheld from the customer document
  pending disclosure timing, or the path mapping did not run (components `unknown`).
  Name each.
- **COMPLETE** — changelog saved to `CHANGELOG.md` (and the customer version, if
  the user asked for it).

---

## Phase 8: Next Steps

**Checkpoint.** Update `production/session-state/active.md` per
`.claude/docs/checkpoint-handoff.md`: Current task `/changelog <range> —
<verdict>`, Next step = the first step below (`/release-notes [version]`), plus
Blocked on / Files in progress (`CHANGELOG.md`, the what's-new file) / Open
questions (unclassified commits, withheld security entry); append the Notes line.
Still updated when the write was declined (`BLOCKED`: record nothing written).

- Use `/release-notes [version]` to generate the styled, saved customer-facing version for publication.
- Use `/release-checklist` before publishing the changelog externally — it checks that notes and upgrade steps exist.
- A security entry that is not yet available to all customers: ask `security-lead` for disclosure timing before any customer document goes out.

### Guidelines

- Never expose internal code references, file paths, story IDs or developer names in the customer-facing changelog
- Group related changes together rather than listing individual commits
- If a commit message is unclear, check the associated files, the story and the bug record for context before guessing; unclassified stays Miscellaneous
- Plan, limit and price changes always get their own section with the effective date and who is affected
- Breaking changes and deprecations come first, with the migration step and the `Sunset` date
- Known issues should be honest — customers appreciate transparency
- Never invent a number: a performance claim carries its measured before/after or says "unmeasured"
- If the git history is messy (merge commits, reverts, fixup commits), clean up the narrative rather than listing every commit literally
- Never put secrets, tokens, customer names or customer data in either document
