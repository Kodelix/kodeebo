# /reverse-document - Phase 2: Evidence Ledger and Sufficiency Gate

> Phase 2 of `SKILL.md`. Read-only. Everything the draft may assert comes from
> this ledger or from lines the owning agent reads itself and cites.

## 1. What may be read

- Read the target code with Read, Glob and Grep. Read git only through the
  granted read-only forms (`git log`, `git rev-parse --short HEAD`, `git status`).
- **Never open a `.env*` file**, a private key (`*.pem`, `*.key`, keystores), a
  `secrets/` directory or a credentials file, in any mode. Learn configuration
  names from the code that reads them (`os.Getenv`, `System.getenv`,
  `import.meta.env`, `application.conf` placeholders), and cite that line.
- Skip vendored and generated trees (`node_modules`, `vendor/`, `build/`,
  `dist/`, generated clients, minified bundles, lockfile bodies beyond the
  pinned-version lines). Name what was skipped. Binary or unreadable files are
  `NOT ASSESSED — <path> unreadable`, not "nothing found".
- **Secret or customer data found in code** (a literal key, a token, a real email
  in a fixture): never copy the value into the ledger, the draft or a search
  query. Record `hardcoded secret at <path:line> (value not copied)` as a finding
  and route it to `/security-audit` in the hand-off. The same holds for PII.

## 2. The ledger

Keep a numbered table in the conversation (it is also passed to the agent):

| # | Observation | Cite (`path:line` or `path:start-end`) | Kind |
|---|---|---|---|
| E1 | `POST /v1/invites` requires role `admin` | `backend/internal/invites/http.go:48` | observed |
| E2 | invitation expires after 7 days (hardcoded `7*24*time.Hour`) | `backend/internal/invites/service.go:22` | observed |
| E3 | likely one-time-use tokens | `backend/internal/invites/service.go:61-70` | inferred |

Rules:
1. **A cite is a location you read in this run**, relative to the repository
   root, with a line that exists. Not remembered, not guessed, not a directory.
2. **Observed** = the line says it. **Inferred** = a deduction from cited lines;
   it must cite them and is written `(inferred from <cite>)`. A deduction about
   *intent* is not an inference, it is `[UNVERIFIED — ask]`.
3. **An absence is a finding with its search**: `none found in the source -
   searched <paths and patterns>`. "No rate limiting" is written only with the
   Grep that found none.
4. **Runtime facts are not in code**: latency, traffic, uptime, cost, customer
   counts, conversion. They are `[UNVERIFIED — ask]`.
5. **Stated intent has its own kind**: a README line, comment, commit message or
   ADR that says why. Cite it and write `(stated in <cite>)`. It outranks
   nothing - when it disagrees with the code, record both and ask.
6. **Dates and authorship** come from read-only `git log` (`--format=%ad
   --date=short`, `--diff-filter=A`); the commit short hash for the banner from
   `git rev-parse --short HEAD`. No repository, or `git` unavailable:
   write `no commit (not a git repository)` and say the provenance is incomplete.
7. **Count by category** while reading: the per-mode signal counts named under
   "Sufficiency floor" in `2-modes.md` (capabilities, endpoints, rules, states,
   entities, providers, modules, data stores, deployment artifacts, runnable
   prototype lines).

## 3. Sufficiency gate - is there enough here to document?

Run this before Phase 3 and **stop if it fails**. The templates accept invented
content in every section; the gate is what prevents it.

Stop with `NOT ASSESSED` when **either**:
- every signal count for the mode is zero, **or**
- the scope holds fewer than ~20 lines of non-boilerplate code (no blank lines,
  comments, imports, generated code, empty classes or stubs).

Say:

> `[scope]` does not contain enough implementation to reverse-document.
> Found: [N] [signal names and counts].
> Reverse-documentation infers a document from behaviour; with no behaviour to
> read, anything I produced would be invention in the shape of a [brief | note |
> spec | architecture doc]. If the answers exist only in your head, `<skill>` is
> the skill that captures them by asking.

with `<skill>` = `/brainstorm` (brief), `/research <context>` (research note),
`/design-spec <feature>` (spec), `/create-architecture` (architecture),
`/prototype` (concept). Verdict: `NOT ASSESSED — insufficient implementation`;
nothing is written.

**Do not proceed on a partial count by filling the rest.** A scope with two
capabilities and no formulas yields a document with two capabilities and
`FORMULAS: none found in the source`; its verdict is `COMPLETE WITH GAPS`, not a
stop. The gate stops only when there is nothing to infer from.

## 4. A check that could not run

Name it in the findings and carry it to the verdict:
- a root, directory or file that could not be read (`NOT ASSESSED — <path>`);
- `git` unavailable or not a repository (provenance incomplete);
- `pins.yaml` or a `VERSION.md` absent (drift not assessed, never "no drift");
- `contracts/` empty (contract drift not assessed);
- a Grep that errored (the absence it was meant to prove is not established).

An item that depends on one of these is written `NOT ASSESSED — <reason>` in the
draft, and the run's verdict cannot be better than `NOT ASSESSED` (precedence in
`SKILL.md`).
