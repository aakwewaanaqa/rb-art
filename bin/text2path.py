#!/usr/bin/env -S uv run --script
# /// script
# dependencies = ["fonttools"]
# ///
"""用法: bin/text2path.py <字型檔> <文字> [字級]
輸出 SVG path 的 d 字串（y 軸已翻成 SVG 方向，原點在第一個字的基線左端）。"""
import sys
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen

font_path, text = sys.argv[1], sys.argv[2]
size = float(sys.argv[3]) if len(sys.argv) > 3 else 100

font = TTFont(font_path, fontNumber=0)  # .ttc 取第一個字型
glyphs = font.getGlyphSet()
cmap = font.getBestCmap()
scale = size / font["head"].unitsPerEm

pen = SVGPathPen(glyphs, ntos=lambda n: f"{n:.2f}".rstrip("0").rstrip("."))
x = 0
for ch in text:
    name = cmap.get(ord(ch), ".notdef")
    # 字型座標 y 朝上，SVG y 朝下，所以 y 乘 -scale
    glyphs[name].draw(TransformPen(pen, (scale, 0, 0, -scale, x, 0)))
    x += glyphs[name].width * scale

print(pen.getCommands())
