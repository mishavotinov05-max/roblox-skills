"""
Сборка файла места WallBreaker.rbxlx: карта (настоящие детали), интерфейс и все скрипты.
Запуск:  python3 tools/build_place.py
Результат: games/wall-breaker/WallBreaker.rbxlx — открыть двойным щелчком в Roblox Studio.
"""
import json
import math
import os
import random
from rbxlx import (Inst, P, Frame3, rot, part, particles, ui_gradient, model, folder, point_light, prompt, script, frame, label, text_button,
                   image, image_button, ui_corner, ui_stroke, ui_padding, ui_scale, ui_list, ui_grid, scrolling,
                   surface_gui, billboard, screen_gui, write_place, FONT_BOLD)

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SRC = os.path.join(ROOT, "src")
OUT = os.path.join(ROOT, "WallBreaker.rbxlx")

# ---------- Размеры лобби ----------
HW, XL, HD = 64, -58, 76       # восточная стена x=HW, западная x=XL, север/юг z=∓HD
WALLH, T = 24, 4
LVL_LEN, LVL_COUNT = 96, 10
LVL0 = -HD - T                  # начало первого уровня (сразу за северной стеной)

DARK = (26, 16, 51)
BRICK = (232, 119, 58)   # рыжие блоки, как на скриншоте
GRASS = (127, 211, 74)
FLOOR = (120, 214, 96)   # пол лобби — чистая сочная трава (меняется у деталей Hub › Floor)
STONE = (143, 147, 157)
WOOD = (122, 74, 36)
GOLD = (255, 200, 40)

rnd = random.Random(7)


def grass_cap(name, w, d, x, z, top):
    return part(name, (w, 1.6, d), (x, top + 0.8, z), GRASS, "Grass")


def wall_box(name, w, h, d, x, z, y0=0, color=BRICK, mat="Brick"):
    return part(name, (w, h, d), (x, y0 + h / 2, z), color, mat)


def lantern(name, pos, light=True):
    x, y, z = pos
    m = model(name)
    m.add(part("Glow", (1.1, 1.4, 1.1), (x, y, z), (255, 184, 74), "Neon", collide=False, cast_shadow=False,
               children=[point_light()] if light else None))
    m.add(part("Top", (1.6, 0.35, 1.6), (x, y + 0.85, z), (43, 34, 56), "Metal"))
    m.add(part("Bottom", (1.6, 0.35, 1.6), (x, y - 0.85, z), (43, 34, 56), "Metal"))
    return m


def sign_part(name, size, pos, r, title, sub="", bg=(75, 42, 158), border=(255, 225, 77), extra=None, ppu=40):
    """Табличка: деталь + SurfaceGui с текстом (Title, Sub, …) на передней стороне."""
    w, h = size[0], size[1]
    gui = surface_gui("SignGui", "Front", ppu)
    board = frame("Board", ((1, 0), (1, 0)), ((0, 0), (0, 0)), bg=bg, bgt=0)
    board.add(ui_corner(0, 18), ui_stroke(6, border, mode=1))
    has_sub = bool(sub) or extra
    board.add(label("Title", title, ((0.92, 0), (0.46 if has_sub else 0.8, 0)), ((0.04, 0), (0.06 if has_sub else 0.1, 0)), stroke=4))
    if sub:
        board.add(label("Sub", sub, ((0.92, 0), (0.24, 0)), ((0.04, 0), (0.52, 0)), color=(255, 233, 168), stroke=3))
    for e in extra or []:
        board.add(e)
    gui.add(board)
    return part(name, size, pos, DARK, "SmoothPlastic", r=r, children=[gui])


# ======================= ЛОББИ =======================
def build_hub():
    hub = folder("Hub")

    # --- Пол с отверстиями под ямы ---
    pit_cols = [PIT_X]
    pit_rows = PIT_ROWS
    hole = PIT_HOLE
    xs = sorted({XL, HW} | {c + s * hole for c in pit_cols for s in (-1, 1)})
    floor_f = folder("Floor")
    for i in range(len(xs) - 1):
        x0, x1 = xs[i], xs[i + 1]
        is_pit_col = any(abs((x0 + x1) / 2 - c) < 1 for c in pit_cols)
        zs = [-HD, HD]
        if is_pit_col:
            zs = sorted({-HD, HD} | {r + s * hole for r in pit_rows for s in (-1, 1)})
        for j in range(len(zs) - 1):
            z0, z1 = zs[j], zs[j + 1]
            if is_pit_col and any(abs((z0 + z1) / 2 - r) < 1 for r in pit_rows):
                continue  # здесь яма
            floor_f.add(part(f"Floor_{i}_{j}", (x1 - x0, 1, z1 - z0), ((x0 + x1) / 2, -0.5, (z0 + z1) / 2), FLOOR, "SmoothPlastic"))
    hub.add(floor_f)

    # --- Стены ---
    # Ступенчатые холмы из рыжих блоков с травой сверху (вместо ровных стен), как на скриншоте
    walls = folder("Walls")
    gap = 9
    cr = random.Random(21)
    n = [0]

    tops = []  # (x0, x1, z0, z1, верх) — чтобы ставить ёлки ровно на холмы

    def cliff(x0, x1, z0, z1, h):
        n[0] += 1
        tops.append((min(x0, x1), max(x0, x1), min(z0, z1), max(z0, z1), h + 1.6))
        col = cr.choice(((236, 128, 72), (226, 112, 60), (245, 145, 85)))
        walls.add(part(f"Cliff_{n[0]}", (x1 - x0, h, z1 - z0), ((x0 + x1) / 2, h / 2, (z0 + z1) / 2), col, "Plastic", studs=True))
        walls.add(part(f"Trim_{n[0]}", (x1 - x0 + 0.2, 0.8, z1 - z0 + 0.2), ((x0 + x1) / 2, h - 0.4, (z0 + z1) / 2), (255, 190, 120),
                       "SmoothPlastic", collide=False))
        walls.add(part(f"GrassCliff_{n[0]}", (x1 - x0 + 0.4, 1.6, z1 - z0 + 0.4), ((x0 + x1) / 2, h + 0.8, (z0 + z1) / 2), GRASS, "Plastic",
                       studs=True))
        return h

    def side(a0, a1, place, skip=None):
        """Вдоль стороны: блоки разной ширины, 2–3 ступени назад и вверх."""
        a = a0
        while a < a1:
            w = cr.choice((8, 12, 12, 16, 20))
            w = min(w, a1 - a)
            if skip and a < skip[1] and a + w > skip[0]:
                if a < skip[0]:
                    w = skip[0] - a  # дотягиваем блок вплотную к арке — без дырки
                else:
                    a = skip[1]
                    continue
            h = cr.choice((12, 14, 16, 18, 20))
            d0 = 0
            for tier in range(cr.choice((2, 3, 3))):
                depth = cr.choice((6, 8, 10))
                shift = cr.choice((-2, 0, 0, 2)) if tier else 0
                place(a + shift, a + w + shift, d0, d0 + depth, h)
                d0 += depth
                h += cr.choice((6, 8, 10))
            a += w

    # юг (z = HD … дальше), запад (x = XL … меньше), восток (x = HW … больше), север (z = -HD … меньше, кроме арки)
    side(XL - 10, HW + 10, lambda a0, a1, d0, d1, h: cliff(a0, a1, HD + d0, HD + d1, h))
    side(-HD - 10, HD + 10, lambda a0, a1, d0, d1, h: cliff(XL - d1, XL - d0, a0, a1, h))
    side(-HD - 10, HD + 10, lambda a0, a1, d0, d1, h: cliff(HW + d0, HW + d1, a0, a1, h))
    side(XL - 10, HW + 10, lambda a0, a1, d0, d1, h: cliff(a0, a1, -HD - d1, -HD - d0, h), skip=(-14, 14))
    # над аркой — перемычка, по бокам арки — блоки
    cliff(-14, -13, -HD - 30, -HD, 23)
    cliff(13, 14, -HD - 30, -HD, 23)
    walls.add(wall_box("WallNorthTop", 28, 6, 6, 0, -HD - 3, y0=23))
    walls.add(grass_cap("GrassNorthTop", 28.4, 6.4, 0, -HD - 3, 29))

    # пиксельные ёлки на холмах
    trees = folder("Trees")
    placed = 0
    for k in range(80):
        if placed >= 20:
            break
        sd = k % 4
        if sd == 0:
            x, z = cr.uniform(XL, HW), HD + cr.uniform(8, 22)
        elif sd == 1:
            x, z = XL - cr.uniform(8, 22), cr.uniform(-HD, HD)
        elif sd == 2:
            x, z = HW + cr.uniform(8, 22), cr.uniform(-HD, HD)
        else:
            x, z = cr.choice((cr.uniform(XL, -20), cr.uniform(20, HW))), -HD - cr.uniform(8, 22)
        # высота земли под ёлкой = верх самого высокого холма в этой точке (с травой)
        under = [t4 for (a0, a1, b0, b1, t4) in tops if a0 + 2 <= x <= a1 - 2 and b0 + 2 <= z <= b1 - 2]
        if not under:
            continue  # не над холмом — не ставим, чтобы ёлка не висела в воздухе
        base = max(under)
        placed += 1
        t = model(f"Tree_{placed}")
        t.add(part("Trunk", (2, 6, 2), (x, base + 3, z), (120, 72, 40), "Wood"))
        for i, (w, hh) in enumerate(((12, 4), (9, 4), (6, 4), (3, 3))):
            t.add(part(f"Leaves{i + 1}", (w, hh, w), (x, base + 6 + i * 4 + hh / 2, z), (70, 190, 60), "Grass"))
        trees.add(t)
    hub.add(trees)
    hub.add(walls)

    # --- Декор: светящиеся линии прохода и фонари ---
    decor = folder("Decor")
    # песчаная дорожка по центральному проходу с белыми бортиками
    decor.add(part("Path_Center", (14, 0.12, 2 * HD - 2), (0, 0.06, 0), (246, 214, 158), "SmoothPlastic", cast_shadow=False))
    for x in (-7.4, 7.4):
        decor.add(part(f"PathTrim_{'L' if x < 0 else 'R'}", (0.8, 0.3, 2 * HD - 2), (x, 0.15, 0), (255, 255, 255), "SmoothPlastic",
                       cast_shadow=False))
    # бордюр по периметру зала
    for nm, sx, sz, px, pz in (("BorderS", HW - XL, 1.4, (XL + HW) / 2, HD - 0.7), ("BorderN", HW - XL, 1.4, (XL + HW) / 2, -HD + 0.7),
                               ("BorderW", 1.4, 2 * HD, XL + 0.7, 0), ("BorderE", 1.4, 2 * HD, HW - 0.7, 0)):
        decor.add(part(nm, (sx, 0.5, sz), (px, 0.25, pz), (255, 236, 200), "SmoothPlastic", cast_shadow=False))
    n = 0
    for z in (-26, 0, 26):
        n += 1
        decor.add(lantern(f"Lantern_{n}", (XL + 0.9, 11, z), light=(z == 0)))
    for x in (-30, -50):
        n += 1
        decor.add(lantern(f"Lantern_{n}", (x, 11, HD - 0.9), light=(x == -50)))
        n += 1
        decor.add(lantern(f"Lantern_{n}", (x, 11, -HD + 0.9), light=False))
    for z in (-42, 42):
        n += 1
        decor.add(lantern(f"Lantern_{n}", (HW - 0.9, 11, z), light=(z == 42)))
    for k, z in enumerate((-52.5, -31.5, -10.5, 10.5, 31.5, 52.5)):
        decor.add(part(f"Path_{k + 1}", (-20.5 - XL, 0.12, 5), ((XL - 20.5) / 2, 0.06, z), (240, 201, 138), "SmoothPlastic"))
    decor.add(part("PathWest", (8, 0.12, 2 * HD - 2), (XL + 4, 0.06, 0), (240, 201, 138), "SmoothPlastic"))
    hub.add(decor)

    # --- Точка появления ---
    hub.add(Inst("SpawnLocation", "SpawnLocation", part("x", (8, 1, 8), (0, 0.5, 40), (122, 60, 255), "Neon").props
                 + [P("int", "Duration", 0), P("bool", "Neutral", True)]))

    hub.add(build_entrance())
    hub.add(build_pickaxe_shop())
    hub.add(build_pits())
    hub.add(build_eggs())
    hub.add(build_trader())
    return hub


