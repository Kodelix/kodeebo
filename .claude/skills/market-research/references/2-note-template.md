# Market note layout — `business/market/<topic>.md`

The shape is `market-researcher`'s output format
(`.claude/agents/market-researcher.md` → Output). Do not invent another.

```
# Market note: <topic>

Date: <YYYY-MM-DD>   Author: market-researcher (via /market-research)   Status: Draft | Final
Countries: <list, each sized separately>   Segment: <name>   Edition: hosted | self-hosted
Horizon: <e.g. 12 months>   Stale after: <date, from the user's horizon>
Verdict per country: <SIZED | SIZED WITH ASSUMPTIONS | INSUFFICIENT DATA>   Overall: <worst of them>

## Question and scope (country, segment, horizon)

## Findings
| Metric | Value + unit + currency | Source (link) + tier | Date | Scope |

## Sizing (per country)
Unit definition: <in words, from the source>
Formula: <TAM/SAM/SOM as written in the method>
| Country | Quantity | Low | Base | High | Inputs (row refs) |
Local currency first; USD equivalent with rate, rate source, rate date; VAT status.

## Buyer behaviour and channels
| Item | Value | Source + tier | Date | Scope |

## Regulatory and payment facts
| Fact | Authority page | Effective date | Note |
(each ends: not legal advice - confirm with a qualified advisor)

## Cross-check (labelled comparison)
Top-down or regional figures, tier shown, never feeding the sizing.

## NOT SOURCEABLE
| What | Searched (terms, sites) | Date | Range estimate used |

## Assumptions and gaps
| # | Assumption / gap | Why it matters (which output moves) | How to close it |

## Tally
Rows: N - A a, B b, C c, D d, E 0

## Next steps
| Action | Owner (role) | Date |

## Not researched / unreachable sources
```

Header block is mandatory so a later reader can tell how old the file is and
which parts are assumption. An `ILLUSTRATIVE SUM` row, if present, says so in its
label.
