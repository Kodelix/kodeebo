package kodeebo.identity.domain
// R3 violation whose only bytecode reference is a `when ... is` branch on a Layer 3 type (ArchUnit issue 1699)
import kodeebo.gaming.domain.Session
fun describe(x: Any): String = when (x) {
    is String -> "text"
    is Session -> "session"
    else -> "other"
}
