# SCRATCH - throwaway spike (part 2 of module-structure-and-core-boundary)
Not product code. Fake contexts to test architecture-test tools. Files named `Violation*.kt` are the deliberate violations.
Modes (-Pmode=...): `clean` (violation files excluded: control), `violations` (included, extra module edges declared so they compile),
`strict` (included, extra edges NOT declared: Gradle wall), `cycle` (violations plus legitimate reverse edges: Gradle cycle check).
Layers: L1 notifications, identity; L2 orders; L3 gaming. vendor-mail stands for a mail client jar; vendor-ktor for Ktor/Exposed jars.
Run via ../run.sh (never run inside this folder).

## Part 4 additions (S40-S49)
Packages renamed to the net.kodelix root: Layer 1 net.kodelix.core.{notifications,identity}; Layer 2 net.kodelix.kodeebo.orders; Layer 3 net.kodelix.kodeebo.gaming.
New violation files: identity/domain/ViolationWhenIsFq.kt, ViolationWhenIsWildcard.kt, orders/domain/ViolationDomainWhenKtor.kt (all reference the banned type only in a `when ... is` branch).
New: syntax24 (compiled Kotlin 2.4 syntax sample, lint target), lint-fixtures/Unformatted.kt (NOT compiled; deliberately badly formatted, lint target).
Rule data: arch-tests/src/test/kotlin/Rules.kt. Konsist tests have an `imports` tier and a `cover` (text) tier.
