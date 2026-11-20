"""
Мини-библиотека для записи файлов места Roblox (.rbxlx, XML-формат).
Используется build_place.py. Только стандартные классы и свойства.
"""
import math
from xml.sax.saxutils import escape

# Enum.Material
MAT = {
    "Plastic": 256, "SmoothPlastic": 272, "Neon": 288, "Wood": 512, "WoodPlanks": 528,
    "Marble": 784, "Basalt": 788, "Slate": 800, "CrackedLava": 804, "Concrete": 816,
    "Granite": 832, "Brick": 848, "Pebble": 864, "Cobblestone": 880, "CorrodedMetal": 1040,
    "DiamondPlate": 1056, "Foil": 1072, "Metal": 1088, "Grass": 1280, "Sand": 1296,
    "Fabric": 1312, "Ice": 1536, "Glass": 1568, "ForceField": 1584,
}
# Enum.Font
FONT_BLACK = 20  # GothamBlack
FONT_BOLD = 19  # GothamBold
# Enum.NormalId
FACE = {"Right": 0, "Top": 1, "Back": 2, "Left": 3, "Bottom": 4, "Front": 5}


def _f(x):
    s = repr(float(x))
    return s[:-2] if s.endswith(".0") else s


class P:
    """Типизированное значение свойства."""

    def __init__(self, kind, name, value):
        self.kind, self.name, self.value = kind, name, value

    def xml(self):
        k, n, v = self.kind, self.name, self.value
        if k == "string":
            return f'<string name="{n}">{escape(v)}</string>'
        if k == "protected":
            return f'<ProtectedString name="{n}"><![CDATA[{v}]]></ProtectedString>'
        if k == "bool":
            return f'<bool name="{n}">{"true" if v else "false"}</bool>'
        if k == "float":
            return f'<float name="{n}">{_f(v)}</float>'
        if k == "double":
            return f'<double name="{n}">{_f(v)}</double>'
        if k == "int":
            return f'<int name="{n}">{int(v)}</int>'
        if k == "token":
            return f'<token name="{n}">{int(v)}</token>'
        if k == "vec3":
            return f'<Vector3 name="{n}"><X>{_f(v[0])}</X><Y>{_f(v[1])}</Y><Z>{_f(v[2])}</Z></Vector3>'
        if k == "vec2":
            return f'<Vector2 name="{n}"><X>{_f(v[0])}</X><Y>{_f(v[1])}</Y></Vector2>'
        if k == "cf":
            (x, y, z), r = v
            return (f'<CoordinateFrame name="{n}"><X>{_f(x)}</X><Y>{_f(y)}</Y><Z>{_f(z)}</Z>'
                    + "".join(f"<R{i}{j}>{_f(r[i][j])}</R{i}{j}>" for i in range(3) for j in range(3))
                    + "</CoordinateFrame>")
        if k == "color3u8":
            r, g, b = v
            return f'<Color3uint8 name="{n}">{0xFF000000 | (r << 16) | (g << 8) | b}</Color3uint8>'
        if k == "color3":
            r, g, b = v
            return f'<Color3 name="{n}"><R>{_f(r / 255)}</R><G>{_f(g / 255)}</G><B>{_f(b / 255)}</B></Color3>'
        if k == "udim2":
            (xs, xo), (ys, yo) = v
            return f'<UDim2 name="{n}"><XS>{_f(xs)}</XS><XO>{int(xo)}</XO><YS>{_f(ys)}</YS><YO>{int(yo)}</YO></UDim2>'
        if k == "udim":
            s, o = v
            return f'<UDim name="{n}"><S>{_f(s)}</S><O>{int(o)}</O></UDim>'
        if k == "colorseq":  # один цвет на всё время
            r, g, b = (c / 255 for c in v)
            return f'<ColorSequence name="{n}">0 {_f(r)} {_f(g)} {_f(b)} 0 1 {_f(r)} {_f(g)} {_f(b)} 0 </ColorSequence>'
        if k == "numseq":  # (начало, конец)
            return f'<NumberSequence name="{n}">0 {_f(v[0])} 0 1 {_f(v[1])} 0 </NumberSequence>'
        if k == "numrange":
            return f'<NumberRange name="{n}">{_f(v[0])} {_f(v[1])} </NumberRange>'
        if k == "content":
            return f'<Content name="{n}"><url>{escape(v)}</url></Content>' if v else f'<Content name="{n}"><null></null></Content>'
        raise ValueError(k)


def rot(rx=0, ry=0, rz=0):
    """Матрица поворота как CFrame.Angles(rx, ry, rz) в градусах (Rx*Ry*Rz)."""
    a, b, c = (math.radians(x) for x in (rx, ry, rz))
    ca, sa, cb, sb, cc, sc = math.cos(a), math.sin(a), math.cos(b), math.sin(b), math.cos(c), math.sin(c)
    rxm = [[1, 0, 0], [0, ca, -sa], [0, sa, ca]]
    rym = [[cb, 0, sb], [0, 1, 0], [-sb, 0, cb]]
    rzm = [[cc, -sc, 0], [sc, cc, 0], [0, 0, 1]]
    return matmul(matmul(rxm, rym), rzm)