def build_entrance():
    m = model("LevelEntrance")
    z = -HD + 1.5
    m.add(part("PillarLeft", (4.5, 23, 5), (-11, 11.5, z), STONE, "Cobblestone"))
    m.add(part("PillarRight", (4.5, 23, 5), (11, 11.5, z), STONE, "Cobblestone"))
    m.add(part("Lintel", (27, 4.5, 5.4), (0, 21.25, z), STONE, "Cobblestone"))
    m.add(part("Step", (28, 0.6, 6), (0, 0.3, z), (95, 99, 109), "Slate"))
    for x in (-11, 11):
        m.add(part(f"Crystal_{'L' if x < 0 else 'R'}", (1.4, 3, 1.4), (x, 25, z + 1), (198, 107, 255), "Neon", r=rot(0, 45, 0),
                   collide=False, cast_shadow=False))
    m.add(lantern("LanternLeft", (-15.2, 12, z + 1.5)))
    m.add(lantern("LanternRight", (15.2, 12, z + 1.5)))
    m.add(sign_part("Sign", (18, 6, 0.6), (0, 27.5, z + 2.2), rot(0, 180, 0), "УРОВНИ", "10 стен · проходи по порядку"))
    return m


# ---------- Кирки: 16 штук, 4 ряда-ступени (как PickaxeConfig) ----------
PICKS = [  # имя, редкость, цена (текст), множитель, цвет головки, цвет рукояти
    ("Деревянная", "Обычная", "Бесплатно", "x1", (205, 140, 80), (107, 63, 29)),
    ("Каменная", "Обычная", "5", "x1.3", (190, 195, 205), (140, 90, 50)),
    ("Медная", "Обычная", "15", "x1.7", (230, 130, 70), (140, 90, 50)),
    ("Железная", "Редкая", "40", "x2.5", (235, 240, 250), (140, 90, 50)),
    ("Стальная", "Редкая", "100", "x3.5", (150, 165, 185), (90, 60, 40)),
    ("Золотая", "Эпическая", "250", "x5", (255, 210, 60), (140, 90, 50)),
    ("Алмазная", "Эпическая", "600", "x7.5", (110, 240, 255), (140, 90, 50)),
    ("Изумрудная", "Эпическая", "1.5K", "x10", (70, 230, 120), (140, 90, 50)),
    ("Обсидиановая", "Легендарная", "4K", "x15", (130, 70, 220), (60, 40, 80)),
    ("Ледяная", "Легендарная", "10K", "x20", (160, 230, 255), (90, 130, 170)),
    ("Огненная", "Легендарная", "25K", "x30", (255, 110, 30), (90, 40, 20)),
    ("Электрическая", "Легендарная", "60K", "x40", (80, 200, 255), (40, 60, 110)),
    ("Космическая", "Божественная", "150K", "x60", (150, 110, 255), (40, 30, 90)),
    ("Ангельская", "Божественная", "400K", "x80", (255, 240, 200), (230, 190, 90)),
    ("Теневая", "Божественная", "1M", "x100", (90, 40, 140), (30, 20, 40)),
    ("Дьявольская", "Божественная", "2.5M", "x150", (220, 30, 40), (40, 15, 15)),
]
RARITY_COL = {"Обычная": (190, 195, 210), "Редкая": (70, 160, 255), "Эпическая": (170, 90, 255),
              "Легендарная": (255, 190, 40), "Божественная": (255, 60, 80)}


PICK_FX = {  # как в PickaxeConfig: эффект и цвет свечения
    "Железная": ("shine", None), "Стальная": ("shine", None),
    "Золотая": ("glow", (255, 240, 150)), "Алмазная": ("glow", (200, 255, 255)), "Изумрудная": ("glow", (170, 255, 190)),
    "Обсидиановая": ("glow", (200, 120, 255)), "Ледяная": ("ice", (210, 245, 255)), "Огненная": ("fire", (255, 220, 80)),
    "Электрическая": ("electric", (160, 240, 255)), "Космическая": ("cosmic", (255, 140, 255)),
    "Ангельская": ("angel", (255, 215, 90)), "Теневая": ("shadow", (190, 90, 255)), "Дьявольская": ("devil", (255, 80, 40)),
}
PICK_PARTICLES = {
    "fire": ((255, 140, 30), 14, "rbxasset://textures/particles/fire_main.dds", 2, 0.6),
    "ice": ((200, 240, 255), 6, "rbxasset://textures/particles/sparkles_main.dds", 0.6, 0.35),
    "electric": ((120, 220, 255), 10, "rbxasset://textures/particles/sparkles_main.dds", 3, 0.3),
    "cosmic": ((220, 140, 255), 8, "rbxasset://textures/particles/sparkles_main.dds", 0.8, 0.4),
    "angel": ((255, 240, 180), 6, "rbxasset://textures/particles/sparkles_main.dds", 0.6, 0.4),
    "shadow": ((120, 40, 180), 10, "rbxasset://textures/particles/smoke_main.dds", 0.8, 0.8),
    "devil": ((255, 60, 20), 12, "rbxasset://textures/particles/fire_main.dds", 1.5, 0.5),
}


def lighten(c, k):
    return tuple(int(v + (255 - v) * k) for v in c)


def dkc(c, k):
    return tuple(int(v * k) for v in c)


def display_pickaxe(name, x, y, z, head, handle):
    """Кирка на витрине — та же форма, что в руке (ReplicatedStorage › Shared › PickaxeLook)."""
    effect, accent = PICK_FX.get(name, ("", None))
    accent = accent or head
    rare = effect not in ("", "shine")
    head_mat = "Glass" if effect in ("ice", "glow") else "Metal"
    dk = lambda c, k: tuple(int(v * k) for v in c)
    m = model("Display")
    L, R, N, SPAN = 4.6, 3.2, 21, 50
    TILT = -35  # наклон кирки на витрине, как на картинке (по диагонали)
    ct, st_ = math.cos(math.radians(TILT)), math.sin(math.radians(TILT))
    PIV = L * 0.55

    def add(nm, size, local, color, mat, ang=0, shape=None, cls="Part", ry=0, children=None, rz=0):
        ly, lz = local[1] - PIV, local[2]
        ly, lz = ly * ct - lz * st_, ly * st_ + lz * ct
        m.add(part(nm, size, (x + local[0], y + PIV + ly, z + lz), color, mat, r=rot(ang + TILT, ry, rz), collide=False,
                   shape=shape, cls=cls, reflectance=0.08 if mat in ("Metal", "SmoothPlastic") else 0,
                   cast_shadow=mat != "Neon", children=children))
    lt = lambda c, k: tuple(int(v + (255 - v) * k) for v in c)
    add("Handle", (L, 0.46, 0.46), (0, L / 2, 0), handle, "Wood", shape="Cylinder", rz=90)
    add("HandleShine", (L * 0.9, 0.12, 0.12), (-0.12, L / 2, -0.12), lt(handle, 0.35), "SmoothPlastic", shape="Cylinder", rz=90)
    for i, yy in enumerate((0.5, 0.85, 1.2, 1.55)):
        add(f"Wrap{i + 1}", (0.2, 0.56, 0.56), (0, yy, 0), dk(handle, 0.55), "Fabric", shape="Cylinder", rz=90)
    add("Pommel", (0.7, 0.7, 0.7), (0, 0.05, 0), accent if rare else dk(handle, 0.8), "Metal", shape="Ball")
    add("Collar", (1.0, 0.8, 0.8), (0, L - 0.2, 0), dk(head, 0.75), "Metal", shape="Cylinder", ry=90)
    top = L + 0.3
    seg = R * math.radians(SPAN * 2 / (N - 1)) * 1.15
    for i in range(N):
        deg = -SPAN + i * (SPAN * 2 / (N - 1))
        t = math.radians(deg)
        k = abs(deg) / SPAN
        h = 1.0 * (1 - 0.65 * k) + 0.2
        cy, cz = top - R * (1 - math.cos(t)), R * math.sin(t)
        extra = None
        if rare and i == N // 2:
            extra = [point_light(accent, 1.2, 8)]
            if effect in PICK_PARTICLES:
                extra.append(particles(*PICK_PARTICLES[effect]))
        add(f"Head{i}", (0.5, h, seg), (0, cy, cz), head, head_mat, ang=deg, children=extra)
        for nm, o, col in (("Top", h * 0.41, lt(head, 0.45)), ("Bottom", -h * 0.41, dk(head, 0.6))):
            add(f"{nm}{i}", (0.52, max(0.06, h * 0.18), seg), (0, cy + o * math.cos(t), cz + o * math.sin(t)), col, head_mat, ang=deg)
        if rare:
            dy, dz = -h * 0.1 * math.cos(t), -h * 0.1 * math.sin(t)
            add(f"Vein{i}", (0.54, max(0.08, h * 0.22), seg * 0.95), (0, cy + dy, cz + dz), accent, "Neon", ang=deg)
    for sgn in (-1, 1):
        t = math.radians(SPAN * sgn)
        d = sgn * seg * 0.75
        cy = top - R * (1 - math.cos(t)) - 0.05 * math.cos(t) - d * math.sin(t)
        cz = R * math.sin(t) - 0.05 * math.sin(t) + d * math.cos(t)
        add("TipA" if sgn < 0 else "TipB", (0.46, 0.3, 0.75), (0, cy, cz), head, head_mat, ang=SPAN * sgn, cls="WedgePart",
            ry=180 if sgn < 0 else 0)
    if effect == "angel":
        for sgn in (-1, 1):
            for f in range(1, 4):
                add(f"Feather{sgn}{f}", (0.2, 0.45, 1.6 - f * 0.25), (0, L - 0.6 + f * 0.35, sgn * (0.9 + f * 0.25)), (255, 255, 255),
                    "SmoothPlastic", ang=sgn * (25 + f * 12))
        add("Halo", (0.12, 1.3, 1.3), (0, top + 0.9, 0), accent, "Neon", rz=90, shape="Cylinder")
    elif effect == "devil":
        for sgn in (-1, 1):
            add(f"Horn{sgn}", (0.3, 0.9, 0.3), (0, top + 0.5, sgn * 0.5), accent, "Neon", ang=sgn * 25)
    return m


