"""把 Noto Sans SC 和 Inter 的可变字体裁剪为 App 内置的子集, 输出到 assets/fonts/.

用法 (需要 fonttools, 原始字体取自 github.com/google/fonts 的 ofl/ 目录), 两个参数可只传其一:

    python3 tool/subset_fonts.py --noto <NotoSansSC[wght].ttf> --inter <Inter[opsz,wght].ttf>

两个字体都保留可变字重轴, 一个文件覆盖全部字重.

Noto Sans SC 只给安卓用 (iOS 用苹方, Web 用引擎按需下载的回落字体). 全量 17.8 MB, 子集只保留
GB 2312 字符和常用标点, 约 4 MB; 子集外的生僻字由系统字体显示, 字形不同但不会缺字.
另外按 WEIGHT_MAP 改写字重轴的映射, 使各档字重的笔画粗细接近 iOS 上的苹方.

Inter 只用于排版数字, 子集保留 ASCII 以及价格和区间所需的几个符号.

输出文件入库, CI 不运行此脚本. 更换字体版本, 扩充字符集或调整字重映射时重新运行.
"""

import argparse
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont

OUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "fonts"

ASCII = range(0x20, 0x7F)

# GB 2312 符号区中有几个字符在 Python 的编码表里映射到其他码位:
# A1A4 映射为 U+30FB 而非 U+00B7, A1AA 映射为 U+2015 而非 U+2014.
# 界面实际使用的是后者, 因此整段补入以下范围.
EXTRA_RANGES = [
    # Latin-1 补充, 如 ¥ ×
    range(0x00A0, 0x0100),
    # 常用标点, 如 – — ‘ ’ “ ” …
    range(0x2010, 0x2028),
    # CJK 符号, 如 、。「」『』《》【】
    range(0x3000, 0x3040),
    # 全角字符, 如 ，！？（）￥
    range(0xFF00, 0xFFF0),
]

# Noto Sans SC 的间隔号 · 是全角宽度, 「去店里吃 · 点外卖」两侧会空出一大截, 苹方的只有半宽.
# 子集不收这个字符, 文字样式把 Inter 设为回落字体, 由 Inter 的半宽间隔号显示.
SANS_EXCLUDED = {0x00B7}

# 字重映射: 文字样式里写的字重 -> Noto Sans SC 实际取的 wght 值.
#
# Flutter 把 FontWeight 原样设为 wght 轴的值. Noto 的 400 与苹方 Regular 粗细相当, 不调整;
# 600 及以上偏粗, 而 iOS 上苹方最粗只有 Semibold, 600–800 都显示成 Semibold.
# 因此 700 对齐苹方 Semibold 的笔画面积, 600 略细, 800 略粗, 保留三档之间的层次.
# 数值由样例汉字的笔画面积 (去掉轮廓重叠后) 比对苹方得出, 再按实际渲染效果微调.
WEIGHT_MAP = [(100, 100), (400, 400), (600, 560), (700, 600), (800, 640), (900, 900)]

NUMERAL_EXTRA = [0x00A5, 0x00B7, 0x2013, 0x2014, 0xFFE5]


def gb2312_chars():
    chars = set()
    for high in range(0xA1, 0xF8):
        for low in range(0xA1, 0xFF):
            try:
                chars.add(ord(bytes([high, low]).decode("gb2312")))
            except UnicodeDecodeError:
                pass
    return chars


def interpolate(points, x):
    """在按 x 升序排列的折线 points 上求 x 处的值."""
    for (x0, y0), (x1, y1) in zip(points, points[1:]):
        if x0 <= x <= x1:
            return y0 if x1 == x0 else y0 + (y1 - y0) * (x - x0) / (x1 - x0)
    raise ValueError(f"{x} 超出折线范围")


def remap_weight_axis(font, weight_map):
    """把 weight_map 叠加到字体原有的 avar 映射之前, 使字重 w 渲染出原字体 wght = weight_map(w) 的字形.

    avar 是归一化坐标上的折线, 两条折线复合后仍是折线, 转折点取两者转折点的并集即可精确表示.
    """
    axis = next(a for a in font["fvar"].axes if a.axisTag == "wght")
    lo, default, hi = axis.minValue, axis.defaultValue, axis.maxValue
    if weight_map[0][0] != lo or weight_map[-1][0] != hi or interpolate(weight_map, default) != default:
        raise ValueError("字重映射须覆盖整条轴, 并保持默认值不变")

    def normalize(w):
        if w < default:
            return (w - default) / (default - lo)
        return 0.0 if w == default else (w - default) / (hi - default)

    def denormalize(n):
        return default + n * ((default - lo) if n < 0 else (hi - default))

    old = sorted(font["avar"].segments["wght"].items()) if "avar" in font else [(-1.0, -1.0), (0.0, 0.0), (1.0, 1.0)]
    inverse = [(y, x) for x, y in weight_map]
    xs = {w for w, _ in weight_map}
    xs |= {interpolate(inverse, denormalize(n)) for n, _ in old}
    # avar 要求 -1, 0, 1 三点映射到自身. 默认值位于轴的一端时, 折线上取不到另一侧的端点, 在此补上.
    segments = {-1.0: -1.0, 0.0: 0.0, 1.0: 1.0}
    for w in sorted(xs):
        segments[round(normalize(w), 4)] = round(interpolate(old, normalize(interpolate(weight_map, w))), 4)
    segments = dict(sorted(segments.items()))

    if "avar" not in font:
        font["avar"] = TTFont().getTableClass("avar")()
        font["avar"].segments = {a.axisTag: {-1.0: -1.0, 0.0: 0.0, 1.0: 1.0} for a in font["fvar"].axes}
    font["avar"].segments["wght"] = segments


def write_subset(font, unicodes, out_name, layout_features=None):
    options = subset.Options()
    # 去掉 hinting: Flutter 在三端都不使用 TrueType 指令渲染, 保留只会增加体积.
    options.hinting = False
    options.desubroutinize = True
    options.name_IDs = ["*"]
    if layout_features is not None:
        options.layout_features = layout_features
    subsetter = subset.Subsetter(options)
    subsetter.populate(unicodes=sorted(unicodes))
    subsetter.subset(font)
    out = OUT_DIR / out_name
    font.save(out)
    print(f"{out.relative_to(OUT_DIR.parent.parent)}: {out.stat().st_size:,} 字节，{len(font.getBestCmap())} 个字符")


def main():
    parser = argparse.ArgumentParser(description="子集化内置字体")
    parser.add_argument("--noto", help="NotoSansSC[wght].ttf")
    parser.add_argument("--inter", help="Inter[opsz,wght].ttf")
    args = parser.parse_args()
    if not args.noto and not args.inter:
        parser.error("至少传入一个字体")
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    if args.noto:
        sans = set(ASCII) | gb2312_chars()
        for r in EXTRA_RANGES:
            sans.update(r)
        noto = TTFont(args.noto)
        remap_weight_axis(noto, WEIGHT_MAP)
        write_subset(noto, sans - SANS_EXCLUDED, "NotoSansSC-VF.ttf")

    if args.inter:
        # 保留全部 OpenType 特性: 等宽数字 tnum 等特性不在 fonttools 的默认集合中, 而文字样式需要使用.
        # 子集只有几十个 ASCII 字形, 多保留的特性表几乎不占体积.
        write_subset(TTFont(args.inter), set(ASCII) | set(NUMERAL_EXTRA), "Inter-VF.ttf", ["*"])


if __name__ == "__main__":
    main()
