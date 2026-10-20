// Root build: no code here. Task below is the documented pattern for locking every project at once.
tasks.register("resolveAndLockAll") {
    notCompatibleWithConfigurationCache("resolves configurations of all projects at execution time")
    doLast {
        allprojects.forEach { p ->
            p.configurations.filter { it.isCanBeResolved }.forEach { it.resolve() }
        }
    }
}
