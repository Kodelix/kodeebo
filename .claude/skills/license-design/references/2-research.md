# /license-design - Phase 2: Research (library choice via `/research`)

> Phase 2 of `SKILL.md`. Fill only the `{...}` slots. Add nothing else: no
> preferred library, no view on the answer.

## 1. Why this is mandatory

`licensing-specialist`: the stack reference does not document Ed25519 library
APIs (Go `crypto/ed25519`, JVM, Swift). Signature, key-encoding and verification
behaviour must be confirmed from official documentation through `/research`
before any design depends on them. Cryptography uses the standard library or a
vetted package named in the stack reference or a research note; no hand-rolled
primitives, formats or encodings (`security-baseline.md`, `security-sensitive.md`).

## 2. Before spawning

1. Decide with the user **which runtimes verify and which sign**:
   - verifier (in the product, offline): backend runtime from `stack.backend` (Go, Ktor/JVM); the installer's runtime (shell, Go binary, other); any client that verifies locally. Each is a row in the note.
   - signer (issuer service, runs on our side): runtime and where the key lives (KMS/HSM/offline ceremony).
2. Reuse an existing `docs/research/licensing.md` if its versions match `pins.yaml`;
   otherwise mode `re-verify` or `extend`.
3. Collect pinned versions already known (`pins.yaml`: toolchain and JVM
   versions) with each stack-reference file's Last verified date; list stale and
   absent layers.

## 3. Brief (spawn `researcher` via `Agent`)

```text
Write a research note for /license-design.

Charter: read .claude/docs/research-protocol.md and .claude/rules/research-docs.md
first; follow .claude/docs/templates/research-note.md exactly (nine sections).

Destination (create this one new file, nothing else): docs/research/licensing.md
Mode: {new | re-verify | extend}   Existing note: {path | none}

Decision this informs: which library verifies (and signs) Ed25519 signatures per
runtime in a self-hosted licence system, and which behaviours the licence format
and verifier may rely on.
Runtimes: verifiers {list}; signer {runtime}; installer {runtime | shell}
Pinned versions read: {component - pins.yaml value - stack-reference file - Last verified}
Stale references: {list | none}   Layers with NO stack reference: {list | none}

Establish from OFFICIAL documentation (cite the URL fetched and the date), or
write NOT SOURCEABLE - <what was searched>:
1. The normative specification for Ed25519 (tier 1) and what it says about
   signature verification, including malleability and non-canonical encodings.
2. For each runtime: the standard-library option and at least one vetted package
   option: exact version, licence, maintenance status, how to verify a detached
   signature over exact bytes, accepted public-key and signature encodings and
   sizes, and the documented behaviour on a non-canonical signature, a wrong-length
   key, a small-order key. Whether verification is constant-time as documented.
3. Deterministic randomness or key-generation hooks available for tests (do not
   propose committing keys), per runtime.
4. Payload serialisation options that make verify-before-parse safe and simple
   (e.g. a binary or text format), with parser-hardening facts: duplicate-field
   handling, size limits, unknown-field behaviour - sourced per library.
5. Security advisories for each candidate at the chosen version: search GHSA and
   OSV and record the date searched, or state the search could not run.
6. ASVS 5.0.0 Level 3 requirement IDs for cryptographic verification, key
   management and licensing-relevant controls, looked up in the official document
   with the URL fetched.
7. How key custody options (KMS/HSM service vs offline ceremony) support Ed25519
   signing: which managed services document Ed25519 support, with versions and
   limits. Do not name a service you did not read about.
At least two options per runtime, each with cost, risk, performance, operability
and self-hosted bundle impact (licence compatible with shipping inside the customer
bundle: docs/ROADMAP.md L1-L4 do not cover libraries - state the library's licence
and flag copyleft). Recommend, do not decide: mark the Decision "Recommended -
pending user decision".
Never paste secrets or keys into a search query or the note.

Return (text, under 200 words): the path; finding counts by tier; the NOT
SOURCEABLE list; open questions that block the design; anything you could not do
and why. A reply without the file is a failed phase.
```

## 4. Check the returned note

| Check | Pass condition |
|---|---|
| File exists | `Read` it; a reply without the file is a failed phase (retry once, then BLOCKED) |
| Nine sections; link + tier on every finding | otherwise return to the researcher |
| Per-runtime verification behaviour | sourced, or `NOT SOURCEABLE` - each gap is carried to the report |
| Versions match `pins.yaml` | mismatches reported, not corrected |
| ASVS IDs | have the URL fetched, or `NOT SOURCEABLE` |
| No key material, quotes at most one short line | otherwise return |

Present the options per runtime; the **user** chooses the library (major decision
in every mode). Record the choice and who made it. A `NOT SOURCEABLE` item that is
load-bearing (non-canonical signature behaviour; accepted key encodings) keeps the
verdict at best `NOT ASSESSED` until closed by another `/research` pass.
