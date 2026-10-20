package kodeebo.gaming.app
// R2c violation: app imports an Exposed type
import org.jetbrains.exposed.v1.core.Table
class SessionStore(val t: Table)
