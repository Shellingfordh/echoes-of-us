"""从 art/ui_texture.png 裁出各处 UI 用的九宫格面板贴图。

UI 尺寸都是按 1280x720 逻辑分辨率定的，所以贴图直接按逻辑尺寸导出。
每张图都带圆角 alpha 和淡黄色描边，配合 StyleBoxTexture 的
texture_margin = 24 做九宫格，中间可平铺、边框不会被拉花。

改完贴图重新跑一次即可：python tools/build_ui_panels.py
"""

import os

from PIL import Image, ImageDraw, ImageEnhance

ART = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "art")
SRC = os.path.join(ART, "ui_texture.png")
OUT = os.path.join(ART, "ui")

# 淡黄色描边，取自素材本身的暖色调，不会和纸纹打架。
BORDER = (240, 222, 160)
ACCENT = (226, 178, 77)

# ui_texture 是左上暗、右下亮的暖色渐变，按需要取不同亮度的区域。
LIGHT = (1024, 640, 2048, 1152)
MID = (512, 384, 1536, 896)
DARK = (0, 0, 1024, 512)


def panel(
    name: str,
    size: tuple,
    src_rect: tuple,
    alpha: int,
    brightness: float = 1.0,
    radius: int = 14,
    border: int = 3,
    border_alpha: int = 210,
    left_accent: int = 0,
) -> None:
    base = Image.open(SRC).convert("RGB").crop(src_rect).resize(size, Image.LANCZOS)
    if brightness != 1.0:
        base = ImageEnhance.Brightness(base).enhance(brightness)
    img = base.convert("RGBA")
    w, h = size

    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, w - 1, h - 1], radius=radius, fill=alpha)
    img.putalpha(mask)

    draw = ImageDraw.Draw(img)
    if border > 0:
        inset = border / 2.0
        draw.rounded_rectangle(
            [inset, inset, w - 1 - inset, h - 1 - inset],
            radius=radius,
            outline=BORDER + (border_alpha,),
            width=border,
        )
    if left_accent > 0:
        draw.rectangle([0, radius // 2, left_accent - 1, h - 1 - radius // 2], fill=ACCENT + (235,))

    img.save(os.path.join(OUT, name))
    print("wrote %s %s" % (name, size))


def main() -> None:
    os.makedirs(OUT, exist_ok=True)

    # 对话框：最亮的纸纹，配深色字。
    panel("dialogue_panel.png", (1152, 232), LIGHT, alpha=248, brightness=1.04, radius=16, border=3)

    # 独白框：同一张纸压暗一点，描边更淡，弱化存在感。
    panel("monologue_panel.png", (900, 124), MID, alpha=232, brightness=1.02, radius=12,
          border=2, border_alpha=140)

    # 交互提示：暗色区 + 半透明，浮在场景上仍然醒目，配浅色粗黑体。
    # 提示必须单行不换行，宽度按 22px simhei 实测最长文案定：
    # 第一章最长 517px、第二章最长 748px，加左右各 18px 内边距 → 820。
    # 九宫格会横向平铺，实际显示宽度由各场景的 offset 决定。
    panel("hint_panel.png", (820, 56), DARK, alpha=198, brightness=0.92, radius=9,
          border=2, border_alpha=225)

    # 关卡目标 / 章节标题 / 进度：中间调小牌子，左侧一条金边。
    # 关卡目标现在是「标题 + 描述」两段，牌子要够高放三行。
    panel("plaque_panel.png", (300, 132), MID, alpha=214, radius=10, border=2,
          border_alpha=170, left_accent=5)

    # 物件观察卡：整块纸，几乎不透明。
    panel("observation_card.png", (660, 470), LIGHT, alpha=252, brightness=1.06, radius=14, border=3)


if __name__ == "__main__":
    main()
