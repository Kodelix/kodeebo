# Part 6 evidence — notes for this folder

Index of the folder: `docs/research/tenant-isolation.md`, Part 6 § 3.9.

## File not committed

- `src/mastg/android-MASVS-PLATFORM-MASTG-TEST-0007.md` — **not committed: contains an OWASP demo credential that the secret scan flags** (gitleaks rule `generic-api-key`, line 158: Drozer sample output against OWASP's deliberately vulnerable Sieve app). It is not cited by the note. Re-fetch it from the MASTG v2.0.0 tag at `https://raw.githubusercontent.com/OWASP/mastg/v2.0.0/tests/android/MASVS-PLATFORM/MASTG-TEST-0007.md` (HTTP 200 on 2026-10-17). SHA-256 of the copy downloaded by part 6: `e962483ba5476bd1f7b631c4ecf3a8efa261943bbee2f9a9ee7048c64fc3cc3e`. No gitleaks allowlist entry was added for it.
