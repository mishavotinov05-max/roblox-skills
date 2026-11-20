"""
Пиксельные текстуры для карты (как в превью). Результат: art/textures/*.png (256×256, бесшовные).
Загрузите их в Roblox (Asset Manager → Bulk Import) и вставьте ID в Config → TextureConfig.
"""
import os
import random
from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "art", "textures")
os.makedirs(OUT, exist_ok=True)
N = 32  # пикселей в тайле, потом увеличиваем ×8


def hexc(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def base(seed, palette):
    r = random.Random(seed)
    img = Image.new("RGB", (N, N))
    px = img.load()
    for y in range(N):
        for x in range(N):
            px[x, y] = hexc(r.choice(palette))
    return img, ImageDraw.Draw(img), r


def save(name, img):
    img.resize((256, 256), Image.NEAREST).save(os.path.join(OUT, name + ".png"))


def rect(d, x, y, w, h, c):
    d.rectangle([x, y, x + w - 1, y + h - 1], fill=hexc(c))


def plates(d, border, rivet):
    for ty in range(2):
        for tx in range(2):
            x, y = tx * 16, ty * 16
            rect(d, x, y + 15, 16, 1, border)
            rect(d, x + 15, y, 1, 16, border)
            for a, b in ((2, 2), (12, 2), (2, 12), (12, 12)):
                rect(d, x + a, y + b, 2, 2, rivet)


def cracks(d, r, color):
    for _ in range(6):
        x, y = r.randrange(N), r.randrange(N)
        for _ in range(9):
            rect(d, x % N, y % N, 1, 1, color)
            x += r.randint(-1, 1)
            y += r.randint(-1, 1)


# Кирпич стен
img, d, r = base(1, ["#c9652f", "#c05d2b", "#d2703a"])
for row in range(8):
    rect(d, 0, row * 4 + 3, 32, 1, "#7d3a20")
    off = 4 if row % 2 else 0
    for x in range(off, 32, 8):
        rect(d, x, row * 4, 1, 3, "#7d3a20")
        rect(d, x + 1, row * 4, 6, 1, r.choice(["#e0844a", "#b5532a", "#c9652f"]))
save("brick", img)

# Трава сверху и сбоку
img, d, r = base(2, ["#4ccb3a", "#43b934", "#58d646", "#3fae30"])
save("grass_top", img)
img, d, r = base(3, ["#8a5a32", "#7d5030", "#946238"])
for x in range(32):
    h = 8 + r.randint(0, 4)
    rect(d, x, 0, 1, h, "#4ccb3a")
    rect(d, x, h - 1, 1, 1, "#3fae30")
save("grass_side", img)

# Пол лобби — фиолетовая плитка
img, d, r = base(4, ["#8e80d4", "#887acd", "#9486da"])
for ty in range(4):
    for tx in range(4):
        x, y = tx * 8, ty * 8
        rect(d, x, y + 7, 8, 1, "#6a5bb2")
        rect(d, x + 7, y, 1, 8, "#6a5bb2")
        rect(d, x, y, 7, 1, "#a99cec")
        rect(d, x, y, 1, 7, "#a99cec")
save("floor_tiles", img)

# Тёмный пол уровней
img, d, r = base(5, ["#5a4f86", "#544a7f", "#5f548d"])
for ty in range(4):
    for tx in range(4):
        rect(d, tx * 8, ty * 8 + 7, 8, 1, "#3e3566")
        rect(d, tx * 8 + 7, ty * 8, 1, 8, "#3e3566")
save("floor_dark", img)

# Каменный кирпич (арка, ступени)
img, d, r = base(6, ["#8f939d", "#868a94", "#979ba5"])
for row in range(4):
    rect(d, 0, row * 8 + 7, 32, 1, "#5f636d")
    off = 8 if row % 2 else 0
    for x in range(off, 32, 16):
        rect(d, x, row * 8, 1, 7, "#5f636d")
save("stone_brick", img)

# Земля
img, d, r = base(8, ["#7a5233", "#6d482c", "#86603c", "#5f3f26"])
save("dirt", img)

# Материалы уровней
img, d, r = base(11, ["#e8c341", "#f0cf52", "#dcb436"])
for _ in range(90):
    rect(d, r.randrange(32), r.randrange(32), r.randint(3, 6), 1, r.choice(["#c99a24", "#fbe58a"]))
rect(d, 0, 7, 32, 2, "#9c6a1a")
rect(d, 0, 23, 32, 2, "#9c6a1a")
save("level_hay", img)

img, d, r = base(7, ["#a86c3a", "#9d6333", "#b07440"])
for row in range(4):
    rect(d, 0, row * 8 + 7, 32, 1, "#5e3a1e")
    rect(d, r.randrange(24), row * 8, 1, 7, "#5e3a1e")
    for _ in range(6):
        rect(d, r.randrange(30), row * 8 + 1 + r.randrange(5), 3, 1, "#8d5a30")
save("level_wood", img)

img, d, r = base(13, ["#4a4c55", "#43454e", "#50525c"])
for _ in range(14):
    rect(d, r.randrange(30), r.randrange(30), r.randint(2, 3), 2, "#16171c")
save("level_coal", img)

img, d, r = base(14, ["#9a9ea8", "#8a8e98", "#a4a8b2"])
for row in range(4):
    rect(d, 0, row * 8 + 7, 32, 1, "#6a6e78")
    for x in range(8 if row % 2 else 0, 32, 16):
        rect(d, x, row * 8, 1, 7, "#6a6e78")
save("level_stone", img)

img, d, r = base(15, ["#d9773a", "#cf6e33", "#e08040"])
plates(d, "#9c4a1f", "#ffcf9a")
for _ in range(18):
    rect(d, r.randrange(32), r.randrange(32), r.randint(1, 2), 1, "#4fb8a0")
save("level_copper", img)

img, d, r = base(16, ["#d5d9e2", "#cdd1db", "#dde1ea"])
plates(d, "#8d93a3", "#ffffff")
save("level_iron", img)

img, d, r = base(17, ["#ffcf3a", "#ffc72e", "#ffd84d"])
plates(d, "#d99a12", "#fff19a")
rect(d, 3, 4, 6, 1, "#fff19a")
rect(d, 19, 20, 6, 1, "#fff19a")
save("level_gold", img)

img, d, r = base(18, ["#1d1030", "#22133a", "#170c27", "#2a1748"])
cracks(d, r, "#b05cff")
save("level_obsidian", img)

img, d, r = base(19, ["#5fe3f0", "#55d8ea", "#6aeaf5"])
for _ in range(16):
    rect(d, r.randrange(30), r.randrange(30), 2, 2, r.choice(["#c8ffff", "#2bb5d6"]))
plates(d, "#2bb5d6", "#e8ffff")
save("level_diamond", img)

img, d, r = base(20, ["#3a2e30", "#43363a", "#33282a", "#4a3b3d"])
cracks(d, r, "#ff5a1f")
save("level_netherite", img)

# ---------- Блоки с пупырышками (как на скриншоте Roblox) ----------
def studs(name, base, light, dark, top_band=None):
    S, cell = 256, 64
    img = Image.new("RGB", (S, S), hexc(base))
    d = ImageDraw.Draw(img)
    for cy in range(0, S, cell):
        for cx in range(0, S, cell):
            # шов между блоками
            d.rectangle([cx, cy, cx + cell - 1, cy + cell - 1], outline=hexc(dark), width=2)
            d.line([cx + 2, cy + 2, cx + cell - 3, cy + 2], fill=hexc(light), width=2)
            # пупырышек: тень, тело, блик
            r = 17
            mx, my = cx + cell // 2, cy + cell // 2
            d.ellipse([mx - r + 3, my - r + 5, mx + r + 3, my + r + 5], fill=hexc(dark))
            d.ellipse([mx - r, my - r, mx + r, my + r], fill=hexc(base), outline=hexc(dark), width=2)
            d.ellipse([mx - r + 5, my - r + 4, mx + 3, my - 2], fill=hexc(light))
    if top_band:
        d.rectangle([0, 0, S, S // 3], fill=hexc(top_band[0]))
        for x in range(0, S, 16):
            d.rectangle([x, S // 3, x + 15, S // 3 + (6 if (x // 16) % 2 else 12)], fill=hexc(top_band[0]))
        d.line([0, S // 3 - 2, S, S // 3 - 2], fill=hexc(top_band[1]), width=3)
    img.save(os.path.join(OUT, name + ".png"))


studs("brick", "#f08a45", "#ffb27a", "#c45f28")            # стены — рыжие блоки
studs("grass_top", "#7fd34a", "#a8ee74", "#5aa832")        # трава сверху
studs("grass_side", "#e8773a", "#ffa66b", "#b4521f", ("#7fd34a", "#5aa832"))
studs("floor_tiles", "#8fdc5a", "#b7f285", "#67b53a")      # пол лобби — светлая трава
studs("sand", "#f0c98a", "#fde3b4", "#c99a57")             # дорожки

print("Текстуры:", len(os.listdir(OUT)), "→", OUT)
