package net.kodelix.core.identity.domain
// R3 violation with NO import and whose only bytecode reference is a `when ... is` branch (fully qualified type): ArchUnit (indy) and a Konsist import check both miss it
fun describe2(x: Any): String = when (x) {
    is String -> "text"
    is net.kodelix.kodeebo.gaming.domain.Session -> "session"
    else -> "other"
}
