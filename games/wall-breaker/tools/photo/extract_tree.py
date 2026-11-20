"""
Читает WallBreaker.rbxlx и сохраняет дерево объектов (Workspace и StarterGui) в JSON
для фото-рендера (photo.html). Также достаёт данные яиц и питомцев из PetConfig.
Запуск: python3 extract_tree.py <place.rbxlx> <out.json>
"""
import json
import re
import sys
import xml.etree.ElementTree as ET


def parse_prop(e):
    tag, name = e.tag, e.get("name")
    t = lambda k: e.find(k).text
    f = lambda k: float(e.find(k).text)
    if tag in ("string", "ProtectedString"):
        return name, e.text or ""
    if tag == "bool":
        return name, e.text == "true"
    if tag in ("float", "double", "int", "token"):
        return name, float(e.text)
    if tag == "Vector3":
        return name, [f("X"), f("Y"), f("Z")]
    if tag == "Vector2":
        return name, [f("X"), f("Y")]
    if tag == "CoordinateFrame":
        return name, [f(k) for k in ("X", "Y", "Z", "R00", "R01", "R02", "R10", "R11", "R12", "R20", "R21", "R22")]
    if tag == "Color3uint8":
        v = int(e.text)
        return name, [(v >> 16) & 255, (v >> 8) & 255, v & 255]
    if tag == "Color3":
        return name, [round(f("R") * 255), round(f("G") * 255), round(f("B") * 255)]
    if tag == "UDim2":
        return name, [f("XS"), f("XO"), f("YS"), f("YO")]
    if tag == "UDim":
        return name, [f("S"), f("O")]
    if tag == "Content":
        u = e.find("url")
        return name, u.text if u is not None else ""
    return None, None


def node(item):
    props = {}
    for e in item.find("Properties"):
        k, v = parse_prop(e)
        if k and k != "Source":
            props[k] = v
    return {"class": item.get("class"), "name": props.get("Name", ""), "props": props,
            "children": [node(c) for c in item.findall("Item") if c.get("class") not in ("ModuleScript", "Script", "LocalScript")]}


def pets_data(path):
    src = open(path, encoding="utf-8").read()
    pets = {}
    for m in re.finditer(r'(\w+) = \{ Name = "([^"]+)", Rarity = "([^"]+)", Multiplier = ([\d.]+), Emoji = "([^"]+)"', src):
        pets[m.group(1)] = {"Name": m.group(2), "Rarity": m.group(3), "Multiplier": float(m.group(4)), "Emoji": m.group(5)}
    eggs = []
    for m in re.finditer(r'\{ Id = "(\w+)", Name = "([^"]+)", Tag = "([^"]+)", (?:Price = (\d+)|RobuxProduct = "\w+", RobuxPrice = (\d+)), '
                         r'Color = rgb\((\d+), (\d+), (\d+)\),\s*Pets = \{([^}]*\}[^}]*\}[^}]*\}[^}]*\})', src):
        plist = re.findall(r'\{ "(\w+)", (\d+) \}', m.group(9))
        eggs.append({"Id": m.group(1), "Name": m.group(2), "Tag": m.group(3), "Price": int(m.group(4) or 0),
                     "RobuxPrice": int(m.group(5) or 0), "Color": [int(m.group(i)) for i in (6, 7, 8)],
                     "Pets": [[p, int(c)] for p, c in plist]})
    rar = {m.group(1): [int(m.group(i)) for i in (2, 3, 4)] for m in re.finditer(r'\["(\S+)"\] = rgb\((\d+), (\d+), (\d+)\)', src)}
    return {"pets": pets, "eggs": eggs, "rarities": rar}


root = ET.parse(sys.argv[1]).getroot()
out = {}
for item in root.findall("Item"):
    cls = item.get("class")
    if cls == "Workspace":
        out["workspace"] = node(item)
    if cls == "StarterGui":
        out["gui"] = node(item)
import os
cfg = os.path.join(os.path.dirname(os.path.abspath(sys.argv[1])), "src", "ReplicatedStorage", "Config", "PetConfig.luau")
out["petdata"] = pets_data(cfg)
json.dump(out, open(sys.argv[2], "w"), ensure_ascii=False)
print("ok", len(out["petdata"]["pets"]), "pets", len(out["petdata"]["eggs"]), "eggs")
