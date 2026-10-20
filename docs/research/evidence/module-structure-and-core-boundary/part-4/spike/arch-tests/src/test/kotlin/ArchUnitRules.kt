import com.tngtech.archunit.core.importer.ClassFileImporter
import com.tngtech.archunit.core.importer.ImportOption
import com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

/** ArchUnit 1.5.1 on bytecode. Rules R1-R4 on the net.kodelix root. The two `whenIs` tests are the #1699 probes. */
class ArchUnitRules {
    private val classes = ClassFileImporter().withImportOption(ImportOption.DoNotIncludeTests()).importPackages("net.kodelix")
    private val clientLibs = Rules.clientLibs.map { "$it.." }.toTypedArray()
    private val infra = Rules.infra.map { "$it.." }.toTypedArray()

    /** Scope sanity: an empty import must not read as a pass (ArchUnit also fails an empty `should` by default; probed in the emptyscope mode). */
    @Test fun scope_sanity_classesImported() = assertTrue(classes.size >= 15, "ArchUnit imported only ${classes.size} classes")

    @Test fun r1_clientLibsOnlyInNotifications() =
        noClasses().that().resideInAPackage("net.kodelix..").and().resideOutsideOfPackage("net.kodelix.core.notifications..")
            .should().dependOnClassesThat().resideInAnyPackage(*clientLibs).check(classes)

    @Test fun r2_domainImportsNoInfra() =
        noClasses().that().resideInAPackage("net.kodelix.*.*.domain..")
            .should().dependOnClassesThat().resideInAnyPackage(*infra).check(classes)

    @Test fun r2_appSeesOnlyPorts_noInfraNoAdapters() =
        noClasses().that().resideInAPackage("net.kodelix.*.*.app..")
            .should().dependOnClassesThat().resideInAnyPackage(*infra, "net.kodelix.*.*.adapters..").check(classes)

    @Test fun r3_layer1ImportsNothingFromLayer2or3() =
        noClasses().that().resideInAPackage("net.kodelix.core..")
            .should().dependOnClassesThat().resideInAPackage("net.kodelix.kodeebo..").check(classes)

    @Test fun r4_platformNeverImportsVertical() =
        noClasses().that().resideInAnyPackage(*Rules.layer2.map { "net.kodelix.kodeebo.$it.." }.toTypedArray())
            .should().dependOnClassesThat().resideInAnyPackage(*Rules.layer3.map { "net.kodelix.kodeebo.$it.." }.toTypedArray()).check(classes)

    // --- #1699 probes: files whose ONLY reference is a `when (x) { is T -> }` branch ---
    @Test fun probe_whenIs_r3_importedType_identityDomain() =
        noClasses().that().haveFullyQualifiedName("net.kodelix.core.identity.domain.ViolationWhenIsKt")
            .should().dependOnClassesThat().resideInAPackage("net.kodelix.kodeebo.gaming..").check(classes)

    @Test fun probe_whenIs_r3_fqType_identityDomain() =
        noClasses().that().haveFullyQualifiedName("net.kodelix.core.identity.domain.ViolationWhenIsFqKt")
            .should().dependOnClassesThat().resideInAPackage("net.kodelix.kodeebo.gaming..").check(classes)

    @Test fun probe_whenIs_r2_ktorType_ordersDomain() =
        noClasses().that().haveFullyQualifiedName("net.kodelix.kodeebo.orders.domain.ViolationDomainWhenKtorKt")
            .should().dependOnClassesThat().resideInAnyPackage(*infra).check(classes)
}
