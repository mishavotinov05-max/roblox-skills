"""
Сборка файла места WallBreaker.rbxlx: карта (настоящие детали), интерфейс и все скрипты.
Запуск:  python3 tools/build_place.py
Результат: games/wall-breaker/WallBreaker.rbxlx — открыть двойным щелчком в Roblox Studio.
"""
import os
import random
from rbxlx import (Inst, P, Frame3, rot, part, model, folder, point_light, prompt, script, frame, label, text_button,
                   image, image_button, ui_corner, ui_stroke, ui_padding, ui_scale, ui_list, ui_grid, scrolling,
                   surface_gui, billboard, screen_gui, write_place, FONT_BOLD)

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SRC = os.path.join(ROOT, "src")
OUT = os.path.join(ROOT, "WallBreaker.rbxlx")

# ---------- Размеры лобби ----------
HW, XL, HD = 64, -58, 64       # восточная стена x=HW, западная x=XL, север/юг z=∓HD
WALLH, T = 24, 4
LVL_LEN, LVL_COUNT = 72, 10
LVL0 = -HD - T                  # начало первого уровня (сразу за северной стеной)

DARK = (26, 16, 51)
BRICK = (201, 101, 47)
GRASS = (76, 203, 58)
FLOOR = (150, 135, 225)
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
    pit_cols = [-36]
    pit_rows = [-55, -33, -11, 11, 33, 55]
    hole = 6.5
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
            floor_f.add(part(f"Floor_{i}_{j}", (x1 - x0, 1, z1 - z0), ((x0 + x1) / 2, -0.5, (z0 + z1) / 2), FLOOR, "Slate"))
    hub.add(floor_f)

    # --- Стены ---
    walls = folder("Walls")
    gap = 9
    walls.add(wall_box("WallSouth", HW - XL + 2 * T, WALLH, T, (XL + HW) / 2, HD + T / 2))
    walls.add(wall_box("WallWest", T, WALLH, 2 * HD, XL - T / 2, 0))
    walls.add(wall_box("WallEast", T, WALLH, 2 * HD, HW + T / 2, 0))
    walls.add(wall_box("WallNorthLeft", -gap - XL + T, WALLH, T, (XL - T - gap) / 2, -HD - T / 2))
    walls.add(wall_box("WallNorthRight", HW - gap + T, WALLH, T, (gap + HW + T) / 2, -HD - T / 2))
    walls.add(wall_box("WallNorthTop", 2 * gap, WALLH - 19, T, 0, -HD - T / 2, y0=19))
    walls.add(grass_cap("GrassSouth", HW - XL + 2 * T + 0.4, T + 0.4, (XL + HW) / 2, HD + T / 2, WALLH))
    walls.add(grass_cap("GrassNorth", HW - XL + 2 * T + 0.4, T + 0.4, (XL + HW) / 2, -HD - T / 2, WALLH))
    walls.add(grass_cap("GrassWest", T + 0.4, 2 * HD, XL - T / 2, 0, WALLH))
    walls.add(grass_cap("GrassEast", T + 0.4, 2 * HD, HW + T / 2, 0, WALLH))
    hub.add(walls)

    # --- Декор: светящиеся линии прохода и фонари ---
    decor = folder("Decor")
    for x in (-7, 7):
        decor.add(part(f"AisleLine_{'L' if x < 0 else 'R'}", (0.5, 0.1, 2 * HD - 14), (x, 0.05, -5), (192, 107, 255), "Neon",
                       collide=False, cast_shadow=False))
    decor.add(part("PitZoneLine", (0.5, 0.1, 2 * HD - 10), (-20.5, 0.05, 0), (198, 107, 255), "Neon", collide=False, cast_shadow=False))
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
    for k, z in enumerate((-44, -22, 0, 22, 44)):
        decor.add(part(f"Path_{k + 1}", (-20.5 - XL, 0.12, 5), ((XL - 20.5) / 2, 0.06, z), (225, 200, 160), "Cobblestone"))
    decor.add(part("PathWest", (8, 0.12, 2 * HD - 2), (XL + 4, 0.06, 0), (225, 200, 160), "Cobblestone"))
    hub.add(decor)

    # --- Точка появления ---
    hub.add(Inst("SpawnLocation", "SpawnLocation", part("x", (8, 1, 8), (0, 0.5, 40), (122, 60, 255), "Neon").props
                 + [P("int", "Duration", 0), P("bool", "Neutral", True)]))

    hub.add(build_entrance())
    hub.add(build_pickaxe_shop())
    hub.add(build_pits(pit_cols, pit_rows, hole))
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


