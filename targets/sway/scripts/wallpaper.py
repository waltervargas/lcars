#!/usr/bin/env python3
"""Generate the LCARS wallpaper. Usage: wallpaper.py OUTPUT.png"""
import sys

from PIL import Image, ImageDraw, ImageFont

W, H, SS = 2560, 1440, 2  # final size and supersampling factor
ORANGE, PEACH, LAVENDER, VIOLET = "#FF9900", "#FFCC99", "#CC99CC", "#9977AA"
BLUE, RUST, BLACK = "#9999FF", "#CC6633", "#000000"
FONT = "/usr/share/fonts/truetype/liberation/LiberationSansNarrow-Bold.ttf"

img = Image.new("RGB", (W * SS, H * SS), BLACK)
d = ImageDraw.Draw(img)


def s(*values):
    return [v * SS for v in values]


def font(size):
    return ImageFont.truetype(FONT, size * SS)


def label(x, y, text, size=24, fill=BLACK, anchor="rs"):
    d.text(s(x, y), text, font=font(size), fill=fill, anchor=anchor)


MARGIN, SIDE, BAR, GAP = 36, 210, 46, 7
LEFT, RIGHT = MARGIN, W - MARGIN
TOP, BOTTOM = MARGIN, H - 64  # stays clear of the 28px swaybar
INNER_X = LEFT + SIDE


def elbow(y0, y1, top):
    """Curved join between the sidebar and a horizontal bar."""
    outer, inner = 90, 34
    bar_top = y0 if top else y1 - BAR
    d.rectangle(s(LEFT, y0, INNER_X + 150, y1), fill=ORANGE)
    # Round the outer corner by cutting it back to black.
    corner_y = y0 if top else y1 - 2 * outer
    d.rectangle(s(LEFT, corner_y if top else y1 - outer,
                  LEFT + outer, (y0 + outer) if top else y1), fill=BLACK)
    d.pieslice(s(LEFT, corner_y, LEFT + 2 * outer, corner_y + 2 * outer),
               180 if top else 90, 270 if top else 180, fill=ORANGE)
    # Cut the inner curve.
    cut_y0 = y0 + BAR if top else y0 - 200
    cut_y1 = y1 + 200 if top else y1 - BAR
    d.rounded_rectangle(s(INNER_X, cut_y0, W + 400, cut_y1), radius=inner * SS, fill=BLACK)
    return bar_top


def bar_segments(y, x0, segments):
    """Horizontal bar split into coloured segments, with a rounded right cap."""
    x = x0
    for i, (width, color) in enumerate(segments):
        end = RIGHT if i == len(segments) - 1 else x + width
        d.rectangle(s(x + GAP, y, end - BAR // 2 if end == RIGHT else end, y + BAR), fill=color)
        if end == RIGHT:
            d.ellipse(s(RIGHT - BAR, y, RIGHT, y + BAR), fill=color)
        x = end


def sidebar(y0, y1, segments):
    """Vertical stack of coloured blocks with reference numbers."""
    total = sum(h for h, _, _ in segments)
    y = y0
    for height, color, code in segments:
        h = (y1 - y0) * height / total
        d.rectangle(s(LEFT, y + GAP, INNER_X, y + h), fill=color)
        label(INNER_X - 12, y + h - 10, code)
        y += h


ELBOW_H = 150

# Upper panel: a short frame holding the title.
split = 300
elbow(TOP, TOP + ELBOW_H, top=True)
bar_segments(TOP, INNER_X + 150, [(420, PEACH), (160, RUST), (900, VIOLET), (0, LAVENDER)])
elbow(split - ELBOW_H, split, top=False)
bar_segments(split - BAR, INNER_X + 150, [(260, LAVENDER), (640, ORANGE), (120, BLUE), (0, PEACH)])
label(RIGHT, TOP + BAR + 92, "LCARS", size=96, fill=ORANGE)
label(RIGHT - 300, TOP + BAR + 88, "LIBRARY COMPUTER ACCESS", size=30, fill=PEACH)

# Main panel: the area windows normally cover.
main_top = split + 12
elbow(main_top, main_top + ELBOW_H, top=True)
bar_segments(main_top, INNER_X + 150, [(180, BLUE), (720, PEACH), (90, RUST), (0, ORANGE)])
elbow(BOTTOM - ELBOW_H, BOTTOM, top=False)
bar_segments(BOTTOM - BAR, INNER_X + 150, [(300, VIOLET), (140, ORANGE), (800, LAVENDER), (0, BLUE)])
sidebar(main_top + ELBOW_H, BOTTOM - ELBOW_H, [
    (3, LAVENDER, "04-2261"),
    (2, BLUE, "19-0871"),
    (5, PEACH, "07-3345"),
    (1, RUST, "62-7719"),
    (4, VIOLET, "28-1150"),
])

img = img.resize((W, H), Image.LANCZOS)
img.save(sys.argv[1])