def build_pickaxe_shop():
    shop = model("PickaxeShop")
    SHOP_Z, ROW_D, STEP = 30, 7, 2.5
    row_x = [HW - 4 * ROW_D + k * ROW_D for k in range(4)]
    row_col = [(190, 195, 210), (70, 160, 255), (255, 190, 40), (255, 60, 80)]
    steps = folder("Steps")
    SHOP_DARK, SHOP_MID = (236, 226, 255), (255, 250, 240)  # светлые пастельные ступени
    steps.add(part("Row1", (ROW_D, 0.4, 2 * SHOP_Z), (row_x[0] + ROW_D / 2, 0.2, 0), SHOP_MID, "SmoothPlastic"))
    for k in range(1, 4):
        steps.add(part(f"Row{k + 1}", (HW - row_x[k], STEP * k, 2 * SHOP_Z), ((row_x[k] + HW) / 2, STEP * k / 2, 0),
                       SHOP_MID if k % 2 == 0 else SHOP_DARK, "SmoothPlastic"))
        steps.add(part(f"Stair{k}", (2.5, STEP * (k - 0.5), 5), (row_x[k] - 1.25, STEP * (k - 0.5) / 2, 0), SHOP_MID, "SmoothPlastic"))
    for r, x in enumerate(row_x):
        steps.add(part(f"Edge{r + 1}", (0.35, 0.35, 2 * SHOP_Z), (x + 0.2, r * STEP + 0.6, 0), row_col[r], "Neon",
                       collide=False, cast_shadow=False))
    shop.add(steps)
    shop.add(part("BackWall", (1.2, 20, 2 * SHOP_Z + 4), (HW - 0.6, 3 * STEP + 10, 0), (255, 214, 150), "SmoothPlastic"))
    shop.add(part("BackWallTrim", (1.4, 0.6, 2 * SHOP_Z + 4), (HW - 0.6, 3 * STEP + 20, 0), (255, 196, 61), "Neon", collide=False))
    shop.add(sign_part("Sign", (24, 5.4, 0.6), (HW - 1.4, 24.5, 0), rot(0, 90, 0), "КИРКИ", "Коллекция: 16 кирок"))

    slots = folder("Slots")
    slot_z = [-21, -7, 7, 21]
    idx = 0
    for r, x0 in enumerate(row_x):
        y = r * STEP + (0.4 if r == 0 else 0)
        for z in slot_z:
            name, rarity, price, mult, head, handle = PICKS[idx]
            rc = RARITY_COL[rarity]
            s = model(f"Slot_{idx + 1:02d}")
            px = x0 + ROW_D - 1.8
            ped = part("Pedestal", (1.4, 2.6, 2.6), (px, y + 0.7, z), (255, 252, 245), "SmoothPlastic", shape="Cylinder", r=rot(0, 0, 90))
            ped.add(billboard("NameGui", (210, 62), (0, 10.6, 0), max_dist=34, children=[
                label("PickName", name, ((1, 0), (0.55, 0)), ((0, 0), (0, 0)), stroke=3),
                frame("Tag", ((0.9, 0), (0.42, 0)), ((0.05, 0), (0.57, 0)), bg=(26, 16, 51), bgt=0.15, children=[
                    ui_corner(1, 0), ui_stroke(2, rc),
                    label("PickInfo", f"{rarity} · {mult} Силы", ((1, -8), (1, -4)), ((0, 4), (0, 2)), color=rc, stroke=2)])]))
            s.add(ped)
            s.add(part("Glow", (0.25, 2.5, 2.5), (px, y + 1.45, z), rc, "Neon", shape="Cylinder", r=rot(0, 0, 90), collide=False,
                       cast_shadow=False, children=[point_light(rc, 0.8, 7)]))
            s.add(display_pickaxe(name, px, y + 1.7, z, head, handle))
            # место под кирку-картинку (PickaxeConfig → Image); пока пусто — видна 3D-кирка
            s.add(part("ImageBoard", (0.1, 6.5, 6.5), (px, y + 4.9, z), (255, 255, 255), "SmoothPlastic", transparency=1, collide=False,
                       query=False, touch=False, cast_shadow=False, children=[
                           surface_gui(f"PickGui{fc}", fc, 60, [image("PickImage", "", ((1, 0), (1, 0)), ((0, 0), (0, 0)), visible=False)])
                           for fc in ("Left", "Right")]))
            pad = part("BuyPad", (3.6, 0.3, 3.6), (x0 + 2.2, y + 0.15, z), lighten(rc, 0.55), "SmoothPlastic",
                       children=[prompt("Купить", name),
                                 billboard("PriceGui", (150, 46), (0, 2.4, 0), max_dist=30, children=[
                                     frame("Bg", ((1, 0), (1, 0)), ((0, 0), (0, 0)), bg=(42, 23, 87), bgt=0.15,
                                           children=[ui_corner(0, 14), ui_stroke(3, rc),
                                                     label("Icon", "🏆", ((0, 38), (1, 0)), ((0, 4), (0, 0)), stroke=0),
                                                     label("Price", price, ((1, -48), (1, -8)), ((0, 44), (0, 4)),
                                                           color=(255, 225, 77), stroke=2.5)])])])
            s.add(pad)
            s.add(part("PadFrame", (4, 0.2, 4), (x0 + 2.2, y + 0.05, z), rc, "Neon", collide=False, cast_shadow=False))
            slots.add(s)
            idx += 1
    shop.add(slots)
    return shop


# ---------- Ямы: 7 штук, как на картинке ----------
PIT_STYLE = [  # имя, перерождения, материал ямы, цвет ямы, цвет камня бортика, акцент (рамка/свет)
    ("Обычная яма", 0, "Pebble", (110, 75, 50), (125, 112, 160), (150, 140, 190)),
    ("Угольная яма", 3, "Slate", (40, 40, 46), (90, 86, 110), (255, 140, 40)),
    ("Каменная яма", 9, "Cobblestone", (150, 152, 160), (160, 162, 172), (120, 200, 90)),
    ("Железная яма", 18, "DiamondPlate", (150, 160, 180), (110, 125, 150), (90, 170, 255)),
    ("Золотая яма", 36, "Foil", (200, 150, 40), (150, 110, 60), (255, 200, 40)),
    ("Алмазная яма", 50, "Ice", (60, 120, 220), (80, 95, 170), (90, 220, 255)),
    ("Мифическая яма", 65, "Basalt", (70, 30, 110), (95, 60, 140), (230, 80, 255)),
]
PIT_ROWS = [-63, -42, -21, 0, 21, 42, 63]
PIT_X = -36
PIT_HOLE = 6  # половина ширины ямы


def crystal(name, pos, size, color, tilt=(0, 0, 0)):
    return part(name, size, pos, color, "Neon", r=rot(*tilt), collide=False)


def build_pits():
    pits = folder("Pits")
    depth, h = 5, PIT_HOLE
    rr = random.Random(11)
    for idx, zc in enumerate(PIT_ROWS):
        name, reb, mat, color, rim_col, accent = PIT_STYLE[idx]
        c = PIT_X
        m = model(f"Pit_{idx + 1:02d}")
        m.add(part("PitFloor", (2 * h, 1, 2 * h), (c, -depth - 0.5, zc), color, mat))
        for side, (dx, dz, sx, sz) in {"N": (0, -h - 0.5, 2 * h + 2, 1), "S": (0, h + 0.5, 2 * h + 2, 1),
                                       "W": (-h - 0.5, 0, 1, 2 * h), "E": (h + 0.5, 0, 1, 2 * h)}.items():
            m.add(part(f"Wall{side}", (sx, depth, sz), (c + dx, -depth / 2, zc + dz), color, mat))
        # каменный бортик из блоков разной высоты
        rim = folder("Rim")
        k = 0
        for side in "NSWE":
            for t in range(6):
                a = -h - 0.5 + (t + 0.5) * (2 * h + 1) / 6
                bh = 0.6 + rr.random() * 1.2
                if side in "NS":
                    pos = (c + a, bh / 2, zc + (-h - 1.2 if side == "N" else h + 1.2))
                    size = (2.1, bh, 2.2)
                else:
                    pos = (c + (-h - 1.2 if side == "W" else h + 1.2), bh / 2, zc + a)
                    size = (2.2, bh, 2.1)
                k += 1
                blk = part(f"Block{k}", size, pos, rim_col, "DiamondPlate" if idx == 3 else "Slate")
                rim.add(blk)
                if idx == 3 and t % 2 == 0:  # заклёпки на железной яме
                    rim.add(part(f"Rivet{k}", (0.35, 0.35, 0.35), (pos[0], bh + 0.1, pos[2]), accent, "Neon", collide=False))
        m.add(rim)
        props = folder("Props")
        fy = -depth
        if idx in (0, 2):  # камни и трава
            for t in range(5):
                s = 0.8 + rr.random() * (1.6 if idx == 2 else 0.8)
                props.add(part(f"Rock{t}", (s, s * 0.8, s), (c + rr.uniform(-4, 4), fy + s * 0.4, zc + rr.uniform(-4, 4)),
                               (120, 90, 60) if idx == 0 else (165, 168, 178), "Slate", r=rot(rr.uniform(0, 40), rr.uniform(0, 90), 0)))
            for t, (gx, gz) in enumerate(((-h - 1.5, -h - 1.5), (h + 1.5, h + 1.5), (-h - 1.5, h + 1.2), (h + 1.2, -h - 1.6))):
                for g in range(3):
                    props.add(part(f"Grass{t}_{g}", (0.3, 1.2, 0.3), (c + gx + g * 0.3, 1.8, zc + gz), (90, 200, 70), "Grass",
                                   r=rot(rr.uniform(-25, 25), 0, rr.uniform(-25, 25)), collide=False))
        elif idx == 1:  # уголь, фонарь, кирка
            for t in range(14):
                s = 0.7 + rr.random() * 0.8
                props.add(part(f"Coal{t}", (s, s, s), (c + rr.uniform(-4.5, 4.5), fy + s / 2, zc + rr.uniform(-4.5, 4.5)), (25, 25, 30),
                               "Slate", r=rot(rr.uniform(0, 45), rr.uniform(0, 90), 0)))
            for t in range(6):
                props.add(part(f"Ember{t}", (0.5, 0.2, 0.5), (c + rr.uniform(-3, 3), fy + 0.15, zc + rr.uniform(-3, 3)), (255, 120, 30), "Neon",
                               collide=False))
            props.add(lantern("Lantern", (c + h + 1.2, 2.6, zc - h - 1.2)))
            props.add(part("PickHandle", (0.4, 5, 0.4), (c - h - 1.6, 2.2, zc + h - 1), (140, 90, 50), "Wood", r=rot(25, 0, 0)))
            props.add(part("PickHead", (0.5, 0.5, 3), (c - h - 1.6, 4.4, zc + h - 2), (180, 185, 195), "Metal", r=rot(25, 0, 0)))
        elif idx == 3:  # железные блоки
            for t in range(6):
                s = 1.2 + rr.random() * 1.2
                props.add(part(f"Iron{t}", (s, s, s), (c + rr.uniform(-4, 4), fy + s / 2, zc + rr.uniform(-4, 4)), (170, 180, 200),
                               "DiamondPlate", r=rot(0, rr.uniform(0, 90), rr.uniform(0, 25))))
        elif idx == 4:  # золотые кристаллы
            for t in range(8):
                hh = 1.5 + rr.random() * 2.5
                props.add(crystal(f"Gold{t}", (c + rr.uniform(-4.5, 4.5), fy + hh / 2, zc + rr.uniform(-4.5, 4.5)), (0.8, hh, 0.8),
                                  (255, 200, 40), (rr.uniform(-20, 20), 45, rr.uniform(-20, 20))))
        elif idx == 5:  # алмазы
            props.add(crystal("BigDiamondTop", (c, fy + 4.2, zc), (2.4, 2.4, 2.4), (110, 235, 255), (45, 45, 0)))
            props.add(crystal("BigDiamondBottom", (c, fy + 2.6, zc), (1.7, 1.7, 1.7), (60, 180, 255), (45, 45, 0)))
            for t in range(6):
                hh = 1.5 + rr.random() * 2.2
                props.add(crystal(f"Diamond{t}", (c + rr.uniform(-4.5, 4.5), fy + hh / 2, zc + rr.uniform(-4.5, 4.5)), (0.9, hh, 0.9),
                                  (110, 235, 255), (rr.uniform(-25, 25), 45, rr.uniform(-25, 25))))
        elif idx == 6:  # мифическая: кристаллы, вихрь, руны
            for t, rad in enumerate((4.5, 3.2, 2.0, 0.9)):
                props.add(part(f"Swirl{t}", (0.12, 2 * rad, 2 * rad), (c, fy + 0.08 + t * 0.03, zc), (230, 80, 255) if t % 2 == 0 else (120, 40, 200),
                               "Neon", shape="Cylinder", r=rot(0, 0, 90), collide=False, cast_shadow=False))
            for t in range(6):
                hh = 2 + rr.random() * 2.5
                props.add(crystal(f"Mythic{t}", (c + rr.choice((-4.6, 4.6)), fy + hh / 2, zc + rr.uniform(-4.5, 4.5)), (0.9, hh, 0.9),
                                  (220, 90, 255), (rr.uniform(-20, 20), 45, rr.uniform(-20, 20))))
            for t, (rx, rz) in enumerate(((-h - 1.8, -h + 1), (-h - 1.8, h - 1))):
                rune = part(f"Rune{t}", (2, 1.2, 2), (c + rx, 0.6, zc + rz), (120, 80, 50), "WoodPlanks")
                rune.add(surface_gui("RuneGui", "Top", 60, [label("Mark", "✦", ((1, 0), (1, 0)), ((0, 0), (0, 0)), color=(255, 200, 60), stroke=0)]))
                props.add(rune)
        m.add(props)
        if idx >= 4:
            light_part = part("Glow", (1, 1, 1), (c, fy + 2, zc), accent, "Neon", transparency=1, collide=False, query=False, touch=False,
                              cast_shadow=False, children=[point_light(accent, 2.5, 22)])
            m.add(light_part)
        # табличка: название сверху, «Перерождения: N» снизу (смотрит на главный проход)
        sx = c - h - 3.2
        m.add(part("SignPostA", (0.5, 6, 0.5), (sx - 0.4, 3, zc - 3), WOOD, "Wood"))
        m.add(part("SignPostB", (0.5, 6, 0.5), (sx - 0.4, 3, zc + 3), WOOD, "Wood"))
        gui = surface_gui("SignGui", "Front", 40)
        title_bg = frame("TitleBanner", ((1, 0), (0.48, 0)), ((0, 0), (0, 0)), bg=(60, 55, 80), bgt=0)
        title_bg.add(ui_corner(0, 18), ui_stroke(6, accent), label("Title", name, ((0.94, 0), (0.86, 0)), ((0.03, 0), (0.07, 0)), stroke=4))
        gui.add(title_bg)
        req_bg = frame("ReqPlaque", ((0.9, 0), (0.38, 0)), ((0.05, 0), (0.58, 0)), bg=(35, 30, 50), bgt=0)
        req_bg.add(ui_corner(0, 18), ui_stroke(5, accent), label("Sub", f"Перерождения: {reb}", ((0.92, 0), (0.8, 0)), ((0.04, 0), (0.1, 0)),
                                                                 stroke=3))
        gui.add(req_bg)
        m.add(part("Sign", (12, 6, 0.4), (sx, 7.4, zc), DARK, "SmoothPlastic", r=rot(0, -90, 0), transparency=1, children=[gui]))
        m.add(part("TrainZone", (2 * h, 8, 2 * h), (c, -1, zc), (255, 255, 255), "SmoothPlastic", transparency=1,
                   collide=False, query=False, touch=False, cast_shadow=False))
        m.add(part("LockBarrier", (2 * h, 0.6, 2 * h), (c, 0.3, zc), accent, "ForceField", transparency=0.2))
        pits.add(m)
    return pits