PICKAXES = [  # (цвет головки, цвет рукояти, неон) — как в PickaxeConfig
    ((217, 160, 102), (107, 63, 29), False), ((195, 200, 210), (168, 106, 60), False), ((255, 178, 122), (168, 106, 60), False),
    ((241, 244, 250), (168, 106, 60), False), ((255, 216, 77), (168, 106, 60), False), ((109, 255, 168), (168, 106, 60), True),
    ((255, 122, 140), (168, 106, 60), True), ((159, 248, 255), (168, 106, 60), True), ((138, 92, 255), (59, 42, 85), True),
    ((106, 80, 84), (59, 42, 46), False), ((255, 176, 240), (138, 92, 255), True), ((255, 225, 77), (94, 231, 255), True),
]
PICK_NAMES = ["Деревянная", "Каменная", "Медная", "Железная", "Золотая", "Изумрудная", "Рубиновая", "Алмазная",
              "Обсидиановая", "Незеритовая", "Кристальная", "Радужная"]
PICK_PRICES = ["Бесплатно", "5", "15", "40", "100", "250", "600", "1.5K", "4K", "10K", "25K", "60K"]


def display_pickaxe(x, y, z, head, handle, neon):
    m = model("Display")
    m.add(part("Handle", (0.5, 5, 0.5), (x, y + 2.5, z), handle, "Wood", collide=False))
    m.add(part("Head", (0.7, 0.7, 3.6), (x, y + 4.8, z), head, "Neon" if neon else "Metal", collide=False))
    for s in (-1, 1):
        m.add(part(f"Tip{'A' if s < 0 else 'B'}", (0.55, 0.55, 1.4), (x, y + 4.35, z + s * 2.2), head, "Neon" if neon else "Metal",
                   r=rot(s * 35, 0, 0), collide=False))
    return m


