# /dependency-audit - Phase 6: Severity, Verdict and Report

> Phase 6 of `SKILL.md`. Severity is rated against this table only; the
> triaging agent does not pre-rate.

## Severity

| Level | Typical | Fix window (`security-lead` policy) |
|---|---|---|
| CRITICAL | a vulnerability reported **reachable** by govulncheck (or confirmed reachable on an internet-facing path) with critical impact in the advisory; a live secret in history that has not been rotated | 48 h |
| HIGH | a reachable vulnerability of high impact; a vulnerability with a published fix in a shipped component on an internet-facing surface; L1-L4 breach in the customer bundle; strong-copyleft or source-available terms shipped without a recorded decision; `react-server-dom-*` in the SPA lockfile; a deprecated API with a published advisory | 7 d |
| MEDIUM | present but not reachable; a deprecated/removed API with no advisory; `BEHIND` pins; `FLOATING` tags; unpinned actions; weak pnpm supply-chain settings; a stale stack reference in use; weak copyleft with an open question | 30 d |
| LOW | hygiene; deprecated but working; stale reference not in use | 90 d |

Reachability first (govulncheck), then exposure (internet-facing vs internal),
then data class. **A CVSS base score alone never sets severity.** A suppression
names the finding ID, the reason, the owner and an **expiry date**; an expired or
blanket suppression is a finding.

## Verdict (first match wins)

1. **DO NOT SHIP** - any open CRITICAL.
2. **FIX BEFORE SHIPPING** - any open HIGH (and no CRITICAL). The known finding
   comes first, with any unscanned category named beside it.
3. **NOT ASSESSED** - no CRITICAL/HIGH, but any of: a tool not run (absent,
   errored, declined); an inventory row `unscanned` or `not run`; a lockfile with
   no tool that scans it; gitleaks history scan not run; the licence of a direct
   dependency unknown; transitive licences not reviewed; a stack reference with no
   readable date; `project-coherence.sh` `SKIPPED`; a deprecated-apis reference
   absent for a layer in use; an unset `stack` value that gates a category; a
   narrowed scope. Name every cause and what closes it.
4. **CLEAR TO SHIP** - every in-scope category assessed with the tools' real
   output on disk and no open CRITICAL/HIGH. MEDIUM/LOW findings are listed with
   their windows. Never given for a narrowed scope.

Accepted risk is the user's decision, recorded with an owner and an expiry; this
skill never accepts a risk or downgrades a finding.

## Report template (`production/qa/dependency-audit-[date]-[scope].md`)

```markdown
# Dependency Audit - [date] - [scope]
Verdict: [DO NOT SHIP | FIX BEFORE SHIPPING | NOT ASSESSED | CLEAR TO SHIP]
Causes: [each open CRITICAL/HIGH, then each NOT ASSESSED cause with what closes it]
Stack: [stack line]   Distribution: [value | unset]   Code roots: [list]   Review mode: [mode]
Triaged by: [appsec-engineer | this session - reason]

## Tools
| Tool | Reported version | Pin | Command | Scope | Result (N findings / clean / not run: reason) |

## Coverage (denominator = inventory)
| Path | Ecosystem | Tool | Scanned / unscanned (reason) / not run (reason) | Findings |

## Findings
DEP-NNN | category | severity | component@version | reachable? | advisory ID as printed by the tool | fixed in (as printed) | exposure | fix window | owner

## Secrets (gitleaks, redacted)
| Rule ID | File | Line | Commit | Rotated? |

## Bundle rules L1-L4
| Rule | Evidence | Met / breached / n/a (reason) / not run |

## Licences
(direct N of M reviewed; transitive: not reviewed - reason)
| Dependency | Version | SPDX as read | Source URL | Shipped where | Flag | Decision (owner, date) |

## Deprecated APIs
| Layer | Rows / greppable / hits / not greppable | Hits file:line -> replacement (as the reference states) |

## Stack-reference freshness
| Layer | Last verified | Age (days) | STALE / FRESH / NO DATE |

## project-coherence.sh (verbatim)
[output]

## Not run / not checked
[every tool, row, layer or category that did not run, with the reason; skipped phases by name]

## Suppressions
[finding - reason - owner - expiry]
```

Never place a secret value, customer data or a working exploit in the report or
the evidence folder.
