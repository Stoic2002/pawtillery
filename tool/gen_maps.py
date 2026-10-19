#!/usr/bin/env python3
"""Generates the map PNGs under assets/maps/<id>/mask.png.

Alpha is the collision mask (255 = ground, 0 = empty); the red channel
carries the material when green is 200 (R = material * 16 + 8), see
lib/game/map_loader.dart. Every shape is original, built from simple
primitives into set pieces: islands with overhangs, caves and props that
are part of the terrain. Standard library only:

    python3 tool/gen_maps.py            # all maps
    python3 tool/gen_maps.py farm       # one map
"""
import math
import struct
import sys
import zlib
from pathlib import Path

W, H = 2400, 1200
WATER = 1120
ROOT = Path(__file__).resolve().parent.parent

# Material ids, matching TerrainMaterial in lib/config/maps.dart.
(SOIL, WOOD, LEAVES, STONE, METAL, CRATE, CONCRETE, HAY, ROOF, SAND, ROCK,
 ICE, SNOW) = range(13)


class Mask:
    """Ground pixels store material id + 1 (0 = empty)."""

    def __init__(self, base=SOIL):
        self.d = bytearray(W * H)
        self.base = base

    def _v(self, m):
        return (self.base if m is None else m) + 1

    def span(self, y, x0, x1, v):
        if y < 0 or y >= H:
            return
        x0, x1 = max(0, int(x0)), min(W, int(x1))
        if x1 > x0:
            row = y * W
            self.d[row + x0:row + x1] = bytes([v]) * (x1 - x0)

    def below(self, surface, m=None, x0=0, x1=W):
        """Ground from surface(x) down to the bottom."""
        v = self._v(m)
        for x in range(x0, x1):
            top = max(0, int(surface(x)))
            for y in range(top, H):
                self.d[y * W + x] = v

    def rect(self, x0, y0, x1, y1, m=None, carve=False):
        v = 0 if carve else self._v(m)
        for y in range(int(y0), int(y1)):
            self.span(y, x0, x1, v)

    def ellipse(self, cx, cy, rx, ry, m=None, carve=False):
        v = 0 if carve else self._v(m)
        for y in range(int(cy - ry), int(cy + ry) + 1):
            t = 1 - ((y - cy) / ry) ** 2
            if t < 0:
                continue
            half = rx * math.sqrt(t)
            self.span(y, cx - half, cx + half + 1, v)

    def poly(self, pts, m=None, carve=False):
        """Fills a polygon (scanline, even-odd)."""
        v = 0 if carve else self._v(m)
        ys = [p[1] for p in pts]
        for y in range(int(min(ys)), int(max(ys)) + 1):
            xs = []
            n = len(pts)
            for i in range(n):
                (xa, ya), (xb, yb) = pts[i], pts[(i + 1) % n]
                if (ya <= y < yb) or (yb <= y < ya):
                    xs.append(xa + (y - ya) * (xb - xa) / (yb - ya))
            xs.sort()
            for i in range(0, len(xs) - 1, 2):
                self.span(y, xs[i], xs[i + 1] + 1, v)

    def blob(self, cx, cy, r, m=None, carve=False, wobble=0.18, seed=1):
        """An organic rounded shape: a circle with a wavy edge."""
        pts = []
        for i in range(48):
            a = i / 48 * math.pi * 2
            k = 1 + wobble * (math.sin(a * 3 + seed) * 0.6 +
                              math.sin(a * 5 + seed * 2.3) * 0.4)
            pts.append((cx + math.cos(a) * r * k, cy + math.sin(a) * r * 0.8 * k))
        self.poly(pts, m=m, carve=carve)

    def recolor(self, x0, y0, x1, y1, frm, to):
        """Changes material frm to to inside a box (e.g. sand on rock)."""
        for y in range(max(0, int(y0)), min(H, int(y1))):
            row = y * W
            for x in range(max(0, int(x0)), min(W, int(x1))):
                if self.d[row + x] == frm + 1:
                    self.d[row + x] = to + 1

    def write(self, path):
        def chunk(tag, data):
            return (struct.pack('>I', len(data)) + tag + data +
                    struct.pack('>I', zlib.crc32(tag + data) & 0xFFFFFFFF))

        px = [b'\x00\x00\x00\x00'] + [
            bytes([m * 16 + 8, 200, 0, 255]) for m in range(16)]
        raw = bytearray()
        for y in range(H):
            raw += b'\x00'
            row = self.d[y * W:(y + 1) * W]
            raw += b''.join(px[v] for v in row)
        png = (b'\x89PNG\r\n\x1a\n' +
               chunk(b'IHDR', struct.pack('>IIBBBBB', W, H, 8, 6, 0, 0, 0)) +
               chunk(b'IDAT', zlib.compress(bytes(raw), 9)) +
               chunk(b'IEND', b''))
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(png)


