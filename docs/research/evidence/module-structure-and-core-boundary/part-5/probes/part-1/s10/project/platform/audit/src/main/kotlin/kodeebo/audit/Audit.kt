package kodeebo.audit

import kodeebo.tenancy.TenantId

/** Port: activity trail. */
public interface Audit {
    public fun record(tenant: TenantId, event: String)
}
