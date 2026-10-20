package net.kodelix.core.identity.adapters
import net.kodelix.core.identity.app.AccountPort
import net.kodelix.core.identity.domain.Account
class PgAccountRepo : AccountPort { override fun find(id: String): Account? = Account(id) }
