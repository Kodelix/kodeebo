package kodeebo.identity.app
import kodeebo.identity.domain.Account
interface AccountPort { fun find(id: String): Account? }