# ---------- Яйца: 6 штук, как на картинке ----------
EGG_STYLE = [  # id, название, бейдж, цена, цвет карточки
    ("chicken", "Куриное\nЯйцо", "Обычное", "20 Побед", (255, 140, 40)),
    ("steel", "Стальное\nЯйцо", "Редкое", "250 Побед", (40, 120, 255)),
    ("magic", "Магическое\nЯйцо", "Эпическое", "1 000 Побед", (170, 60, 255)),
    ("admin", "Админское\nЯйцо", "Легендарное", "2 000 Побед", (255, 170, 20)),
    ("divine", "Божественное\nЯйцо", "Божественное", "100 Robux", (150, 120, 255)),
    ("devil", "Дьявольское\nЯйцо", "Божественное", "150 Robux", (230, 30, 50)),
]
EGG_X = [57, 44, 30, 16, 2, -12]  # у южной стены: из зала слева направо — от Куриного к Дьявольскому


def egg_body(m, x, y, z, color, mat="SmoothPlastic"):
    egg = part("Egg", (4, 4, 4), (x, y, z), color, mat, shape="Ball", children=[
        Inst("SpecialMesh", "Mesh", [P("token", "MeshType", 3), P("vec3", "Scale", (1, 1.3, 1))])])
    m.add(egg)


def ring(name, x, y, z, radius, color, mat="Metal", thick=0.35, tilt=0):
    return part(name, (thick, 2 * radius, 2 * radius), (x, y, z), color, mat, shape="Cylinder", r=rot(tilt, 0, 90), collide=False)


def build_eggs():
    eggs = folder("Eggs")
    z = HD - 12
    for (egg_id, title, tag, price, card), x in zip(EGG_STYLE, EGG_X):
        m = model(f"Egg_{egg_id}")
        m.add(part("Pedestal", (1.6, 6.5, 6.5), (x, 0.8, z), (70, 60, 100), "Slate", shape="Cylinder", r=rot(0, 0, 90)))
        m.add(part("Ring", (0.3, 6.9, 6.9), (x, 1.7, z), card, "Neon", shape="Cylinder", r=rot(0, 0, 90), collide=False, cast_shadow=False))
        ey = 4.6
        if egg_id == "chicken":
            egg_body(m, x, ey, z, (245, 235, 215))
            for k, (a, b) in enumerate(((0.4, 0.8), (-0.3, 0.2), (0.2, -0.5))):
                m.add(part(f"Crack{k}", (0.12, 1.2, 0.12), (x + a, ey + b, z - 1.95), (90, 70, 50), "SmoothPlastic", r=rot(0, 0, 30 * (k - 1)),
                           collide=False))
            for k in range(10):
                ang = k * 36
                m.add(part(f"Straw{k}", (2.8, 0.35, 0.35), (x + 2.2 * math.cos(math.radians(ang)), 2.2, z + 2.2 * math.sin(math.radians(ang))),
                           (230, 180, 60), "Fabric", r=rot(0, -ang + 90, 12), collide=False))
        elif egg_id == "steel":
            egg_body(m, x, ey, z, (120, 130, 145), "Metal")
            for k, dy in enumerate((-1.2, 0.2, 1.5)):
                m.add(ring(f"Band{k}", x, ey + dy, z, 2.05 - abs(dy) * 0.25, (170, 180, 195), "DiamondPlate", 0.5))
        elif egg_id == "magic":
            egg_body(m, x, ey, z, (140, 50, 220), "Neon")
            for k in range(4):
                m.add(part(f"Lattice{k}", (0.25, 5, 0.25), (x, ey, z), (255, 200, 60), "Foil", r=rot(0, 45 * k, 18), collide=False))
            m.add(crystal("Gem", (x, ey, z - 2.05), (1, 1, 0.5), (230, 150, 255), (0, 0, 45)))
        elif egg_id == "admin":
            egg_body(m, x, ey, z, (30, 28, 36))
            screen = part("Screen", (2.4, 1.4, 0.2), (x, ey, z - 2.0), (20, 10, 30), "SmoothPlastic", collide=False)
            screen.add(surface_gui("ScreenGui", "Front", 60, [label("Prompt", ">_", ((1, 0), (1, 0)), ((0, 0), (0, 0)),
                                                                    color=(255, 70, 220), stroke=0)]))
            m.add(screen)
            m.add(ring("CrownBase", x, ey + 2.6, z, 1.3, (255, 200, 40), "Foil", 0.6))
            for k in range(5):
                ang = math.radians(k * 72)
                m.add(part(f"CrownSpike{k}", (0.4, 1.1, 0.4), (x + 1.1 * math.cos(ang), ey + 3.3, z + 1.1 * math.sin(ang)), (255, 200, 40), "Foil",
                           collide=False))
            for s in (-1, 1):
                for k in range(3):
                    m.add(part(f"Laurel{s}_{k}", (0.4, 1.2, 0.8), (x + s * (2.4 - k * 0.2), ey - 1.5 + k * 1.1, z - 0.6), (230, 180, 40), "Foil",
                               r=rot(0, 0, -s * (20 + k * 15)), collide=False))
        elif egg_id == "divine":
            egg_body(m, x, ey, z, (250, 245, 235))
            m.add(ring("GoldBand", x, ey, z, 2.05, (255, 200, 60), "Foil", 0.45))
            m.add(crystal("Gem", (x, ey, z - 2.05), (0.9, 0.9, 0.5), (80, 200, 255), (0, 0, 45)))
            m.add(ring("Halo", x, ey + 4.1, z, 1.6, (255, 220, 80), "Neon", 0.25, 0))
            m.add(part("HaloHole", (0.3, 2.4, 2.4), (x, ey + 4.1, z), card, "SmoothPlastic", shape="Cylinder", r=rot(0, 0, 90),
                       transparency=1, collide=False))
            for s in (-1, 1):
                for k in range(3):
                    m.add(part(f"Wing{s}_{k}", (2.6 - k * 0.5, 0.5, 1.2), (x + s * (2.8 + k * 0.4), ey + 0.8 - k * 0.7, z + 0.3), (255, 255, 255),
                               "SmoothPlastic", r=rot(0, 0, s * (25 - k * 10)), collide=False))
        elif egg_id == "devil":
            egg_body(m, x, ey, z, (35, 15, 18))
            for k in range(6):
                m.add(part(f"Crack{k}", (0.15, 1.6, 0.15), (x + math.cos(k) * 1.4, ey + math.sin(k * 2) * 1.2, z - 1.6 + abs(math.cos(k)) * 0.3),
                           (255, 60, 30), "Neon", r=rot(0, 0, k * 40), collide=False))
            for s in (-1, 1):
                m.add(part(f"Horn{s}a", (0.7, 1.6, 0.7), (x + s * 1.3, ey + 2.6, z), (60, 20, 20), "SmoothPlastic", r=rot(0, 0, -s * 30), collide=False))
                m.add(part(f"Horn{s}b", (0.45, 1.2, 0.45), (x + s * 1.9, ey + 3.6, z), (200, 40, 30), "SmoothPlastic", r=rot(0, 0, -s * 10),
                           collide=False))
            m.add(ring("Chain", x, ey - 0.6, z, 2.1, (90, 90, 100), "Metal", 0.3, 20))
            m.add(ring("CrownBase", x, ey + 2.7, z, 0.9, (255, 200, 40), "Foil", 0.45))
        # карточка-фон с названием, бейджем и ценой (смотрит на север, к игрокам)
        gui = surface_gui("CardGui", "Front", 40)
        bg = frame("Card", ((1, 0), (1, 0)), ((0, 0), (0, 0)), bg=card, bgt=0)
        bg.add(ui_corner(0, 40), ui_stroke(10, (255, 255, 255), transparency=0.3))
        bg.add(label("Title", title, ((0.92, 0), (0.24, 0)), ((0.04, 0), (0.03, 0)), stroke=6))
        tagf = frame("TagBg", ((0.7, 0), (0.08, 0)), ((0.15, 0), (0.28, 0)), bg=(26, 16, 51), bgt=0.2)
        tagf.add(ui_corner(1, 0), label("Tag", tag, ((0.9, 0), (0.8, 0)), ((0.05, 0), (0.1, 0)), stroke=3))
        bg.add(tagf)
        pricef = frame("PriceBg", ((0.88, 0), (0.13, 0)), ((0.06, 0), (0.84, 0)),
                       bg=(40, 140, 60) if "Robux" in price else (60, 40, 20), bgt=0.1)
        pricef.add(ui_corner(0, 26), ui_stroke(5, (255, 210, 80)),
                   label("Icon", "💎" if "Robux" in price else "🏆", ((0.25, 0), (0.9, 0)), ((0.02, 0), (0.05, 0)), stroke=0),
                   label("Price", price, ((0.7, 0), (0.86, 0)), ((0.28, 0), (0.07, 0)), color=(255, 225, 77), stroke=4))
        bg.add(pricef)
        gui.add(bg)
        m.add(part("Card", (9, 13, 0.6), (x, 6.5, z + 4.2), DARK, "SmoothPlastic", children=[gui]))
        eggs.add(m)
    return eggs


def blocky_npc(fr, base, shirt=(63, 111, 214), name="NPC"):
    m = model(name)
    skin, pants, hat = (255, 217, 168), (43, 43, 58), (122, 74, 36)
    bx, by, bz = base

    def add(n, size, off, color, mat="SmoothPlastic"):
        pos, r = fr.at((bx + off[0], by + off[1], bz + off[2]))
        m.add(part(n, size, pos, color, mat, r=r, collide=False))
    add("Torso", (2, 2, 1), (0, 3, 0), shirt)
    add("Head", (1.25, 1.25, 1.25), (0, 4.65, 0), skin)
    add("HatBrim", (2.2, 0.35, 2.2), (0, 5.4, 0), hat)
    add("HatTop", (1.4, 0.8, 1.4), (0, 5.9, 0), hat)
    add("ArmL", (1, 2, 1), (-1.5, 3, 0), skin)
    add("ArmR", (1, 2, 1), (1.5, 3, 0), skin)
    add("LegL", (1, 2, 1), (-0.5, 1, 0), pants)
    add("LegR", (1, 2, 1), (0.5, 1, 0), pants)
    return m


