"""Render App Store screenshots with caption banners: img/appstore/raw/*.png -> img/appstore/captioned/.
Run: python3 scripts/caption_screenshots.py (needs Pillow; macOS Avenir Next font)."""
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "img", "appstore")
W, H = 1320, 2868
ORANGE, WHITE = (255, 168, 38), (255, 255, 255)
FONT_PATH = "/System/Library/Fonts/Avenir Next.ttc"
def font(sz): return ImageFont.truetype(FONT_PATH, sz, index=8)  # Heavy
SHOTS = [
    ("final_menu.png",            [[("AN ALARM EVERY", WHITE)], [("10 MINUTES. ", WHITE), ("FOREVER.", ORANGE)]]),
    ("final_ringing.png",         [[("SNOOZE IN TIME", WHITE)], [("OR LOSE ", WHITE), ("EVERYTHING", ORANGE)]]),
    ("final_smash_repaired.png",  [[("HAD ENOUGH?", WHITE)], [("SMASH ", ORANGE), ("THE CLOCK", WHITE)]]),
    ("final_missions.png",        [[("A NEW ", WHITE), ("DARE", ORANGE)], [("EVERY SINGLE DAY", WHITE)]]),
    ("final_collection.png",      [[("COLLECT THE CLOCKS", WHITE)], [("YOU ", WHITE), ("SILENCED", ORANGE)]]),
]
def fit_size(all_lines, max_w):
    d = ImageDraw.Draw(Image.new("RGB", (1, 1)))
    for sz in range(140, 60, -2):
        f = font(sz)
        if all(sum(d.textlength(t, font=f) for t, _ in segs) <= max_w for lines in all_lines for segs in lines):
            return sz
    return 60
FONT = font(fit_size([l for _, l in SHOTS], W - 140))
def render(src, lines, dst):
    bg = Image.new("RGB", (W, H))
    d = ImageDraw.Draw(bg)
    for y in range(H):  # deep navy to near-black, matching the app's night scene
        t = y / H
        d.line([(0, y), (W, y)], fill=(int(22 - 14*t), int(26 - 18*t), int(58 - 44*t)))
    # warm glow behind the caption
    glow = Image.new("L", (W, H), 0); ImageDraw.Draw(glow).ellipse((-200, -300, W+200, 900), fill=90)
    bg.paste(Image.new("RGB", (W, H), (190, 70, 20)), (0, 0), glow.filter(ImageFilter.GaussianBlur(220)))
    d = ImageDraw.Draw(bg)
    # caption
    y, lh = 170, int(FONT.size * 1.22)
    for segs in lines:
        tw = sum(d.textlength(t, font=FONT) for t, _ in segs)
        x = (W - tw) / 2
        for t, c in segs:
            d.text((x+5, y+7), t, font=FONT, fill=(0, 0, 0))  # drop shadow
            d.text((x, y), t, font=FONT, fill=c)
            x += d.textlength(t, font=FONT)
        y += lh
    # inset screenshot
    top = 540
    sh = Image.open(os.path.join(ROOT, "raw", src)).convert("RGB")
    shh = H - top - 110; sw = int(sh.width * shh / sh.height)
    sh = sh.resize((sw, shh), Image.LANCZOS)
    r = 70
    mask = Image.new("L", (sw, shh), 0); ImageDraw.Draw(mask).rounded_rectangle((0, 0, sw, shh), r, fill=255)
    sx = (W - sw) // 2
    shadow = Image.new("L", (W, H), 0); ImageDraw.Draw(shadow).rounded_rectangle((sx, top+20, sx+sw, top+20+shh), r, fill=200)
    bg.paste(Image.new("RGB", (W, H), (0, 0, 0)), (0, 0), shadow.filter(ImageFilter.GaussianBlur(40)))
    ImageDraw.Draw(bg).rounded_rectangle((sx-6, top-6, sx+sw+6, top+shh+6), r+6, fill=(255, 168, 38))  # orange frame
    bg.paste(sh, (sx, top), mask)
    bg.save(dst, "PNG")
for src, lines in SHOTS:
    render(src, lines, os.path.join(ROOT, "captioned", src.replace(".png", "_captioned.png")))
