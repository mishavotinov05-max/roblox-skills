"""
Готовит «скины» интерфейса из картинок автора игры (art/ui_src/*.png):
 убирает напечатанные числа, чтобы игра писала свои значения поверх.
Результат: art/ui_ref/*.png и art/ui_ref/skins.json (где писать число).
Запуск: python3 tools/make_ui_skins.py
"""
import json
import os
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "art", "ui_src")
OUT = os.path.join(ROOT, "art", "ui_ref")
os.makedirs(OUT, exist_ok=True)
meta = {}


def load(name):
    im = Image.open(os.path.join(SRC, name)).convert("RGBA")
    a = im.getchannel("A").point(lambda v: 0 if v < 128 else v)
    im.putalpha(a)
    return im.crop(im.getbbox())


def lum(c):
    return 0.3 * c[0] + 0.59 * c[1] + 0.11 * c[2]


def text_box(im, x0, x1, y0, y1):
    """Рамка белого текста (с обводкой) в заданной области."""
    px = im.load()
    xs, ys = [], []
    for y in range(y0, y1):
        for x in range(x0, x1):
            c = px[x, y]
            if c[3] > 200 and min(c[:3]) > 225:
                xs.append(x)
                ys.append(y)
    return min(xs), min(ys), max(xs), max(ys)


def erase(im, box, pad, top_limit=None, left_only=False):
    """Стирает число: каждую строку заливаем цветом фона этой же строки, взятым из чистого места
    справа от текста (у правого края карточки, внутри обводки)."""
    px = im.load()
    w, h = im.size
    x0, x1 = box[0] - pad, box[2] + pad
    y0, y1 = box[1] - pad, box[3] + pad
    if top_limit is not None:
        y0 = max(y0, top_limit)
    for y in range(y0, y1 + 1):
        # ищем справа налево внутреннюю часть карточки (после чёрной обводки)
        x = w - 1
        while x > x1 and (px[x, y][3] < 200 or lum(px[x, y]) < 60):
            x -= 1
        sx = max(x1 + 2, x - 14)
        cr = px[min(sx, w - 1), y]
        cl = px[x0 - 2, y]
        if left_only or cr[3] < 200 or lum(cr) < 60:
            cr = cl
        if cl[3] < 200 or lum(cl) < 60:
            cl = cr
        for xx in range(x0, min(x1 + 1, w)):
            t = (xx - x0) / max(1, x1 - x0)
            px[xx, y] = tuple(int(cl[i] * (1 - t) + cr[i] * t) for i in range(3)) + (255,)
    region = im.crop((x0 - 2, y0 - 2, x1 + 3, y1 + 3)).filter(ImageFilter.GaussianBlur(1.5))
    im.paste(region, (x0 - 2, y0 - 2))
    return (x0, y0, x1, y1)


def frac(box, im):
    w, h = im.size
    return [round(box[0] / w, 4), round(box[1] / h, 4), round((box[2] - box[0]) / w, 4), round((box[3] - box[1]) / h, 4)]


# Карточки: Победы / Сила / Удача — число во второй строке справа от значка
for src, name in (("wins.webp", "card_wins"), ("strength.webp", "card_strength"), ("luck.webp", "card_luck")):
    im = load(src)
    w, h = im.size
    tx0 = int(w * 0.38)
    top = text_box(im, tx0, int(w * 0.97), int(h * 0.1), int(h * 0.48))
    num = text_box(im, tx0, int(w * 0.97), int(h * 0.5), int(h * 0.92))
    area = erase(im, num, 30, top_limit=top[3] + 10)
    im.save(os.path.join(OUT, name + ".png"))
    meta[name] = {"ratio": round(w / h, 4), "value": frac(area, im), "title": frac(top, im)}

# Перерождения: число внутри тёмной «таблетки»
im = load("rebirth.webp")
w, h = im.size
num = text_box(im, int(w * 0.45), int(w * 0.75), int(h * 0.45), int(h * 0.95))
area = erase(im, num, 22, left_only=True)
im.save(os.path.join(OUT, "card_rebirth.png"))
meta["card_rebirth"] = {"ratio": round(w / h, 4), "value": frac(area, im)}

# Полоса уровня: делаем 2 картинки — пустую (тёмную) и полную (жёлтую), без текста
im = load("level.webp")
w, h = im.size
px = im.load()
sword_end = int(w * 0.122)
clean_x = None
def is_yellow(c):
    return c[3] > 200 and c[0] > 200 and c[1] > 120 and c[2] < 140


for x in range(int(w * 0.35), int(w * 0.75)):  # чистый жёлтый столбец между «272» и «3.82M»
    if all(is_yellow(px[x, y]) for y in range(int(h * 0.25), int(h * 0.75))):
        clean_x = x
        break
# толщина обводки полосы: меряем у нижнего края, где нет текста
yy = int(h * 0.8)
xr = max(x for x in range(w) if px[x, yy][3] > 200)
OUTLINE = 0
while lum(px[xr - OUTLINE, yy]) < 70:
    OUTLINE += 1
OUTLINE = min(OUTLINE, int(w * 0.012)) + 2

yellow, dark = im.copy(), im.copy()
yp, dp = yellow.load(), dark.load()
for y in range(h):
    # внутренняя часть полосы в этой строке: между тёмной обводкой слева и справа
    row = [x for x in range(sword_end, w) if px[x, y][3] > 200 and lum(px[x, y]) < 70]
    if len(row) < 2:
        continue
    right = max(row)
    inner_end = right - OUTLINE
    base = px[clean_x, y]
    if base[3] < 200 or lum(base) < 70:
        continue
    for x in range(sword_end, inner_end + 1):
        if px[x, y][3] < 200:
            continue
        yp[x, y] = base
        g = int(lum(base))
        dp[x, y] = (int(g * 0.28 + 40), int(g * 0.28 + 40), int(g * 0.3 + 58), 255)
yellow.save(os.path.join(OUT, "levelbar_full.png"))
dark.save(os.path.join(OUT, "levelbar_empty.png"))
# строки самой полосы (без кончика меча сверху): где справа есть непрозрачные пиксели
rows = [y for y in range(h) if px[int(w * 0.6), y][3] > 200]
meta["levelbar"] = {"ratio": round(w / h, 4), "start": round(sword_end / w, 4),
                    "barTop": round(min(rows) / h, 4), "barBottom": round((max(rows) + 1) / h, 4)}


# Кнопка «Мощный удар»: глянцевая жёлтая плашка в том же стиле
W, H = 800, 300
btn = Image.new("RGBA", (W, H), (0, 0, 0, 0))
d = ImageDraw.Draw(btn)
d.rounded_rectangle([0, 0, W - 1, H - 1], radius=110, fill=(15, 12, 20, 255))
d.rounded_rectangle([18, 18, W - 19, H - 19], radius=95, fill=(255, 176, 0, 255))
for i in range(120):  # градиент сверху светлее
    c = (255, 214 - i // 4, 40 + max(0, 60 - i), 255)
    d.rounded_rectangle([18, 18 + i, W - 19, H - 19], radius=95, outline=c, width=1)
d.rounded_rectangle([40, 30, W - 41, 110], radius=40, fill=(255, 246, 170, 120))
btn.save(os.path.join(OUT, "power_button.png"))

json.dump(meta, open(os.path.join(OUT, "skins.json"), "w"), indent=1)
print(json.dumps(meta, indent=1))
