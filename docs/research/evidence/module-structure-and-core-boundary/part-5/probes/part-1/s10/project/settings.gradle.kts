pluginManagement {
    includeBuild("build-logic")
}
dependencyResolutionManagement {
    repositories { mavenCentral() }
}
enableFeaturePreview("TYPESAFE_PROJECT_ACCESSORS")
rootProject.name = "kprobe-modules"
include(":platform:tenancy", ":platform:audit", ":platform:ratelimit", ":platform:notify", ":contexts:venue", ":app")
