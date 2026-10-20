// S11 overlay: build-logic locks its own project configurations and its own buildscript classpath.
plugins { `kotlin-dsl` }
buildscript {
    configurations.classpath {
        resolutionStrategy.activateDependencyLocking()
    }
}
dependencyLocking { lockAllConfigurations() }
dependencies {
    implementation("org.jetbrains.kotlin:kotlin-gradle-plugin:2.4.21")
}
