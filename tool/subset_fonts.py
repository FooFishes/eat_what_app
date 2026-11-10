"""把 Inter 的可变字体裁剪为 App 内置的子集, 输出到 assets/fonts/.

用法 (需要 fonttools, 原始字体取自 github.com/google/fonts 的 ofl/ 目录):

    python3 tool/subset_fonts.py <Inter[opsz,wght].ttf>

保留可变字重轴和光学尺寸轴, 一个文件覆盖全部字重.

Inter 只用于排版数字, 子集保留 ASCII 以及价格和区间所需的几个符号. 中文使用系统字体, 不内置.

输出文件入库, CI 不运行此脚本. 更换字体版本或扩充字符集时重新运行.
"""

import sys
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont

OUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "fonts"

ASCII = range(0x20, 0x7F)

NUMERAL_EXTRA = [0x00A5, 0x00B7, 0x2013, 0x2014, 0xFFE5]


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


def main(inter_path):
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    # 保留全部 OpenType 特性: 等宽数字 tnum 等特性不在 fonttools 的默认集合中, 而文字样式需要使用.
    # 子集只有几十个 ASCII 字形, 多保留的特性表几乎不占体积.
    write_subset(TTFont(inter_path), set(ASCII) | set(NUMERAL_EXTRA), "Inter-VF.ttf", ["*"])


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(sys.argv[1])
