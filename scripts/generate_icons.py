"""Generates the Vocab app icon at the three sizes iOS needs, using Pillow
and the system Helvetica Bold font. No external assets or network access
required. Design verified visually during planning: lavender-to-purple
gradient background, white bold 'Vocab' wordmark, white underline accent.
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

TOP_COLOR = (161, 119, 240)     # #a177f0
BOTTOM_COLOR = (107, 47, 179)   # #6b2fb3
HELVETICA_BOLD = ("/System/Library/Fonts/Helvetica.ttc", 1)

SIZES = [180, 192, 512]


def render_icon(size):
    img = Image.new("RGB", (size, size), "#ffffff")
    draw = ImageDraw.Draw(img)

    for y in range(size):
        t = y / size
        r = int(TOP_COLOR[0] + (BOTTOM_COLOR[0] - TOP_COLOR[0]) * t)
        g = int(TOP_COLOR[1] + (BOTTOM_COLOR[1] - TOP_COLOR[1]) * t)
        b = int(TOP_COLOR[2] + (BOTTOM_COLOR[2] - TOP_COLOR[2]) * t)
        draw.line([(0, y), (size, y)], fill=(r, g, b))

    font_size = int(size * 0.215)
    font = ImageFont.truetype(HELVETICA_BOLD[0], font_size, index=HELVETICA_BOLD[1])
    text = "Vocab"
    bbox = draw.textbbox((0, 0), text, font=font)
    w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
    x = (size - w) / 2 - bbox[0]
    y = (size - h) / 2 - bbox[1] - size * 0.04
    draw.text((x, y), text, font=font, fill="white")

    underline_width = w  # span the whole word
    underline_y = y + h + size * 0.05
    underline_height = max(2, size * 0.016)
    draw.rounded_rectangle(
        [size / 2 - underline_width / 2, underline_y, size / 2 + underline_width / 2, underline_y + underline_height],
        radius=underline_height / 2,
        fill="white",
    )
    return img


def main():
    icons_dir = Path(__file__).parent.parent / "App" / "icons"
    icons_dir.mkdir(parents=True, exist_ok=True)
    for size in SIZES:
        img = render_icon(size)
        out_path = icons_dir / f"icon-{size}.png"
        img.save(out_path)
        print(f"Wrote {out_path} ({size}x{size})")


if __name__ == "__main__":
    main()
