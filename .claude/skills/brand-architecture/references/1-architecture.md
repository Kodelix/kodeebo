# Architecture models, criteria and the decision record — `/brand-architecture`

Read in Phase 2 for `architecture`/`both`; give to `marketing-lead`. The models are
this studio's **working vocabulary**, not a cited standard; no market figure appears
here, and every trade-off below is `JUDGEMENT` unless the file the user supplied says
otherwise. Nothing here is a trademark or legal statement: those are `NEEDS COUNSEL`.

## Two layers, decided separately

| Layer | Question | Typical values |
|---|---|---|
| **A. Family model** | How do the products/verticals relate to each other? | branded house · endorsed · house of brands · hybrid |
| **B. Company relationship** | How does the company name appear next to the family? | endorser line ("by <Company>") on everything · only on some surfaces (site, legal, about) · not shown |

A record that decides only one layer says so. A user's decision such as "one master
brand, verticals as themes, the company as endorser" is Layer A = branded house and
Layer B = endorser line, and both are written down.

## The four models (working definitions)

| Model | What it is | Tends to fit when (JUDGEMENT) | Tends to cost (JUDGEMENT) |
|---|---|---|---|
| **Branded house** | One master brand names every product; verticals are descriptors or themes of the same name | verticals share the buyer, the trust story and the product core; one name is cheaper to build and to protect than several | a failure or scandal in one vertical lands on all; a vertical that needs a very different personality is constrained; the master name must stretch to verticals not yet built |
| **Endorsed** | Each product has its own name, visibly backed by a parent brand | a parent whose credibility transfers, products that need their own identity but not independence | more names to build, screen and protect; the endorser line must be governed so it stays consistent |
| **House of brands** | Independent names; the parent is not visible to the customer | verticals with unrelated buyers or conflicting reputations; a vertical that may be sold or partnered off under its own name | no shared recognition: every name is built and protected from zero; the highest number of names to screen |
| **Hybrid** | Different models for different parts of the portfolio | an unrelated line sits beside a coherent family | permanent governance burden; a hybrid **with no per-product rule is not a decision** — the record lists which model applies to which product |

## Decision criteria

Each criterion is answered by the user, a file, or marked `UNKNOWN`. The table in
the output file shows, per model and criterion, `FAVOURS` / `NEUTRAL` / `AGAINST` /
`UNKNOWN` with the evidence (user statement and date, file path, or `JUDGEMENT`).
**No numeric score and no summed total** — a sum hides which criteria carry the
decision. The recommendation names the two or three criteria that drive it and what
would change it.

1. **Buyer and user overlap** across verticals (same owner buying for several venue types?).
2. **Reputation spillover** — would a trust failure or a bad review wave in one vertical damage the others?
3. **Personality spread** — how different must the tone, look and price signal be between verticals?
4. **Build cost** — one name to build recognition for, or several; the marketing budget that exists (user-supplied, or `UNKNOWN`).
5. **Number of names to screen and protect** — names × markets × forms (word, Arabic-script form, logo, mascot). What protection costs and covers is `NEEDS COUNSEL`.
6. **Language fit** — whether one name works in Arabic and English and in every dialect group the user named (native review pending → `UNKNOWN`).
7. **Stretch** — can the master name carry the verticals planned later (restaurant, retail, others the user lists) without a rename? A vertical word inside the master name is a stretch risk.
8. **Channel structure** — one app or several, one domain or several, store-listing names, reseller and distributor recognition. Store and registry rules are sourced at run time, never stated here.
9. **Company goals for its own name** — build the company name as an asset (B2B trust, hiring, partnerships) or keep it back.
10. **Exit and partnership flexibility** — can a vertical be sold, licensed or co-branded on its own name (JUDGEMENT; ownership mechanics are `NEEDS COUNSEL`).
11. **Existing equity** — names, domains, handles, mascot or audience already in use by the user (user-stated, listed as `USER-STATED`).

## Recommendation shape

```
Recommendation: <model for Layer A> with <rule for Layer B>   Confidence: <what is UNKNOWN>
Drivers: <2-3 criteria>   What would change it: <conditions>   Revisit triggers: <list>
Decision needed from the user: <exact question>   Status: RECOMMENDED
```

The user decides. After the decision the status is `DECIDED`, with the user's reasons
paraphrased (not invented), the date, and the alternatives considered.

## Consequence check (also runs when the user decided before the run)

1. **Name inventory** — every name in scope with its type: master brand, endorser/company, vertical descriptor, mascot, tagline, logo. Per name: Latin form, Arabic-script rendering (`PROPOSED — native review` until reviewed), screening status (`NOT SCREENED` or the naming file that screened it), counsel status (`not reported` unless the user reports otherwise).
2. **Naming rule for future verticals** — the pattern (for example `<Master> <Descriptor>`), who approves a new descriptor, and that every new descriptor and any new mascot name is screened before use.
3. **Domain, handle and store-listing structure** — options (one master domain with sections per vertical, per-vertical domains, country domains), the observations the naming round recorded, and the registry or store rules to source at run time. Site structure itself is `astro-specialist` / `web-lead`.
4. **What the visual system must keep constant** — the part of the identity that makes the family recognisable across verticals (name lockup, mascot role, one token tier) versus what a vertical may override. The structure is recorded here; the values are design's.
5. **Arabic rendering** — the name lockup in Arabic script and in mixed-direction text; reviewed with `localization-lead` and `design-director`.
6. **Mascot** — role (family-level or per-vertical variants), its name screened like any other name, ownership of the artwork and any designer's rights (`NEEDS COUNSEL`), cultural review questions for the target markets.
7. **Open `NEEDS COUNSEL` questions** — which entity should hold the marks, licensing between company and family, protection scope per market, whether the endorsement line needs its own protection.

## Visual handoff (what this skill records vs what design owns)

This skill **records**: the architecture decision; the table of brands/verticals with
the user's words about each vertical's audience and feel (`USER DIRECTION`, quoted or
paraphrased, not styled); what must stay constant; the platforms in the stack that must
consume the result; the Arabic/RTL requirement; the questions `design-director` must
settle. It **does not** choose colours, fonts, token names or values, mascot art or
motion. Those belong to `design-director` and the `/impeccable` workflow, and the token
format is whatever the project's stack reference and `design-director` record — not
asserted here. A proposed update to `PRODUCT.md` is written as text in the file; the
edit is `design-director`'s, after the user's approval.
