import com.lemonappdev.konsist.api.Konsist
import com.lemonappdev.konsist.api.architecture.KoArchitectureCreator.assertArchitecture
import com.lemonappdev.konsist.api.architecture.Layer
import com.lemonappdev.konsist.api.verify.assertFalse
import org.junit.jupiter.api.Test

class KonsistRules {
    private val root = System.getProperty("spike.srcroot")
    private fun scope() = Konsist.scopeFromDirectory(root)
    private fun files() = scope().files.filter { it.path.contains("/src/main/") && it.packagee?.name?.startsWith("kodeebo.") == true }
    private fun pkg(f: com.lemonappdev.konsist.api.declaration.KoFileDeclaration) = f.packagee?.name ?: ""

    @Test fun r1_clientLibsOnlyInNotifications() =
        files().filterNot { pkg(it).startsWith("kodeebo.notifications") }
            .assertFalse { f -> f.imports.any { i -> Rules.clientLibs.any { Rules.under(i.name, it) } } }

    @Test fun r2_domainImportsNoInfra() =
        files().filter { Regex("""kodeebo\.\w+\.domain(\..*)?""").matches(pkg(it)) }
            .assertFalse { f -> f.imports.any { i -> Rules.infra.any { Rules.under(i.name, it) } } }

    @Test fun r2_appSeesOnlyPorts_noInfraNoAdapters() =
        files().filter { Regex("""kodeebo\.\w+\.app(\..*)?""").matches(pkg(it)) }
            .assertFalse { f -> f.imports.any { i -> Rules.infra.any { Rules.under(i.name, it) } || Regex("""kodeebo\.\w+\.adapters(\..*)?""").matches(i.name) } }

    @Test fun r3_layer1ImportsNothingFromLayer2or3_imports() =
        files().filter { f -> Rules.layer1.any { pkg(f).startsWith("kodeebo.$it") } }
            .assertFalse { f -> f.imports.any { i -> (Rules.layer2 + Rules.layer3).any { Rules.under(i.name, "kodeebo.$it") } } }

    @Test fun r3_layer1_architectureApi() = scope().assertArchitecture {
        val notifications = Layer("Notifications", "kodeebo.notifications..")
        val identity = Layer("Identity", "kodeebo.identity..")
        val orders = Layer("Orders", "kodeebo.orders..")
        val gaming = Layer("Gaming", "kodeebo.gaming..")
        notifications.doesNotDependOn(orders, gaming)
        identity.doesNotDependOn(orders, gaming)
    }

    @Test fun r3_layer1_textFallback_fullyQualifiedUse() =
        files().filter { f -> Rules.layer1.any { pkg(f).startsWith("kodeebo.$it") } }
            .assertFalse { f -> (Rules.layer2 + Rules.layer3).any { f.text.contains("kodeebo.$it.") } }

    @Test fun r3_whenIsOnly_identityDomainNotGaming() =
        files().filter { pkg(it).startsWith("kodeebo.identity.domain") }
            .assertFalse { f -> f.imports.any { Rules.under(it.name, "kodeebo.gaming") } }

    @Test fun r4_platformNeverImportsVertical_architectureApi() = scope().assertArchitecture {
        val orders = Layer("Orders", "kodeebo.orders..")
        val gaming = Layer("Gaming", "kodeebo.gaming..")
        orders.doesNotDependOn(gaming)
    }
}
