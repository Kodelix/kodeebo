package kodeebo.identity.app
// R2b violation: app imports an adapter
import kodeebo.identity.adapters.PgAccountRepo
class LoginService(val repo: PgAccountRepo)
