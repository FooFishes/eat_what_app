"""把手绘的 App 图标原稿整理成 flutter_launcher_icons 的输入图, 输出到 tool/app_icons/.

用法 (需要 Pillow):

    python3 tool/app_icons.py

原稿 tool/app_icons/<名字>_original.png 是白底上画的一块黄色方块, 主角在方块里. 脚本把白底和方块
边上的白色笔触都涂成同一种黄色, 再按主角的范围重新居中, 每个图标输出两张 1024 px 的图:

- <名字>.png: 满版图, 给 iOS 和安卓旧版图标. 主角最长边占画布的 ICONS 里给的比例.
- <名字>_foreground.png: 安卓自适应图标的前景, 主角整个落在 66/108 的安全圆里, 背景色同为黄色.

另外输出 assets/app_icons/<名字>.png, 是个性化页面里预览用的小图.

输出文件入库, CI 不运行此脚本. 换原稿或调整主角大小时重新运行, 再运行 flutter_launcher_icons.
"""

import math
from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "tool" / "app_icons"
PREVIEW = ROOT / "assets" / "app_icons"

YELLOW = (248, 211, 71)
SIZE = 1024
PREVIEW_SIZE = 192

# 满版图里主角最长边占画布的比例. 猪猪画面满, 饭饭只有一团白, 后者放小一些看起来才一样大.
ICONS = {"pig": 0.72, "bun": 0.62}

# 自适应图标前景里主角外接圆的半径, 按 108 dp 画布计. 安全区是直径 66 dp 的圆, 留 1 dp 余量.
FOREGROUND_RADIUS = 32 / 108


def _is_white(p):
    return min(p) >= 235


def _is_fringe(p):
    """黄色和白色之间的抗锯齿过渡色."""
    r, g, b = p
    if r < 240:
        return False
    t = (b - YELLOW[2]) / (255 - YELLOW[2])
    return -0.05 <= t <= 1.05 and abs((g - YELLOW[1]) - t * (255 - YELLOW[1])) < 12


def _is_ink(p):
    """明显不是黄色的像素, 即主角的笔触和颜色."""
    return sum(abs(a - b) for a, b in zip(p, YELLOW)) > 60


def _neighbors4(x, y, w, h):
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        nx, ny = x + dx, y + dy
        if 0 <= nx < w and 0 <= ny < h:
            yield nx, ny


def _clean(path):
    """返回涂好底色的图, 主角的中心点和主角像素到中心的最大距离."""
    im = Image.open(path).convert("RGB")
    w, h = im.size
    px = im.load()

    # 从四边往里灌, 连到边上的白色都是底.
    bg = [[False] * w for _ in range(h)]
    queue = deque([(x, y) for x in range(w) for y in (0, h - 1)] + [(x, y) for y in range(h) for x in (0, w - 1)])
    while queue:
        x, y = queue.popleft()
        if bg[y][x] or not _is_white(px[x, y]):
            continue
        bg[y][x] = True
        queue.extend(n for n in _neighbors4(x, y, w, h) if not bg[n[1]][n[0]])
    for _ in range(3):
        grow = [(x, y) for y in range(h) for x in range(w)
                if not bg[y][x] and _is_fringe(px[x, y])
                and any(bg[ny][nx] for nx, ny in _neighbors4(x, y, w, h))]
        for x, y in grow:
            bg[y][x] = True
    for y in range(h):
        for x in range(w):
            if bg[y][x]:
                px[x, y] = YELLOW

    # 把非黄色像素按八连通分块, 最大的一块是主角.
    ink = [[_is_ink(px[x, y]) for x in range(w)] for y in range(h)]
    seen = [[False] * w for _ in range(h)]
    parts = []
    for sy in range(h):
        for sx in range(w):
            if not ink[sy][sx] or seen[sy][sx]:
                continue
            part, queue = [], deque([(sx, sy)])
            seen[sy][sx] = True
            while queue:
                x, y = queue.popleft()
                part.append((x, y))
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < w and 0 <= ny < h and ink[ny][nx] and not seen[ny][nx]:
                            seen[ny][nx] = True
                            queue.append((nx, ny))
            parts.append(part)
    parts.sort(key=len, reverse=True)
    main = parts[0]
    x0, x1 = min(p[0] for p in main), max(p[0] for p in main)
    y0, y1 = min(p[1] for p in main), max(p[1] for p in main)

    # 主角附近的小块 (五官, 签名) 保留; 方块边上的细笔触涂掉.
    kept = []
    for part in parts:
        xs, ys = [p[0] for p in part], [p[1] for p in part]
        near = min(xs) >= x0 - 60 and max(xs) <= x1 + 60 and min(ys) >= y0 - 40 and max(ys) <= y1 + 40
        thin = max(xs) - min(xs) <= 3 or max(ys) - min(ys) <= 3
        if (near and not (thin and len(part) < 40)) or len(part) > 150:
            kept.extend(part)
        else:
            for x, y in part:
                px[x, y] = YELLOW
    # 主角范围外颜色较淡的笔触也涂掉.
    for y in range(h):
        for x in range(w):
            if not ink[y][x] and not (x0 - 10 <= x <= x1 + 10 and y0 - 10 <= y <= y1 + 10):
                px[x, y] = YELLOW

    xs, ys = [p[0] for p in kept], [p[1] for p in kept]
    left, top, right, bottom = min(xs), min(ys), max(xs) + 1, max(ys) + 1
    cx, cy = (left + right) / 2, (top + bottom) / 2
    radius = max(math.hypot(x - cx, y - cy) for x, y in kept)
    return im, (cx, cy), max(right - left, bottom - top), radius


def _place(im, center, scale):
    cx, cy = center
    big = im.resize((round(im.width * scale), round(im.height * scale)), Image.LANCZOS)
    canvas = Image.new("RGB", (SIZE, SIZE), YELLOW)
    canvas.paste(big, (round(SIZE / 2 - cx * scale), round(SIZE / 2 - cy * scale)))
    return canvas


def main():
    PREVIEW.mkdir(parents=True, exist_ok=True)
    for name, ratio in ICONS.items():
        im, center, extent, radius = _clean(SRC / f"{name}_original.png")
        full = _place(im, center, SIZE * ratio / extent)
        full.save(SRC / f"{name}.png", optimize=True)
        _place(im, center, SIZE * FOREGROUND_RADIUS / radius).save(SRC / f"{name}_foreground.png", optimize=True)
        full.resize((PREVIEW_SIZE, PREVIEW_SIZE), Image.LANCZOS).save(PREVIEW / f"{name}.png", optimize=True)
        print(f"{name}: 主角 {extent} px, 满版放大 {SIZE * ratio / extent:.2f} 倍")


if __name__ == "__main__":
    main()
