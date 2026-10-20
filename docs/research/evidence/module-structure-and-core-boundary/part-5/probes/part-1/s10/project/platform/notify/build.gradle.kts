plugins { id("kodeebo.kotlin-module") }
dependencies {
    // RateLimiter is used only inside notify, so `implementation`: it must not leak to consumers.
    implementation(projects.platform.ratelimit)
}
