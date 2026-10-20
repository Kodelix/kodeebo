package kodeebo.app

import kodeebo.audit.Audit
import kodeebo.tenancy.TenantId          // visible: audit exposes it through `api`
import kodeebo.venue.branches.Branch

public fun main() {
    val branch = Branch(TenantId("t1"), "main")
    val audit = object : Audit { override fun record(tenant: TenantId, event: String) { println("${tenant.value} $event") } }
    audit.record(branch.tenant, "boot")
}
