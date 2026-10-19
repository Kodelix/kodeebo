// Scratch probe: same endpoints and JSON shape as scripts/go-probe/main.go.
import io.ktor.http.ContentType
import io.ktor.serialization.kotlinx.json.json
import io.ktor.server.application.install
import io.ktor.server.engine.embeddedServer
import io.ktor.server.netty.Netty
import io.ktor.server.plugins.contentnegotiation.ContentNegotiation
import io.ktor.server.response.respond
import io.ktor.server.response.respondText
import io.ktor.server.routing.get
import io.ktor.server.routing.routing
import java.lang.management.ManagementFactory
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Line(val sku: String, val qty: Int, @SerialName("price_piastres") val price: Long)

@Serializable
data class Order(val id: Int, val tenant: String, val status: String, val lines: List<Line>)

fun orders(n: Int): List<Order> = List(n) { i ->
    Order(i, "tenant-${i % 10}", "paid", listOf(Line("coffee", 2, 4500), Line("ps5-hour", 1, 6000), Line("water", 3, 1000)))
}

fun main() {
    embeddedServer(Netty, port = 8080, host = "0.0.0.0") {
        install(ContentNegotiation) { json() }
        routing {
            get("/ping") { call.respondText("""{"ok":true}""", ContentType.Application.Json) }
            get("/orders") { call.respond(orders(50)) }
            get("/info") {
                val rt = Runtime.getRuntime()
                val gcs = ManagementFactory.getGarbageCollectorMXBeans().joinToString(",") { it.name }
                call.respondText(
                    """{"procs":${rt.availableProcessors()},"max_heap":${rt.maxMemory()},"total_heap":${rt.totalMemory()},"free_heap":${rt.freeMemory()},"java":"${System.getProperty("java.version")}","gc":"$gcs"}""",
                    ContentType.Application.Json,
                )
            }
        }
    }.start(wait = true)
}