def build_pickaxe_shop():
    shop = model("PickaxeShop")
    SHOP_Z, ROW_D, STEP = 30, 8, 3
    row_x = [HW - 3 * ROW_D, HW - 2 * ROW_D, HW - ROW_D]
    row_col = [(255, 225, 77), (94, 231, 255), (255, 95, 210)]
    steps = folder("Steps")
    steps.add(part("Row1", (ROW_D, 0.4, 2 * SHOP_Z), (row_x[0] + ROW_D / 2, 0.2, 0), FLOOR, "Slate"))
    steps.add(part("Row2", (HW - row_x[1], STEP, 2 * SHOP_Z), ((row_x[1] + HW) / 2, STEP / 2, 0), STONE, "Cobblestone"))
    steps.add(part("Row3", (HW - row_x[2], 2 * STEP, 2 * SHOP_Z), ((row_x[2] + HW) / 2, STEP, 0), STONE, "Cobblestone"))
    steps.add(part("Stair1", (3, STEP / 2, 5), (row_x[1] - 1.5, STEP / 4, 0), STONE, "Cobblestone"))
    steps.add(part("Stair2", (3, STEP * 1.5, 5), (row_x[2] - 1.5, STEP * 0.75, 0), STONE, "Cobblestone"))
    for r, x in enumerate(row_x):
        steps.add(part(f"Edge{r + 1}", (0.35, 0.35, 2 * SHOP_Z), (x + 0.2, r * STEP + 0.6, 0), row_col[r], "Neon",
                       collide=False, cast_shadow=False))
    shop.add(steps)
    shop.add(part("BackWall", (1.2, 18, 2 * SHOP_Z + 4), (HW - 0.6, 2 * STEP + 9, 0), WOOD, "WoodPlanks"))
    shop.add(sign_part("Sign", (22, 5, 0.6), (HW - 1.4, 21.5, 0), rot(0, 90, 0), "Магазин кирок", "3 ряда · подойди и купи"))

    slots = folder("Slots")
    slot_z = [-22, -9, 9, 22]
    idx = 0
    for r, x0 in enumerate(row_x):
        y = r * STEP + (0.4 if r == 0 else 0)
        for z in slot_z:
            head, handle, neon = PICKAXES[idx]
            s = model(f"Slot_{idx + 1:02d}")
            px = x0 + ROW_D - 2
            ped = part("Pedestal", (2.6, 2.2, 2.6), (px, y + 1.1, z), STONE, "Cobblestone")
            ped.add(billboard("NameGui", (200, 40), (0, 9.2, 0), [
                label("PickName", PICK_NAMES[idx], ((1, 0), (1, 0)), ((0, 0), (0, 0)), stroke=3)]))
            s.add(ped)
            s.add(part("Glow", (2.8, 0.25, 2.8), (px, y + 2.3, z), row_col[r], "Neon", collide=False, cast_shadow=False))
            s.add(display_pickaxe(px, y + 2.4, z, head, handle, neon))
            pad = part("BuyPad", (4, 0.3, 4), (x0 + 2.6, y + 0.15, z), (42, 23, 87), "SmoothPlastic",
                       children=[prompt("Купить", PICK_NAMES[idx]),
                                 billboard("PriceGui", (160, 50), (0, 2.6, 0), [
                                     frame("Bg", ((1, 0), (1, 0)), ((0, 0), (0, 0)), bg=(42, 23, 87), bgt=0.15,
                                           children=[ui_corner(0, 14), ui_stroke(3, row_col[r]),
                                                     label("Icon", "🏆", ((0, 40), (1, 0)), ((0, 4), (0, 0)), stroke=0),
                                                     label("Price", PICK_PRICES[idx], ((1, -50), (1, -8)), ((0, 46), (0, 4)),
                                                           color=(255, 225, 77), stroke=2.5)])])])
            s.add(pad)
            s.add(part("PadFrame", (4.4, 0.2, 4.4), (x0 + 2.6, y + 0.05, z), row_col[r], "Neon", collide=False, cast_shadow=False))
            slots.add(s)
            idx += 1
    shop.add(slots)
    return shop


PIT_LOOK = [  # материал и цвет ямы, цвет бортика — как в превью
    ("Землянка", "Pebble", (122, 82, 51), (176, 122, 69)),
    ("Угольная", "Slate", (50, 52, 60), (80, 84, 95)),
    ("Каменная", "Cobblestone", (160, 165, 175), (195, 201, 212)),
    ("Железная", "DiamondPlate", (215, 220, 230), (243, 230, 216)),
    ("Золотая", "Foil", (255, 200, 40), (255, 199, 46)),
    ("Алмазная", "Ice", (95, 227, 240), (94, 231, 255)),
]
PIT_SUBS = ["открыта · +1 силы", "🔒 2 перерождения", "🔒 5 перерождений", "🔒 10 перерождений", "🔒 20 перерождений", "🔒 40 перерождений"]


