package net.kodelix.core.identity.app
// R2b violation: app imports an adapter
import net.kodelix.core.identity.adapters.PgAccountRepo
class LoginService(val repo: PgAccountRepo)
