"""
Вырезает 16 кирок из картинки-референса (art/ui_src/pickaxes_ref.webp) → art/pickaxes/<id>.png
(фон убирается алгоритмом GrabCut из OpenCV). Нужен opencv-python-headless.
"""
import os
import sys
import cv2
import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
src = cv2.imread(os.path.join(ROOT, "art", "ui_src", "pickaxes_ref.webp"), cv2.IMREAD_COLOR)
OUT = os.path.join(ROOT, "art", "pickaxes")
os.makedirs(OUT, exist_ok=True)
IDS = ["wood", "stone", "copper", "iron", "steel", "gold", "diamond", "emerald",
       "obsidian", "ice", "fire", "electric", "cosmic", "angel", "shadow", "devil"]
COLS = [(412, 614), (634, 838), (856, 1062), (1080, 1290)]
ROWS = [(186, 290), (390, 492), (580, 668), (765, 852)]  # область кирки внутри карточки (над плашкой редкости)
k = 0
for (y0, y1) in ROWS:
    for (x0, x1) in COLS:
        pad = 6
        crop = src[y0 - pad:y1 + pad, x0:x1].copy()
        h, w = crop.shape[:2]
        mask = np.zeros((h, w), np.uint8)
        rect = (int(w * 0.12), 2, int(w * 0.76), h - 4)
        bgd, fgd = np.zeros((1, 65), np.float64), np.zeros((1, 65), np.float64)
        cv2.grabCut(crop, mask, rect, bgd, fgd, 8, cv2.GC_INIT_WITH_RECT)
        alpha = np.where((mask == 1) | (mask == 3), 255, 0).astype(np.uint8)
        # оставить самый большой кусок, сгладить край
        n, lab, stats, _ = cv2.connectedComponentsWithStats(alpha)
        if n > 1:
            big = 1 + int(np.argmax(stats[1:, cv2.CC_STAT_AREA]))
            alpha = np.where(lab == big, 255, 0).astype(np.uint8)
        alpha = cv2.GaussianBlur(alpha, (3, 3), 0)
        rgba = cv2.cvtColor(crop, cv2.COLOR_BGR2BGRA)
        rgba[:, :, 3] = alpha
        ys, xs = np.where(alpha > 10)
        rgba = rgba[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
        side = max(rgba.shape[:2])
        canvas = np.zeros((side, side, 4), np.uint8)
        oy, ox = (side - rgba.shape[0]) // 2, (side - rgba.shape[1]) // 2
        canvas[oy:oy + rgba.shape[0], ox:ox + rgba.shape[1]] = rgba
        canvas = cv2.resize(canvas, (512, 512), interpolation=cv2.INTER_CUBIC)
        cv2.imwrite(os.path.join(OUT, IDS[k] + ".png"), canvas)
        k += 1
print("готово:", k)
