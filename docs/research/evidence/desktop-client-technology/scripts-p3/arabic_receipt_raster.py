#!/usr/bin/env python3
"""Tier-E probe: render an Arabic/English/digits receipt to a 1-bit bitmap with
Pillow+Raqm (HarfBuzz+FriBidi), emit an ESC/POS byte stream (ESC @, GS v 0 raster,
ESC p drawer pulse), decode it back, and report sizes. No printer involved.
Usage: arabic_receipt_raster.py OUTDIR
Test parameters (NOT sourced printer facts): width 576 dots (80 mm test) and 384 dots (58 mm test)."""
import sys, os, struct
from PIL import Image, ImageDraw, ImageFont, features, __version__

out = sys.argv[1]; os.makedirs(out, exist_ok=True)
FONT = os.environ.get("RECEIPT_FONT", "/usr/share/fonts/noto/NotoNaskhArabic-Medium.ttf")
assert features.check("raqm"), "raqm missing"
LINES = [  # (text, size, align)  Arabic = RTL base direction
 ("مقهى الجليتش", 34, "c"),
 ("إيصال رقم ١٢٣ / Order 123", 22, "c"),
 ("بلايستيشن ٥ - ساعة ونصف", 24, "r"),
 ("Latte x2          ٢ × 45.00", 22, "l"),
 ("عصير برتقال        ٣٠٫٠٠", 24, "r"),
 ("الإجمالي: 120.00 ج.م", 28, "r"),
 ("Total EGP 120.00", 24, "l"),
]
def render(width):
    img = Image.new("L", (width, 10), 255); y = 4; rows = []
    for text, size, al in LINES:
        f = ImageFont.truetype(FONT, size, layout_engine=ImageFont.Layout.RAQM)
        has_ar = any("؀" <= c <= "ۿ" for c in text)
        d = ImageDraw.Draw(img)
        l, t, r, b = d.textbbox((0, 0), text, font=f, direction="rtl" if has_ar else "ltr")
        rows.append((text, f, has_ar, al, b - t, t)); y += (b - t) + 14
    img = Image.new("L", (width, y + 8), 255); d = ImageDraw.Draw(img); y = 4
    for text, f, has_ar, al, h, t in rows:
        w = d.textlength(text, font=f, direction="rtl" if has_ar else "ltr")
        x = {"c": (width - w) / 2, "r": width - w - 4, "l": 4}[al]
        d.text((x, y - t), text, font=f, fill=0, direction="rtl" if has_ar else "ltr"); y += h + 14
    return img.convert("1")
def raster_cmd(img):
    w, h = img.size; wb = (w + 7) // 8; px = img.load(); data = bytearray()
    for yy in range(h):
        for xb in range(wb):
            byte = 0
            for bit in range(8):
                x = xb * 8 + bit
                if x < w and px[x, yy] == 0: byte |= 0x80 >> bit
            data.append(byte)
    assert wb <= 255 and h <= 65535
    return b"\x1d\x76\x30\x00" + struct.pack("<HH", wb, h) + bytes(data)   # GS v 0 m xL xH yL yH d...
def decode(stream):
    i, ev = 0, []
    while i < len(stream):
        if stream[i:i+2] == b"\x1b\x40": ev.append("ESC @ (init)"); i += 2
        elif stream[i:i+3] == b"\x1d\x76\x30":
            m, xl, xh, yl, yh = stream[i+3], stream[i+4], stream[i+5], stream[i+6], stream[i+7]
            wb, h = xl + xh*256, yl + yh*256; ev.append(f"GS v 0 m={m} width_bytes={wb} height={h}"); i += 8 + wb*h
        elif stream[i:i+2] == b"\x1b\x70": ev.append(f"ESC p m={stream[i+2]} t1={stream[i+3]} t2={stream[i+4]}"); i += 5
        elif stream[i:i+1] == b"\x0a": ev.append("LF"); i += 1
        else: raise SystemExit(f"unknown byte 0x{stream[i]:02x} at {i}")
    return ev
print("python-pillow", __version__, "raqm", features.check("raqm"), "fribidi", features.check("fribidi"), "harfbuzz", features.check("harfbuzz"))
for name, w in (("80mm_test_576dots", 576), ("58mm_test_384dots", 384)):
    img = render(w); img.save(f"{out}/receipt_{name}.png")
    stream = b"\x1b\x40" + raster_cmd(img) + b"\x0a\x0a\x0a" + b"\x1b\x70\x00\x19\xfa"  # drawer: pin2, 25*2=50ms on, 250*2=500ms off
    open(f"{out}/receipt_{name}.escpos.bin", "wb").write(stream)
    print(name, "image", img.size, "stream bytes", len(stream), "decoded:", decode(stream))
