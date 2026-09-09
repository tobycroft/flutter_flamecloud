#!/usr/bin/env python3
"""
从「完整合成图」生成 Android 自适应图标(Adaptive Icon)专用的前景图。

背景
----
assets/icon/icon.png 是一张 1024x1024 的合成图：
  上部 = 火焰云图形(mark)
  底部 = "FLAME CLOUD" 文字
如果直接拿它当 adaptive icon 的 foreground，启动器会再套形状遮罩，
底部的文字会被裁掉/缩得看不清，导致桌面图标与安装时看到的不一致。

本脚本只保留「火焰云图形」，去掉文字与浅色渐变底，输出为：
  透明背景 + 图形居中 + 尺寸控制在自适应图标安全区内的前景图。

用法
----
  python3 tools/gen_adaptive_foreground.py
  python3 tools/gen_adaptive_foreground.py --ratio 0.80
"""

import argparse
from PIL import Image

SRC = "assets/icon/icon.png"
OUT = "assets/icon/icon_foreground.png"

# 只在图片上部寻找图形，用于排除底部的 "FLAME CLOUD" 文字。
# 该图实测：图形底部约 y=745，文字位于 y≈778~845，中间 y≈752~775 为空白，
# 故取 0.75*1024=768 作为分界线。
TOP_LIMIT_RATIO = 0.75
# 图形在前景画布中占的比例(相对于画布边长)，需保证 <0.90 才能落在安全区内
DEFAULT_RATIO = 0.80
# 判定为「图形像素」的阈值
SAT_THRESHOLD = 28   # 最大/最小通道差(饱和度)，用于识别橙/红火焰与蓝云
DARK_THRESHOLD = 200 # 最大通道亮度，低于该值视为深色图形


def ink_strength(r: int, g: int, b: int) -> float:
    """返回 0~1 的「图形强度」，用于生成带抗锯齿的 alpha。"""
    mx, mn = max(r, g, b), min(r, g, b)
    sat = (mx - mn) / float(SAT_THRESHOLD * 1.4)
    dark = max(0, DARK_THRESHOLD - mx) / 60.0
    return max(sat, dark)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", default=SRC)
    ap.add_argument("--out", default=OUT)
    ap.add_argument("--ratio", type=float, default=DEFAULT_RATIO)
    args = ap.parse_args()

    src = Image.open(args.src).convert("RGBA")
    w, h = src.size
    px = src.load()

    top_limit = int(h * TOP_LIMIT_RATIO)

    min_x, min_y, max_x, max_y = w, h, -1, -1
    for y in range(top_limit):
        for x in range(w):
            r, g, b, _ = px[x, y]
            if ink_strength(r, g, b) >= 1.0:
                if x < min_x:
                    min_x = x
                if x > max_x:
                    max_x = x
                if y < min_y:
                    min_y = y
                if y > max_y:
                    max_y = y

    if max_x < 0:
        raise SystemExit("未在上部区域检测到图形像素，请检查源图或调整 TOP_LIMIT_RATIO")

    print(f"源图尺寸: {w}x{h}，上部扫描区: 0~{top_limit}")
    print(f"图形包围盒: x {min_x}~{max_x}, y {min_y}~{max_y} "
          f"(宽 {max_x - min_x + 1}, 高 {max_y - min_y + 1})")

    mark = src.crop((min_x, min_y, max_x + 1, max_y + 1))

    # 把浅色渐变底变透明，只保留图形本身(带抗锯齿 alpha)
    mw, mh = mark.size
    mp = mark.load()
    for y in range(mh):
        for x in range(mw):
            r, g, b, _ = mp[x, y]
            a = int(min(1.0, ink_strength(r, g, b)) * 255)
            mp[x, y] = (r, g, b, a)

    # 等比缩放到目标尺寸后居中放到透明画布上
    target = int(w * args.ratio)
    scale = target / float(max(mw, mh))
    new_size = (max(1, round(mw * scale)), max(1, round(mh * scale)))
    mark = mark.resize(new_size, Image.LANCZOS)

    canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    canvas.paste(mark, ((w - new_size[0]) // 2, (h - new_size[1]) // 2), mark)
    canvas.save(args.out)

    print(f"前景图已生成: {args.out}，图形占画布 {args.ratio:.0%} "
          f"(自适应图标安全区内)")


if __name__ == "__main__":
    main()
