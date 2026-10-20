import com.lemonappdev.konsist.api.Konsist
import com.lemonappdev.konsist.api.declaration.KoFileDeclaration
import com.lemonappdev.konsist.api.verify.assertFalse
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.condition.EnabledIfSystemProperty

/** S44 probes: how does Konsist 0.18.1 report a rule that checked nothing? A test that PASSES here is a silent pass. Only runs with -Pprobe=true. */
@EnabledIfSystemProperty(named = "probe", matches = "true")
class NotRunProbes {
    @Test fun konsist_emptyFileList_assertFalse_alwaysTrueLambda() {
        emptyList<KoFileDeclaration>().assertFalse { true }   // would fail on any element; there is none
    }

    @Test fun konsist_filterMatchesNothing_wrongPackage() {
        Konsist.scopeFromDirectory(System.getProperty("spike.srcroot")).files
            .filter { it.packagee?.name?.startsWith("net.kodelix.typo.") == true }
            .assertFalse { true }
    }

    @Test fun konsist_scopeFromDirectory_missingDir() {
        Konsist.scopeFromDirectory("no/such/dir").files.assertFalse { true }
    }
}