def wave(x, *terms):
    return sum(a * math.sin(x / p + ph) for a, p, ph in terms)


def shores(x, y, left=120, right=2280):
    """Both map edges slope down into the water."""
    if x < left:
        y = max(y, y + (left - x) * 2.2)
    if x > right:
        y = max(y, y + (x - right) * 2.2)
    return y


# ------------------------------------------------------------------- farm

def farm():
    m = Mask(SOIL)

    def ground(x):
        y = 800 + wave(x, (45, 260, 0.3), (18, 90, 1.7))
        y -= 120 * math.exp(-((x - 1700) / 260) ** 2)  # orchard hill
        if 1070 <= x <= 1450:  # duck pond, a basin under the water line
            t = math.cos(math.pi * (x - 1260) / 190) * 0.5 + 0.5
            y += (1150 - y) * min(1, t * 1.25)
        return shores(x, y)

    m.below(ground)

    # Barn: thick plank walls, a hollow ground floor with a door each side,
    # a hay loft, a big pitched roof with eaves.
    bx0, bx1, floor = 430, 760, int(ground(595)) + 8
    m.rect(bx0, floor - 250, bx1, floor, m=WOOD)
    m.rect(bx0 + 22, floor - 120, bx1 - 22, floor - 4, carve=True)   # stalls
    m.rect(bx0 - 2, floor - 92, bx0 + 24, floor - 4, carve=True)     # door L
    m.rect(bx1 - 24, floor - 92, bx1 + 2, floor - 4, carve=True)     # door R
    m.rect(bx0 + 22, floor - 228, bx1 - 22, floor - 140, carve=True)  # loft
    m.rect(bx0 + 40, floor - 170, bx0 + 150, floor - 140, m=HAY)      # loft hay
    m.rect(bx0 + 120, floor - 60, bx0 + 210, floor - 4, m=HAY)        # bale
    m.poly([(bx0 - 40, floor - 248), ((bx0 + bx1) / 2, floor - 400),
            (bx1 + 40, floor - 248), (bx1 + 40, floor - 230),
            ((bx0 + bx1) / 2, floor - 378), (bx0 - 40, floor - 230)], m=ROOF)
    m.poly([(bx0 - 4, floor - 248), ((bx0 + bx1) / 2, floor - 380),
            (bx1 + 4, floor - 248)], m=WOOD)
    m.ellipse((bx0 + bx1) / 2, floor - 300, 26, 26, carve=True)      # window

    # Haystacks and a staircase of bales.
    m.blob(960, int(ground(960)) - 40, 85, m=HAY, wobble=0.08, seed=2)
    m.rect(870, int(ground(960)) - 20, 1050, int(ground(960)) + 30, m=HAY)
    for i, (x, h) in enumerate([(1040, 1), (1100, 2)]):
        top = int(ground(x)) + 6
        for k in range(h):
            m.rect(x, top - 52 * (k + 1), x + 70, top - 52 * k, m=HAY)

    # Fences either side of the pond (thin, breakable perches).
    for x0, x1 in ((240, 400), (1380, 1520)):
        y = int(ground(x0))
        for x in range(x0, x1, 40):
            m.rect(x, y - 70, x + 10, int(ground(x)) + 4, m=WOOD)
        m.rect(x0 - 6, y - 58, x1, y - 46, m=WOOD)

    # Orchard hill with a tunnel through it and an apple tree on top.
    m.ellipse(1700, 760, 120, 46, carve=True)
    m.rect(1590, 760, 1810, 800, carve=True)
    top = int(ground(1700))
    m.rect(1690, top - 150, 1712, top + 6, m=WOOD)
    m.blob(1700, top - 200, 110, m=LEAVES, wobble=0.12, seed=3)
    m.blob(1630, top - 160, 60, m=LEAVES, wobble=0.15, seed=5)

    # Rabbit burrows under the fields.
    m.blob(330, 960, 70, carve=True, wobble=0.2, seed=11)
    m.rect(330, 935, 720, 985, carve=True)
    m.blob(720, 960, 60, carve=True, wobble=0.2, seed=12)
    m.blob(1000, 1000, 80, carve=True, wobble=0.25, seed=13)
    m.blob(1950, 960, 90, carve=True, wobble=0.2, seed=14)

    # Water tower on stilts at the far right.
    tx = 2120
    tg = int(ground(tx))
    for lx in (tx - 70, tx + 58):
        m.rect(lx, tg - 230, lx + 12, tg + 6, m=WOOD)
    m.rect(tx - 76, tg - 120, tx + 76, tg - 108, m=WOOD)
    m.ellipse(tx, tg - 290, 100, 70, m=WOOD)
    m.rect(tx - 100, tg - 290, tx + 100, tg - 230, m=WOOD)
    m.poly([(tx - 112, tg - 340), (tx, tg - 420), (tx + 112, tg - 340)], m=ROOF)
    return m


