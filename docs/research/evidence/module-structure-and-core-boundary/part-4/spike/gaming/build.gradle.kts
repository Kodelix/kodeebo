plugins { kotlin("jvm") }
val reverseEdges = rootProject.extra["reverseEdges"] as Boolean
dependencies {
    implementation(project(":vendor-ktor"))
    if (reverseEdges) implementation(project(":orders"))  // legitimate L3 -> L2 edge (cycle check)
}