def stall(name, fr, prompt_text, sign_title, sign_sub, sign_bg):
    m = model(name)

    def add(n, size, off, color, mat, lr=None, children=None, collide=True):
        pos, r = fr.at(off, lr)
        p = part(n, size, pos, color, mat, r=r, children=children, collide=collide)
        m.add(p)
        return p
    add("Counter", (10, 3, 3), (0, 1.5, 0), WOOD, "WoodPlanks", children=[prompt(prompt_text, sign_title, dist=12)])
    for i, (x, z) in enumerate([(-4.6, -1.2), (4.6, -1.2), (-4.6, -5), (4.6, -5)]):
        add(f"Post{i + 1}", (0.6, 9, 0.6), (x, 4.5, z), (107, 63, 29), "Wood")
    for i in range(6):
        add(f"Awning{i + 1}", (1.8, 0.5, 6), (-4.5 + i * 1.8, 9.4, -2.6), (255, 255, 255) if i % 2 else (255, 77, 109), "Fabric",
            lr=rot(-14, 0, 0))
    m.add(blocky_npc(fr, (0, 0, -2.6)))
    for i, (x, z) in enumerate([(-6.8, 0), (-6.5, -2.4)]):
        add(f"Barrel{i + 1}", (2.6, 2, 2), (x, 1.3, z), (140, 90, 50), "WoodPlanks", lr=rot(0, 0, 90))
    add("Crate", (2.4, 2, 2.4), (6.8, 1, 0.4), (150, 100, 55), "WoodPlanks")
    for i in range(3):
        add(f"Crystal{i + 1}", (0.7, 1.6, 0.7), (6.2 + i * 0.6, 2.8, 0.4), (94, 231, 255), "Neon", lr=rot(0, 45, 12 * (i - 1)),
            collide=False)
    pos, r = fr.at((0, 11.6, -0.4), rot(0, 180, 0))
    m.add(sign_part("Sign", (9, 3.4, 0.4), pos, r, sign_title, sign_sub, bg=sign_bg))
    return m


def build_trader():
    fr = Frame3((HW - 10, 0, -HD + 10), rot(0, -45, 0))
    return stall("OreTrader", fr, "Продать все руды", "Торговец", "Продажа руд", (31, 143, 114))


# ======================= УРОВНИ =======================
LEVELS = [
    ("Сено", "Fabric", (232, 195, 65)), ("Дерево", "WoodPlanks", (160, 105, 58)), ("Уголь", "Slate", (58, 60, 68)),
    ("Камень", "Cobblestone", (150, 154, 163)), ("Медь", "Metal", (217, 119, 58)), ("Железо", "DiamondPlate", (205, 209, 218)),
    ("Золото", "Foil", (255, 200, 40)), ("Обсидиан", "Basalt", (52, 28, 80)), ("Алмаз", "Ice", (95, 227, 240)),
    ("Незерит", "CrackedLava", (80, 58, 60)),
]
RECOMMENDED = ["5", "30", "150", "750", "3.5K", "15K", "62.5K", "250K", "1M", "4M"]
REWARDS = [1, 3, 6, 15, 25, 40, 67, 75, 100, 130]


def build_levels():
    levels = folder("Levels")
    for i, (name, mat, color) in enumerate(LEVELS):
        lid = i + 1
        z0 = LVL0 - i * LVL_LEN
        f = folder(f"Level_{lid:02d}")
        st = folder("Structure")
        st.add(part("Floor", (24, 1, LVL_LEN), (0, -0.5, z0 - LVL_LEN / 2), (240, 201, 138), "SmoothPlastic"))
        for x in (-10.5, 10.5):
            st.add(part(f"Line{'L' if x < 0 else 'R'}", (0.4, 0.1, LVL_LEN), (x, 0.05, z0 - LVL_LEN / 2), (255, 158, 31), "Neon",
                        collide=False, cast_shadow=False))
        niche_z, niche_l = z0 - 60, 26
        seg1 = niche_z + niche_l / 2 - z0          # отрицательная длина до ниши
        seg2 = LVL_LEN + seg1 - niche_l
        st.add(wall_box("WallLeft", 3, 18, LVL_LEN, -13.5, z0 - LVL_LEN / 2))
        st.add(wall_box("WallRightA", 3, 18, -seg1, 13.5, z0 + seg1 / 2))
        st.add(wall_box("WallRightB", 3, 18, seg2, 13.5, niche_z - niche_l / 2 - seg2 / 2))
        st.add(wall_box("NicheSideA", 16, 18, 3, 23, niche_z + niche_l / 2 + 1.5))
        st.add(wall_box("NicheSideB", 16, 18, 3, 23, niche_z - niche_l / 2 - 1.5))
        st.add(wall_box("NicheBack", 3, 18, niche_l + 6, 32.5, niche_z))
        st.add(part("NicheFloor", (20, 1, niche_l), (22, -0.5, niche_z), (240, 201, 138), "SmoothPlastic"))
        for nm, x, w, zc, l in [("GrassLeft", -13.5, 3.4, z0 - LVL_LEN / 2, LVL_LEN), ("GrassRightA", 13.5, 3.4, z0 + seg1 / 2, -seg1),
                                ("GrassRightB", 13.5, 3.4, niche_z - niche_l / 2 - seg2 / 2, seg2), ("GrassNiche", 32.5, 3.4, niche_z, niche_l + 6),
                                ("GrassNicheA", 23, 16, niche_z + niche_l / 2 + 1.5, 3.4), ("GrassNicheB", 23, 16, niche_z - niche_l / 2 - 1.5, 3.4)]:
            st.add(grass_cap(nm, w, l, x, zc, 18))
        for k, zz in enumerate((z0 - 4, z0 - 36, z0 - 90)):
            st.add(part(f"BeamPostL{k}", (1.2, 16, 1.2), (-11.4, 8, zz), WOOD, "Wood"))
            st.add(part(f"BeamPostR{k}", (1.2, 16, 1.2), (11.4, 8, zz), WOOD, "Wood"))
            st.add(part(f"Beam{k}", (24, 1.4, 1.4), (0, 16, zz), (141, 90, 48), "Wood"))
        st.add(lantern("Lantern1", (-11.6, 10, z0 - 20)))
        st.add(lantern("Lantern2", (11.6, 10, z0 - 40), light=False))
        st.add(lantern("Lantern3", (-11.6, 10, z0 - 58), light=False))
        st.add(lantern("Lantern4", (11.6, 10, z0 - 82)))
        if lid == LVL_COUNT:
            st.add(wall_box("EndWall", 30, 18, 3, 0, z0 - LVL_LEN - 1.5))
        f.add(st)

        f.add(sign_part("Sign", (15, 5.4, 0.6), (0, 13.6, z0 - 4.8), rot(0, 180, 0), f"Уровень {lid} · {name}",
                        f"Сила: {RECOMMENDED[i]} · награда {REWARDS[i]} побед",
                        extra=[label("Progress", "Прогресс: 0 / 10", ((0.92, 0), (0.18, 0)), ((0.04, 0), (0.78, 0)),
                                     color=(150, 255, 190), stroke=3)]))
        wall = folder("Wall")
        for k in range(10):
            wall.add(part(f"Layer_{k + 1:02d}", (24, 18, 2), (0, 9, z0 - 12 - k * 2.3), color, mat))
        f.add(wall)
        f.add(part("Zone", (46, 26, LVL_LEN), (10, 12, z0 - LVL_LEN / 2), (255, 255, 255), "SmoothPlastic", transparency=1,
                   collide=False, query=False, touch=False, cast_shadow=False))
        word = "победа" if REWARDS[i] == 1 else "побед"
        for pad_name, dz, col, big in (("RewardPad", 6.5, GOLD, f"+{REWARDS[i]} {word}"),
                                       ("X3Pad", -6.5, (166, 91, 255), f"x3 = {REWARDS[i] * 3} побед")):
            f.add(part(pad_name, (9, 0.6, 9), (22, 0.3, niche_z + dz), col, "Neon", children=[
                billboard("PadGui", (220, 54), (0, 4.5, 0), [
                    frame("Bg", ((1, 0), (1, 0)), ((0, 0), (0, 0)), bg=(26, 16, 51), bgt=0.25, children=[
                        ui_corner(0, 16), ui_stroke(3, col),
                        label("Reward", big, ((1, -12), (1, -10)), ((0, 6), (0, 5)), color=(255, 225, 77), stroke=3)])])]))
        f.add(part("MerchantSpot", (1, 1, 1), (-8, 5, z0 - 80), (255, 255, 255), "SmoothPlastic", r=rot(0, 90, 0), transparency=1,
                   collide=False, query=False, touch=False, cast_shadow=False))
        levels.add(f)
    return levels


def build_ground():
    g = folder("Ground")
    top = -0.6
    def ground(name, x0, x1, z0, z1):
        g.add(part(name, (x1 - x0, 2, z1 - z0), ((x0 + x1) / 2, top - 1, (z0 + z1) / 2), GRASS, "Grass"))
    zmin = LVL0 - LVL_COUNT * LVL_LEN - 120
    ground("West", -700, XL - T, zmin, 300)
    ground("East", HW + T, 700, zmin, 300)
    ground("South", XL - T, HW + T, HD + T, 300)
    ground("North", XL - T, HW + T, zmin, -HD - T)
    deco = folder("Terraces")
    for k in range(34):
        side = k % 3
        w, h, d = 8 + rnd.randint(0, 2) * 4, 8 + rnd.randint(0, 4) * 4, 8 + rnd.randint(0, 2) * 4
        if side == 0:
            x, z = XL - 14 - rnd.random() * 40, rnd.uniform(zmin + 100, HD)
        elif side == 1:
            x, z = HW + 14 + rnd.random() * 40, rnd.uniform(zmin + 100, HD)
        else:
            x, z = rnd.uniform(XL, HW), HD + 14 + rnd.random() * 30
        b = model(f"Block_{k + 1}")
        b.add(part("Brick", (w, h, d), (x, top + h / 2, z), BRICK, "Brick"))
        b.add(part("Grass", (w + 0.4, 1.6, d + 0.4), (x, top + h + 0.8, z), GRASS, "Grass"))
        deco.add(b)
    g.add(deco)
    return g


def build_rare_merchant():
    return stall("RareMerchantTemplate", Frame3((0, -5, 0), rot(0, 0, 0)), "Продать руды ×2", "Редкий торговец", "покупает дороже!",
                 (166, 91, 255))


# ======================= ИНТЕРФЕЙС =======================
def fallback(text, size=((0.62, 0), (0.62, 0)), pos=((0.5, 0), (0.44, 0)), z=3):
    return label("Fallback", text, size, pos, anchor=(0.5, 0.5), stroke=0, z=z)


def left_button(name, text, emoji, color, order, label_size=19):
    """Большая плитка слева: картинка + подпись на нижнем краю (как на референсе)."""
    b = image_button(name, ((0, 104), (0, 104)), ((0, 0), (0, 0)), bg=color, bgt=0, order=order)
    b.add(ui_corner(0, 20), ui_stroke(4, DARK), ui_scale("Pulse"))
    b.add(image("Tile", "", ((1, 0), (1, 0)), ((0, 0), (0, 0)), visible=False, z=2))
    b.add(image("Symbol", "", ((0.78, 0), (0.78, 0)), ((0.5, 0), (0.42, 0)), anchor=(0.5, 0.5), visible=False, z=3))
    b.add(fallback(emoji, size=((0.62, 0), (0.62, 0)), pos=((0.5, 0), (0.4, 0))))
    b.add(label("Label", text, ((1.1, 0), (0, label_size + 6)), ((0.5, 0), (1, -2)), anchor=(0.5, 1), z=4, stroke=3))
    return b


