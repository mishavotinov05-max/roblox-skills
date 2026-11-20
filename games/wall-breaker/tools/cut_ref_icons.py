"""
Вырезает иконки из картинки-референса интерфейса (присланной автором игры) → art/icons_ref/*.png.
Фон вокруг значков убирается заливкой от краёв; у плиток скругляются углы.
Запуск: python3 tools/cut_ref_icons.py <reference.png>
"""
import os
import sys
from collections import deque
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "art", "icons_ref")
os.makedirs(OUT, exist_ok=True)
src = Image.open(sys.argv[1]).convert("RGBA")


def dist(a, b):
    return sum((x - y) ** 2 for x, y in zip(a[:3], b[:3])) ** 0.5


def key_bg(img, bg_colors, tol=48):
    """Убирает фон: заливка от краёв по пикселям, похожим на заданные цвета фона
    (цвета берутся из пустых мест картинки), и останавливается на тёмной обводке."""
    w, h = img.size
    px = img.load()
    seen = [[False] * h for _ in range(w)]
    q = deque((x, y) for x in range(w) for y in (0, h - 1))
    q.extend((x, y) for y in range(h) for x in (0, w - 1))
    while q:
        x, y = q.popleft()
        if x < 0 or y < 0 or x >= w or y >= h or seen[x][y]:
            continue
        seen[x][y] = True
        c = px[x, y]
        lum = 0.3 * c[0] + 0.59 * c[1] + 0.11 * c[2]
        if lum < 60 or min(dist(c, b) for b in bg_colors) > tol:
            continue
        px[x, y] = (0, 0, 0, 0)
        q.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    # обводка карточки у самого края кадра — тоже фон
    m = 4
    for x in range(w):
        for y in range(h):
            if x < m or y < m or x >= w - m or y >= h - m:
                px[x, y] = (0, 0, 0, 0)
    return img


def colors_at(points):
    """Цвета фона из пустых мест референса (по 3×3 пикселя вокруг каждой точки)."""
    out = []
    for x, y in points:
        for dx in (-3, 0, 3):
            for dy in (-3, 0, 3):
                out.append(src.getpixel((x + dx, y + dy)))
    return out


def circle(img):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).ellipse([1, 1, img.size[0] - 2, img.size[1] - 2], fill=255)
    img.putalpha(mask)
    return img


def round_tile(img, radius):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, img.size[0] - 1, img.size[1] - 1], radius=radius, fill=255)
    img.putalpha(mask)
    return img


def save(name, img, size=256):
    bb = img.getbbox()  # обрезаем только пустые прозрачные поля
    if bb:
        img = img.crop(bb)
    w, h = img.size
    s = size / max(w, h)
    img = img.resize((max(1, round(w * s)), max(1, round(h * s))), Image.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.paste(img, ((size - img.size[0]) // 2, (size - img.size[1]) // 2), img)
    canvas.save(os.path.join(OUT, name + ".png"))


# Цвета фона, взятые из пустых мест референса
FLOOR = colors_at([(1050, 60), (1200, 60), (1350, 110), (1480, 60), (1600, 130), (1180, 125), (1300, 20), (1440, 115)])
YELLOW = colors_at([(30, 600), (220, 600), (60, 650)])
RED = colors_at([(30, 700), (220, 705), (60, 750)])
GREEN = colors_at([(30, 800), (220, 800), (60, 845)])
BAR = colors_at([(470, 560), (520, 600), (600, 545), (440, 600)])
BUTTON = colors_at([(1500, 440), (1460, 455), (1620, 450), (1350, 455), (1345, 395), (1360, 375), (1350, 430), (1440, 380)])

# Плитки слева: берём с запасом (ручка корзины выходит за плитку), фон-пол убираем
for name, box in {"ref_shop": (6, 230, 162, 398), "ref_pets": (152, 252, 310, 398), "ref_auras": (6, 398, 162, 548),
                  "ref_rebirth": (152, 398, 310, 548)}.items():
    save(name, key_bg(src.crop(box), FLOOR + colors_at([(8, 300), (150, 250), (8, 560), (315, 300)])), 300)

# Значки справа сверху (фон — пол)
save("ref_settings", key_bg(src.crop((1068, 6, 1184, 102)), FLOOR))
save("ref_quests", key_bg(src.crop((1218, 4, 1338, 101)), FLOOR))
save("ref_wheel", circle(src.crop((1377, 14, 1473, 110))))
save("ref_rewards", key_bg(src.crop((1494, 4, 1596, 101)), FLOOR))
# Значки на карточках показателей
save("ref_wins", key_bg(src.crop((25, 583, 109, 667)), YELLOW))
save("ref_strength", key_bg(src.crop((27, 683, 109, 761)), RED))
save("ref_luck", key_bg(src.crop((27, 777, 109, 859)), GREEN))
# Мечи
save("ref_level_sword", src.crop((322, 496, 432, 630)))  # лежит на жёлтой полосе — фон совпадает
save("ref_power_sword", src.crop((1338, 352, 1450, 470)))  # лежит на жёлтой кнопке — фон совпадает
print("готово:", sorted(os.listdir(OUT)))
