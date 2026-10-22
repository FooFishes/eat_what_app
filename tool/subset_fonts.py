"""把 Noto Sans SC 和 Bricolage Grotesque 的可变字体裁成 App 内置的子集，输出到 assets/fonts/。

用法（需要 fonttools，原始字体从 github.com/google/fonts 的 ofl/ 目录取）：

    python3 tool/subset_fonts.py <NotoSansSC[wght].ttf> <BricolageGrotesque[opsz,wdth,wght].ttf>

两个字体都保留可变字重轴，一份文件覆盖全部字重。Noto Sans SC 全量 17.8 MB，只留 GB 2312 的
字符和常用标点；子集外的生僻字由系统字体补，样子不同但不缺字。Bricolage Grotesque 只用来排数字，
留下 ASCII 和价格、区间要用的几个符号。输出入库，CI 不跑这个脚本；换字体版本或扩字符集时重跑。
"""

import sys
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

OUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "fonts"

ASCII = range(0x20, 0x7F)

# GB 2312 的符号区里有几个字在 Python 的编码表里落到了别的码位（A1A4 是 U+30FB 而不是 U+00B7，
# A1AA 是 U+2015 而不是 U+2014），界面上实际打出来的是后者，所以把这几段整段补上。
EXTRA_RANGES = [
    range(0x00A0, 0x0100),  # Latin-1 补充：· ¥ ×
    range(0x2010, 0x2028),  # 常用标点：– — ‘ ’ “ ” …
    range(0x3000, 0x3040),  # CJK 符号：、。「」『』《》【】
    range(0xFF00, 0xFFF0),  # 全角字符：，！？（）￥
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


def write_subset(font, unicodes, out_name):
    options = subset.Options()
    # 去掉 hinting：Flutter 在三端都不用 TrueType 指令渲染，留着只增加体积。
    options.hinting = False
    options.desubroutinize = True
    options.name_IDs = ["*"]
    subsetter = subset.Subsetter(options)
    subsetter.populate(unicodes=sorted(unicodes))
    subsetter.subset(font)
    out = OUT_DIR / out_name
    font.save(out)
    print(f"{out.relative_to(OUT_DIR.parent.parent)}: {out.stat().st_size:,} 字节，{len(font.getBestCmap())} 个字符")


def main(noto_path, bricolage_path):
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    sans = set(ASCII) | gb2312_chars()
    for r in EXTRA_RANGES:
        sans.update(r)
    write_subset(TTFont(noto_path), sans, "NotoSansSC-VF.ttf")

    # 宽度轴固定在 100（标准宽度），只留光学尺寸和字重：设计稿在浏览器里按字号自动取光学尺寸，
    # 文字样式里同样按字号设 opsz，才能和画板一致。
    bricolage = instancer.instantiateVariableFont(TTFont(bricolage_path), {"wdth": 100})
    write_subset(bricolage, set(ASCII) | set(NUMERAL_EXTRA), "BricolageGrotesque-VF.ttf")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
