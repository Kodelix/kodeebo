plugins { kotlin("jvm") }
dependencies {
    for (m in listOf(":notifications", ":identity", ":orders", ":gaming", ":vendor-mail", ":vendor-ktor")) testImplementation(project(m))
    testImplementation("com.lemonappdev:konsist:0.18.1")
    testImplementation("com.tngtech.archunit:archunit:1.5.1")
    testImplementation(platform("org.junit:junit-bom:5.12.2"))
    testImplementation("org.junit.jupiter:junit-jupiter")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}
val mode = providers.gradleProperty("mode").getOrElse("violations")
// Konsist reads source files from disk, not Gradle source sets: for the clean control it must read a copy without the Violation*.kt files.
val cleanSrc = tasks.register<Sync>("prepareCleanSources") {
    from(rootProject.projectDir) { include("*/src/main/**"); exclude("**/Violation*", "arch-tests/**", "**/build/**") }
    into(layout.buildDirectory.dir("clean-src"))
}
tasks.test {
    useJUnitPlatform(); testLogging { events("passed", "failed"); showStandardStreams = false }
    // Konsist's scopeFromDirectory takes a path relative to the enclosing repository root (run 1 of this edit failed with an absolute path).
    val repoRoot = rootProject.projectDir.resolve("../../../../../..").canonicalFile
    val srcRoot = if (mode == "clean") layout.buildDirectory.dir("clean-src").get().asFile else rootProject.projectDir
    systemProperty("spike.srcroot", srcRoot.relativeTo(repoRoot).path)
    systemProperty("probe", providers.gradleProperty("probe").getOrElse("false"))
    if (mode == "clean") dependsOn(cleanSrc)
}
