pluginManagement { repositories { gradlePluginPortal(); mavenCentral() } }
rootProject.name = "spike"
include(":vendor-mail", ":vendor-ktor", ":notifications", ":identity", ":orders", ":gaming", ":syntax24", ":lintfix", ":arch-tests")
if (providers.gradleProperty("withGraphPlugin").isPresent) include(":graph-check")