# ------------------------------------------------------------------ coast

def coast():
    m = Mask(ROCK)

    # Left headland: a tall cliff that overhangs the sea, a sea cave.
    def headland(x):
        y = 520 + wave(x, (25, 120, 0.4), (10, 40, 1.1))
        y += max(0, x - 640) ** 1.4 * 0.08
        return shores(x, y)

    m.below(headland, x1=900)
    m.poly([(640, 560), (920, 600), (980, 660), (900, 700), (700, 720)])
    m.ellipse(760, 980, 150, 110, carve=True)          # sea cave
    m.rect(610, 1000, 910, 1200, carve=True)
    m.blob(330, 760, 120, carve=True, wobble=0.1, seed=4)  # inner grotto
    m.rect(300, 760, 360, 880, carve=True)

    # Lighthouse: striped stone tower, gallery, lamp room, cap.
    lx = 360
    lg = int(headland(lx))
    m.poly([(lx - 60, lg + 10), (lx - 42, lg - 330), (lx + 42, lg - 330),
            (lx + 60, lg + 10)], m=STONE)
    m.rect(lx - 26, lg - 300, lx + 26, lg - 40, carve=True)   # stairwell
    m.rect(lx - 62, lg - 70, lx - 30, lg - 4, carve=True)      # door
    m.rect(lx - 70, lg - 345, lx + 70, lg - 330, m=METAL)      # gallery
    m.rect(lx - 34, lg - 400, lx + 34, lg - 345, m=METAL)      # lamp room
    m.poly([(lx - 46, lg - 400), (lx, lg - 450), (lx + 46, lg - 400)], m=ROOF)

    # Sea stacks and a rock arch in the bay.
    m.blob(1080, 1010, 95, wobble=0.2, seed=7)
    m.poly([(1020, 1060), (1040, 880), (1090, 840), (1130, 870), (1150, 1060)])
    m.poly([(1240, 1200), (1270, 760), (1360, 700), (1480, 720), (1540, 800),
            (1560, 1200)])
    m.ellipse(1400, 1010, 80, 150, carve=True)         # the arch

    # Right: dunes down to a sandy beach, a pier and a beached boat.
    def dunes(x):
        y = 1130 - 0.6 * (x - 1700) + wave(x, (14, 70, 0.2), (6, 31, 1.4))
        return shores(x, max(y, 770))

    m.below(dunes, m=SAND, x0=1640)
    m.below(lambda x: dunes(x) + 60, m=ROCK, x0=1640)
    py = 1056
    m.rect(1560, py, 1800, py + 12, m=WOOD)                  # pier deck
    for x in range(1570, 1790, 46):
        m.rect(x, py + 12, x + 10, 1200, m=WOOD)
    bg = int(dunes(1970))
    m.poly([(1890, bg - 50), (2050, bg - 50), (2020, bg + 10), (1910, bg + 10)],
           m=WOOD)                                            # beached boat
    m.rect(1966, bg - 150, 1976, bg - 50, m=WOOD)             # mast
    m.poly([(1978, bg - 146), (1978, bg - 58), (2050, bg - 58)], m=SNOW)  # sail
    # Beach hut on the dune crest.
    hx = 2200
    hg = int(dunes(hx))
    m.rect(hx - 60, hg - 110, hx + 60, hg + 6, m=WOOD)
    m.rect(hx - 40, hg - 80, hx + 10, hg + 2, carve=True)
    m.poly([(hx - 80, hg - 108), (hx, hg - 170), (hx + 80, hg - 108)], m=ROOF)
    return m