def matmul(a, b):
    return [[sum(a[i][k] * b[k][j] for k in range(3)) for j in range(3)] for i in range(3)]


def apply(m, v):
    return tuple(sum(m[i][k] * v[k] for k in range(3)) for i in range(3))


IDENT = [[1, 0, 0], [0, 1, 0], [0, 0, 1]]


class Frame3:
    """Система координат (позиция + поворот) для удобной сборки моделей."""

    def __init__(self, pos=(0, 0, 0), r=None):
        self.pos, self.r = pos, r or IDENT

    def at(self, local, lr=None):
        p = apply(self.r, local)
        world = (self.pos[0] + p[0], self.pos[1] + p[1], self.pos[2] + p[2])
        return world, matmul(self.r, lr or IDENT)


class Inst:
    _ref = 0

    def __init__(self, cls, name, props=None, children=None):
        self.cls, self.name = cls, name
        self.props = list(props or [])
        self.children = list(children or [])

    def add(self, *kids):
        for k in kids:
            if k is not None:
                self.children.append(k)
        return self

    def xml(self, out):
        Inst._ref += 1
        out.append(f'<Item class="{self.cls}" referent="RBX{Inst._ref:06d}"><Properties>')
        out.append(P("string", "Name", self.name).xml())
        for p in self.props:
            out.append(p.xml())
        out.append("</Properties>")
        for c in self.children:
            c.xml(out)
        out.append("</Item>")


def write_place(path, services):
    out = ['<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
           'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">',
           "<External>null</External><External>nil</External>"]
    for s in services:
        s.xml(out)
    out.append("</roblox>")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(out))


# ---------- Детали ----------

def part(name, size, pos, color, material="SmoothPlastic", r=None, anchored=True, collide=True,
         transparency=0, shape=None, cls="Part", query=True, touch=True, cast_shadow=True, children=None, studs=False, reflectance=0):
    sf = 3 if studs else 0  # SurfaceType: Smooth = 0, Studs = 3 — классические «пупырышки» Roblox
    props = [
        P("bool", "Anchored", anchored),
        P("token", "BottomSurface", 0), P("token", "TopSurface", sf),
        P("token", "FrontSurface", sf), P("token", "BackSurface", sf), P("token", "LeftSurface", sf), P("token", "RightSurface", sf),
        P("cf", "CFrame", (pos, r or IDENT)),
        P("bool", "CanCollide", collide),
        P("bool", "CanQuery", query),
        P("bool", "CanTouch", touch),
        P("bool", "CastShadow", cast_shadow),
        P("color3u8", "Color3uint8", color),
        P("token", "Material", MAT[material]),
        P("float", "Transparency", transparency),
        P("float", "Reflectance", reflectance),
        P("vec3", "size", size),
    ]
    if shape is not None:
        props.append(P("token", "shape", {"Ball": 0, "Block": 1, "Cylinder": 2}[shape]))
    return Inst(cls, name, props, children)


def model(name, children=None):
    return Inst("Model", name, [], children)


def folder(name, children=None):
    return Inst("Folder", name, [], children)


def point_light(color=(255, 184, 96), brightness=1.5, rng=16):
    return Inst("PointLight", "Light", [P("color3", "Color", color), P("float", "Brightness", brightness), P("float", "Range", rng),
                                        P("bool", "Shadows", False)])


def prompt(action, obj, dist=10, hold=0):
    return Inst("ProximityPrompt", "Prompt", [
        P("string", "ActionText", action), P("string", "ObjectText", obj),
        P("float", "HoldDuration", hold), P("float", "MaxActivationDistance", dist),
        P("bool", "RequiresLineOfSight", False), P("token", "KeyboardKeyCode", 101),
    ])


def script(cls, name, source):
    return Inst(cls, name, [P("protected", "Source", source)])


# ---------- Интерфейс ----------

def gui_base(name, size, pos, anchor=(0, 0), bg=(255, 255, 255), bgt=1.0, visible=True, z=1, order=0, rotation=0, clip=False):
    return [
        P("vec2", "AnchorPoint", anchor), P("color3", "BackgroundColor3", bg), P("float", "BackgroundTransparency", bgt),
        P("int", "BorderSizePixel", 0), P("udim2", "Position", pos), P("udim2", "Size", size),
        P("bool", "Visible", visible), P("int", "ZIndex", z), P("int", "LayoutOrder", order), P("float", "Rotation", rotation),
        P("bool", "ClipsDescendants", clip),
    ]


def frame(name, size, pos, children=None, **kw):
    return Inst("Frame", name, gui_base(name, size, pos, **kw), children)


def text_props(text, color, font, scaled, xalign, size=24):
    return [P("string", "Text", text), P("color3", "TextColor3", color), P("token", "Font", font),
            P("bool", "TextScaled", scaled), P("float", "TextSize", size), P("token", "TextXAlignment", xalign),
            P("bool", "TextWrapped", True), P("bool", "RichText", False)]


