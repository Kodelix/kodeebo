plugins { kotlin("jvm"); id("com.jraska.module.graph.assertion") version "2.9.1" }
dependencies { for (m in listOf(":notifications", ":identity", ":orders", ":gaming")) implementation(project(m)) }
moduleGraphAssert {
    restricted = arrayOf(
        ":(notifications|identity) -X> :(orders|gaming)",   // R3
        ":orders -X> :gaming",                                // R4
        ":(identity|orders|gaming|graph-check) -X> :vendor-mail" // R1 (third-party client only)
    )
}
