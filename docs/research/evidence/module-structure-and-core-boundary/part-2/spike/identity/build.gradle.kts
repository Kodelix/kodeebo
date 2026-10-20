plugins { kotlin("jvm") }
val extraEdges = rootProject.extra["extraEdges"] as Boolean
dependencies {
    if (extraEdges) { implementation(project(":orders")); implementation(project(":gaming")) }  // R3 violation edges
}
