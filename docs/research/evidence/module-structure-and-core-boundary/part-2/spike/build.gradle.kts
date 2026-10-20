import org.jetbrains.kotlin.gradle.dsl.KotlinJvmProjectExtension
plugins { kotlin("jvm") version "2.4.21" apply false }
val mode = providers.gradleProperty("mode").getOrElse("violations")
extra["extraEdges"] = (mode == "violations" || mode == "cycle")
extra["reverseEdges"] = (mode == "cycle")
subprojects {
    repositories { mavenCentral() }
    plugins.withId("org.jetbrains.kotlin.jvm") {
        if (mode == "clean") {
            extensions.configure<KotlinJvmProjectExtension>("kotlin") {
                sourceSets.getByName("main").kotlin.exclude("**/Violation*.kt")
            }
        }
    }
}
