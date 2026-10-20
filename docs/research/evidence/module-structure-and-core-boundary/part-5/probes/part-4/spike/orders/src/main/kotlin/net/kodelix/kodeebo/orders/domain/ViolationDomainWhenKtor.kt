package net.kodelix.kodeebo.orders.domain
// R2 violation inside ONE Gradle module (orders declares the Ktor stub for its adapters): the only reference to a Ktor type is a `when ... is` branch
import io.ktor.server.application.Application
fun describe4(x: Any): String = when (x) {
    is String -> "text"
    is Application -> "ktor"
    else -> "other"
}
