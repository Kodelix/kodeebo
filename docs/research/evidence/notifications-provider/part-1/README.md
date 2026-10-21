# Evidence: notifications-provider, part 1 (run 2026-10-21)

All files are network reads (GitHub API, Maven Central, OSV, raw GitHub). No credential, no customer data, no downloaded jar. No secret literal exists in any file (T1 gitleaks).

| File | What it is | Status |
|---|---|---|
| `s10-versions-osv.sh`, `s10-output.txt` | First version/licence/OSV run | **Wrong test, kept:** its `grep` over single-line JSON printed nothing useful and its OSV batch used the package name `angus-mail`, under which the advisory is not filed. See note F116 and F120. |
| `s10b-parse.py`, `s10b-output.txt` | Valid parse of the S10 raw JSON, plus the OSV record of GHSA-9342-92gg-6v29 | valid |
| `s11-deps-licence-osv.py`, `s11-output.txt` | Licence text head, pom dependencies, OSV under the right package names, location of the SMTP docs in the 2.0.5 tag | valid |
| `s12-angus-props-asvs.py`, `s12-output.txt` | Angus SMTP property docs and send flow (saved sources), ASVS 5.0.0 rows | The property regex found nothing (wrong test, kept); the rows were read directly from `raw/angus-smtp-package-info.java`. ASVS part valid. |
| `raw/` | Saved raw responses and source files used above | scratch/evidence, small (under 1 MB) |

Commands: `sh docs/research/evidence/notifications-provider/part-1/s10-versions-osv.sh`; `python3 -I <script>` for the `.py` files, from the repository root. Python 3 stdlib only.