def build_pits(cols, rows, hole):
    pits = folder("Pits")
    depth = 5
    walk_x = -51
    idx = 0
    for c in cols:
        for zc in rows:
            idx += 1
            if idx <= len(PIT_LOOK):
                name, mat, color, rim = PIT_LOOK[idx - 1]
                sub = PIT_SUBS[idx - 1]
                bg = (122, 60, 255) if idx == 1 else (74, 79, 102)
            else:
                name, mat, color, rim, sub, bg = "Новая яма", "Concrete", (90, 90, 110), (85, 90, 112), "свободное место", (47, 52, 72)
            m = model(f"Pit_{idx:02d}")
            m.add(part("PitFloor", (2 * hole, 1, 2 * hole), (c, -depth - 0.5, zc), color, mat))
            for side, (dx, dz, sx, sz) in {"N": (0, -hole - 0.5, 2 * hole + 2, 1), "S": (0, hole + 0.5, 2 * hole + 2, 1),
                                           "W": (-hole - 0.5, 0, 1, 2 * hole), "E": (hole + 0.5, 0, 1, 2 * hole)}.items():
                m.add(part(f"Wall{side}", (sx, depth, sz), (c + dx, -depth / 2, zc + dz), color, mat))
            for side, (dx, dz, sx, sz) in {"N": (0, -hole, 2 * hole, 0.6), "S": (0, hole, 2 * hole, 0.6),
                                           "W": (-hole, 0, 0.6, 2 * hole), "E": (hole, 0, 0.6, 2 * hole)}.items():
                m.add(part(f"Rim{side}", (sx, 0.3, sz), (c + dx, 0.15, zc + dz), rim, "Neon", collide=False, cast_shadow=False))
            # забор: вход со стороны дорожки между рядами
            fence = folder("Fence")
            fr = 8
            open_side = "W"
            posts = []
            for k in range(-2, 3):
                v = k * fr / 2
                posts += [("N", v, -fr), ("S", v, fr), ("W", -fr, v), ("E", fr, v)]
            seen = set()
            for side, a, b in posts:
                px, pz = a, b
                if side == open_side and abs(b) < 0.1:
                    continue
                key = (round(px, 2), round(pz, 2))
                if key in seen:
                    continue
                seen.add(key)
                fence.add(part("Post", (0.6, 3.2, 0.6), (c + px, 1.6, zc + pz), (154, 98, 53), "WoodPlanks"))
            for side in "NSWE":
                for y in (1.3, 2.7):
                    if side in "NS":
                        fence.add(part("Rail", (2 * fr, 0.3, 0.3), (c, y, zc + (-fr if side == "N" else fr)), (181, 122, 69), "WoodPlanks"))
                    elif side == open_side:
                        for s in (-1, 1):
                            fence.add(part("Rail", (0.3, 0.3, fr / 2), (c + (-fr if side == "W" else fr), y, zc + s * (fr * 0.75)),
                                           (181, 122, 69), "WoodPlanks"))
                    else:
                        fence.add(part("Rail", (0.3, 0.3, 2 * fr), (c + (-fr if side == "W" else fr), y, zc), (181, 122, 69), "WoodPlanks"))
            m.add(fence)
            # табличка с дальней стороны ямы, смотрит на главный проход (+X)
            sx = c - fr - 1.4
            m.add(part("SignPostA", (0.5, 5, 0.5), (sx - 0.4, 2.5, zc - 2.5), WOOD, "Wood"))
            m.add(part("SignPostB", (0.5, 5, 0.5), (sx - 0.4, 2.5, zc + 2.5), WOOD, "Wood"))
            m.add(sign_part("Sign", (10, 3.6, 0.4), (sx, 6.8, zc), rot(0, -90, 0), name, sub, bg=bg, border=rim))
            m.add(part("TrainZone", (2 * hole, 8, 2 * hole), (c, -1, zc), (255, 255, 255), "SmoothPlastic", transparency=1,
                       collide=False, query=False, touch=False, cast_shadow=False))
            m.add(part("LockBarrier", (2 * hole, 0.6, 2 * hole), (c, 0.3, zc), rim, "ForceField", transparency=0.2))
            pits.add(m)
    return pits


EGGS = [("common", -13, (242, 248, 255), (90, 180, 255), "Обычное яйцо", "10"),
        ("rare", 0, (255, 200, 60), (255, 174, 0), "Редкое яйцо", "75"),
        ("epic", 13, (200, 120, 255), (198, 107, 255), "Эпическое яйцо", "400")]


