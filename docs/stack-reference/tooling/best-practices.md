# Backend tooling best practices — Go (golangci-lint v2, gitleaks, OSV-Scanner, govulncheck) and Kotlin (ktlint, detekt, Kover, architecture tests)

Last verified: Go part 2026-10-11; Kotlin part 2026-10-16 (starts at "# Kotlin" below). Sourced items cite the page fetched this session. Items marked *judgement* are recommendations.

# Go

## golangci-lint v2

### Config format
- `version: "2"` is required; "The only possible value is '2'". Source: [configuration file](https://golangci-lint.run/docs/configuration/file/).
- Linter selection: `linters.default` (`standard`, `all`, `none`, `fast`), then `linters.enable` / `linters.disable`. Per-linter options: `linters.settings`. File exclusions: `linters.exclusions` (`generated`, `rules`, `paths`, `presets`). Source: [configuration file](https://golangci-lint.run/docs/configuration/file/), [migration guide](https://golangci-lint.run/docs/product/migration-guide/).
- Formatters are separate: `formatters.enable` (`gofmt`, `gofumpt`, `goimports`, `gci`) and `formatters.settings`. They moved out of `linters` in v2. Source: [configuration file](https://golangci-lint.run/docs/configuration/file/), [migration guide](https://golangci-lint.run/docs/product/migration-guide/).
- v1 to v2 migration: `golangci-lint migrate` writes a backup `<name>.bck.<ext>`; comments and unknown fields are dropped and must be re-added by hand. Source: [migration guide](https://golangci-lint.run/docs/product/migration-guide/).
- Renamed or merged linters in v2: `gas`→`gosec`, `goerr113`→`err113`, `gomnd`→`mnd`, `logrlint`→`loggercheck`, `vet`/`vetshadow`→`govet`, `megacheck`/`gosimple`/`stylecheck`→`staticcheck`. Removed: deadcode, execinquery, exhaustivestruct, exportloopref, golint, ifshort, interfacer, maligned, nosnakecase, scopelint, structcheck, tenv, varcheck. Source: [migration guide](https://golangci-lint.run/docs/product/migration-guide/).

### Default-enabled linters (v2.14.0, verified locally)
`golangci-lint help linters`: errcheck, govet, ineffassign, staticcheck, unused. Source: local binary output; [quick start](https://golangci-lint.run/docs/welcome/quick-start/) lists the same five.

### Recommended linters for a SaaS backend (*judgement*, each description sourced from [linters](https://golangci-lint.run/docs/linters/))
- Keep the defaults above.
- `gosec`: security problems in source.
- `bodyclose`: HTTP response bodies closed.
- `noctx`: HTTP calls without `context.Context`.
- `contextcheck`: function uses a non-inherited context.
- `sqlclosecheck`, `rowserrcheck`: SQL rows/statements closed and `Rows.Err` checked.
- `errorlint`: error-wrapping problems (Go 1.13+ `errors.Is`/`As`).
- `nilerr`: returns nil despite checking error is non-nil.
- `wrapcheck`: errors from external packages wrapped.
- `copyloopvar`, `intrange`: unnecessary loop copies and integer ranges (both support autofix).
- `testifylint`: only if testify is used.

### Example config (composed from documented keys; not copied from a page)
```yaml
version: "2"
linters:
  default: standard
  enable:
    - gosec
    - bodyclose
    - noctx
    - contextcheck
    - sqlclosecheck
    - rowserrcheck
    - errorlint
    - nilerr
    - wrapcheck
    - copyloopvar
    - intrange
  exclusions:
    generated: lax
formatters:
  enable:
    - gofmt
    - goimports
```
Run `golangci-lint run ./...`. Confirm linter names against `golangci-lint help linters` on the pinned version (verified locally on 2.14.0). Validation subcommands: NOT SOURCEABLE.

## gitleaks

### Pre-commit (verified against local `gitleaks git --help`)
- Flags: `--pre-commit` ("scan using git diff") and `--staged` ("scan staged commits (good for pre-commit)"). Command: `gitleaks git --pre-commit --staged`.
- Pre-commit framework: the README example sets `rev: v8.24.2` (stale). Set `repo: https://github.com/gitleaks/gitleaks`, hook `id: gitleaks`, run `pre-commit autoupdate`, then `pre-commit install`. Source: [gitleaks README](https://github.com/gitleaks/gitleaks/blob/master/README.md).
- Skip one commit: `SKIP=gitleaks git commit ...` (README).

### CI
- `gitleaks git` scans `git log -p`. Pass commit ranges with `--log-opts`, e.g. `gitleaks git -v --log-opts="--all commitA..commitB" path_to_repo`. Source: [gitleaks README](https://github.com/gitleaks/gitleaks/blob/master/README.md).
- Suggested PR job (*judgement*, built from documented flags): `gitleaks git -v --redact --log-opts="origin/main..HEAD" -f sarif -r gitleaks.sarif`.
- Flags: `--redact` (default 100%; accepts a percent), `-f/--report-format` (`json`, `csv`, `junit`, `sarif`, `template`), `-r/--report-path`, `--exit-code` (default 1 on leaks). Source: local `gitleaks git --help` and [README](https://github.com/gitleaks/gitleaks/blob/master/README.md).
- For non-git trees: `gitleaks dir <path>`. Source: [README](https://github.com/gitleaks/gitleaks/blob/master/README.md).
- Config precedence: `--config`/`-c`, then `GITLEAKS_CONFIG` (path), then `GITLEAKS_CONFIG_TOML` (content), then `.gitleaks.toml` in the target path; otherwise built-in defaults. Source: [README](https://github.com/gitleaks/gitleaks/blob/master/README.md).

### Maintenance status
- README: "feature complete"; future releases are security patches only; focus moving to Betterleaks. Source: [README](https://github.com/gitleaks/gitleaks/blob/master/README.md). Plan a migration decision; Betterleaks version: NOT SOURCEABLE.

## OSV-Scanner (Go, Gradle, npm)

### Commands (from [usage](https://google.github.io/osv-scanner/usage/))
- Source scan (default): `osv-scanner scan -r ./path/`.
- Explicit lockfile: `osv-scanner scan -L package-lock.json --output-file scan-results.txt`; `-L` also accepts `go.mod` or `path/to/package-lock.json`.
- Custom config: `osv-scanner scan -L package-lock.json --config ./osv-scanner.toml`.
- Container image: `osv-scanner scan image <image>:<tag>`.
- Machine output: `--format json`; `--format=vertical` also appears in examples. All other `--format` values: NOT SOURCEABLE (Output page not fetched).
- Remediation: `osv-scanner fix -M path/to/package.json -L path/to/package-lock.json`. The page warns `fix` can run package-manager scripts or reach external registries, so run it only on trusted sources. There is no documented `--fix` flag. Source: usage page.

### Lockfile and manifest support (from [supported languages and lockfiles](https://google.github.io/osv-scanner/supported-languages-and-lockfiles/))
| Ecosystem | Supported | Not listed |
|---|---|---|
| Go | `go.mod` | `go.sum`, `go.work` |
| Gradle | `gradle.lockfile`, `buildscript-gradle.lockfile`, `gradle/verification-metadata.xml` | `build.gradle`, `settings.gradle` variants |
| npm | `package-lock.json` | `npm-shrinkwrap.json`, `package.json` |

Caveat from the same page: manifests can declare version ranges, so extracted versions are best-effort. Prefer the resolved lockfile.

### Recommended usage (*judgement*)
- Scan the repo root recursively in CI: `osv-scanner scan -r .` (or `scan source --recursive .` as in the pre-commit examples).
- Fail CI on findings; keep the lockfile committed so results match what is installed.

## govulncheck (Go)
- Install: `go install golang.org/x/vuln/cmd/govulncheck@latest`. Run: `govulncheck ./...`. Reports only vulnerabilities whose functions your code reaches. Source: [govulncheck doc](https://go.dev/doc/security/vuln/).
- `-json` gives streaming JSON; exit code 0 whether or not findings exist (so parse output in CI). `-mode binary` scans a compiled binary. Source: [pkg.go.dev govulncheck](https://pkg.go.dev/golang.org/x/vuln/cmd/govulncheck).
- The security best-practices page also points to a GitHub Action and `-json` for CI. Source: [security best practices](https://go.dev/doc/security/best-practices).

## Not sourced
- `golangci-lint config verify` subcommand: NOT SOURCEABLE — not on the fetched pages.
- govulncheck Go version requirement: NOT SOURCEABLE — not stated on the fetched pages.
- OSV-Scanner `--format` values other than `json`/`vertical`: NOT SOURCEABLE.
- Betterleaks replacement version: NOT SOURCEABLE.

---

# Kotlin

Last verified: 2026-10-16. Versions and compatibility verdicts are in `VERSION.md` (Kotlin part); read its status flags first: **ktlint 1.8.0 and detekt 1.23.8 do not support the pinned Kotlin 2.4.21, and detekt 2.x is alpha.** Practices below are written so they hold whichever ktlint/detekt line a product's ADR picks. Items marked *judgement* are recommendations.

## ktlint

### Where configuration lives
- Rules are configured in `.editorconfig` under the `[*.{kt,kts}]` section. Write the glob with no space after the comma: IntelliJ's auto-format can insert one (`[*{kt, kts}]`), and the EditorConfig library ignores the section after a space. Source: [configuration-ktlint.md @ 1.8.0](https://github.com/ktlint/ktlint/blob/1.8.0/documentation/release-latest/docs/rules/configuration-ktlint.md) (tier 3).
- Code style: `ktlint_code_style = ktlint_official` (default), `intellij_idea` or `android_studio`. Same source.
- Disable a rule set or rule: `ktlint_standard = disabled`, `ktlint_standard_<rule-id> = disabled`; rule properties win over rule-set properties. Experimental rules run only with `ktlint_experimental = enabled`. Same source.
- Per-directory overrides use extra `.editorconfig` sections; nested `.editorconfig` files apply to their folder recursively. Same source and [cli.md @ 1.8.0](https://github.com/ktlint/ktlint/blob/1.8.0/documentation/release-latest/docs/install/cli.md).
- Scaffold: `ktlint generateEditorConfig --code-style ktlint_official` writes only the properties of loaded rules. Source: cli.md @ 1.8.0.
- Use a single root `.editorconfig` shared by the IDE, the hook and CI so all three agree (*judgement*).

### How it fails the build
- CLI reports violations to `stderr`; the exit code on violations is NOT SOURCEABLE — not stated on the install/cli page fetched. Verify on the pinned version before wiring CI.
- Gradle plugins: ktlint-gradle adds `ktlintCheck` (all source sets and `.kts`) and `ktlintFormat`, and `ktlintCheck` is wired into `check` ([README](https://github.com/JLLeitschuh/ktlint-gradle/blob/main/README.md), tier 3). kotlinter adds `lintKotlin` ("by default fail the build") and `formatKotlin`, with `check` depending on `lintKotlin` ([README](https://github.com/jeremymailen/kotlinter-gradle/blob/master/README.md), tier 3).

### Gradle integration — the options
The ktlint docs list four Gradle plugins (`JLLeitschuh/ktlint-gradle`, `jeremymailen/kotlinter-gradle`, `diffplug/spotless`, `autostyle/autostyle`) and say, of the hand-written `JavaExec` setups, "It is recommended to use one of the Gradle plugins mentioned before." Source: [integrations.md @ 1.8.0](https://github.com/ktlint/ktlint/blob/1.8.0/documentation/release-latest/docs/install/integrations.md) (tier 3). The ktlint project does not name one as preferred.
- **ktlint-gradle** 14.2.0: ktlint-version pin via `ktlint { version = "..." }` or `ktlint-plugins.properties` (`ktlint-version=`); default version may change between plugin patch releases, so always pin; per-module baseline (`ktlintGenerateBaseline`, format tasks ignore the baseline); worker heap 256 MB by default; supports `kotlin`, `kotlin-android`, `kotlin-multiplatform`, `.kts`.
- **kotlinter** 5.7.0: Worker API, incremental, `.editorconfig`-driven; Gradle 8.4+; installs a pre-push hook with `installKotlinterPrePushHook` (runs `lintKotlin`, and `formatKotlin` on errors).
- **Spotless** 8.10.4: general formatter plugin; ktlint support is one of several formatters. Kotlin 2.4 position NOT SOURCEABLE.
- **Custom `JavaExec` on the ktlint CLI "fat jar"** (resolved from its own Gradle configuration): isolated from the project's Kotlin, so Gradle's dependency alignment cannot swap ktlint's embedded compiler. This is the failure behind [ktlint #3403](https://github.com/ktlint/ktlint/issues/3403), where a plugin-managed ktlint broke after a Kotlin upgrade; the reporter's workaround pinned `org.jetbrains.kotlin` to 2.2.21 inside the `ktlint*` configurations (tier 3, a lead). On Java 24+ the docs add `--sun-misc-unsafe-memory-access=allow` to the format task's `jvmArgs`.
- Whichever is used, the ktlint embedded compiler version must not be forced to the project's Kotlin version (*judgement* derived from #3403 and the maintainer comment in #3289 that ktlint 1.8.0 depends on embedded Kotlin 2.2.21).

### Baseline for legacy code
- `ktlint --baseline=ktlint-baseline.xml` creates the baseline when absent; later runs ignore violations recorded in it; delete the file to reset. Source: cli.md @ 1.8.0.
- Via ktlint-gradle: `ktlintGenerateBaseline`, one file per module, and format tasks ignore the baseline. Source: ktlint-gradle README.

### Hook, push, CI split
- The ktlint maintainer's own recommendation: IDE plugin for direct feedback, a git pre-commit hook, and the build pipeline "as last defense" (so developers who disable hooks are still caught). Source: [setup.md @ 1.8.0](https://github.com/ktlint/ktlint/blob/1.8.0/documentation/release-latest/docs/install/setup.md) (tier 3). `ktlint installGitPreCommitHook` / `installGitPrePushHook` generate the hooks (cli.md @ 1.8.0).
- Format check is a seconds-scale, file-local check, so it belongs in pre-commit on staged files; full-repo `ktlintCheck`/`lintKotlin` runs in CI (*judgement*; the cost claim is unmeasured).

## detekt

### Which line (read VERSION.md first)
- 1.23.8 (Gradle id `io.gitlab.arturbosch.detekt`) is built on Kotlin 2.0.21; 2.0.0-alpha.6 (Gradle id `dev.detekt`) is built on Kotlin 2.4.10 and is the only line with Kotlin 2.4 in its compatibility row. Sources: [compatibility](https://detekt.dev/docs/introduction/compatibility) (tier 2), [migration guide source](https://github.com/detekt/detekt/blob/main/website/src/components/MigrationGuide.mdx) (tier 2).
- The Gradle plugin applies the Kotlin and Android Gradle plugins as `compileOnly`, so the product chooses its own KGP/AGP version; detekt itself is "tightly coupled to the Kotlin compiler" at runtime, and a forced mismatched `kotlin-compiler-embeddable` fails with "compiled with Kotlin X but is currently running with Y". Fixes: align through `dev.detekt.gradle.getSupportedKotlinVersion()` in a `resolutionStrategy`, or exclude the `detekt` configuration from the forced version. Source: [Gradle docs](https://detekt.dev/docs/gettingstarted/gradle) (tier 2). Same trap as ktlint above.

### Config and failing the build
- Config is a YAML file passed as `detekt { config.setFrom(...) }`; generate the default with `detektGenerateConfig`; `buildUponDefaultConfig = true` layers your file on defaults (otherwise a custom file replaces the defaults entirely: "default values are ignored"). `allRules`, `parallel`, `baseline`, `basePath`, `ignoreFailures` are the other extension keys. Sources: [Gradle docs](https://detekt.dev/docs/gettingstarted/gradle), [configuration](https://github.com/detekt/detekt/blob/main/website/docs/introduction/configurations.mdx) (tier 2).
- Enable config validation (`config: validation: true, warningsAsErrors: true`) so renamed or deprecated rules fail rather than silently warn. Source: configuration page above (the option names), recommendation is *judgement*.
- **2.x fails on severity, not issue count:** `detekt { failOnSeverity }` accepts `Info | Warning | Error | Never`, default `Error`; per-rule `severity:` in the YAML. `build.maxIssues` and CLI `--max-issues` no longer exist in 2.x. `ignoreFailures = true` overrides `failOnSeverity`. Sources: migration guide (tier 2), Gradle docs (tier 2). The Gradle docs page shows no `maxIssues` key; for the 1.x line `maxIssues` behaviour: NOT SOURCEABLE (1.23.8 docs not fetched).
- `detekt` is wired into `check` (Gradle docs). To keep it out of `check`, filter it from `dependsOn`; the docs suggest a baseline instead.
- Reports are configured per task: `checkstyle` and `html` default on, `sarif` and `markdown` off by default per the DSL comments (the same page says all four are produced, an inconsistency on the page). `sarif` is the one to upload to code scanning (*judgement*). Source: Gradle docs.

### Type resolution
- Two analysis modes in 2.x: `light` (PSI only: rules needing types **do not run**, silently) and `full` (Kotlin Analysis API; all rules). Gradle picks `full` for any task with a non-empty classpath. Source: migration guide + [type resolution](https://detekt.dev/docs/gettingstarted/type-resolution) (tier 2).
- Gradle tasks: plain `detekt` = light (the one wired to `check`); `detektMain` / `detektTest` = full; `detektMainSourceSet` etc. = light; baselines `detektBaselineMain` etc. On Android `detekt<Variant>`; on KMP `detekt<Compilation><Target>` (e.g. `detektMainJvm`), and **only JVM and Android targets get full analysis; Native, JS, Wasm do not.** Source: type resolution page, migration guide.
- Consequence for CI (*judgement from the above*): `./gradlew check` alone does not run the type-resolved rules; add `detektMain detektTest` (or the KMP/Android equivalents) to the CI job. To see which rules were skipped, run with `--debug` (the skip message appears only then).
- Known open issues at detekt 2.0.0-alpha.6: classes added to a project dependency reported as unresolved when the Gradle daemon is reused ([#9793](https://github.com/detekt/detekt/issues/9793)); expect/actual from different KMP source sets analysed as one fragment ([#9602](https://github.com/detekt/detekt/issues/9602)); AGP transform input / Gradle 9.7 deprecation ([#9742](https://github.com/detekt/detekt/issues/9742)). Tier 3.

### Baseline for legacy code
- `detektBaseline` (light) or `detektBaselineMain` / `detektBaselineTest` (type-resolved) writes an XML `SmellBaseline` with `ManuallySuppressedIssues` and `CurrentIssues`; later runs print only findings not in the baseline. Configure `detekt { baseline = file("...") }`. Source: [baseline](https://detekt.dev/docs/introduction/baseline) (tier 2).
- 1.x baselines do not work with 2.x (separator changed `$` to `:`): regenerate after upgrading. Do not combine auto-format with a baseline (signatures become ambiguous). Same page.
- Source-set tasks write `detekt-baseline-<name>.xml`; a more specific file takes precedence over `detekt.xml` for that task. Gradle docs.

### Formatting / ktlint wrapper
- 1.x: `detekt-formatting` plugin; 2.x: `dev.detekt:detekt-rules-ktlint-wrapper`, added with `detektPlugins(...)`; needs JDK 17+ to run; wraps ktlint 1.8.0 in detekt `main`. Sources: migration guide (tier 2), [libs.versions.toml](https://github.com/detekt/detekt/blob/main/gradle/libs.versions.toml) (tier 3).
- Wrapper `autoCorrect` is off unless `--auto-correct` is passed; a ruleset-level `autoCorrect: false` is only a default, a rule-level value wins. Source: configuration page (tier 2).
- Running ktlint both directly and through the wrapper doubles the work and can report one violation twice (*judgement*): pick one place for formatting rules.

### Compose
- detekt documents recommended overrides for Compose: `FunctionNaming` (`functionPattern: '[a-zA-Z][a-zA-Z0-9]*'` or `ignoreAnnotated: ['Composable']`), `TopLevelPropertyNaming` (`constantPattern: '[A-Z][A-Za-z0-9]*'`), `LongParameterList` (raise `functionThreshold`, `ignoreDefaultParameters`), `MagicNumber`, `UnusedPrivateFunction` (`ignoreAnnotated` must list `Preview` and every multipreview annotation: meta-annotations are not followed), `TooManyFunctions` (`ignoreAnnotatedFunctions: ['Preview']`). Source: [compose config page](https://github.com/detekt/detekt/blob/main/website/docs/introduction/compose.mdx) (tier 2).

### Hook, push, CI split
- detekt documents a pre-commit hook that runs `./gradlew detekt` on the whole project, a Gradle variant restricted to staged files (`-Pprecommit=true`) and a CLI variant on staged files. Warnings from the page: the CLI/staged variant does not run type-resolution rules correctly ("recommended that you still implement a full `detekt` check as part of your CI pipeline"), and `.gradle.kts` files must be excluded from a type-resolved pre-commit run (issue #5501 crash). Source: [git pre-commit hook](https://github.com/detekt/detekt/blob/main/website/docs/gettingstarted/git-pre-commit-hook.mdx) (tier 2).
- Recommended split (*judgement*): pre-commit = ktlint on staged files only (fast); pre-push = Gradle `detekt` light on the module(s) changed; CI = full `ktlintCheck`, `detekt` + `detektMain detektTest` (type-resolved), Kover verify, architecture tests.

## Compose static rules (compose-rules 0.6.8)
- Two artifacts: `io.nlopez.compose.rules:detekt` (added as `detektPlugins "io.nlopez.compose.rules:detekt:<VERSION>"`) and `io.nlopez.compose.rules:ktlint` (`ktlintRuleset` in ktlint-gradle >= 11.1.0, or the `buildscript` classpath for kotlinter, or the `-all.jar` uber jar from the releases page with `ktlint -R`). Sources: [detekt.md](https://github.com/mrmans0n/compose-rules/blob/main/docs/detekt.md), [ktlint.md](https://github.com/mrmans0n/compose-rules/blob/main/docs/ktlint.md) (tier 3).
- The rule artifact version must match the host linter version (each compose-rules version targets one detekt or ktlint version; see the matrices in the two docs and `VERSION.md`). The ktlint artifact has no matrix row for ktlint 2.x.
- Choose ONE host (ktlint or detekt) for Compose rules; the project says "2 ways" to add the checks (README). detekt: enable rules under a `Compose:` key in `detekt.yml` (rules are opt-in via `active: true`; e.g. `ComposableNestingDepth` is off by default). ktlint: settings in `.editorconfig` such as `compose_content_emitters`, `compose_view_model_factories`. Source: same docs.
- Do not also apply detekt's own Compose naming overrides unless using that host (detekt's `FunctionNaming` conflicts with PascalCase composables unless relaxed; see the detekt Compose section above).

## Kover coverage (0.9.11)
- Apply `id("org.jetbrains.kotlinx.kover") version "0.9.11"`; `mavenCentral()` must be configured (Kover and JaCoCo are downloaded from it). Source: [plugin docs](https://kotlin.github.io/kotlinx-kover/gradle-plugin/) (page still shows 0.9.8; use the version from `VERSION.md`).
- Thresholds: `kover { reports { verify { rule { minBound(50) } } } }`; rules may set min and/or max bounds, group by `APPLICATION` (default), `CLASS` or `PACKAGE`, and measure `LINE` (default), `INSTRUCTION` or `BRANCH`. A violated rule fails `koverVerify` (named-variant form `koverVerifyDebug`). Sources: plugin docs, [kover-gradle-plugin/docs/index.md @ v0.9.11](https://github.com/Kotlin/kotlinx-kover/blob/v0.9.11/kover-gradle-plugin/docs/index.md). The `bound { minValue }` form is not in the docs: use `minBound(...)`.
- In the plugin source at v0.9.11, `verify.onCheck` defaults to true only for the total variant, and html/xml/binary/log reports default to off on `check` (`ReportsImpl.kt`, tier 3). So `./gradlew check` runs `koverVerify` once a rule exists; HTML/XML reports must be requested (`koverHtmlReport`, `koverXmlReport`) or set `onCheck = true`. The plugin docs page does not state this. Confirm on the pinned version.
- Filters: `kover { reports { filters { excludes { classes("..."); annotatedBy("...") } } } }`; excludes win over includes; annotation filters need BINARY or RUNTIME retention. Exclude generated code and `@Composable` previews with a filter rather than lowering the threshold (*judgement*).
- Multi-module: one merging module (the root is recommended) with `kover(project(":moduleA"))` dependencies produces a combined report and verify. Plugin docs.
- KMP: "Kover supports coverage measurement only for JVM targets"; non-JVM tests are ignored. Android: build variants get report variants; on-device instrumented tests cannot be measured. Plugin docs.
- Instrumentation cost: classes are instrumented on load and "may lead to some performance degradation, or affect concurrent tests" (README). `instrumentation { excludedClasses.add(...) }` and `disableForTestTasks` exist for problem classes and load tests.
- Optional JaCoCo engine: `useJacoco()`; the docs warn that full feature compatibility is not guaranteed. Plugin docs.
- Whether to set a threshold at all, and its number: NOT SOURCEABLE here: the number belongs to `docs/architecture/perf-budgets.md`/`testing-standards.md`, not to this reference.

## Architecture tests (clean-architecture layering)
Options, no decision (the decision is `cto`'s, via ADR). Both run as ordinary unit tests, so they fit gate 2 evidence in the normal test task.
- **Konsist 0.18.1** (Kotlin-native, source-level, Apache-2.0): tests are JUnit 4/5 or Kotest. `Konsist.scopeFromProduction().assertArchitecture { val domain = Layer("Domain", "com.x.domain.."); domain.dependsOnNothing() ... }` declares package-based layers. `dependsOnNothing()` forbids importing any other declared layer; `doesNotDependOn(b)` forbids one; plain `dependsOn(b)` always passes and forbids nothing. Only `import` directives of declared layers are checked: imports from `kotlin..`, third-party libraries and undeclared packages are ignored, and fully qualified references without an import are missed; no `@Suppress` support. Source: [assert-architecture page](https://docs.konsist.lemonappdev.com/writing-tests/architecture-assert.md) (tier 2). **Consequence for "domain has no framework/DB/HTTP imports": a layer rule alone does not catch `io.ktor..` or `org.jetbrains.exposed..` imports unless those packages are declared as layers; use Konsist's file/import queries for forbidden-import rules (the API is described as covering classes, functions, properties, and imports; page not fetched, so the exact method names are NOT SOURCEABLE here).** Works for Android, Spring and KMP projects per its docs home; scope must include the relevant module/source set (the page does not detail multi-module or source-set handling). Pre-1.0 (1.0 planned Q1 2027): expect API changes between 0.x minors (0.18.0 to 0.18.1 changed `parent.sourceDeclaration` text, per the release notes).
- **ArchUnit 1.5.1** (JVM bytecode, Java library, widest rule vocabulary for layers/slices/cycles): analyses compiled classes, so tests run after compilation and see JVM targets only (not Kotlin/Native, JS or Wasm; KMP `commonMain` is covered only through the JVM/Android compilation). Dependency detection depends on what Kotlin emits: ArchUnit 1.5.0 misses the dependency from Kotlin 2.4.20+ `when (x) { is T -> ... }` (invokedynamic `typeSwitch`, [issue #1699](https://github.com/TNG/ArchUnit/issues/1699), open). No official Kotlin support statement was found (NOT SOURCEABLE).
- **Trade-off summary (*judgement from the above*)**: Konsist reads source, so it sees imports exactly as written and works on every KMP source set, but checks only imports of declared layers and is 0.x; ArchUnit sees real bytecode references (including references without imports) and has a stable 1.x API, but depends on Kotlin's bytecode shapes, JVM targets only, and has an open Kotlin 2.4.20+ detection gap. Using both is possible; cost is two test dependencies.
- Neither belongs in a commit hook (they need compilation or a full source scope); run them in the unit-test task and CI (*judgement*).

## OSV-Scanner for Gradle projects
- Confirmed: for source scans OSV-Scanner lists `gradle.lockfile`, `buildscript-gradle.lockfile` and `gradle/verification-metadata.xml` (plus `pom.xml`) as supported Java files. Source: [supported languages and lockfiles](https://google.github.io/osv-scanner/supported-languages-and-lockfiles/) (tier 2), also in the repo file `docs/supported_languages_and_lockfiles.md`. It prefers resolved lockfiles: manifests "can declare version ranges". The page gives no parsing detail for the Gradle files and documents transitive resolution only for `pom.xml`.
- Gradle setup needed (Gradle docs, "current" version, which is newer than the pinned 9.7: re-check on 9.7): lock project configurations with `dependencyLocking { lockAllConfigurations() }` (does not cover buildscript), lock the plugin classpath with `buildscript { configurations.classpath { resolutionStrategy.activateDependencyLocking() } }`, write with `./gradlew dependencies --write-locks` (writes `gradle.lockfile` per project, `buildscript-gradle.lockfile` for the buildscript). With a lock present, a differing resolution fails the build; `LockMode.STRICT` also fails on a missing lock. Source: [dependency locking](https://docs.gradle.org/current/userguide/dependency_locking.html) (tier 2).
- Alternative or addition: `./gradlew --write-verification-metadata sha256` writes `gradle/verification-metadata.xml` (components and artifact checksums, including plugin artifacts; strict mode fails on a missing or mismatched checksum). Source: [dependency verification](https://docs.gradle.org/current/userguide/dependency_verification.html) (tier 2). Review generated entries: bootstrapping trusts what the repositories serve today.
- Commit the lockfiles. Run `osv-scanner scan source -r .` in CI (same command as the Go part). Whether the lockfile includes Kotlin Multiplatform/Android configurations depends on which configurations are locked: NOT SOURCEABLE (Gradle page has no Android/KMP note).

## Not sourced (Kotlin)
- ktlint CLI exit code on violations: NOT SOURCEABLE — not on the install/cli pages fetched.
- detekt 1.23.8 `maxIssues` semantics: NOT SOURCEABLE — 1.23.8 docs not fetched.
- detekt `sarif`/`markdown` default report state: the Gradle page contradicts itself (see above); resolve by running the pinned version.
- Spotless + ktlint: NOT SOURCEABLE — not researched.
- Konsist API for forbidden-import rules (method names): NOT SOURCEABLE — only the `assertArchitecture` page was fetched.
- ArchUnit official Kotlin/KMP support statement: NOT SOURCEABLE — README and issue tracker only.
- Kover: Kotlin 2.4.21 / Gradle 9.7 explicit compatibility and minimum Kotlin version: NOT SOURCEABLE (see `VERSION.md`). The `onCheck` defaults above come from plugin source at v0.9.11, not from documentation.
- Gradle dependency-locking behaviour for Android/KMP configurations, and the 9.7 versions of the Gradle pages: NOT SOURCEABLE — the 9.7 URL returned 404; "current" docs used.
- Executed evidence: none. No tool in this section was run (Gradle and the tools are not installed locally); every verdict is from documents. A run of detekt 2.0.0-alpha.6 and ktlint on a Kotlin 2.4.21 sample is the spike that would settle the open compatibility questions.
