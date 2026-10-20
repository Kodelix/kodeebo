import com.tngtech.archunit.core.importer.ClassFileImporter
import com.tngtech.archunit.core.importer.ImportOption
import com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses
import org.junit.jupiter.api.Test

class ArchUnitRules {
    private val classes = ClassFileImporter().withImportOption(ImportOption.DoNotIncludeTests()).importPackages("kodeebo")

    @Test fun r1_clientLibsOnlyInNotifications() =
        noClasses().that().resideInAPackage("kodeebo..").and().resideOutsideOfPackage("kodeebo.notifications..")
            .should().dependOnClassesThat().resideInAnyPackage("fake.mail..", "jakarta.mail..", "javax.mail..", "java.net.http..")
            .check(classes)

    @Test fun r2_domainImportsNoInfra() =
        noClasses().that().resideInAPackage("kodeebo.*.domain..")
            .should().dependOnClassesThat().resideInAnyPackage("io.ktor..", "org.jetbrains.exposed..", "com.zaxxer.hikari..", "org.postgresql..", "org.bouncycastle..", "io.opentelemetry..")
            .check(classes)

    @Test fun r2_appSeesOnlyPorts_noInfraNoAdapters() =
        noClasses().that().resideInAPackage("kodeebo.*.app..")
            .should().dependOnClassesThat().resideInAnyPackage("io.ktor..", "org.jetbrains.exposed..", "com.zaxxer.hikari..", "org.postgresql..", "org.bouncycastle..", "io.opentelemetry..", "kodeebo.*.adapters..")
            .check(classes)

    @Test fun r3_layer1ImportsNothingFromLayer2or3() =
        noClasses().that().resideInAnyPackage("kodeebo.notifications..", "kodeebo.identity..")
            .should().dependOnClassesThat().resideInAnyPackage("kodeebo.orders..", "kodeebo.gaming..")
            .check(classes)

    @Test fun r3_whenIsOnly_identityDomainNotGaming() =
        noClasses().that().resideInAPackage("kodeebo.identity.domain..")
            .should().dependOnClassesThat().resideInAPackage("kodeebo.gaming..")
            .check(classes)

    @Test fun r4_platformNeverImportsVertical() =
        noClasses().that().resideInAPackage("kodeebo.orders..")
            .should().dependOnClassesThat().resideInAPackage("kodeebo.gaming..")
            .check(classes)
}
