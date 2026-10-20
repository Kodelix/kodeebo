// Convention plugin applied by every module: one place for toolchain, explicit API, ABI validation, locking.
plugins {
    id("org.jetbrains.kotlin.jvm")
    `java-library`
}

kotlin {
    jvmToolchain(21)
    explicitApi()
    @OptIn(org.jetbrains.kotlin.gradle.dsl.abi.ExperimentalAbiValidation::class)
    abiValidation()
}

dependencyLocking {
    lockAllConfigurations()
}