# ------------------------------------------------------------------- snow

def snow():
    m = Mask(ROCK)

    def mountain(x):
        y = 860 + wave(x, (30, 140, 0.5), (12, 47, 2.0))
        y -= 430 * math.exp(-((x - 1220) / 230) ** 2)     # peak
        y -= 160 * math.exp(-((x - 860) / 160) ** 2)      # shoulder
        if 1700 <= x <= 2000:                              # frozen lake
            y = max(y, 1150)
        return shores(x, y)

    m.below(mountain, x1=1700)
    m.below(mountain, x0=2000)

    # Tunnel through the peak and an ice cave with a ledge.
    m.ellipse(1220, 820, 210, 55, carve=True)
    m.rect(1000, 820, 1440, 870, carve=True)
    m.blob(1330, 640, 70, carve=True, wobble=0.15, seed=9)
    m.rect(1280, 680, 1380, 694, m=ICE)

    # Caverns in the mountain's roots.
    m.blob(560, 1010, 90, carve=True, wobble=0.22, seed=15)
    m.blob(900, 1030, 70, carve=True, wobble=0.2, seed=16)
    m.rect(560, 1000, 900, 1040, carve=True)

    # Overhanging cornice on the peak's right face.
    m.poly([(1300, 480), (1480, 520), (1500, 560), (1400, 560), (1320, 540)],
           m=SNOW)

    # Frozen lake: a breakable ice sheet over the water.
    m.rect(1690, 1086, 2010, 1104, m=ICE)
    m.blob(1850, 1060, 40, m=SNOW, wobble=0.1, seed=3)

    # Log cabin on the left with a stone chimney and a porch.
    cx0, cx1 = 260, 520
    cg = int(mountain(390)) + 6
    m.rect(cx0, cg - 150, cx1, cg, m=WOOD)
    m.rect(cx0 + 22, cg - 110, cx1 - 22, cg - 4, carve=True)
    m.rect(cx1 - 24, cg - 80, cx1 + 2, cg - 4, carve=True)
    m.rect(cx0 + 60, cg - 92, cx0 + 110, cg - 4, m=WOOD)        # table
    m.rect(cx0 + 160, cg - 220, cx0 + 200, cg - 150, m=STONE)   # chimney
    m.poly([(cx0 - 40, cg - 148), ((cx0 + cx1) / 2, cg - 250),
            (cx1 + 40, cg - 148)], m=ROOF)
    m.rect(cx1, cg - 6, cx1 + 90, cg + 6, m=WOOD)               # porch

    # Pines: trunks and three tiers each.
    for px, s in ((680, 1.0), (760, 0.75), (1560, 0.9), (2160, 1.1),
                  (2260, 0.8)):
        g = int(mountain(px))
        m.rect(px - 8 * s, g - 60 * s, px + 8 * s, g + 6, m=WOOD)
        for k in range(3):
            base = g - 40 * s - k * 52 * s
            half = (78 - k * 18) * s
            m.poly([(px - half, base), (px, base - 92 * s), (px + half, base)],
                   m=LEAVES)

    # A floating ice floe over the lake.
    m.blob(1850, 880, 60, m=ICE, wobble=0.12, seed=6)
    return m


MAPS = {'farm': farm, 'coast': coast, 'snow': snow}

if __name__ == '__main__':
    for name in sys.argv[1:] or MAPS:
        out = ROOT / 'assets' / 'maps' / name / 'mask.png'
        MAPS[name]().write(out)
        print(f'wrote {out} ({out.stat().st_size} bytes)')