def top_button(name, text, emoji, order):
    """Кнопка справа сверху: большой значок без фона + подпись снизу (как на референсе)."""
    b = image_button(name, ((0, 100), (0, 102)), ((0, 0), (0, 0)), bgt=1, order=order)
    b.add(image("Icon", "", ((0, 100), (0, 100)), ((0.5, 0), (0, 0)), anchor=(0.5, 0), visible=False, z=2))
    b.add(label("Fallback", emoji, ((0, 58), (0, 58)), ((0.5, 0), (0, 4)), anchor=(0.5, 0), stroke=0, z=2))
    b.add(label("Label", text, ((1.05, 0), (0, 19)), ((0.5, 0), (1, 0)), anchor=(0.5, 1), z=3, stroke=2.5))
    return b


SKINS = json.load(open(os.path.join(ROOT, "art", "ui_ref", "skins.json")))


def stat_card(name, emoji, title, color, order, skin):
    """Карточка показателя. Skin — картинка карточки (UI-скин из art/ui_ref); пока её ID не вставлен,
    видна простая цветная карточка. Число пишется в Value — на месте, где число на картинке."""
    meta = SKINS[skin]
    w = 200
    h = round(w / meta["ratio"])
    r = frame(name, ((0, w), (0, h)), ((0, 0), (0, 0)), bg=color, bgt=0, order=order)
    r.add(ui_corner(0, 14), ui_stroke(4, DARK))
    cv = meta["canvas"]  # загружен исходный файл с полями — растягиваем так, чтобы карточка совпала с рамкой
    r.add(image("Skin", "", ((cv["size"][0], 0), (cv["size"][1], 0)), ((cv["pos"][0], 0), (cv["pos"][1], 0)), visible=False,
                stretch=True, z=1))
    r.add(image("Icon", "", ((0, h - 16), (0, h - 16)), ((0, 8), (0.5, 0)), anchor=(0, 0.5), visible=False, z=2))
    r.add(label("Fallback", emoji, ((0, h - 20), (0, h - 20)), ((0, 10), (0.5, 0)), anchor=(0, 0.5), stroke=0, z=2))
    vx, vy, vw, vh = meta["value"]
    if "title" in meta:
        tx, ty, tw, th = meta["title"]
        r.add(label("Title", title, ((tw, 0), (th, 0)), ((tx, 0), (ty, 0)), stroke=2.5, z=3))
    else:  # перерождения: название над «таблеткой»
        r.add(label("Title", title, ((0.6, 0), (0.36, 0)), ((0.36, 0), (0.05, 0)), stroke=2.5, z=3))
    # заплатка цвета карточки — закрывает число, напечатанное на картинке
    vb = frame("ValueBg", ((vw, 0), (vh, 0)), ((vx, 0), (vy, 0)), bg=(255, 255, 255), bgt=0, visible=False, z=2)
    vb.add(ui_corner(0, 6), ui_gradient(tuple(meta["patchTop"]), tuple(meta["patchBottom"])))
    r.add(vb)
    r.add(label("Value", "0", ((vw, 0), (vh * 0.9, 0)), ((vx + vw / 2, 0), (vy + vh / 2, 0)), anchor=(0.5, 0.5), stroke=3, z=3))
    return r


def card_template(kind):
    """Карточка для списков: kind = 'grid' (плитка) или 'row' (строка)."""
    if kind == "grid":
        t = frame("Template", ((0, 180), (0, 196)), ((0, 0), (0, 0)), bg=(70, 48, 140), bgt=0, visible=False)
        t.add(ui_corner(0, 14), ui_stroke(3, DARK))
        t.add(image("Icon", "", ((0, 70), (0, 70)), ((0.5, 0), (0, 8)), anchor=(0.5, 0), visible=False))
        t.add(label("Fallback", "⛏", ((0, 64), (0, 64)), ((0.5, 0), (0, 10)), anchor=(0.5, 0), stroke=0))
        t.add(label("NameLabel", "Название", ((1, -12), (0, 26)), ((0, 6), (0, 82)), stroke=2.5))
        t.add(label("InfoLabel", "Описание", ((1, -12), (0, 36)), ((0, 6), (0, 110)), color=(255, 233, 168), font=FONT_BOLD, stroke=1.5))
        t.add(text_button("ActionButton", "Купить", ((1, -16), (0, 36)), ((0.5, 0), (1, -8)), (61, 200, 110), anchor=(0.5, 1)))
    else:
        t = frame("Template", ((1, -10), (0, 78)), ((0, 0), (0, 0)), bg=(70, 48, 140), bgt=0, visible=False)
        t.add(ui_corner(0, 14), ui_stroke(3, DARK))
        t.add(image("Icon", "", ((0, 58), (0, 58)), ((0, 10), (0.5, 0)), anchor=(0, 0.5), visible=False))
        t.add(label("Fallback", "🏆", ((0, 54), (0, 54)), ((0, 12), (0.5, 0)), anchor=(0, 0.5), stroke=0))
        t.add(label("NameLabel", "Название", ((1, -250), (0, 30)), ((0, 76), (0, 8)), xalign=0, stroke=2.5))
        t.add(label("InfoLabel", "Описание", ((1, -250), (0, 28)), ((0, 76), (0, 42)), xalign=0, color=(255, 233, 168),
                    font=FONT_BOLD, stroke=1.5))
        t.add(text_button("ActionButton", "Забрать", ((0, 150), (0, 46)), ((1, -12), (0.5, 0)), (61, 200, 110), anchor=(1, 0.5)))
    return t


def panel(name, title, layout="grid", content_top=64, content_bottom=16, children=None, template=None):
    p = frame(name, ((0, 660), (0, 450)), ((0.5, 0), (0.5, 0)), anchor=(0.5, 0.5), bg=(43, 26, 94), bgt=0, visible=False, z=10)
    p.add(ui_corner(0, 22), ui_stroke(5, DARK), ui_scale())
    p.add(label("Title", title, ((1, -130), (0, 44)), ((0, 22), (0, 10)), xalign=0, color=(255, 225, 77), stroke=4))
    p.add(text_button("CloseButton", "X", ((0, 46), (0, 46)), ((1, -12), (0, 10)), (230, 60, 60), anchor=(1, 0)))
    if layout:
        c = scrolling("Content", ((1, -28), (1, -(content_top + content_bottom))), ((0, 14), (0, content_top)))
        c.add(ui_padding(6))
        c.add(ui_grid((180, 196), (10, 10)) if layout == "grid" else ui_list(padding=8, halign=0))
        p.add(c)
        p.add(template or card_template("grid" if layout == "grid" else "row"))
    for ch in children or []:
        p.add(ch)
    return p


