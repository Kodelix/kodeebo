plugins { kotlin("jvm") }
val extraEdges = rootProject.extra["extraEdges"] as Boolean
val reverseEdges = rootProject.extra["reverseEdges"] as Boolean
dependencies {
    implementation(project(":vendor-ktor"))
    implementation(project(":notifications"))
    if (extraEdges) { implementation(project(":vendor-mail")); implementation(project(":gaming")) }  // R1a and R4 violation edges
    if (reverseEdges) implementation(project(":identity"))  // legitimate L2 -> L1 edge (cycle check)
}
