<!-- PROTOTYPE - NOT FOR PRODUCTION -->
<!-- Question: Do A (Compose Desktop) and B (Electron) render and accept Egyptian Arabic correctly on Windows 10 22H2 (G3, S6/S46, OQ22)? -->
<!-- Date: 2026-10-17 -->

# G3 Arabic test sheet: identical in A and B

Round 2, G3. Both apps show **exactly** these strings, in this order, with the same layout, so a difference between the screenshots is the runtime's. The strings are typed **raw**: no bidi control marks (LRM, RLM, ALM, isolates) are added, because the test is what each runtime does by default. A product build may add them later; that is a finding, not a fix done here.

## Modes

| Argument | Font | Base direction |
|---|---|---|
| `--arabic` | bundled **Noto Naskh Arabic 2.021** (Regular and Bold, SIL OFL 1.1, from the host's `noto-fonts` package: `/usr/share/fonts/noto/NotoNaskhArabic-{Regular,Bold}.ttf`) | right to left |
| `--arabic-system` | the Windows UI font: A uses the platform default font family, B uses CSS `"Segoe UI", sans-serif` | right to left |

The window opens **maximized**, so the screenshot shows the whole sheet. The name field has focus at start. **Tab** moves focus from the name field to the price field.

## Layout, top to bottom (in reading order, right to left)

1. **Title bar row** (one row): start = `‹ رجوع` (back); middle, taking the free space = `كوديبو — الكاشير` (bold); end = `الوردية: صباحي`.
   *Checks:* the row mirrors, so "back" is at the **right** edge. The `‹` glyph is Bidi_Mirrored in Unicode, so in a right-to-left run it should show as `›`.
2. **Counter list**: ten rows, three columns: name (start, takes the free space, **one line, ellipsis at the end** when too long); quantity or duration (fixed width); price (fixed width, aligned to the end).

| # | Name | Qty / time | Price | Tests |
|---|---|---|---|---|
| 1 | `بلايستيشن 5 — جهاز ٣` | `ساعة ونص` | `٤٥٫٥٠ ج.م` | Latin digit inside Arabic; Arabic-Indic digits and decimal separator |
| 2 | `PS5 VIP Room 2` | `02:15` | `120.00 EGP` | a Latin-only row inside an RTL layout |
| 3 | `قهوة تركي (Turkish coffee)` | `×2` | `٣٠٫٠٠ ج.م` | brackets around a Latin run (mirrored brackets) |
| 4 | `شاي بالنعناع` | `×3` | `15.00 ج.م` | Latin digits with an Arabic currency |
| 5 | `FIFA 26 — بطولة الجمعة` | `4 لاعبين` | `200.00 EGP` | a Latin start inside an Arabic name |
| 6 | `عصير مانجو طازة كبير مع آيس كريم فانيليا وقطع فواكه موسمية مشكلة ومكسرات وصوص شوكولاتة بلجيكية وكريمة مخفوقة وبسكويت لوتس مطحون وصوص كراميل مملح مع قطع براونيز` | `×1` | `٦٥٫٠٠ ج.م` | **long name truncated with an ellipsis** (founder addition): the ellipsis must sit at the logical end, on the **left** (lengthened for run 2: run 1's name fitted in the 1280 px window) |
| 7 | `استرداد — جهاز 4` | (empty) | `-45.50 ج.م` | **negative amount, Latin digits** (founder addition): the minus must stay attached to the number |
| 8 | `استرداد — جهاز ٤` | (empty) | `-٤٥٫٥٠ ج.م` | **negative amount, Arabic-Indic digits** (founder addition) |
| 9 | `خصم 10%` | (empty) | `-12.00 EGP` | **percentage with Latin digits** (founder addition) |
| 10 | `خصم ١٠٪ للأعضاء` | (empty) | `-١٢٫٠٠ ج.م` | percentage with the Arabic percent sign |

3. **Sentence line**: `بدأ الساعة 02:30 — للحجز اتصل على 01012345678`. **Time and phone number inside an Arabic sentence** (founder addition): `02:30` must not show as `30:02`, and the 11 phone digits stay in order.
4. **Fields and receipt, side by side** (one row; the fields block at the start, i.e. the right, the receipt at the end): the fields block holds, one row each, label `الاسم:` then an empty single-line text field (300 px wide), and label `السعر:` then an empty single-line text field (300 px wide). Text direction **inside the fields** follows the content (first strong character). **Labels and list text use each runtime's default** for a right-to-left layout (A: no `textDirection` set; B: inherited `dir="rtl"`).
   *(Round 2 run 1 placed the receipt under the fields, where the 800 px screen cut it off, and set A's labels to follow their content, which left-aligned Latin-led names; both changed for run 2. Run 1's screenshots are kept as `evidence/g3/a-naskh-0*`, `a-naskh-1*`, `a-naskh-2*`.)*
5. **Receipt preview** (the end of row 4): a bordered box 320 px wide, paper-like, with the seven lines of the receipt raster research (`docs/research/evidence/desktop-client-technology/scripts-p3/arabic_receipt_raster.py`), and the same alignment as that script (c = centre, r = right, l = left, absolute, not mirrored):

| Line | Size (px) | Align |
|---|---|---|
| `مقهى الجليتش` | 22 | c |
| `إيصال رقم ١٢٣ / Order 123` | 15 | c |
| `بلايستيشن ٥ - ساعة ونصف` | 16 | r |
| `Latte x2          ٢ × 45.00` | 15 | l |
| `عصير برتقال        ٣٠٫٠٠` | 16 | r |
| `الإجمالي: 120.00 ج.م` | 18 | r |
| `Total EGP 120.00` | 16 | l |

Font sizes: title 22 px, list and sentence 18 px, fields 18 px, receipt as in the table. Colours: black text on white, a light grey line under each list row, a grey border around the fields and the receipt box.

## Input test (keystrokes sent from the host with `virsh send-key`, Arabic 101 layout active)

After each step, a screenshot is taken.

1. **Name field:** type `شاي بالنعناع` (Arabic 101 keys `a h d`, space, `f h g k u k h u`).
2. Press **Shift+Left** three times: the selection must cover the last three letters typed, `ناع` (the leftmost on screen).
3. Press **Delete**: those three letters go, and the field shows `شاي بالنع`.
4. Press **Home**, then type `ش` (key `a`): the caret was at the logical start (the right edge), so the field shows `ششاي بالنع`.
5. **Tab** to the price field. Type `45.50` on the **numeric keypad** (Num Lock on) and screenshot it. Then press Backspace five times and type `-12` on the keypad.

What each layout key produces is read from the screenshots. If a key gives a different letter than expected, that's recorded as a harness fact, not a runtime defect.
