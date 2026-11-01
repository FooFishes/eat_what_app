"""把 Noto Sans SC 和 Inter 的可变字体裁剪为 App 内置的子集, 输出到 assets/fonts/.

用法 (需要 fonttools, 原始字体取自 github.com/google/fonts 的 ofl/ 目录):

    python3 tool/subset_fonts.py <NotoSansSC[wght].ttf> <Inter[opsz,wght].ttf>

两个字体都保留可变字重轴, 一个文件覆盖全部字重.

Noto Sans SC 全量 17.8 MB, 子集只保留 GB 2312 字符和常用标点.
子集外的生僻字由系统字体显示, 字形不同但不会缺字.

Inter 只用于排版数字, 子集保留 ASCII 以及价格和区间所需的几个符号.

输出文件入库, CI 不运行此脚本. 更换字体版本或扩充字符集时重新运行.
"""

import sys
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont

OUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "fonts"

ASCII = range(0x20, 0x7F)

# GB 2312 符号区中有几个字符在 Python 的编码表里映射到其他码位:
# A1A4 映射为 U+30FB 而非 U+00B7, A1AA 映射为 U+2015 而非 U+2014.
# 界面实际使用的是后者, 因此整段补入以下范围.
EXTRA_RANGES = [
    # Latin-1 补充, 如 · ¥ ×
    range(0x00A0, 0x0100),
    # 常用标点, 如 – — ‘ ’ “ ” …
    range(0x2010, 0x2028),
    # CJK 符号, 如 、。「」『』《》【】
    range(0x3000, 0x3040),
    # 全角字符, 如 ，！？（）￥
    range(0xFF00, 0xFFF0),
]

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


def main(noto_path, inter_path):
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    sans = set(ASCII) | gb2312_chars()
    for r in EXTRA_RANGES:
        sans.update(r)
    write_subset(TTFont(noto_path), sans, "NotoSansSC-VF.ttf")

    # 保留全部 OpenType 特性: 等宽数字 tnum 等特性不在 fonttools 的默认集合中, 而文字样式需要使用.
    # 子集只有几十个 ASCII 字形, 多保留的特性表几乎不占体积.
    write_subset(TTFont(inter_path), set(ASCII) | set(NUMERAL_EXTRA), "Inter-VF.ttf", ["*"])


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