def build_eggs():
    eggs = folder("Eggs")
    z = HD - 9
    for egg_id, x, color, ring, title, price in EGGS:
        m = model(f"Egg_{egg_id}")
        ped = part("Pedestal", (2.2, 7, 7), (x, 1.1, z), STONE, "Cobblestone", shape="Cylinder", r=rot(0, 0, 90),
                   children=[prompt("Открыть", title)])
        m.add(ped)
        m.add(part("Ring", (0.3, 7.4, 7.4), (x, 2.3, z), ring, "Neon", shape="Cylinder", r=rot(0, 0, 90), collide=False,
                   cast_shadow=False))
        egg = part("Egg", (4, 4, 4), (x, 5.4, z), color, "SmoothPlastic", shape="Ball", children=[
            Inst("SpecialMesh", "Mesh", [P("token", "MeshType", 3), P("vec3", "Scale", (1, 1.3, 1))]),
            billboard("InfoGui", (220, 90), (0, 4.6, 0), [
                label("Title", title, ((1, 0), (0.55, 0)), ((0, 0), (0, 0)), stroke=3),
                frame("PriceBg", ((0.7, 0), (0.42, 0)), ((0.15, 0), (0.58, 0)), bg=(26, 16, 51), bgt=0.2, children=[
                    ui_corner(1, 0),
                    label("Icon", "🏆", ((0.3, 0), (1, 0)), ((0.02, 0), (0, 0)), stroke=0),
                    label("Price", price, ((0.62, 0), (0.9, 0)), ((0.34, 0), (0.05, 0)), color=(255, 225, 77), stroke=2)])])])
        m.add(egg)
        eggs.add(m)
    eggs.add(sign_part("Sign", (16, 5, 0.6), (0, 15.5, HD - 1.6), rot(0, 0, 0), "ЯЙЦА", "питомцы усиливают силу"))
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
        st.add(part("Floor", (24, 1, LVL_LEN), (0, -0.5, z0 - LVL_LEN / 2), (90, 79, 134), "Slate"))
        for x in (-10.5, 10.5):
            st.add(part(f"Line{'L' if x < 0 else 'R'}", (0.4, 0.1, LVL_LEN), (x, 0.05, z0 - LVL_LEN / 2), (255, 158, 31), "Neon",
                        collide=False, cast_shadow=False))
        niche_z, niche_l = z0 - 50, 16
        seg1 = niche_z + niche_l / 2 - z0          # отрицательная длина до ниши
        seg2 = LVL_LEN + seg1 - niche_l
        st.add(wall_box("WallLeft", 3, 18, LVL_LEN, -13.5, z0 - LVL_LEN / 2))
        st.add(wall_box("WallRightA", 3, 18, -seg1, 13.5, z0 + seg1 / 2))
        st.add(wall_box("WallRightB", 3, 18, seg2, 13.5, niche_z - niche_l / 2 - seg2 / 2))
        st.add(wall_box("NicheSideA", 10, 18, 3, 20, niche_z + niche_l / 2 + 1.5))
        st.add(wall_box("NicheSideB", 10, 18, 3, 20, niche_z - niche_l / 2 - 1.5))
        st.add(wall_box("NicheBack", 3, 18, niche_l + 6, 26.5, niche_z))
        st.add(part("NicheFloor", (12, 1, niche_l), (19, -0.5, niche_z), (90, 79, 134), "Slate"))
        for nm, x, w, zc, l in [("GrassLeft", -13.5, 3.4, z0 - LVL_LEN / 2, LVL_LEN), ("GrassRightA", 13.5, 3.4, z0 + seg1 / 2, -seg1),
                                ("GrassRightB", 13.5, 3.4, niche_z - niche_l / 2 - seg2 / 2, seg2), ("GrassNiche", 26.5, 3.4, niche_z, niche_l + 6),
                                ("GrassNicheA", 20, 10, niche_z + niche_l / 2 + 1.5, 3.4), ("GrassNicheB", 20, 10, niche_z - niche_l / 2 - 1.5, 3.4)]:
            st.add(grass_cap(nm, w, l, x, zc, 18))
        for k, zz in enumerate((z0 - 4, z0 - 36, z0 - 66)):
            st.add(part(f"BeamPostL{k}", (1.2, 16, 1.2), (-11.4, 8, zz), WOOD, "Wood"))
            st.add(part(f"BeamPostR{k}", (1.2, 16, 1.2), (11.4, 8, zz), WOOD, "Wood"))
            st.add(part(f"Beam{k}", (24, 1.4, 1.4), (0, 16, zz), (141, 90, 48), "Wood"))
        st.add(lantern("Lantern1", (-11.6, 10, z0 - 20)))
        st.add(lantern("Lantern2", (11.6, 10, z0 - 40), light=False))
        st.add(lantern("Lantern3", (-11.6, 10, z0 - 58), light=False))
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
        f.add(part("Zone", (40, 26, LVL_LEN), (8, 12, z0 - LVL_LEN / 2), (255, 255, 255), "SmoothPlastic", transparency=1,
                   collide=False, query=False, touch=False, cast_shadow=False))
        f.add(part("MerchantSpot", (1, 1, 1), (19, 5, niche_z), (255, 255, 255), "SmoothPlastic", r=rot(0, -90, 0), transparency=1,
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


def left_button(name, text, emoji, color, order, label_size=13):
    b = image_button(name, ((0, 62), (0, 62)), ((0, 0), (0, 0)), bg=color, bgt=0, order=order)
    b.add(ui_corner(0, 14), ui_stroke(3, DARK), ui_scale("Pulse"))
    b.add(image("Tile", "", ((1, 0), (1, 0)), ((0, 0), (0, 0)), visible=False, z=2))
    b.add(image("Symbol", "", ((0.8, 0), (0.8, 0)), ((0.5, 0), (0.46, 0)), anchor=(0.5, 0.5), visible=False, z=3))
    b.add(fallback(emoji, size=((0.6, 0), (0.6, 0)), pos=((0.5, 0), (0.42, 0))))
    b.add(label("Label", text, ((1.25, 0), (0, label_size + 2)), ((0.5, 0), (1, 5)), anchor=(0.5, 1), z=4, stroke=2))
    return b


def small_button(name, text, emoji, order):
    b = image_button(name, ((0, 54), (0, 62)), ((0, 0), (0, 0)), bgt=1, order=order)
    b.add(image("Icon", "", ((0, 42), (0, 42)), ((0.5, 0), (0, 0)), anchor=(0.5, 0), visible=False, z=2))
    b.add(label("Fallback", emoji, ((0, 36), (0, 36)), ((0.5, 0), (0, 3)), anchor=(0.5, 0), stroke=0, z=2))
    b.add(label("Label", text, ((1.3, 0), (0, 14)), ((0.5, 0), (1, 0)), anchor=(0.5, 1), z=3, stroke=1.5))
    return b


def stat_row(name, emoji, text, order):
    r = frame(name, ((0, 190), (0, 24)), ((0, 0), (0, 0)), order=order)
    r.add(image("Icon", "", ((0, 24), (0, 24)), ((0, 0), (0, 0)), visible=False, z=2))
    r.add(label("Fallback", emoji, ((0, 22), (0, 22)), ((0, 1), (0, 1)), stroke=0))
    r.add(label("Value", text, ((1, -30), (0, 18)), ((0, 30), (0, 3)), xalign=0, stroke=2))
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

    left = frame("LeftMenu", ((0, 140), (0, 150)), ((0, 6), (0, 56)))
    left.add(Inst("UIGridLayout", "UIGridLayout", [P("udim2", "CellSize", ((0, 62), (0, 62))),
                                                   P("udim2", "CellPadding", ((0, 8), (0, 14))), P("token", "SortOrder", 2)]))
    left.add(left_button("ShopButton", "Магазин", "🏪", (255, 106, 82), 1))
    left.add(left_button("PetsButton", "Питомцы", "🐾", (69, 170, 255), 2))
    left.add(left_button("AurasButton", "Ауры", "🔥", (111, 52, 220), 3))
    left.add(left_button("RebirthButton", "Перерождение", "🔄", (240, 244, 250), 4, label_size=10))
    hud.add(left)

    stats = frame("Stats", ((0, 190), (0, 84)), ((0, 4), (0, 214)))
    stats.add(ui_list(padding=3))
    stats.add(stat_row("StrengthRow", "⛏", "Сила: 0", 1))
    stats.add(stat_row("LuckRow", "🍀", "Удача: 0%", 2))
    stats.add(stat_row("WinsRow", "🏆", "Победы: 0", 3))
    hud.add(stats)

    # Правый верхний угол: колесо + 4 кнопки одного размера
    top = frame("TopRight", ((0, 300), (0, 66)), ((1, -6), (0, 4)), anchor=(1, 0))
    top.add(ui_list(horizontal=True, padding=2, halign=2, valign=1))
    wheel = image_button("WheelButton", ((0, 54), (0, 62)), ((0, 0), (0, 0)), bgt=1, order=0)
    for nm, z in (("Base", 3), ("Disc", 4), ("Top", 5)):
        wheel.add(image(nm, "", ((0, 42), (0, 42)), ((0.5, 0), (0, 0)), anchor=(0.5, 0), visible=False, z=z))
    fb = label("Fallback", "🎡", ((0, 40), (0, 40)), ((0.5, 0), (0, 1)), anchor=(0.5, 0), bg=(122, 60, 255), bgt=0, stroke=0, z=3)
    fb.add(ui_corner(1, 0), ui_stroke(2, DARK, mode=1))
    wheel.add(fb)
    badge = frame("Badge", ((0, 16), (0, 16)), ((1, -2), (0, -2)), anchor=(1, 0), bg=(255, 43, 58), bgt=0, z=6)
    badge.add(ui_corner(1, 0), ui_stroke(2, (255, 255, 255)), ui_scale("UIScale"),
              label("Text", "!", ((1, 0), (1, 0)), ((0, 0), (0, 0)), stroke=0, z=7))
    wheel.add(badge)
    wheel.add(label("Label", "Колесо", ((1.3, 0), (0, 14)), ((0.5, 0), (1, 0)), anchor=(0.5, 1), z=3, stroke=1.5))
    top.add(wheel)
    top.add(small_button("AchievementsButton", "Достижения", "🏆", 1))
    top.add(small_button("RewardsButton", "Награды", "🎁", 2))
    top.add(small_button("QuestsButton", "Задания", "📅", 3))
    top.add(small_button("SettingsButton", "Настройки", "⚙️", 4))
    hud.add(top)

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
    lvl.add(text_button("CashOutButton", "Забрать награду и в лобби", ((0, 280), (0, 32)), ((0.5, 0), (0, 92)), (61, 200, 110),
                        anchor=(0.5, 0), visible=False))
    hud.add(lvl)

    # Окно выбора награды после стены
    choice = frame("LevelChoice", ((0, 480), (0, 310)), ((0.5, 0), (0.5, 0)), anchor=(0.5, 0.5), bg=(43, 26, 94), bgt=0, visible=False, z=30)
    choice.add(ui_corner(0, 22), ui_stroke(5, (255, 225, 77)), ui_scale())
    choice.add(label("Title", "Уровень пройден!", ((1, -30), (0, 40)), ((0, 15), (0, 12)), color=(255, 225, 77), stroke=3, z=31))
    choice.add(label("Info", "Награда: 1 победа", ((1, -40), (0, 56)), ((0, 20), (0, 56)), font=FONT_BOLD, stroke=2, z=31))
    choice.add(text_button("FreeButton", "+1 🏆 и в лобби", ((1, -60), (0, 50)), ((0.5, 0), (0, 124)), (61, 200, 110), anchor=(0.5, 0), z=31))
    choice.add(text_button("X3Button", "×3 = 3 🏆 и в лобби (Robux)", ((1, -60), (0, 50)), ((0.5, 0), (0, 184)), (166, 91, 255),
                           anchor=(0.5, 0), z=31))
    choice.add(text_button("ContinueButton", "Идти дальше →", ((0, 240), (0, 40)), ((0.5, 0), (0, 250)), (63, 140, 255),
                           anchor=(0.5, 0), z=31))
    hud.add(choice)

    # Анимация открытия яйца
    egg_open = frame("EggOpen", ((1, 0), (1, 0)), ((0, 0), (0, 0)), bg=(0, 0, 0), bgt=0.35, visible=False, z=40)
    rays = frame("Rays", ((0, 520), (0, 520)), ((0.5, 0), (0.5, 0)), anchor=(0.5, 0.5), visible=False, z=41)
    for k in range(8):
        rays.add(frame(f"Ray{k + 1}", ((0, 34), (1, 0)), ((0.5, 0), (0.5, 0)), anchor=(0.5, 0.5), bg=(255, 225, 77), bgt=0.6,
                       rotation=k * 22.5, z=41))
    egg_open.add(rays)
    egg = frame("Egg", ((0, 150), (0, 190)), ((0.5, 0), (0.5, 0)), anchor=(0.5, 0.5), bg=(242, 248, 255), bgt=0, z=42)
    egg.add(ui_corner(0.5, 0), ui_stroke(6, DARK), ui_scale())
    for k, (x, y, d) in enumerate(((0.3, 0.35, 26), (0.62, 0.55, 32), (0.35, 0.72, 22))):
        spot = frame(f"Spot{k + 1}", ((0, d), (0, d)), ((x, 0), (y, 0)), anchor=(0.5, 0.5), bg=(26, 16, 51), bgt=0.75, z=43)
        spot.add(ui_corner(1, 0))
        egg.add(spot)
    shine = frame("Shine", ((0, 24), (0, 44)), ((0.3, 0), (0.2, 0)), anchor=(0.5, 0.5), bg=(255, 255, 255), bgt=0.4, rotation=20, z=43)
    shine.add(ui_corner(1, 0))
    egg.add(shine)
    egg_open.add(egg)
    card = frame("PetCard", ((0, 340), (0, 270)), ((0.5, 0), (0.5, 0)), anchor=(0.5, 0.5), visible=False, z=44)
    card.add(ui_scale())
    card.add(label("PetIcon", "🐾", ((0, 140), (0, 140)), ((0.5, 0), (0, 0)), anchor=(0.5, 0), stroke=0, z=45))
    card.add(label("PetName", "Питомец", ((1, 0), (0, 46)), ((0, 0), (0, 146)), stroke=4, z=45))
    card.add(label("PetRarity", "Обычный", ((1, 0), (0, 30)), ((0, 0), (0, 194)), stroke=3, z=45))
    card.add(label("PetBonus", "+0.2 к силе", ((1, 0), (0, 26)), ((0, 0), (0, 228)), color=(255, 233, 168), stroke=2.5, z=45))
    egg_open.add(card)
    egg_open.add(frame("Flash", ((1, 0), (1, 0)), ((0, 0), (0, 0)), bg=(255, 255, 255), bgt=0, visible=False, z=50))
    hud.add(egg_open)

    hud.add(frame("Toasts", ((1, 0), (1, 0)), ((0, 0), (0, 0)), z=20))

    panels = frame("Panels", ((1, 0), (1, 0)), ((0, 0), (0, 0)), z=10)
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
    panels.add(panel("QuestsPanel", "Ежедневные задания", "row", content_top=96, children=[
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
    starter_gui = Inst("StarterGui", "StarterGui", [], [build_gui()])
    lighting = Inst("Lighting", "Lighting", [P("float", "ClockTime", 14.5), P("float", "Brightness", 2.5),
                                             P("bool", "GlobalShadows", True)])
    write_place(OUT, [workspace, lighting, replicated, server, storage, starter_player, starter_gui])
    print("Готово:", OUT, f"({os.path.getsize(OUT) // 1024} КБ)")


if __name__ == "__main__":
    build()
