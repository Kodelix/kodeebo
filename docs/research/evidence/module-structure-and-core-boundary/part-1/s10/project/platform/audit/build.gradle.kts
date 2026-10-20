plugins { id("kodeebo.kotlin-module") }
dependencies {
    // TenantId is part of audit's public API, so `api`.
    api(projects.platform.tenancy)
}
