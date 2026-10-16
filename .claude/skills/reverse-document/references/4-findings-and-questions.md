# /reverse-document - Phase 3: Present Findings, Ask About Intent

> Phase 3 of `SKILL.md`. The draft does not exist yet. Code records what was
> built, never why; this phase is where the "why" is asked for.

## 1. Present the findings

Show the ledger digest in this shape. **Every list may be empty and an empty one
says `none found in the source`**; the bracketed rows are shapes, not quotas, and
a source with one capability yields one row.

```
I read [N] files under [paths] (mode: [mode], tier: [tier], commit [sha]).
Skipped: [vendored/generated paths | none]. Not assessed: [path - reason | none].

FOUND (observed):
- [capability / rule / endpoint / decision] - [path:line]
...
FOUND (inferred):
- [deduction] - inferred from [path:line]
NONE FOUND IN THE SOURCE:
- [category] - searched [paths and patterns]
DRIFT AND DEFECTS SEEN WHILE READING:
- [hardcoded business value | missing tenant scope | layering violation | pin
  drift | contract drift | hardcoded secret (value not copied)] - [path:line]

UNCLEAR INTENT:
1. [question the code cannot answer]
...
```

Defects seen are reported, not fixed and not argued with: this skill documents
the product as it is.

## 2. Ask the intent questions

Ask about intent, not just what. Shapes by mode (use the product's own words):

- **brief**: "Billing code defines three plans (`path:line`). Is this the pricing
  you sell today, or a leftover?"; "Who is the buyer - the tenant admin, or an
  operator who self-hosts?"; "The README says [quote line `path:line`]. Is that
  still the problem you solve?"
- **research**: "The context stores sessions in Redis with a 30-minute TTL
  (`path:line`). Chosen for speed, for revocation, or inherited?"; "Was any
  alternative to [provider] evaluated?"
- **spec**: "Only role `admin` may do X (`path:line`). Is `owner` meant to be
  allowed?"; "The 7-day expiry is hardcoded (`path:line`): is 7 the rule, or a
  placeholder for plan-based limits?"; "Which roles and plans is this for?"
- **architecture**: "Tenant isolation is a `tenant_id` filter in repositories
  (`path:line`), not RLS. Deliberate, or not yet migrated?"; "`saas-core` is
  re-implemented locally for identity (`path:line`). Is `/core-extract` planned?"
- **concept**: "What was the hypothesis, and what did testers do?"; "Is this
  validated, invalidated, or untested?"

Ask via `AskUserQuestion` in `collaborative` mode (batch related questions, at
most four per call; options are the plausible answers plus "unknown"); in
`guided`, one batched call for the questions that change the document's meaning;
in `autonomous`, ask none (see below).

## 3. When questions are not answered

A question that comes back skipped, dismissed or empty is **not an answer**
(`.claude/docs/automation-modes.md`, "a question with no answer"). Do not draft
the resolved version. Ask again in plain text, say that drafting waits on it, and
wait. Only an explicit reply - "unknown", "ask the team later", "draft it with
open questions" - lets a question be carried.

A carried question appears in the document verbatim as `[UNVERIFIED — ask]` with
the question, and in the Open Questions section with an owner. In `autonomous`
mode no question is asked, so every intent question is carried this way and the
verdict can only be `COMPLETE WITH GAPS`. Where nobody can answer (CI, headless),
stop after Phase 2 and report the ledger and the questions rather than drafting
an answer.

## 4. Record the answers

Each answer is recorded as `(confirmed by <user name or "user">, <YYYY-MM-DD>)`
next to the claim it settles; the date comes from `date +%F`, not from memory. An answer that contradicts the code does not rewrite the observation:
the draft states both ("implemented as A; the user states the intent is B -
flagged for update"), because the document must let a reader tell what the code
does from what someone wants it to do.
