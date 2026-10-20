package kodeebo.identity.adapters
import kodeebo.identity.app.AccountPort
import kodeebo.identity.domain.Account
class PgAccountRepo : AccountPort { override fun find(id: String): Account? = Account(id) }
