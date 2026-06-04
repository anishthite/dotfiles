#!/usr/bin/env python3
"""Minimal pixel-art ghost sprites."""
from PIL import Image
from pathlib import Path

OUT = Path(__file__).parent

# 10x9 grid. Solid body, 2-pixel eyes. Two leg frames.
BODY = [
    "...####...",
    "..######..",
    ".########.",
    "##########",
    "##########",
    "##########",
    "##########",
    "##########",
]
LEGS_A = ["#.##.##.#."]
LEGS_B = ".##.##.##."

MOODS = {
    "idle":        (205, 214, 244),
    "happy":       (249, 226, 175),
    "caffeinated": (250, 179, 135),
    "sleepy":      (137, 143, 168),
    "panic":       (243, 139, 168),
    "vibe":        (203, 166, 247),
    "lonely":      (116, 199, 236),
}
PUPIL = (24, 24, 37, 255)
ACCENT = (249, 226, 175, 255)


def eyes(mood, frame):
    """Return list of (x, y, color) pixels for eyes/accent."""
    pts = []
    if mood == "sleepy":
        # closed lines
        pts += [(2, 4, PUPIL), (3, 4, PUPIL), (6, 4, PUPIL), (7, 4, PUPIL)]
        return pts
    if mood == "happy":
        # arcs ^ ^
        pts += [(2, 5, PUPIL), (3, 4, PUPIL), (4, 5, PUPIL)]
        pts += [(5, 5, PUPIL), (6, 4, PUPIL), (7, 5, PUPIL)]
        return pts
    if mood == "panic":
        # X eyes
        pts += [(2, 3, PUPIL), (4, 3, PUPIL), (3, 4, PUPIL), (2, 5, PUPIL), (4, 5, PUPIL)]
        pts += [(5, 3, PUPIL), (7, 3, PUPIL), (6, 4, PUPIL), (5, 5, PUPIL), (7, 5, PUPIL)]
        return pts
    if mood == "caffeinated":
        off = 0 if frame == 0 else 1
        pts += [(2 + off, 4, PUPIL), (2 + off, 5, PUPIL)]
        pts += [(6 + off, 4, PUPIL), (6 + off, 5, PUPIL)]
        return pts
    if mood == "vibe":
        pts += [(3, 4, PUPIL), (7, 4, PUPIL)]
        # little note bob
        if frame == 0:
            pts += [(9, 1, ACCENT), (9, 2, ACCENT)]
        else:
            pts += [(9, 0, ACCENT), (9, 1, ACCENT)]
        return pts
    if mood == "lonely":
        pts += [(3, 5, PUPIL), (7, 5, PUPIL)]
        pts += [(3, 6, (137, 180, 250, 255))]  # tear
        return pts
    # idle: pupils shift between frames
    if frame == 0:
        pts += [(3, 4, PUPIL), (7, 4, PUPIL)]
    else:
        pts += [(2, 4, PUPIL), (6, 4, PUPIL)]
    return pts


def build(mood, frame):
    color = MOODS[mood]
    alpha = 180 if mood == "sleepy" else 255
    body_c = (*color, alpha)

    W, H = 10, 9
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = img.load()

    rows = list(BODY) + [LEGS_A[0] if frame == 0 else LEGS_B]
    rows = rows[:H]

    for y, row in enumerate(rows):
        for x, ch in enumerate(row[:W]):
            if ch == "#":
                px[x, y] = body_c

    for (x, y, c) in eyes(mood, frame):
        if 0 <= x < W and 0 <= y < H:
            px[x, y] = c

    img = img.resize((W * 4, H * 4), Image.NEAREST)
    img.save(OUT / f"{mood}_{frame}.png")


def main():
    for mood in MOODS:
        for frame in (0, 1):
            build(mood, frame)
    print("generated", len(MOODS) * 2, "sprites")


if __name__ == "__main__":
    main()
