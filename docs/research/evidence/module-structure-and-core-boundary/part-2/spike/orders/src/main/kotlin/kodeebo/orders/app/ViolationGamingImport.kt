package kodeebo.orders.app
// R4 violation: platform (L2) imports a vertical (L3)
import kodeebo.gaming.domain.Session
class BillSession(val s: Session)
