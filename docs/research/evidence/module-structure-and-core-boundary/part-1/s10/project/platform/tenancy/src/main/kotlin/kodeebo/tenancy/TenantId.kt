package kodeebo.tenancy

/** Opaque tenant identifier. */
public class TenantId(public val value: String)

/** Port: resolves the current tenant. */
public interface TenantScope {
    public fun current(): TenantId
}

internal fun hiddenHelper(): Int = 1
