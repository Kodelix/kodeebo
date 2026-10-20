package kodeebo.identity.domain
// R3 violation without an import directive (fully qualified use)
fun makeBill(): Any = kodeebo.orders.domain.Bill("x")
