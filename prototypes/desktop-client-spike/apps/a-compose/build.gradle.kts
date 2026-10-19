// PROTOTYPE - NOT FOR PRODUCTION
// Question: Can A (Compose Desktop), B (Electron) or C (Tauri 2) do the counter's duties on the 4 GB reference VM?
// Date: 2026-10-16
import org.jetbrains.compose.desktop.application.dsl.TargetFormat

plugins {
    kotlin("jvm") version "2.4.21"                                  // pins.yaml kotlin.kotlin
    id("org.jetbrains.kotlin.plugin.compose") version "2.4.21"
    id("org.jetbrains.compose") version "1.12.2"                    // pins.yaml kmp.compose_multiplatform
}

kotlin { jvmToolchain(21) }                                         // pins.yaml kotlin.jvm_toolchain

dependencies {
    implementation(compose.desktop.currentOs)
    implementation(compose.foundation)
    implementation("io.github.willena:sqlite-jdbc:3.53.4.0")        // SQLite3 Multiple Ciphers (research F109)
    implementation("net.java.dev.jna:jna:5.19.1")                   // winspool RAW printing
}

// Round 3 (G4): one project builds 1.0.0 and 1.0.1 (gradle -PappVersion=1.0.1 packageMsi); the running app reads
// its version from the kspike.version system property (written to version.txt by --version).
val appVersion = (findProperty("appVersion") ?: "1.0.0").toString()

compose.desktop {
    application {
        mainClass = "MainKt"
        jvmArgs += listOf("-Dkspike.version=$appVersion")
        nativeDistributions {
            targetFormats(TargetFormat.Msi)
            packageName = "KodeeboSpikeA"
            packageVersion = appVersion
            modules("java.sql")
            windows {
                perUserInstall = true
                upgradeUuid = "db180c1d-ac4c-4641-a4fe-7f901094e8d4"
                menuGroup = "Kodeebo Spike"
            }
        }
    }
}
