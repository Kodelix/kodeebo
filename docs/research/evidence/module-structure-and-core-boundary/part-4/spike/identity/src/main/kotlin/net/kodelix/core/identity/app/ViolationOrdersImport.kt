package net.kodelix.core.identity.app
// R3 violation: Layer 1 imports Layer 2
import net.kodelix.kodeebo.orders.app.OrderService
class BillingSync(val orders: OrderService?)
