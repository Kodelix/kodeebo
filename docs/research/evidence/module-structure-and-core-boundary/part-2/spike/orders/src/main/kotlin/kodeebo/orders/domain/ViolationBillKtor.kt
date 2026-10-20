package kodeebo.orders.domain
// R2a violation: domain imports a Ktor type
import io.ktor.server.application.Application
class BillWithKtor(val app: Application)
