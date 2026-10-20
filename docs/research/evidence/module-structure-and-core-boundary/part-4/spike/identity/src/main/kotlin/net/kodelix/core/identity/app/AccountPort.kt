package net.kodelix.core.identity.app
import net.kodelix.core.identity.domain.Account
interface AccountPort { fun find(id: String): Account? }
