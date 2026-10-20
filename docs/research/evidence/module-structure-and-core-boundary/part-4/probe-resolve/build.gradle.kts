import org.gradle.api.attributes.Usage
import org.gradle.api.attributes.Category
import org.gradle.api.attributes.LibraryElements
import org.gradle.api.attributes.java.TargetJvmVersion
import org.gradle.api.attributes.java.TargetJvmEnvironment
plugins { base }
repositories { mavenCentral(); gradlePluginPortal() }
val sets = mapOf(
    "ktlint2engine" to listOf("io.github.ktlint.core:ktlint-rule-engine:2.0.0-ALPHA-4", "io.github.ktlint.core:ktlint-ruleset-standard:2.0.0-ALPHA-4", "io.github.ktlint.core:ktlint-cli-reporter-plain:2.0.0-ALPHA-4", "io.github.ktlint.core:ktlint-cli-reporter-checkstyle:2.0.0-ALPHA-4", "io.github.ktlint.core:ktlint-cli-reporter-sarif:2.0.0-ALPHA-4"),
    "ktlint18engine" to listOf("com.pinterest.ktlint:ktlint-rule-engine:1.8.0", "com.pinterest.ktlint:ktlint-ruleset-standard:1.8.0", "com.pinterest.ktlint:ktlint-cli-reporter-plain:1.8.0", "com.pinterest.ktlint:ktlint-cli-reporter-checkstyle:1.8.0"),
    "ktlintGradle" to listOf("org.jlleitschuh.gradle:ktlint-gradle:14.2.0"),
    "kotlinter" to listOf("org.jmailen.gradle:kotlinter-gradle:5.7.0"),
)
for ((n, deps) in sets) {
    val c = configurations.create(n) {
        isCanBeConsumed = false; isCanBeResolved = true
        attributes {
            attribute(Usage.USAGE_ATTRIBUTE, objects.named(Usage::class.java, Usage.JAVA_RUNTIME))
        }
    }
    deps.forEach { dependencies.add(n, it) }
}
tasks.register("printGraph") {
    doLast {
        for (n in sets.keys) {
            println("## CONFIG $n")
            try {
                val res = configurations.getByName(n).incoming.resolutionResult
                res.allDependencies.forEach { d ->
                    if (d is org.gradle.api.artifacts.result.UnresolvedDependencyResult) println("UNRESOLVED ${d.requested.displayName}: ${d.failure.message?.replace("\n"," | ")}")
                }
                res.allComponents.forEach { println("COMP ${it.moduleVersion?.group}:${it.moduleVersion?.name}:${it.moduleVersion?.version}") }
            } catch (e: Exception) { println("ERROR $n: ${e.message?.lines()?.first()}") }
        }
    }
}