def build_gui():
    hud = screen_gui("MainHud")
    hud.add(ui_scale("Scale"))

    # ===== Слева: 4 большие плитки 2×2 (как на референсе) =====
    left = frame("LeftMenu", ((0, 216), (0, 216)), ((0, 12), (0.24, 0)))
    left.add(Inst("UIGridLayout", "UIGridLayout", [P("udim2", "CellSize", ((0, 104), (0, 104))),
                                                   P("udim2", "CellPadding", ((0, 8), (0, 8))), P("token", "SortOrder", 2)]))
    left.add(left_button("ShopButton", "Магазин", "🧺", (255, 196, 40), 1))
    left.add(left_button("PetsButton", "Питомцы", "🐾", (40, 150, 255), 2))
    left.add(left_button("AurasButton", "Ауры", "🔥", (140, 60, 230), 3))
    left.add(left_button("RebirthButton", "Перерождения", "🔄", (225, 230, 245), 4, label_size=13))
    hud.add(left)

    # ===== Слева снизу: цветные карточки показателей =====
    # размер: UIScale "Size" (Scale = 0.6) — поменяйте число, чтобы сделать крупнее/мельче
    stats = frame("Stats", ((0, 200), (0, 330)), ((0, 3), (1, -3)), anchor=(0, 1))
    stats.add(ui_list(padding=4, valign=2), ui_scale("Size", 0.7))
    stats.add(stat_card("WinsRow", "🏆", "Победы", (255, 196, 40), 1, "card_wins"))
    stats.add(stat_card("StrengthRow", "💪", "Сила", (235, 55, 55), 2, "card_strength"))
    stats.add(stat_card("LuckRow", "🍀", "Удача", (60, 200, 70), 3, "card_luck"))
    stats.add(stat_card("RebirthRow", "🔄", "Перерождения", (230, 70, 30), 4, "card_rebirth"))
    hud.add(stats)

    # ===== Справа сверху: Настройки, Задания, Колесо, Награды =====
    top = frame("TopRight", ((0, 420), (0, 104)), ((1, -6), (0, 2)), anchor=(1, 0))
    top.add(ui_list(horizontal=True, padding=0, halign=2, valign=1))
    top.add(top_button("SettingsButton", "Настройки", "⚙️", 1))
    top.add(top_button("QuestsButton", "Задания", "📜", 2))
    wheel = image_button("WheelButton", ((0, 100), (0, 102)), ((0, 0), (0, 0)), bgt=1, order=3)
    for nm, z in (("Base", 3), ("Disc", 4), ("Top", 5)):
        wheel.add(image(nm, "", ((0, 100), (0, 100)), ((0.5, 0), (0, 0)), anchor=(0.5, 0), visible=False, z=z))
    wheel.add(label("Fallback", "🎡", ((0, 58), (0, 58)), ((0.5, 0), (0, 4)), anchor=(0.5, 0), stroke=0, z=3))
    wheel.add(label("Label", "Колесо", ((1.05, 0), (0, 19)), ((0.5, 0), (1, 0)), anchor=(0.5, 1), z=6, stroke=2.5))
    top.add(wheel)
    rewards_btn = top_button("RewardsButton", "Награды", "🎁", 4)
    badge = frame("Badge", ((0, 24), (0, 24)), ((1, -2), (0, 0)), anchor=(1, 0), bg=(235, 40, 50), bgt=0, z=7, visible=False)
    badge.add(ui_corner(1, 0), ui_stroke(2.5, (255, 255, 255)), ui_scale("UIScale"),
              label("Text", "1", ((1, 0), (1, 0)), ((0, 0), (0, 0)), stroke=0, z=8))
    rewards_btn.add(badge)
    top.add(rewards_btn)
    hud.add(top)

    # ===== Снизу: большая «N Сила», «Мощный удар», полоса уровня и кнопки опыта =====
    # размер: UIScale "Size" (Scale = 0.6)
    power = frame("PowerPanel", ((0, 1030), (0, 306)), ((0.5, 0), (1, -8)), anchor=(0.5, 1))
    power.add(ui_scale("Size", 0.6))
    power.add(label("StrengthBig", "0 Сила", ((0.7, 0), (0, 86)), ((0.02, 0), (0, 0)), stroke=6, z=2))
    sw = 250
    strike = text_button("PowerStrikeButton", "", ((0, sw), (0, round(sw / SKINS["power_button"]["ratio"]))), ((1, 0), (0, -14)),
                         (255, 200, 40), anchor=(1, 0), stroke=0)
    strike.add(image("Icon", "", ((0, 64), (0, 64)), ((0, 4), (0.5, 0)), anchor=(0, 0.5), visible=False, z=3),
               label("Fallback", "🗡️", ((0, 60), (0, 60)), ((0, 6), (0.5, 0)), anchor=(0, 0.5), stroke=0, z=3),
               label("Text", "Мощный\nудар", ((1, -76), (1, -10)), ((0, 70), (0, 5)), stroke=3.5, z=3),
               image("Skin", "", ((SKINS["power_button"]["canvas"]["size"][0], 0), (SKINS["power_button"]["canvas"]["size"][1], 0)),
                     ((SKINS["power_button"]["canvas"]["pos"][0], 0), (SKINS["power_button"]["canvas"]["pos"][1], 0)),
                     visible=False, stretch=True, z=2))
    power.add(strike)
    # полоса уровня: Skin — пустая (тёмная) картинка, Fill/Skin — полная (жёлтая), обрезается по проценту
    lb = SKINS["levelbar"]
    bh = lb["barBottom"] - lb["barTop"]
    skin_size, skin_pos = ((1, 0), (1 / bh, 0)), ((0, 0), (-lb["barTop"] / bh, 0))
    lbar = frame("LevelBar", ((1, 0), (0, 110)), ((0, 0), (0, 90)), bg=(60, 60, 80), bgt=0, clip=False)
    lbar.add(ui_corner(0, 18), ui_stroke(5, DARK))
    lbar.add(image("Skin", "", skin_size, skin_pos, visible=False, stretch=True, z=1))
    lfill = frame("Fill", ((0.5, 0), (1, 0)), ((0, 0), (0, 0)), bg=(255, 196, 40), bgt=0, clip=True, z=2)
    lfill.add(ui_corner(0, 18))
    lfill.add(image("Skin", "", skin_size, skin_pos, visible=False, stretch=True, z=2))
    lbar.add(lfill)
    lbar.add(image("Icon", "", ((0, 84), (0, 84)), ((0, 4), (0.5, 0)), anchor=(0, 0.5), visible=False, z=3))
    lbar.add(label("Fallback", "🗡️", ((0, 76), (0, 76)), ((0, 8), (0.5, 0)), anchor=(0, 0.5), stroke=0, z=3))
    lbar.add(label("Level", "Уровень 1", ((0.5, 0), (0, 60)), ((0, 96), (0.5, 0)), anchor=(0, 0.5), xalign=0, stroke=5, z=3))
    lbar.add(label("Xp", "0 / 10", ((0.4, 0), (0, 52)), ((1, -16), (0.5, 0)), anchor=(1, 0.5), xalign=1, stroke=5, z=3))
    power.add(lbar)
    xpb = frame("XpButtons", ((1, 0), (0, 94)), ((0, 0), (0, 210)))
    xpb.add(ui_list(horizontal=True, padding=10, halign=0, valign=1))
    for k, (nm, col) in enumerate((("XpSmallButton", (255, 196, 40)), ("XpMediumButton", (150, 60, 235)), ("XpBigButton", (235, 55, 70)))):
        xpb.add(text_button(nm, "+0 очков опыта", ((0.32, 0), (1, 0)), ((0, 0), (0, 0)), col, order=k + 1, radius=16))
    power.add(xpb)
    hud.add(power)

    lvl = frame("LevelPanel", ((0, 480), (0, 92)), ((0.5, 0), (0, 4)), anchor=(0.5, 0), visible=False)
    lvl.add(label("Title", "Уровень 1 · Сено", ((1, 0), (0, 30)), ((0, 0), (0, 0)), stroke=3))
    lvl.add(label("Sub", "Рекомендуемая сила: 5", ((1, 0), (0, 20)), ((0, 0), (0, 30)), color=(255, 233, 168), stroke=2))
    bar = frame("Bar", ((1, -20), (0, 28)), ((0, 10), (0, 56)), bg=DARK, bgt=0.35)
    bar.add(ui_corner(0, 12), ui_stroke(3, DARK))
    fill = frame("Fill", ((0, 0), (1, 0)), ((0, 0), (0, 0)), bg=(255, 196, 61), bgt=0)
    fill.add(ui_corner(0, 12))
    bar.add(fill)
    bar.add(label("BarText", "Слой 1 / 10", ((1, 0), (1, -4)), ((0, 0), (0, 2)), stroke=2, z=3))
    lvl.add(bar)
    hud.add(lvl)

    # ===== Окно яйца: подходишь — видишь питомцев и шансы, зелёная кнопка открывает =====
    prev = frame("EggPreview", ((0, 720), (0, 250)), ((0.5, 0), (0.36, 0)), anchor=(0.5, 0.5), bg=(30, 18, 60), bgt=0.05,
                 visible=False, z=25)
    prev.add(ui_corner(0, 22), ui_stroke(5, (255, 140, 40)), ui_scale())
    ebox = frame("EggBox", ((0, 170), (1, -20)), ((0, 10), (0, 10)), bg=(255, 140, 40), bgt=0, z=26)
    ebox.add(ui_corner(0, 18), ui_stroke(3, DARK))
    ebox.add(label("Title", "Куриное\nЯйцо", ((1, -10), (0, 56)), ((0, 5), (0, 4)), stroke=3.5, z=27))
    ebox.add(label("EggIcon", "🥚", ((0, 96), (0, 96)), ((0.5, 0), (0, 60)), anchor=(0.5, 0), stroke=0, z=27))
    pbg = frame("PriceBg", ((1, -16), (0, 40)), ((0, 8), (1, -48)), bg=(26, 16, 51), bgt=0.15, z=27)
    pbg.add(ui_corner(0, 14), label("Price", "🏆 20 Побед", ((1, -8), (1, -6)), ((0, 4), (0, 3)), color=(255, 225, 77), stroke=2.5, z=28))
    ebox.add(pbg)
    prev.add(ebox)
    prev.add(label("Header", "Возможные питомцы", ((0, 360), (0, 34)), ((0, 300), (0, 8)), stroke=3, z=26))
    plist = frame("Pets", ((1, -200), (0, 140)), ((0, 192), (0, 46)), z=26)
    plist.add(ui_list(horizontal=True, padding=8, halign=1, valign=1))
    ptpl = frame("PetTemplate", ((0, 120), (0, 140)), ((0, 0), (0, 0)), bg=(60, 45, 100), bgt=0, visible=False, z=27)
    ptpl.add(ui_corner(0, 14), ui_stroke(3, (170, 175, 190)))
    ptpl.add(label("Emoji", "🐔", ((0, 58), (0, 58)), ((0.5, 0), (0, 4)), anchor=(0.5, 0), stroke=0, z=28))
    ptpl.add(label("PetName", "Курица", ((1, -6), (0, 22)), ((0, 3), (0, 62)), stroke=2, z=28))
    ptpl.add(label("Mult", "x1.2 Силы", ((1, -6), (0, 22)), ((0, 3), (0, 86)), color=(255, 225, 77), stroke=2, z=28))
    ptpl.add(label("Chance", "50%", ((1, -6), (0, 22)), ((0, 3), (0, 112)), stroke=2, z=28))
    plist.add(ptpl)
    prev.add(plist)
    prev.add(text_button("OpenButton", "Открыть", ((0, 250), (0, 48)), ((1, -14), (1, 22)), (60, 200, 80), anchor=(1, 0.5), z=27))
    hud.add(prev)

    # ===== Анимация открытия: лента с питомцами прокручивается и останавливается на выигрыше =====
    eo = frame("EggOpen", ((1, 0), (1, 0)), ((0, 0), (0, 0)), bg=(5, 0, 15), bgt=0.25, visible=False, z=40)
    eo.add(label("Title", "Открываем…", ((0, 600), (0, 50)), ((0.5, 0), (0.5, -170)), anchor=(0.5, 0.5), stroke=4, z=41))
    reel = frame("Reel", ((0, 760), (0, 210)), ((0.5, 0), (0.5, 0)), anchor=(0.5, 0.5), bg=(28, 16, 52), bgt=0, clip=True, z=41)
    reel.add(ui_corner(0, 26), ui_stroke(5, (120, 70, 220)))
    reel.add(frame("Strip", ((0, 4000), (1, 0)), ((0, 0), (0, 0)), z=42))
    ctpl = frame("CardTemplate", ((0, 150), (0, 180)), ((0, 0), (0.5, 0)), anchor=(0, 0.5), bg=(70, 60, 110), bgt=0, visible=False, z=43)
    ctpl.add(ui_corner(0, 18), ui_stroke(3, (20, 10, 40)))
    ctpl.add(frame("Spot", ((0.8, 0), (0.55, 0)), ((0.1, 0), (0, 0)), bg=(255, 255, 255), bgt=0.8, z=43))
    ctpl.add(label("Emoji", "🐔", ((0, 86), (0, 86)), ((0.5, 0), (0, 22)), anchor=(0.5, 0), stroke=0, z=44))
    ctpl.add(label("PetName", "Курица", ((1, -8), (0, 26)), ((0, 4), (0, 118)), stroke=2.5, z=44))
    ctpl.add(label("Mult", "x1.2", ((1, -8), (0, 22)), ((0, 4), (0, 148)), color=(255, 225, 77), stroke=2, z=44))
    reel.add(ctpl)
    reel.add(frame("Marker", ((0, 6), (1, 0)), ((0.5, 0), (0, 0)), anchor=(0.5, 0), bg=(255, 210, 60), bgt=0, z=46))
    eo.add(reel)
    win = frame("WinCard", ((0, 270), (0, 300)), ((0.5, 0), (0.5, 0)), anchor=(0.5, 0.5), bg=(255, 190, 40), bgt=0, visible=False, z=50)
    win.add(ui_corner(0, 26), ui_stroke(6, (255, 255, 255)), ui_scale())
    win.add(frame("Spot", ((0.8, 0), (0.6, 0)), ((0.1, 0), (0, 0)), bg=(255, 255, 255), bgt=0.7, z=50))
    win.add(label("Emoji", "🐔", ((0, 150), (0, 150)), ((0.5, 0), (0, 26)), anchor=(0.5, 0), stroke=0, z=51))
    win.add(label("PetName", "Курица", ((1, -10), (0, 40)), ((0, 5), (0, 182)), stroke=4, z=51))
    win.add(label("Rarity", "Обычный", ((1, -10), (0, 28)), ((0, 5), (0, 222)), stroke=3, z=51))
    win.add(label("Mult", "x1.2 Силы", ((1, -10), (0, 30)), ((0, 5), (0, 254)), color=(255, 225, 77), stroke=3, z=51))
    eo.add(win)
    hud.add(eo)

    # Слои на весь экран выключены в редакторе (иначе перехватывают клики в Studio), игра включает их сама
    hud.add(frame("Toasts", ((1, 0), (1, 0)), ((0, 0), (0, 0)), visible=False, z=20))

    panels = frame("Panels", ((1, 0), (1, 0)), ((0, 0), (0, 0)), visible=False, z=10)
    # Магазин с вкладками
    tabs = frame("Tabs", ((1, -28), (0, 40)), ((0, 14), (0, 60)))
    tabs.add(ui_list(horizontal=True, padding=8, halign=1))
    for i, (nm, txt) in enumerate((("LuckTab", "Удача"), ("DonateTab", "Донат"))):
        tabs.add(text_button(nm, txt, ((0, 150), (1, 0)), ((0, 0), (0, 0)), (90, 70, 160), order=i + 1))
    panels.add(panel("ShopPanel", "Магазин", "grid", content_top=106, children=[tabs]))
    # Питомцы
    pets_tpl = card_template("grid")
    pets_tpl.add(text_button("DeleteButton", "🗑", ((0, 30), (0, 30)), ((1, -4), (0, 4)), (200, 60, 60), anchor=(1, 0), stroke=0))
    panels.add(panel("PetsPanel", "Питомцы", "grid", content_top=104, template=pets_tpl, children=[
        label("Info", "Надето 0/3", ((1, -230), (0, 34)), ((0, 18), (0, 60)), xalign=0, font=FONT_BOLD, stroke=2),
        text_button("EquipBestButton", "Надеть лучших", ((0, 190), (0, 38)), ((1, -16), (0, 58)), (63, 140, 255), anchor=(1, 0))]))
    panels.add(panel("AurasPanel", "Ауры", "grid"))
    panels.add(panel("TraderPanel", "Торговец рудами", "row", content_bottom=110, children=[
        label("Total", "Выбрано: 0 🏆", ((1, -40), (0, 26)), ((0, 20), (1, -100)), color=(255, 225, 77), stroke=2),
        text_button("SelectAllButton", "Выделить все", ((0, 190), (0, 46)), ((0, 16), (1, -14)), (63, 140, 255), anchor=(0, 1)),
        text_button("SellSelectedButton", "Продать выбранное", ((0, 220), (0, 46)), ((0.5, 0), (1, -14)), (61, 200, 110), anchor=(0.5, 1)),
        text_button("SellAllButton", "Продать все", ((0, 190), (0, 46)), ((1, -16), (1, -14)), (255, 160, 40), anchor=(1, 1))]))
    # Перерождение
    panels.add(panel("RebirthPanel", "Перерождение", None, children=[
        label("Info", "Перерождений: 0", ((1, -40), (1, -160)), ((0, 20), (0, 66)), xalign=0, font=FONT_BOLD, stroke=2, scaled=True),
        text_button("RebirthButton", "Переродиться!", ((0, 320), (0, 58)), ((0.5, 0), (1, -18)), (166, 91, 255), anchor=(0.5, 1))]))
    # Колесо
    wheel_box = frame("Wheel", ((0, 280), (0, 280)), ((0.5, 0), (0, 58)), anchor=(0.5, 0))
    disc = frame("Disc", ((1, 0), (1, 0)), ((0, 0), (0, 0)), bg=(122, 60, 255), bgt=0)
    disc.add(ui_corner(1, 0), ui_stroke(6, DARK), image("DiscImage", "", ((1, 0), (1, 0)), ((0, 0), (0, 0))))
    wheel_box.add(disc)
    wheel_box.add(label("Pointer", "▼", ((0, 44), (0, 44)), ((0.5, 0), (0, 14)), anchor=(0.5, 1), color=(255, 225, 77), stroke=3, z=5))
    hub_dot = frame("Hub", ((0, 40), (0, 40)), ((0.5, 0), (0.5, 0)), anchor=(0.5, 0.5), bg=(255, 210, 63), bgt=0, z=5)
    hub_dot.add(ui_corner(1, 0), ui_stroke(4, DARK))
    wheel_box.add(hub_dot)
    panels.add(panel("WheelPanel", "Колесо Фортуны", None, children=[
        wheel_box,
        label("Timer", "Бесплатное вращение готово!", ((1, -40), (0, 26)), ((0, 20), (1, -96)), color=(255, 233, 168), stroke=2),
        text_button("SpinButton", "Крутить!", ((0, 230), (0, 50)), ((0.5, -8), (1, -14)), (255, 160, 40), anchor=(1, 1)),
        text_button("BuySpinButton", "Крутить за Robux", ((0, 230), (0, 50)), ((0.5, 8), (1, -14)), (166, 91, 255), anchor=(0, 1),
                    visible=False)]))
    # Награды
    rewards_tpl = frame("Template", ((0, 130), (0, 140)), ((0, 0), (0, 0)), bg=(70, 48, 140), bgt=0, visible=False)
    rewards_tpl.add(ui_corner(0, 14), ui_stroke(3, DARK),
                    label("Fallback", "🎁", ((0, 54), (0, 54)), ((0.5, 0), (0, 8)), anchor=(0.5, 0), stroke=0),
                    image("Icon", "", ((0, 54), (0, 54)), ((0.5, 0), (0, 8)), anchor=(0.5, 0), visible=False),
                    label("NameLabel", "День 1", ((1, -10), (0, 28)), ((0, 5), (0, 66)), stroke=2.5),
                    label("InfoLabel", "+2 побед", ((1, -10), (0, 28)), ((0, 5), (0, 98)), color=(255, 225, 77), stroke=2),
                    text_button("ActionButton", "", ((0, 0), (0, 0)), ((0, 0), (0, 0)), (61, 200, 110), visible=False))
    rewards = panel("RewardsPanel", "Ежедневные награды", None, children=[
        label("Info", "Награда готова!", ((1, -40), (0, 28)), ((0, 20), (1, -100)), color=(255, 233, 168), stroke=2),
        text_button("ClaimButton", "Забрать", ((0, 260), (0, 50)), ((0.5, 0), (1, -14)), (61, 200, 110), anchor=(0.5, 1))])
    rc = scrolling("Content", ((1, -28), (1, -170)), ((0, 14), (0, 62)))
    rc.add(ui_padding(6), Inst("UIGridLayout", "UIGridLayout", [P("udim2", "CellSize", ((0, 130), (0, 140))),
                                                               P("udim2", "CellPadding", ((0, 10), (0, 10))), P("token", "SortOrder", 2),
                                                               P("token", "HorizontalAlignment", 0)]))
    rewards.add(rc, rewards_tpl)
    panels.add(rewards)
    panels.add(panel("QuestsPanel", "Задания и достижения", "row", content_top=96, children=[
        label("Info", "Новые задания через 0:00", ((1, -40), (0, 28)), ((0, 20), (0, 60)), color=(255, 233, 168), xalign=0, stroke=2)]))
    panels.add(panel("AchievementsPanel", "Достижения", "row"))
    panels.add(panel("SettingsPanel", "Настройки", "row"))
    hud.add(panels)
    return hud


