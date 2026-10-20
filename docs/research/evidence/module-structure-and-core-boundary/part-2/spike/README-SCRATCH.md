# SCRATCH - throwaway spike (part 2 of module-structure-and-core-boundary)
Not product code. Fake contexts to test architecture-test tools. Files named `Violation*.kt` are the deliberate violations.
Modes (-Pmode=...): `clean` (violation files excluded: control), `violations` (included, extra module edges declared so they compile),
`strict` (included, extra edges NOT declared: Gradle wall), `cycle` (violations plus legitimate reverse edges: Gradle cycle check).
Layers: L1 notifications, identity; L2 orders; L3 gaming. vendor-mail stands for a mail client jar; vendor-ktor for Ktor/Exposed jars.
Run via ../run.sh (never run inside this folder).
