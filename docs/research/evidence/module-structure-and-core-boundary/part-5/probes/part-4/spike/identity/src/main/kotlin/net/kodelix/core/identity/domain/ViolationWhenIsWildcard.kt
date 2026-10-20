package net.kodelix.core.identity.domain
// R3 violation through a wildcard import, referenced only in a `when ... is` branch
import net.kodelix.kodeebo.gaming.domain.*
fun describe3(x: Any): String = when (x) {
    is String -> "text"
    is Session -> "session"
    else -> "other"
}
