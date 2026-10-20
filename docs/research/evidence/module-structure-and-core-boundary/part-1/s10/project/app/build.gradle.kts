plugins {
    id("kodeebo.kotlin-module")
    application
}
dependencies {
    implementation(projects.platform.audit)
    implementation(projects.platform.notify)
    implementation(projects.contexts.venue)
}
application { mainClass.set("kodeebo.app.MainKt") }
