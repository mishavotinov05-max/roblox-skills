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


def key_bg(img, bg_colors, tol=48, edge=4):
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
    m = edge
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


def largest_part(img):
    """Оставляет только самый большой непрозрачный кусок (убирает мелкие обрывки фона)."""
    w, h = img.size
    px = img.load()
    seen = [[False] * h for _ in range(w)]
    best = []
    for sx in range(w):
        for sy in range(h):
            if seen[sx][sy] or px[sx, sy][3] == 0:
                continue
            comp, q = [], deque([(sx, sy)])
            seen[sx][sy] = True
            while q:
                x, y = q.popleft()
                comp.append((x, y))
                for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1), (x + 1, y + 1), (x - 1, y - 1), (x + 1, y - 1), (x - 1, y + 1)):
                    if 0 <= nx < w and 0 <= ny < h and not seen[nx][ny] and px[nx, ny][3] > 0:
                        seen[nx][ny] = True
                        q.append((nx, ny))
            if len(comp) > len(best):
                best = comp
    keep = set(best)
    for x in range(w):
        for y in range(h):
            if (x, y) not in keep:
                px[x, y] = (0, 0, 0, 0)
    return img


def draw_wheel(size=256):
    """Колесо фортуны в стиле референса (в оригинале его низ закрыт подписью, поэтому рисуем целиком)."""
    import colorsys, math
    from PIL import ImageFilter
    big = size * 4
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    px = img.load()
    c = big / 2
    r_out, r_in = big * 0.48, big * 0.43
    for y in range(big):
        for x in range(big):
            dx, dy = x - c, y - c
            d = math.hypot(dx, dy)
            if d > r_out:
                continue
            if d > r_in:
                px[x, y] = (20, 16, 30, 255)
                continue
            ang = (math.degrees(math.atan2(dx, -dy)) + 360) % 360
            seg = math.floor(ang / 45) * 45 + 22.5  # 8 секторов, как на референсе
            blend = 0.25 * math.sin(math.radians((ang % 45) * 4))
            hue = ((seg + blend * 10 + 20) % 360) / 360
            r, g, b = colorsys.hsv_to_rgb(hue, 0.78, 1.0)
            k = 0.12 * (1 - d / r_in)  # светлее к центру
            px[x, y] = (int(255 * min(1, r + k)), int(255 * min(1, g + k)), int(255 * min(1, b + k)), 255)
    d = ImageDraw.Draw(img)
    d.ellipse([c - r_in, c - r_in, c + r_in, c + r_in], outline=(255, 255, 255, 70), width=int(big * 0.012))
    d.ellipse([c - big * 0.03, c - big * 0.03, c + big * 0.03, c + big * 0.03], fill=(255, 255, 255, 255))
    return img.resize((size, size), Image.LANCZOS)


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
FLOOR = colors_at([(1200, 20), (1350, 15), (1500, 20), (1175, 60), (1345, 60), (1505, 75), (1665, 70), (1215, 85), (1365, 90)])
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
gear = largest_part(key_bg(src.crop((1078, 21, 1168, 97)), FLOOR, 48, 0))
gm = Image.new("L", gear.size, 0)
ImageDraw.Draw(gm).ellipse([45 - 42, 38 - 42, 45 + 42, 38 + 42], fill=255)  # шестерёнка круглая — всё вне круга это фон
gear.putalpha(Image.composite(gear.getchannel("A"), Image.new("L", gear.size, 0), gm))
save("ref_settings", gear)
save("ref_quests", largest_part(key_bg(src.crop((1222, 12, 1332, 99)), FLOOR, 48, 0)))
draw_wheel().save(os.path.join(OUT, "ref_wheel.png"))
save("ref_rewards", key_bg(src.crop((1524, 6, 1662, 99)), FLOOR, 48, 0))
# Значки на карточках показателей
save("ref_wins", key_bg(src.crop((25, 583, 109, 667)), YELLOW))
save("ref_strength", key_bg(src.crop((27, 683, 109, 761)), RED))
save("ref_luck", key_bg(src.crop((27, 777, 109, 859)), GREEN))
# Мечи
save("ref_level_sword", src.crop((322, 496, 432, 630)))  # лежит на жёлтой полосе — фон совпадает
save("ref_power_sword", src.crop((1338, 352, 1450, 470)))  # лежит на жёлтой кнопке — фон совпадает
print("готово:", sorted(os.listdir(OUT)))
