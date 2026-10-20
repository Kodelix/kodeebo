/** Rule data shared by the ArchUnit and Konsist tests ("rule data, not rule code": one list per concept). Package root net.kodelix. */
object Rules {
    const val ROOT = "net.kodelix"
    const val CORE = "net.kodelix.core"          // Layer 1: net.kodelix.core.<module>
    const val PRODUCT = "net.kodelix.kodeebo"    // Layers 2 and 3: net.kodelix.kodeebo.<context>
    const val MAIL_OWNER = "net.kodelix.core.notifications"
    val clientLibs = listOf("fake.mail", "jakarta.mail", "javax.mail", "java.net.http")
    val infra = listOf("io.ktor", "org.jetbrains.exposed", "com.zaxxer.hikari", "org.postgresql", "org.bouncycastle", "io.opentelemetry")
    val layer2 = listOf("orders")    // platform contexts
    val layer3 = listOf("gaming")    // vertical contexts
    fun under(name: String, pkg: String) = name == pkg || name.startsWith("$pkg.")
    val domainPkg = Regex("""net\.kodelix\.(core|kodeebo)\.\w+\.domain(\..*)?""")
    val appPkg = Regex("""net\.kodelix\.(core|kodeebo)\.\w+\.app(\..*)?""")
    val adaptersPkg = Regex("""net\.kodelix\.(core|kodeebo)\.\w+\.adapters(\..*)?""")
}