def label(name, text, size, pos, color=(255, 255, 255), font=FONT_BLACK, stroke=2.5, xalign=2, scaled=True, children=None, **kw):
    # TextXAlignment: Left=0, Right=1, Center=2
    inst = Inst("TextLabel", name, gui_base(name, size, pos, **kw) + text_props(text, color, font, scaled, xalign), children)
    if stroke:
        inst.add(ui_stroke(stroke, (26, 16, 51), mode=0))
    return inst


def text_button(name, text, size, pos, bg, color=(255, 255, 255), radius=12, stroke=2, children=None, **kw):
    kw.setdefault("bgt", 0)
    inst = Inst("TextButton", name, gui_base(name, size, pos, bg=bg, **kw) + text_props(text, color, FONT_BLACK, True, 2)
                + [P("bool", "AutoButtonColor", True)], children)
    inst.add(ui_corner(0, radius), ui_stroke(3, (26, 16, 51), mode=1))
    if stroke:
        inst.add(ui_padding(4))
    return inst


def image(name, img, size, pos, visible=True, stretch=False, **kw):
    # ScaleType: Stretch = 0, Fit = 3
    return Inst("ImageLabel", name, gui_base(name, size, pos, visible=visible, **kw)
                + [P("content", "Image", img), P("token", "ScaleType", 0 if stretch else 3)])


def image_button(name, size, pos, children=None, **kw):
    return Inst("ImageButton", name, gui_base(name, size, pos, **kw) + [P("content", "Image", ""), P("bool", "AutoButtonColor", True)], children)


def ui_corner(scale, offset):
    return Inst("UICorner", "UICorner", [P("udim", "CornerRadius", (scale, offset))])


def ui_stroke(thickness, color, mode=1, transparency=0):
    # ApplyStrokeMode: Contextual=0, Border=1
    return Inst("UIStroke", "UIStroke", [P("float", "Thickness", thickness), P("color3", "Color", color),
                                         P("token", "ApplyStrokeMode", mode), P("float", "Transparency", transparency)])


def ui_padding(px):
    return Inst("UIPadding", "UIPadding", [P("udim", n, (0, px)) for n in ("PaddingTop", "PaddingBottom", "PaddingLeft", "PaddingRight")])


def ui_scale(name="UIScale", scale=1):
    return Inst("UIScale", name, [P("float", "Scale", scale)])


def ui_list(horizontal=False, padding=6, halign=0, valign=1):
    # FillDirection: Horizontal=0, Vertical=1; HorizontalAlignment: Center=0, Left=1, Right=2; VerticalAlignment: Center=0, Top=1, Bottom=2
    return Inst("UIListLayout", "UIListLayout", [
        P("token", "FillDirection", 0 if horizontal else 1), P("udim", "Padding", (0, padding)),
        P("token", "SortOrder", 2), P("token", "HorizontalAlignment", halign), P("token", "VerticalAlignment", valign)])


def ui_grid(cell, pad=(10, 10)):
    return Inst("UIGridLayout", "UIGridLayout", [
        P("udim2", "CellSize", ((0, cell[0]), (0, cell[1]))), P("udim2", "CellPadding", ((0, pad[0]), (0, pad[1]))),
        P("token", "SortOrder", 2), P("token", "HorizontalAlignment", 0)])


def scrolling(name, size, pos, children=None):
    return Inst("ScrollingFrame", name, gui_base(name, size, pos, clip=True) + [
        P("udim2", "CanvasSize", ((0, 0), (0, 0))), P("token", "AutomaticCanvasSize", 2),
        P("int", "ScrollBarThickness", 8), P("token", "ScrollingDirection", 2)], children)


def surface_gui(name, face="Front", ppu=50, children=None):
    # SizingMode: FixedSize=0, PixelsPerStud=1
    return Inst("SurfaceGui", name, [P("token", "Face", FACE[face]), P("token", "SizingMode", 1),
                                     P("float", "PixelsPerStud", ppu), P("float", "LightInfluence", 0),
                                     P("bool", "AlwaysOnTop", False)], children)


def billboard(name, size_px, offset, children=None, max_dist=90):
    return Inst("BillboardGui", name, [P("udim2", "Size", ((0, size_px[0]), (0, size_px[1]))),
                                       P("vec3", "StudsOffset", offset), P("float", "MaxDistance", max_dist),
                                       P("bool", "AlwaysOnTop", False), P("float", "LightInfluence", 0)], children)


def screen_gui(name, children=None):
    return Inst("ScreenGui", name, [P("bool", "ResetOnSpawn", False), P("token", "ZIndexBehavior", 1),
                                    P("bool", "IgnoreGuiInset", False)], children)


def particles(color, rate, texture, speed, size, name="Particles"):
    return Inst("ParticleEmitter", name, [
        P("colorseq", "Color", color), P("float", "LightEmission", 0.8), P("float", "Rate", rate),
        P("numrange", "Lifetime", (0.5, 1)), P("numrange", "Speed", (speed, speed * 2)),
        P("vec2", "SpreadAngle", (180, 180)), P("numseq", "Size", (size, 0)), P("numseq", "Transparency", (0.1, 1)),
        P("content", "Texture", texture)])
