# Comparison matrix — `business/competitors/comparison-matrix.md`

Built by this skill (not by the researchers) **from the competitor files as they
stand after the run**, so every cell can be traced to a file and a capture date.

## Layout

```
# Competitor comparison: <segment / product category>

Date: <YYYY-MM-DD>   Built from: <list of competitor files with their last-captured dates>
Our product: <name or "not yet priced">   Horizon: <days>   Stale cells flagged: <n>

## Prices (normalised view; originals live in the files)
Normalised unit: <e.g. per user per year, excl. VAT>   Currency shown: <local first, USD beside>
FX: <rate>, <source>, <date>   Normalisation rule: <how monthly/annual/VAT were treated>
| Competitor | Plan | Original price as published | Normalised | Capture date | Mark |

## Capability and market fit
| Field | <Competitor A> | <Competitor B> | ... | Us |
Rows: billing options - local payment methods - Arabic/RTL - self-hosted offer - data-residency claims - free tier / trial
Each cell: value + mark (V = VERIFIED-ON-SITE, T = THIRD-PARTY, NC = NOT CAPTURED, NS = NOT SOURCEABLE) + capture date.

## Corridor
Lowest / median / highest normalised price among VERIFIED-ON-SITE captures for comparable plans.
n = <captures used> of <captures in scope>; comparable-plan rule: <how plans were matched>.
Cells that are NC/NS are excluded and counted, never filled.

## Reading the gaps
Where we are cheaper/dearer, where we are the only one with <Arabic/self-hosted/local payment>. Each statement points at cells.
No statement relies on a THIRD-PARTY tier 4-5 cell.

## Tally and gaps
Fields: N - V v, T t, NC c, NS s.   What to re-capture and how: <list>
```

## Rules

- Median/lowest/highest are computed (use `calc.py`), and `n` is shown. With fewer than three verified captures the corridor says "fewer than 3 captures" and gives no median.
- Plan matching ("Starter ≈ Basic") is a judgement: write the rule you used and mark each matched pair as a judgement call.
- Currency conversion happens in one column only, with one rate for the whole matrix; if captures are on different dates the rate date is shown per row.
- Our own column shows `not priced` if there is no price file — never a guess.
