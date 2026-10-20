// S11 overlay: root build with buildscript classpath locking added.
buildscript {
    configurations.classpath {
        resolutionStrategy.activateDependencyLocking()
    }
}

tasks.register("resolveAndLockAll") {
    notCompatibleWithConfigurationCache("resolves configurations of all projects at execution time")
    doLast {
        allprojects.forEach { p ->
            p.configurations.filter { it.isCanBeResolved }.forEach { it.resolve() }
        }
    }
}
