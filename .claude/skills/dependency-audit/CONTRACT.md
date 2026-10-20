# /dependency-audit - Handoff Contract

## Role in Pipeline
Audits dependencies and the supply chain with real tool output. Called by
`/team-security`, `/team-hardening`, `/release-checklist` and `/integration`
(new SDK follow-up); its report is cited by `/security-audit` categories 8-9 and
read by the `SL-RELEASE-SECURITY` gate and `/tech-debt`.

## Inputs Consumed
| Input | Required | Read-only? |
|-------|----------|-----------|
| Manifests, lockfiles, images, CI files discovered in the repository | Yes (none found = NOT ASSESSED for that ecosystem) | Yes |
| `docs/stack-reference/pins.yaml`, `tooling/`, `<layer>/{VERSION,deprecated-apis}.md` | Yes | Yes |
| `.claude/docs/standing-decisions.md` decisions L1-L4, T1; `.claude/rules/deploy.md` | Yes | Yes |
| `project.yaml` via `resolve_config` (`stack`, `review_mode`, `automation`) | Yes (unset = asked) | Yes |
| `bash .claude/scripts/project-coherence.sh` | Yes | Run, not edited |
| Installed tools: govulncheck, osv-scanner, pnpm, gitleaks | Each optional; absent = `not run` | - |

## Preconditions
- The user agrees that OSV-Scanner and `pnpm audit` contact advisory databases/registries
- Nothing is installed or upgraded without the user's explicit yes

## Verdicts Emitted
`DO NOT SHIP` / `FIX BEFORE SHIPPING` / `NOT ASSESSED` / `CLEAR TO SHIP`; first
match wins. NOT ASSESSED outranks CLEAR TO SHIP and ranks below the two failure
values. A narrowed scope never yields CLEAR TO SHIP.

## Outputs Produced
| File | Guaranteed content | Notes |
|------|--------------------|-------|
| `production/qa/dependency-audit-[date]-[scope].md` | tools table with versions vs pins, coverage table over the whole inventory, findings DEP-NNN, redacted secrets table, L1-L4 table, licence table, deprecated-API coverage lines, freshness table, `project-coherence.sh` output verbatim, Not run list | after approval |
| `production/qa/evidence/dependency-audit-[date]-[scope]/` | raw tool output (redacted), coherence output, freshness output | after approval |

## Output Guarantees
- Every inventory row appears in the coverage table as scanned, unscanned or not run, each with a reason
- A tool that did not run, and a lockfile no tool scanned, are named; neither reads as clean
- No secret value, customer data or exploit appears in any output
- Versions, flags and advisory IDs are as printed by the tools or the references; none is recalled

## Immutability Rules
- Reads the repository and the studio references; runs scanners and the coherence script
- Writes only the two output paths; edits no manifest, lockfile, source, deploy file, reference or pin
- Never runs `osv-scanner fix`, an install, an upgrade or a history rewrite

## Hard Constraints (Never Violate)
- Never reports a skipped or absent tool as a clean result
- Never accepts a risk, downgrades a finding or infers a licence decision
- Never prints a secret (gitleaks runs with `--redact`)
- A suspected live secret is announced immediately and routed to `security-lead`

## Downstream Skill Expects
- `SL-RELEASE-SECURITY` and `/security-audit`: scan results, the unscanned list and the secret-scan result
- `/tech-debt`: deprecated-API rows with file:line and replacements as sourced
- `/research refresh`: the STALE layers list

## Known Fragile Points
- OSV-Scanner support for `pnpm-lock.yaml` and SwiftPM `Package.resolved` is not in the sourced table; coverage is decided by the tool's own output
- No sourced licence-inventory tool: transitive licences stay unreviewed until `/research` picks one
- govulncheck's exit code is 0 with or without findings; the output must be read
- A pnpm version or registry change can alter `pnpm audit` output; flags beyond the bare command are not sourced
