// PROTOTYPE - NOT FOR PRODUCTION
// Question: Do A (Compose Desktop) and B (Electron) render and accept Egyptian Arabic correctly on Windows 10 22H2 (G3, S6/S46, OQ22)?
// Date: 2026-10-17
// Content and layout: ../../ARABIC-SHEET.md (identical in A and B; strings raw, no bidi control marks).
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.key.*
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.platform.Font
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDirection
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Window
import androidx.compose.ui.window.WindowPlacement
import androidx.compose.ui.window.application
import androidx.compose.ui.window.rememberWindowState
import java.io.File

val ROWS = listOf(
    Triple("بلايستيشن 5 — جهاز ٣", "ساعة ونص", "٤٥٫٥٠ ج.م"),
    Triple("PS5 VIP Room 2", "02:15", "120.00 EGP"),
    Triple("قهوة تركي (Turkish coffee)", "×2", "٣٠٫٠٠ ج.م"),
    Triple("شاي بالنعناع", "×3", "15.00 ج.م"),
    Triple("FIFA 26 — بطولة الجمعة", "4 لاعبين", "200.00 EGP"),
    Triple("عصير مانجو طازة كبير مع آيس كريم فانيليا وقطع فواكه موسمية مشكلة ومكسرات وصوص شوكولاتة بلجيكية وكريمة مخفوقة وبسكويت لوتس مطحون وصوص كراميل مملح مع قطع براونيز", "×1", "٦٥٫٠٠ ج.م"),
    Triple("استرداد — جهاز 4", "", "-45.50 ج.م"),
    Triple("استرداد — جهاز ٤", "", "-٤٥٫٥٠ ج.م"),
    Triple("خصم 10%", "", "-12.00 EGP"),
    Triple("خصم ١٠٪ للأعضاء", "", "-١٢٫٠٠ ج.م"),
)
const val SENTENCE = "بدأ الساعة 02:30 — للحجز اتصل على 01012345678"
val RECEIPT = listOf(
    Triple("مقهى الجليتش", 22, TextAlign.Center),
    Triple("إيصال رقم ١٢٣ / Order 123", 15, TextAlign.Center),
    Triple("بلايستيشن ٥ - ساعة ونصف", 16, TextAlign.Right),
    Triple("Latte x2          ٢ × 45.00", 15, TextAlign.Left),
    Triple("عصير برتقال        ٣٠٫٠٠", 16, TextAlign.Right),
    Triple("الإجمالي: 120.00 ج.م", 18, TextAlign.Right),
    Triple("Total EGP 120.00", 16, TextAlign.Left),
)

fun fontBytes(name: String) = object {}.javaClass.getResourceAsStream("/fonts/$name")!!.readBytes()

fun arabicSheet(bundledFont: Boolean) {
    val family = if (bundledFont) FontFamily(
        Font("naskh-regular", fontBytes("NotoNaskhArabic-Regular.ttf"), FontWeight.Normal),
        Font("naskh-bold", fontBytes("NotoNaskhArabic-Bold.ttf"), FontWeight.Bold),
    ) else FontFamily.Default
    val procStart = ProcessHandle.current().info().startInstant().map { it.toEpochMilli() }.orElse(-1L)
    application {
        val state = rememberWindowState(placement = WindowPlacement.Maximized)
        Window(onCloseRequest = ::exitApplication, state = state,
            title = if (bundledFont) "Kodeebo spike A — Arabic (Naskh)" else "Kodeebo spike A — Arabic (system font)") {
            CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Rtl) {
                Sheet(family)
            }
            LaunchedEffect(Unit) {
                File(dataDir, "ready.txt").appendText("arabic=${if (bundledFont) "naskh" else "system"} pid=${ProcessHandle.current().pid()} proc_start_ms=$procStart shown_ms=${System.currentTimeMillis()}\n")
            }
        }
    }
}

@Composable
fun Sheet(family: FontFamily) {
    // Labels and list text: Compose's default text direction (run 2). Run 1 set TextDirection.Content here, which
    // made Latin-led names left-to-right paragraphs (ARABIC-SHEET.md item 4). Only the fields follow their content.
    val t18 = TextStyle(fontFamily = family, fontSize = 18.sp, color = Color.Black)
    val field = t18.copy(textDirection = TextDirection.Content)
    val focus = LocalFocusManager.current
    val nameFocus = remember { FocusRequester() }
    var name by remember { mutableStateOf("") }
    var price by remember { mutableStateOf("") }
    val tabToNext = Modifier.onPreviewKeyEvent {
        if (it.key == Key.Tab && it.type == KeyEventType.KeyDown) { focus.moveFocus(FocusDirection.Next); true } else false
    }
    Column(Modifier.fillMaxSize().background(Color.White).padding(16.dp)) {
        // 1. title bar row: start = back, middle = title, end = shift
        Row(Modifier.fillMaxWidth().padding(bottom = 8.dp), verticalAlignment = Alignment.CenterVertically) {
            BasicText("‹ رجوع", style = t18)
            BasicText("كوديبو — الكاشير", Modifier.weight(1f).padding(horizontal = 16.dp),
                style = t18.copy(fontSize = 22.sp, fontWeight = FontWeight.Bold))
            BasicText("الوردية: صباحي", style = t18)
        }
        // 2. counter list
        ROWS.forEach { (n, q, p) ->
            Row(Modifier.fillMaxWidth().padding(vertical = 4.dp),
                verticalAlignment = Alignment.CenterVertically) {
                BasicText(n, Modifier.weight(1f), style = t18, maxLines = 1, overflow = TextOverflow.Ellipsis)
                BasicText(q, Modifier.width(110.dp), style = t18, maxLines = 1)
                BasicText(p, Modifier.width(150.dp), style = t18.copy(textAlign = TextAlign.End), maxLines = 1)
            }
            Box(Modifier.fillMaxWidth().height(1.dp).background(Color(0xFFDDDDDD)))
        }
        // 3. sentence
        BasicText(SENTENCE, Modifier.padding(vertical = 12.dp), style = t18)
        // 4 + 5. fields (start = right) and receipt preview (end = left), side by side
        Row(Modifier.fillMaxWidth()) {
            Column {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    BasicText("الاسم:", Modifier.width(80.dp), style = t18)
                    BasicTextField(name, { name = it }, Modifier.width(300.dp).border(1.dp, Color.Gray).padding(6.dp)
                        .focusRequester(nameFocus).then(tabToNext), textStyle = field, singleLine = true)
                }
                Spacer(Modifier.height(8.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    BasicText("السعر:", Modifier.width(80.dp), style = t18)
                    BasicTextField(price, { price = it }, Modifier.width(300.dp).border(1.dp, Color.Gray).padding(6.dp).then(tabToNext),
                        textStyle = field, singleLine = true)
                }
            }
            Spacer(Modifier.weight(1f))
            // receipt preview: absolute alignment, as on paper
            Column(Modifier.width(320.dp).border(1.dp, Color.Gray).padding(8.dp)) {
                RECEIPT.forEach { (line, size, align) ->
                    BasicText(line, Modifier.fillMaxWidth().padding(vertical = 2.dp), style = t18.copy(fontSize = size.sp, textAlign = align))
                }
            }
        }
    }
    LaunchedEffect(Unit) { nameFocus.requestFocus() }
}
