#!/usr/bin/env python3
"""Generates the map PNGs under assets/maps/<id>/mask.png.

Alpha is the collision mask (255 = ground, 0 = empty); the red channel
carries the material when green is 200 (R = material * 16 + 8), see
lib/game/map_loader.dart. Every shape is original, built from simple
primitives into set pieces: islands with overhangs, caves and props that
are part of the terrain. Standard library only:

    python3 tool/gen_maps.py            # all maps
    python3 tool/gen_maps.py castle     # one map
"""
import math
import random
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


def crenels(m, x0, x1, top, mat=STONE, w=22, h=26):
    """Battlements along a wall top: merlons with gaps."""
    x = x0
    while x + w <= x1:
        m.rect(x, top - h, x + w, top, m=mat)
        x += w * 2


def broken_top(m, x0, x1, base, top, mat, seed, drop=70):
    """A wall whose top edge is smashed into a jagged line."""
    rng = random.Random(seed)
    pts = [(x0, base)]
    x = x0
    while x < x1:
        pts.append((x, top + rng.randint(0, drop)))
        x += rng.randint(14, 34)
    pts += [(x1, top + rng.randint(0, drop)), (x1, base)]
    m.poly(pts, m=mat)


def tombstone(m, x, ground, h, w=34):
    m.rect(x - w // 2, ground - h, x + w // 2, ground + 6, m=STONE)
    m.ellipse(x, ground - h, w // 2, w // 2 - 2, m=STONE)


def dead_tree(m, x, ground, h, seed):
    """A bare trunk with a few crooked branches (thin, breakable)."""
    rng = random.Random(seed)
    m.poly([(x - 14, ground + 6), (x - 6, ground - h), (x + 6, ground - h),
            (x + 14, ground + 6)], m=WOOD)
    for k in range(4):
        y = ground - h * (0.45 + k * 0.15)
        side = -1 if k % 2 else 1
        length = rng.randint(50, 90) * (1 - k * 0.15)
        m.poly([(x, y), (x + side * length, y - length * 0.6),
                (x + side * (length + 6), y - length * 0.6 + 8),
                (x, y + 12)], m=WOOD)


# ----------------------------------------------------------------- castle

def castle():
    m = Mask(SOIL)

    def hills(x):
        y = 860 + wave(x, (30, 170, 0.3), (12, 53, 1.9))
        if 1520 <= x <= 1660:  # moat ravine below the water line
            t = math.cos(math.pi * (x - 1590) / 70) * 0.5 + 0.5
            y += (1160 - y) * t
        return shores(x, y)

    m.below(hills)

    # The crag the castle stands on: flat-topped rock.
    def crag(x):
        return 1200 - 640 * math.exp(-((x - 1100) / 360) ** 4) + wave(
            x, (8, 41, 0.5))

    m.below(crag, m=ROCK, x0=640, x1=1530)

    top = 560
    # Curtain wall with battlements and a gate arch.
    m.rect(820, 450, 1390, top + 10, m=STONE)
    crenels(m, 820, 1390, 450)
    m.rect(925, 486, 985, top + 2, carve=True)
    m.ellipse(955, 488, 30, 26, carve=True)
    # Towers with conical roofs.
    for x0, x1, t, apex in ((790, 900, 300, 210), (1300, 1410, 260, 160)):
        m.rect(x0, t, x1, top + 10, m=STONE)
        crenels(m, x0 - 6, x1 + 6, t, w=18, h=20)
        m.poly([(x0 - 16, t - 18), ((x0 + x1) / 2, apex), (x1 + 16, t - 18)],
               m=ROOF)
        m.rect(x0 + 32, t + 50, x1 - 32, t + 90, carve=True)  # arrow slit
    # The keep: two hollow floors.
    m.rect(1000, 330, 1210, top + 10, m=STONE)
    crenels(m, 994, 1216, 330)
    m.rect(1022, 350, 1188, 440, carve=True)
    m.rect(1022, 456, 1188, top - 4, carve=True)
    m.ellipse(1105, 400, 22, 30, carve=True)
    # Dungeon under the crag.
    m.rect(920, 712, 1280, 742, carve=True)
    for cx in (930, 1100, 1270):
        m.blob(cx, 724, 36, carve=True, wobble=0.15, seed=cx)
    # Broken drawbridge over the moat.
    m.rect(1410, 548, 1545, 562, m=WOOD)

    # Graveyard on the right hill: tombstones, a crypt, a dead tree.
    for x, h in ((1740, 50), (1800, 64), (1870, 46), (2060, 58), (2130, 44)):
        tombstone(m, x, int(hills(x)), h)
    cg = int(hills(1960)) + 6
    m.rect(1910, cg - 120, 2010, cg, m=STONE)
    m.rect(1932, cg - 90, 1988, cg - 4, carve=True)
    m.poly([(1896, cg - 118), (1960, cg - 170), (2024, cg - 118)], m=ROOF)
    dead_tree(m, 2200, int(hills(2200)), 220, seed=4)

    # Left: a ruined watchtower and a dead tree.
    lg = int(hills(330))
    broken_top(m, 280, 390, lg + 6, lg - 230, STONE, seed=7, drop=90)
    m.rect(306, lg - 150, 364, lg + 2, carve=True)
    dead_tree(m, 560, int(hills(560)), 180, seed=9)
    m.blob(470, 1000, 80, carve=True, wobble=0.2, seed=21)  # burrow
    return m


# ------------------------------------------------------------------ wreck

def wreck():
    m = Mask(ROCK)

    # Left headland with a sea cave and a broken lighthouse.
    def headland(x):
        y = 600 + wave(x, (22, 110, 0.4), (9, 37, 1.3))
        y += max(0, x - 520) ** 1.35 * 0.12
        return shores(x, y)

    m.below(headland, x1=760)
    m.ellipse(640, 1010, 110, 100, carve=True)
    m.rect(560, 1020, 760, 1200, carve=True)
    lx = 300
    lg = int(headland(lx))
    broken_top(m, lx - 55, lx + 55, lg + 8, lg - 300, STONE, seed=3, drop=110)
    m.rect(lx - 26, lg - 220, lx + 26, lg - 30, carve=True)
    m.rect(lx - 60, lg - 70, lx - 28, lg - 2, carve=True)

    # Sandbar the wreck lies on.
    m.below(lambda x: 1135 - 60 * math.exp(-((x - 1230) / 300) ** 2),
            m=SAND, x0=780, x1=1700)

    # Bow half: a hull curving up to the prow, hollow with a deck.
    bow = [(800, 830), (860, 880), (1170, 880), (1170, 1080), (990, 1100),
           (880, 1060), (830, 960)]
    m.poly(bow, m=WOOD)
    m.poly([(886, 902), (1146, 902), (1146, 956), (880, 956)], carve=True)
    for wx in (920, 1000, 1080):                  # gun ports
        m.rect(wx, 990, wx + 22, 1010, carve=True)
    m.poly([(980, 880), (996, 880), (1050, 600), (1036, 598)], m=WOOD)  # mast
    m.rect(1010, 660, 1080, 672, m=WOOD)          # crow's nest

    # Stern half, tilted, with a raised stern castle and cabin windows.
    stern = [(1290, 1090), (1300, 900), (1520, 870), (1540, 760), (1700, 740),
             (1700, 1010), (1560, 1080)]
    m.poly(stern, m=WOOD)
    m.poly([(1326, 922), (1518, 896), (1544, 802), (1680, 788), (1680, 930),
            (1326, 972)], carve=True)
    for wx in (1580, 1630):
        m.rect(wx, 800, wx + 22, 830, carve=True)
    m.rect(1400, 700, 1414, 900, m=WOOD)          # broken mast stub

    # Right island: rocks, a sandy beach and a lookout shack on stilts.
    def island(x):
        y = 1150 - 0.55 * (x - 1700) + wave(x, (12, 60, 0.7))
        return shores(x, max(y, 730))

    m.below(island, x0=1700)
    m.recolor(1700, 700, 1980, 1200, ROCK, SAND)
    sx = 2140
    sg = int(island(sx))
    for px in (sx - 80, sx + 60):
        m.rect(px, sg - 120, px + 12, sg + 6, m=WOOD)
    m.rect(sx - 96, sg - 230, sx + 86, sg - 120, m=WOOD)
    m.rect(sx - 74, sg - 210, sx + 64, sg - 132, carve=True)
    m.poly([(sx - 116, sg - 226), (sx - 5, sg - 290), (sx + 106, sg - 226)],
           m=ROOF)
    return m


# ------------------------------------------------------------------ ruins

def ruins():
    m = Mask(SOIL)

    def ground(x):
        y = 840 + wave(x, (26, 150, 1.1), (10, 47, 0.2))
        if 1040 <= x <= 1360:  # flooded bomb crater
            t = math.cos(math.pi * (x - 1200) / 160) * 0.5 + 0.5
            y += (1160 - y) * min(1, t * 1.3)
        return shores(x, y)

    m.below(ground)

    # Bombed church: nave walls with a broken roofline, a cracked spire.
    g = int(ground(380)) + 8
    broken_top(m, 220, 520, g, g - 230, STONE, seed=11, drop=80)
    m.rect(246, g - 160, 494, g - 4, carve=True)
    for wx in (290, 380, 450):
        m.rect(wx, g - 140, wx + 30, g - 90, carve=True)
        m.ellipse(wx + 15, g - 140, 15, 15, carve=True)
    m.rect(250, g - 60, 330, g - 4, m=WOOD)                   # pews
    broken_top(m, 520, 600, g, g - 420, STONE, seed=12, drop=60)
    m.rect(540, g - 330, 580, g - 260, carve=True)

    # Houses with smashed walls, floors and half roofs.
    for x0, x1, seed in ((760, 960, 21), (1480, 1720, 22), (1960, 2200, 23)):
        hg = int(ground((x0 + x1) / 2)) + 8
        broken_top(m, x0, x1, hg, hg - 214, STONE, seed=seed, drop=40)
        m.rect(x0 + 26, hg - 150, x1 - 26, hg - 4, carve=True)
        m.rect(x0 + 20, hg - 96, x1 - 20, hg - 84, m=WOOD)     # floor
        m.rect(x0 + 50, hg - 150, x0 + 86, hg - 112, carve=True)
        m.poly([(x0 - 20, hg - 196), (x0 + (x1 - x0) * 0.45, hg - 290),
                (x0 + (x1 - x0) * 0.55, hg - 250), (x0 + 30, hg - 196)],
               m=ROOF)

    # Sandbag barricades and rubble.
    for x, n in ((1000, 3), (1420, 2)):
        sg = int(ground(x)) + 4
        for row in range(n):
            for k in range(n - row):
                m.ellipse(x + k * 40 + row * 20, sg - 14 - row * 24, 22, 14,
                          m=SAND)
    for x in (680, 1820, 2280):
        m.blob(x, int(ground(x)) - 10, 34, m=ROCK, wobble=0.3, seed=x)
    # A toppled water tank in the crater.
    m.ellipse(1200, 1080, 70, 40, m=METAL)
    m.blob(600, 1010, 70, carve=True, wobble=0.2, seed=31)       # cellar
    m.rect(600, 990, 860, 1030, carve=True)
    return m


MAPS = {'castle': castle, 'wreck': wreck, 'ruins': ruins}

if __name__ == '__main__':
    for name in sys.argv[1:] or MAPS:
        out = ROOT / 'assets' / 'maps' / name / 'mask.png'
        MAPS[name]().write(out)
        print(f'wrote {out} ({out.stat().st_size} bytes)')
