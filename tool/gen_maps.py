#!/usr/bin/env python3
"""Generates the map masks under assets/maps/<id>/mask.png.

Only alpha matters: 255 = ground, 0 = empty. All shapes are original and
built from simple primitives. Standard library only:

    python3 tool/gen_maps.py            # all maps
    python3 tool/gen_maps.py park       # one map
"""
import math
import struct
import sys
import zlib
from pathlib import Path

W, H = 2400, 1200
ROOT = Path(__file__).resolve().parent.parent


class Mask:
    def __init__(self):
        self.d = bytearray(W * H)

    def column(self, x, y0, y1, v=1):
        y0, y1 = max(0, int(y0)), min(H, int(y1))
        for y in range(y0, y1):
            self.d[y * W + x] = v

    def below(self, surface):
        """Ground from surface(x) down to the bottom."""
        for x in range(W):
            self.column(x, surface(x), H)

    def rect(self, x0, y0, x1, y1, v=1):
        for y in range(max(0, y0), min(H, y1)):
            row = y * W
            self.d[row + max(0, x0):row + min(W, x1)] = bytes([v]) * (
                min(W, x1) - max(0, x0))

    def ellipse(self, cx, cy, rx, ry, v=1):
        for y in range(max(0, cy - ry), min(H, cy + ry + 1)):
            t = 1 - ((y - cy) / ry) ** 2
            if t < 0:
                continue
            half = int(rx * math.sqrt(t))
            self.rect(cx - half, y, cx + half + 1, y + 1, v)

    def triangle(self, x0, x1, base_y, apex_y):
        """Isosceles roof from (x0..x1, base_y) up to apex_y."""
        mid = (x0 + x1) / 2
        for y in range(apex_y, base_y):
            f = (y - apex_y) / (base_y - apex_y)
            half = (x1 - x0) / 2 * f
            self.rect(int(mid - half), y, int(mid + half) + 1, y + 1)

    def write(self, path):
        def chunk(tag, data):
            return (struct.pack('>I', len(data)) + tag + data +
                    struct.pack('>I', zlib.crc32(tag + data) & 0xFFFFFFFF))

        ground = b'\x80\x80\x80\xff'
        empty = b'\x00\x00\x00\x00'
        raw = bytearray()
        for y in range(H):
            raw += b'\x00'
            row = self.d[y * W:(y + 1) * W]
            raw += b''.join(ground if v else empty for v in row)
        png = (b'\x89PNG\r\n\x1a\n' +
               chunk(b'IHDR', struct.pack('>IIBBBBB', W, H, 8, 6, 0, 0, 0)) +
               chunk(b'IDAT', zlib.compress(bytes(raw), 9)) +
               chunk(b'IEND', b''))
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(png)


def edges(x, y):
    """Drop both map edges into the water."""
    if x < 110 or x > 2290:
        return max(y, 1150)
    return y


def backyard():
    m = Mask()
    m.below(lambda x: edges(x, 760 + 60 * math.sin(x / 310) +
                             25 * math.sin(x / 83 + 0.7)))
    # Doghouse: box, pointed roof, round door.
    base = 760 + 60 * math.sin(680 / 310) + 25 * math.sin(680 / 83 + 0.7)
    floor = int(base) + 10
    m.rect(600, floor - 110, 760, floor)
    m.triangle(585, 775, floor - 110, floor - 175)
    m.ellipse(680, floor - 30, 28, 38, v=0)
    # Garden table: top and two legs.
    m.rect(1480, 560, 1760, 578)
    m.rect(1500, 578, 1516, 760)
    m.rect(1724, 578, 1740, 760)
    # Fence posts on the left.
    for x in range(200, 460, 52):
        m.rect(x, 610, x + 14, 800)
    m.rect(200, 640, 460, 652)
    # Flower mound on the right.
    m.ellipse(2050, 760, 150, 70)
    return m


def park():
    m = Mask()

    def surface(x):
        y = 820 - 220 * math.exp(-((x - 1050) / 330) ** 2)
        y += 20 * math.sin(x / 70)
        if 1560 <= x <= 1880:  # pond basin, dips under the water line
            y = max(y, 1135 - 0.0006 * (x - 1720) ** 2 * 20)
        return edges(x, y)

    m.below(surface)
    # Trees: trunk plus crown.
    for tx, crown_y in ((380, 520), (1050, 330), (2080, 560)):
        top = int(surface(tx))
        m.rect(tx - 9, crown_y, tx + 9, top + 5)
        m.ellipse(tx, crown_y, 95, 60)
    # Bench.
    m.rect(1300, 720, 1460, 734)
    m.rect(1312, 734, 1324, 800)
    m.rect(1436, 734, 1448, 800)
    return m


def warehouse():
    m = Mask()
    m.below(lambda x: edges(x, 920))
    # Crate stacks (each crate 110 px).
    for x, n in ((260, 2), (700, 1), (980, 3), (1560, 2), (2000, 1)):
        for k in range(n):
            m.rect(x, 920 - 110 * (k + 1) + 2, x + 110, 920 - 110 * k)
    # Shelves with posts.
    m.rect(1150, 560, 1500, 574)
    m.rect(1160, 574, 1174, 920)
    m.rect(1476, 574, 1490, 920)
    m.rect(1150, 740, 1500, 752)
    m.rect(400, 470, 640, 482)
    # Barrels.
    for cx in (1750, 1830, 2180):
        m.ellipse(cx, 870, 40, 50)
    # Hanging beam.
    m.rect(1700, 380, 2150, 396)
    return m


MAPS = {'backyard': backyard, 'park': park, 'warehouse': warehouse}

if __name__ == '__main__':
    for name in sys.argv[1:] or MAPS:
        out = ROOT / 'assets' / 'maps' / name / 'mask.png'
        MAPS[name]().write(out)
        print(f'wrote {out} ({out.stat().st_size} bytes)')
