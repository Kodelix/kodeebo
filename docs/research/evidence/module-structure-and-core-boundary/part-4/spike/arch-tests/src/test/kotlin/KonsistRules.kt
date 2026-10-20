import com.lemonappdev.konsist.api.Konsist
import com.lemonappdev.konsist.api.architecture.KoArchitectureCreator.assertArchitecture
import com.lemonappdev.konsist.api.architecture.Layer
import com.lemonappdev.konsist.api.declaration.KoFileDeclaration
import com.lemonappdev.konsist.api.verify.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

/**
 * Konsist 0.18.1 on source. Two tiers per rule:
 *  - `imports` tests: the import directives (what Konsist's own architecture API checks);
 *  - `cover` tests: the COVERING RULE for ArchUnit's #1699 blind spot and Konsist's import-only limit: any occurrence of the banned package as a dotted
 *    prefix anywhere in the file text (imports, fully-qualified use, `when ... is` branches), comments included (coarse by design).
 */
class KonsistRules {
    private val root = System.getProperty("spike.srcroot")
    private fun scope() = Konsist.scopeFromDirectory(root)
    private fun files() = scope().files.filter { it.path.contains("/src/main/") && it.packagee?.name?.startsWith("net.kodelix.") == true }
    private fun pkg(f: KoFileDeclaration) = f.packagee?.name ?: ""
    private fun importsHit(f: KoFileDeclaration, banned: List<String>) = f.imports.any { i -> banned.any { Rules.under(i.name, it) } }
    private fun textHit(f: KoFileDeclaration, banned: List<String>) = banned.any { f.text.contains("$it.") }

    /** Scope sanity: Konsist must have found the spike sources (a wrong root must not read as a pass). */
    @Test fun scope_sanity_filesFound() = assertTrue(files().size >= 15, "Konsist found only ${files().size} files under $root")

    // --- tier 1: imports ---
    @Test fun r1_imports() = files().filterNot { pkg(it).startsWith(Rules.MAIL_OWNER) }.assertFalse { importsHit(it, Rules.clientLibs) }
    @Test fun r2_domain_imports() = files().filter { Rules.domainPkg.matches(pkg(it)) }.assertFalse { importsHit(it, Rules.infra) }
    @Test fun r2_app_imports() = files().filter { Rules.appPkg.matches(pkg(it)) }
        .assertFalse { f -> importsHit(f, Rules.infra) || f.imports.any { Rules.adaptersPkg.matches(it.name) } }
    @Test fun r3_imports() = files().filter { pkg(it).startsWith(Rules.CORE) }.assertFalse { importsHit(it, listOf(Rules.PRODUCT)) }
    @Test fun r4_imports() = files().filter { f -> Rules.layer2.any { pkg(f).startsWith("${Rules.PRODUCT}.$it") } }
        .assertFalse { f -> importsHit(f, Rules.layer3.map { "${Rules.PRODUCT}.$it" }) }

    // --- tier 1b: Konsist architecture API (import-based) ---
    @Test fun r3_r4_architectureApi() = scope().assertArchitecture {
        val core = Layer("Core", "net.kodelix.core..")
        val orders = Layer("Orders", "net.kodelix.kodeebo.orders..")
        val gaming = Layer("Gaming", "net.kodelix.kodeebo.gaming..")
        val product = Layer("Product", "net.kodelix.kodeebo..")
        core.doesNotDependOn(product)
        orders.doesNotDependOn(gaming)
    }

    // --- tier 2: covering rule (text) ---
    @Test fun cover_r1_text() = files().filterNot { pkg(it).startsWith(Rules.MAIL_OWNER) }.assertFalse { textHit(it, Rules.clientLibs) }
    @Test fun cover_r2_domain_text() = files().filter { Rules.domainPkg.matches(pkg(it)) }.assertFalse { textHit(it, Rules.infra) }
    @Test fun cover_r2_app_text() = files().filter { Rules.appPkg.matches(pkg(it)) }.assertFalse { textHit(it, Rules.infra + "net.kodelix.core.identity.adapters") }
    @Test fun cover_r3_text() = files().filter { pkg(it).startsWith(Rules.CORE) }.assertFalse { textHit(it, listOf(Rules.PRODUCT)) }
    @Test fun cover_r4_text() = files().filter { f -> Rules.layer2.any { pkg(f).startsWith("${Rules.PRODUCT}.$it") } }
        .assertFalse { f -> textHit(f, Rules.layer3.map { "${Rules.PRODUCT}.$it" }) }
}
