package kodeebo.venue.branches

import kodeebo.tenancy.TenantId

/** A branch of a venue (context 13, grouped module). */
public class Branch(public val tenant: TenantId, public val name: String)
