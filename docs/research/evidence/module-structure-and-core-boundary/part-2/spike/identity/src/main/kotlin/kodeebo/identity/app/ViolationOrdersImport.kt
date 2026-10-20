package kodeebo.identity.app
// R3 violation: Layer 1 imports Layer 2
import kodeebo.orders.app.OrderService
class BillingSync(val orders: OrderService?)