# ======================= СКРИПТЫ =======================
def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def modules_from(dirpath):
    out = []
    for fn in sorted(os.listdir(dirpath)):
        if fn.endswith(".luau"):
            out.append(script("ModuleScript", fn[:-5], read(os.path.join(dirpath, fn))))
    return out


# ---------- Иконки из IconConfig прямо в файл (видны в Studio и без Play) ----------
ICON_MAP = [  # (путь в MainHud, картинка, ключ IconConfig, что скрыть, убрать фон)
    ("LeftMenu.ShopButton", "Tile", "ShopTile", ["Fallback", "Label"], True),
    ("LeftMenu.PetsButton", "Tile", "PetsTile", ["Fallback", "Label"], True),
    ("LeftMenu.AurasButton", "Tile", "AurasTile", ["Fallback", "Label"], True),
    ("LeftMenu.RebirthButton", "Tile", "RebirthTile", ["Fallback", "Label"], True),
    ("TopRight.WheelButton", "Disc", "WheelDisc", ["Fallback", "Label"], False),
    ("TopRight.RewardsButton", "Icon", "Rewards", ["Fallback", "Label"], False),
    ("TopRight.QuestsButton", "Icon", "Quests", ["Fallback", "Label"], False),
    ("TopRight.SettingsButton", "Icon", "Settings", ["Fallback", "Label"], False),
    ("Stats.WinsRow", "Skin", "WinsCard", ["Icon", "Fallback", "Title"], True),
    ("Stats.StrengthRow", "Skin", "StrengthCard", ["Icon", "Fallback", "Title"], True),
    ("Stats.LuckRow", "Skin", "LuckCard", ["Icon", "Fallback", "Title"], True),
    ("Stats.RebirthRow", "Skin", "RebirthCard", ["Icon", "Fallback", "Title"], True),
    ("PowerPanel.PowerStrikeButton", "Skin", "PowerButton", ["Icon", "Fallback", "Text"], True),
    ("PowerPanel.LevelBar", "Skin", "LevelBarEmpty", ["Icon", "Fallback"], True),
    ("PowerPanel.LevelBar.Fill", "Skin", "LevelBarFull", [], True),
]


def icon_ids():
    import re
    src = read(os.path.join(SRC, "ReplicatedStorage", "Config", "IconConfig.luau"))
    src = re.sub(r"--\[\[.*?\]\]", "", src, flags=re.S)  # без комментариев
    src = re.sub(r"--[^\n]*", "", src)
    return {k: v for k, v in re.findall(r'(\w+) = "(rbxassetid://\d+)"', src) if not v.endswith("://0")}


def bake_icons(hud):
    ids = icon_ids()

    # Эмодзи-заглушки на кнопках убраны: кнопки пустые, картинки ставятся через IconConfig
    def clear_fallbacks(node):
        for c in node.children:
            if c.name == "Fallback" and c.cls == "TextLabel":
                c.props = [p for p in c.props if p.name != "Text"] + [P("string", "Text", "")]
            clear_fallbacks(c)
    clear_fallbacks(hud)

    def find(node, path):
        for name in path.split("."):
            node = next((c for c in node.children if c.name == name), None)
            if node is None:
                return None
        return node

    def setp(node, kind, name, value):
        node.props = [p for p in node.props if p.name != name] + [P(kind, name, value)]

    for path, child, key, hide, clear_bg in ICON_MAP:
        holder = find(hud, path)
        img = holder and find(holder, child)
        if not img or key not in ids:
            continue
        setp(img, "content", "Image", ids[key])
        setp(img, "bool", "Visible", True)
        for h in hide:
            show = h.startswith("+")
            o = find(holder, h.lstrip("+"))
            if o:
                setp(o, "bool", "Visible", show)
        if clear_bg:
            setp(holder, "float", "BackgroundTransparency", 1)
            holder.children = [c for c in holder.children if c.cls != "UIStroke"]


def build():
    rs = SRC + "/ReplicatedStorage"
    sss = SRC + "/ServerScriptService"
    sps = SRC + "/StarterPlayerScripts"

    workspace = Inst("Workspace", "Workspace")
    workspace.add(folder("Map", [build_hub(), build_levels(), build_ground()]))

    replicated = Inst("ReplicatedStorage", "ReplicatedStorage", [], [
        folder("Config", modules_from(rs + "/Config")),
        folder("Shared", modules_from(rs + "/Shared")),
        folder("PetModels"),
    ])
    server = Inst("ServerScriptService", "ServerScriptService", [], [
        script("Script", "Main", read(sss + "/Main.server.luau")),
        folder("Services", modules_from(sss + "/Services")),
    ])
    storage = Inst("ServerStorage", "ServerStorage", [], [folder("PickaxeModels"), build_rare_merchant()])
    client = script("LocalScript", "ClientMain", read(sps + "/ClientMain.client.luau"))
    client.add(folder("Controllers", modules_from(sps + "/Controllers")))
    starter_player = Inst("StarterPlayer", "StarterPlayer", [], [
        Inst("StarterPlayerScripts", "StarterPlayerScripts", [], [client]),
        Inst("StarterCharacterScripts", "StarterCharacterScripts"),
    ])
    hud = build_gui()
    bake_icons(hud)
    starter_gui = Inst("StarterGui", "StarterGui", [], [hud])
    # Освещение: яркий мультяшный день. Все значения можно менять в Studio: Explorer › Lighting.
    # Technology: 3 = ShadowMap (мягкие тени, быстро на телефонах); 4 = Future (красивее, тяжелее).
    lighting = Inst("Lighting", "Lighting", [
        P("token", "Technology", 3), P("float", "ClockTime", 14), P("float", "GeographicLatitude", 30),
        P("float", "Brightness", 2), P("float", "ExposureCompensation", -0.35),
        P("bool", "GlobalShadows", True), P("float", "ShadowSoftness", 0.35),
        P("float", "EnvironmentDiffuseScale", 1), P("float", "EnvironmentSpecularScale", 0.6),
        P("color3", "Ambient", (80, 80, 95)), P("color3", "OutdoorAmbient", (120, 125, 140)),
        P("color3", "ColorShift_Top", (255, 245, 225))], [
        Inst("Sky", "Sky", [P("float", "SunAngularSize", 18), P("float", "MoonAngularSize", 9), P("int", "StarCount", 0),
                            P("bool", "CelestialBodiesShown", True)]),
        Inst("Atmosphere", "Atmosphere", [P("float", "Density", 0.22), P("float", "Offset", 0.1), P("color3", "Color", (199, 226, 255)),
                                          P("color3", "Decay", (120, 170, 255)), P("float", "Glare", 0.15), P("float", "Haze", 0.4)]),
        Inst("BloomEffect", "Bloom", [P("float", "Intensity", 0.35), P("float", "Size", 22), P("float", "Threshold", 1.8)]),
        Inst("ColorCorrectionEffect", "ColorCorrection", [P("float", "Saturation", 0.2), P("float", "Contrast", 0.12),
                                                          P("float", "Brightness", -0.04), P("color3", "TintColor", (245, 242, 238))]),
        Inst("SunRaysEffect", "SunRays", [P("float", "Intensity", 0.04), P("float", "Spread", 0.6)]),
    ])
    write_place(OUT, [workspace, lighting, replicated, server, storage, starter_player, starter_gui])
    print("Готово:", OUT, f"({os.path.getsize(OUT) // 1024} КБ)")


if __name__ == "__main__":
    build()
