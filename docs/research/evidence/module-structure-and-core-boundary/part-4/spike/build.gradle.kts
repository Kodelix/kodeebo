import org.jetbrains.kotlin.gradle.dsl.KotlinJvmProjectExtension
plugins {
    kotlin("jvm") version "2.4.21" apply false
    id("org.jlleitschuh.gradle.ktlint") version "14.2.0" apply false
    id("org.jmailen.kotlinter") version "5.7.0" apply false
}
// -Plint=kg (ktlint-gradle 14.2.0) | kotlinter (5.7.0) | none ; -PktlintVersion=<engine version for ktlint-gradle>
val lint = providers.gradleProperty("lint").getOrElse("none")
val ktlintVersion = providers.gradleProperty("ktlintVersion").getOrElse("1.8.0")
val lintTargets = listOf(":syntax24", ":lintfix")
val mode = providers.gradleProperty("mode").getOrElse("violations")
extra["extraEdges"] = (mode == "violations" || mode == "cycle")
extra["reverseEdges"] = (mode == "cycle")
// Evidence hygiene: build output goes to the gitignored cache when -PbuildRoot=<abs path> is given.
val buildRoot = providers.gradleProperty("buildRoot").orNull
subprojects {
    repositories { mavenCentral() }
    if (buildRoot != null) layout.buildDirectory.set(File(buildRoot, project.name))
    plugins.withId("org.jetbrains.kotlin.jvm") {
        if (mode == "clean") {
            extensions.configure<KotlinJvmProjectExtension>("kotlin") {
                sourceSets.getByName("main").kotlin.exclude("**/Violation*.kt")
            }
        }
    }
}

// Keep ktlint's embedded Kotlin compiler on the cached 2.4.21 (the plugins default to 2.4.10 / 2.2.21 and would download ~57-60 MB each).
subprojects {
    configurations.configureEach {
        resolutionStrategy.eachDependency {
            if (requested.group == "org.jetbrains.kotlin" && requested.name == "kotlin-compiler-embeddable" && System.getProperty("lint.noforce") == null) useVersion("2.4.21")
        }
    }
}
if (lint == "kg") configure(lintTargets.map { project(it) }) {
    apply(plugin = "org.jlleitschuh.gradle.ktlint")
    extensions.configure<org.jlleitschuh.gradle.ktlint.KtlintExtension>("ktlint") { version.set(ktlintVersion) }
}
if (lint == "kotlinter") configure(lintTargets.map { project(it) }) { apply(plugin = "org.jmailen.kotlinter") }

// ---- S41: ktlint 2.0.0-ALPHA-4 run directly (no Gradle wrapper plugin supports it, see F404/F411): JavaExec over the CLI's own jars ----
if (lint == "ktlint2") project(":syntax24").run {
    val v = "2.0.0-ALPHA-4"
    val k2 = configurations.create("ktlint2")
    dependencies {
        add("ktlint2", "io.github.ktlint.core:ktlint-cli:$v@jar")
        for (a in listOf("ktlint-logger", "ktlint-cli-reporter-baseline", "ktlint-cli-reporter-core", "ktlint-cli-reporter-plain", "ktlint-com-pinterest-backward-compatibility",
            "ktlint-rule-engine", "ktlint-ruleset-standard", "ktlint-cli-reporter-checkstyle", "ktlint-cli-reporter-json", "ktlint-cli-reporter-format", "ktlint-cli-reporter-html",
            "ktlint-cli-reporter-plain-summary", "ktlint-cli-reporter-sarif")) add("ktlint2", "io.github.ktlint.core:$a:$v")
        add("ktlint2", "com.github.ajalt.clikt:clikt-jvm:5.1.0")
        add("ktlint2", "ch.qos.logback:logback-classic:1.6.3")
    }
    val main = providers.gradleProperty("ktlintMain").get()
    fun exec(name: String, dir: File, vararg a: String) = tasks.register<JavaExec>(name) {
        classpath = k2; mainClass.set(main); workingDir = dir; args(*a); isIgnoreExitValue = true
        doLast { println("KTLINT_EXIT $name = ${executionResult.get().exitValue}") }
    }
    exec("ktlint2Syntax", project(":syntax24").projectDir, "src/main/kotlin/**/*.kt")
    exec("ktlint2Fixture", project(":lintfix").projectDir, "src/main/kotlin/**/*.kt")
    val copy = tasks.register<Sync>("ktlint2FixtureCopy") { from(project(":lintfix").projectDir.resolve("src/main/kotlin")); into(layout.buildDirectory.dir("fixture-copy")) }
    // controls: tool help text; a glob that matches nothing (does a no-match run read as a pass?); the real Syntax24.kt plus one deliberately bad line (proves the file is seen)
    exec("ktlint2Help", project(":syntax24").projectDir, "--help")
    exec("ktlint2Empty", project(":syntax24").projectDir, "nomatch/**/*.kt")
    val ctl = tasks.register<Sync>("ktlint2ControlCopy") {
        from(project(":syntax24").projectDir.resolve("src/main/kotlin")); into(layout.buildDirectory.dir("control-copy"))
        doLast { layout.buildDirectory.dir("control-copy/net/kodelix/syntax24/Syntax24.kt").get().asFile.appendText("val   badControl  =1\n") }
    }
    exec("ktlint2Control", layout.buildDirectory.dir("control-copy").get().asFile, "**/*.kt").configure { dependsOn(ctl) }
    exec("ktlint2Format", layout.buildDirectory.dir("fixture-copy").get().asFile, "-F", "**/*.kt").configure { dependsOn(copy)
        doLast { println("FORMATTED_BEGIN"); println(layout.buildDirectory.dir("fixture-copy").get().asFile.walkTopDown().filter { it.isFile }.joinToString("\n") { it.readText() }); println("FORMATTED_END") } }
}
