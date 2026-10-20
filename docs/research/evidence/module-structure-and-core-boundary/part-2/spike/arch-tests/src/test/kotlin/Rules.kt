object Rules {
    val clientLibs = listOf("fake.mail", "jakarta.mail", "javax.mail", "java.net.http")
    val infra = listOf("io.ktor", "org.jetbrains.exposed", "com.zaxxer.hikari", "org.postgresql", "org.bouncycastle", "io.opentelemetry")
    val layer1 = listOf("notifications", "identity")
    val layer2 = listOf("orders")
    val layer3 = listOf("gaming")
    fun under(name: String, pkg: String) = name == pkg || name.startsWith("$pkg.")
}
