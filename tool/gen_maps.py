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
 ICE, SNOW, TOY, CAN) = range(15)


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


def settle(m, x0, x1, y0, y1, mats, fill, max_gap=70):
    """Grounds a structure so it never hovers: in each column of the box,
    under the lowest pixel made of one of `mats`, fills the air down to
    the ground with `fill` (a footing, a mound of sand...). Columns where
    the ground is further than `max_gap` are left alone: those are real
    overhangs (a ship's prow, eaves, a drawbridge)."""
    vals = {v + 1 for v in mats}
    for x in range(max(0, int(x0)), min(W, int(x1))):
        low = None
        for y in range(min(H - 1, int(y1)), max(0, int(y0)) - 1, -1):
            if m.d[y * W + x] in vals:
                low = y
                break
        if low is None:
            continue
        gap = 0
        while low + 1 + gap < H and m.d[(low + 1 + gap) * W + x] == 0:
            gap += 1
        if 0 < gap <= max_gap and low + 1 + gap < H:
            for y in range(low + 1, low + 1 + gap):
                m.d[y * W + x] = fill + 1


def crenels(m, x0, x1, top, mat=STONE, w=22, h=26):
    """Battlements along a wall top: merlons with gaps."""
    x = x0
    while x + w <= x1:
        m.rect(x, top - h, x + w, top, m=mat)
        x += w * 2


def arch(m, x, top, w, h):
    """An arched opening (window or door): a slot with a round head."""
    m.rect(x - w / 2, top + w / 2, x + w / 2, top + h, carve=True)
    m.ellipse(x, top + w / 2, w / 2, w / 2, carve=True)


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
    """A headstone on a sunken base slab, grounded on a little mound."""
    m.ellipse(x, ground + 2, w * 0.9, 9, m=SOIL)
    m.rect(x - w // 2 - 5, ground - 8, x + w // 2 + 5, ground + 4, m=STONE)
    m.rect(x - w // 2, ground - h, x + w // 2, ground - 6, m=STONE)
    m.ellipse(x, ground - h, w // 2, w // 2 - 2, m=STONE)
    settle(m, x - w, x + w, ground - 20, ground + 10, [STONE, SOIL], SOIL)


def tunnel(m, x0, x1, y, r, seed):
    """A winding burrow from x0 to x1 around depth y: overlapping blobs
    that rise and fall a little, so it reads as dug rather than cut."""
    rng = random.Random(seed)
    steps = max(2, int((x1 - x0) / (r * 0.8)))
    for i in range(steps + 1):
        x = x0 + (x1 - x0) * i / steps
        yy = y + math.sin(i * 1.3 + seed) * r * 0.35
        m.blob(x, yy, r * rng.uniform(0.9, 1.15), carve=True, wobble=0.16,
               seed=seed * 100 + i)


def dead_tree(m, x, ground, h, seed):
    """A bare tree: a trunk tapering from a flared root plate, crooked
    branches that thin out, and twigs. Roots are dug into a soil mound."""
    rng = random.Random(seed)
    m.ellipse(x, ground + 4, 46, 14, m=SOIL)
    m.poly([(x - 40, ground + 10), (x - 22, ground - 16), (x - 14, ground - h * 0.6),
            (x - 9, ground - h), (x + 9, ground - h), (x + 14, ground - h * 0.6),
            (x + 22, ground - 16), (x + 40, ground + 10)],
           m=WOOD)
    for k in range(5):
        y = ground - h * (0.38 + k * 0.13)
        side = -1 if k % 2 else 1
        length = rng.randint(70, 105) * (1 - k * 0.12)
        tip = (x + side * length, y - length * 0.6)
        w = 11 - k * 1.5
        # A tapering branch: thick where it leaves the trunk.
        m.poly([(x, y - w), (tip[0], tip[1] - 3), (tip[0] + side * 2, tip[1] + 3),
                (x, y + w)], m=WOOD)
        # Two twigs off each branch.
        for f, up in ((0.45, 30), (0.75, 22)):
            mid = (x + side * length * f, y - length * 0.6 * f)
            m.poly([(mid[0] - side * 3, mid[1] - 2),
                    (mid[0] + side * 18, mid[1] - up),
                    (mid[0] + side * 4, mid[1] + 4)], m=WOOD)
    settle(m, x - 40, x + 40, ground - 30, ground + 20, [WOOD, SOIL], SOIL)


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
    # Curtain wall on a battered (sloping) footing, battlements, gate arch.
    m.poly([(812, top - 30), (1398, top - 30), (1412, top + 12),
            (798, top + 12)], m=STONE)
    m.rect(820, 450, 1390, top, m=STONE)
    crenels(m, 820, 1390, 450)
    arch(m, 955, 470, 56, 92)
    for wx in (880, 1250):
        arch(m, wx, 478, 18, 40)
    # Round-shouldered towers: walls that taper upwards, arched windows,
    # conical roofs with eaves.
    for x0, x1, t, apex in ((790, 900, 300, 210), (1300, 1410, 260, 160)):
        m.poly([(x0 + 6, t), (x1 - 6, t), (x1 + 8, top + 12),
                (x0 - 8, top + 12)], m=STONE)
        crenels(m, x0 - 6, x1 + 6, t, w=18, h=20)
        m.poly([(x0 - 18, t - 18), ((x0 + x1) / 2, apex), (x1 + 18, t - 18)],
               m=ROOF)
        arch(m, (x0 + x1) / 2, t + 44, 20, 48)
        arch(m, (x0 + x1) / 2, t + 140, 16, 36)
    # The keep: two hollow floors, arched windows.
    m.rect(1000, 330, 1210, top, m=STONE)
    crenels(m, 994, 1216, 330)
    m.rect(1022, 350, 1188, 440, carve=True)
    m.rect(1022, 456, 1188, top - 4, carve=True)
    arch(m, 1105, 372, 40, 56)
    # Everything stands on the crag, never above it.
    settle(m, 790, 1420, 300, top + 14, [STONE], STONE, max_gap=120)
    # Dungeon under the crag.
    m.rect(920, 712, 1280, 742, carve=True)
    for cx in (930, 1100, 1270):
        m.blob(cx, 724, 36, carve=True, wobble=0.15, seed=cx)
    # Broken drawbridge over the moat, on its chains.
    m.rect(1410, 548, 1545, 562, m=WOOD)
    m.poly([(1406, 470), (1412, 470), (1540, 548), (1530, 548)], m=METAL)

    # Graveyard on the right hill: tombstones, a crypt, a dead tree.
    for x, h in ((1740, 50), (1800, 64), (1870, 46), (2060, 58), (2130, 44)):
        tombstone(m, x, int(hills(x)), h)
    cg = int(hills(1960)) + 6
    m.rect(1900, cg - 10, 2020, cg + 6, m=STONE)                 # plinth
    m.rect(1910, cg - 120, 2010, cg - 8, m=STONE)
    arch(m, 1960, cg - 92, 44, 84)
    m.poly([(1896, cg - 118), (1960, cg - 170), (2024, cg - 118)], m=ROOF)
    settle(m, 1896, 2024, cg - 130, cg + 8, [STONE], STONE)
    dead_tree(m, 2200, int(hills(2200)), 220, seed=4)

    # Left: a ruined watchtower and a dead tree.
    lg = int(hills(330))
    broken_top(m, 280, 390, lg + 6, lg - 230, STONE, seed=7, drop=90)
    m.rect(306, lg - 150, 364, lg - 2, carve=True)
    arch(m, 335, lg - 200, 18, 34)
    settle(m, 280, 390, lg - 240, lg + 8, [STONE], STONE)
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
    # Lighthouse: a tapering tower on a wide base, smashed at the top.
    m.poly([(lx - 76, lg + 10), (lx - 56, lg - 40), (lx + 56, lg - 40),
            (lx + 76, lg + 10)], m=STONE)
    broken_top(m, lx - 52, lx + 52, lg - 30, lg - 300, STONE, seed=3,
               drop=110)
    m.rect(lx - 26, lg - 220, lx + 26, lg - 30, carve=True)
    arch(m, lx - 44, lg - 74, 30, 70)
    arch(m, lx + 30, lg - 200, 14, 30)
    settle(m, lx - 80, lx + 80, lg - 60, lg + 14, [STONE], STONE)

    # Sandbar the wreck lies on.
    m.below(lambda x: 1135 - 60 * math.exp(-((x - 1230) / 300) ** 2),
            m=SAND, x0=780, x1=1700)

    rng = random.Random(5)

    def ribs(x_edge, y0, y1, side):
        """Ribs sticking out of a broken hull end."""
        for y in range(int(y0), int(y1), 26):
            length = rng.randint(14, 34)
            m.rect(min(x_edge, x_edge + side * length), y,
                   max(x_edge, x_edge + side * length), y + 8, m=WOOD)

    # Bow half: hull rising to the prow, broken off jaggedly at the stern
    # end, with gun ports, a mast and a crow's nest.
    bow = [(800, 830), (860, 880), (1150, 880), (1172, 905), (1150, 930),
           (1176, 960), (1154, 990), (1180, 1030), (1160, 1084), (990, 1104),
           (880, 1064), (830, 960)]
    m.poly(bow, m=WOOD)
    m.poly([(886, 902), (1140, 902), (1140, 956), (880, 956)], carve=True)
    for wx in (920, 1000, 1080):                  # gun ports
        m.rect(wx, 990, wx + 22, 1010, carve=True)
    ribs(1166, 900, 1080, 1)
    m.poly([(980, 880), (996, 880), (1050, 600), (1036, 598)], m=WOOD)  # mast
    m.rect(1004, 660, 1086, 672, m=WOOD)          # crow's nest
    m.poly([(1012, 640), (1078, 640), (1086, 660), (1004, 660)], m=WOOD)

    # Stern half, tilted, broken off jaggedly at the bow end, with a raised
    # stern castle and cabin windows.
    stern = [(1300, 1092), (1282, 1040), (1304, 1000), (1280, 960),
             (1302, 930), (1290, 900), (1520, 870), (1540, 760), (1700, 740),
             (1700, 1010), (1560, 1082)]
    m.poly(stern, m=WOOD)
    m.poly([(1326, 922), (1518, 896), (1544, 802), (1680, 788), (1680, 930),
            (1326, 972)], carve=True)
    ribs(1290, 910, 1080, -1)
    for wx in (1590, 1640):
        arch(m, wx, 800, 22, 34)
    m.poly([(1398, 900), (1416, 900), (1410, 700), (1400, 704)], m=WOOD)
    # Sand piled against and under both hulls: they lie *in* the bar.
    for cx, rx in ((1180, 60), (1290, 50), (1700, 50), (980, 120)):
        m.ellipse(cx, 1104, rx, 26, m=SAND)
    settle(m, 830, 1700, 800, 1110, [WOOD], SAND, max_gap=100)

    # Right island: rocks, a sandy beach and a lookout shack on stilts.
    def island(x):
        y = 1150 - 0.55 * (x - 1700) + wave(x, (12, 60, 0.7))
        return shores(x, max(y, 730))

    m.below(island, x0=1700)
    m.recolor(1700, 700, 1980, 1200, ROCK, SAND)
    sx = 2140
    sg = int(island(sx))
    for px in (sx - 80, sx + 60):
        m.rect(px, sg - 120, px + 12, int(island(px)) + 10, m=WOOD)
        m.ellipse(px + 6, int(island(px)) + 4, 16, 6, m=ROCK)   # footing
    m.rect(sx - 96, sg - 230, sx + 86, sg - 120, m=WOOD)
    m.rect(sx - 74, sg - 210, sx + 64, sg - 132, carve=True)
    m.poly([(sx - 116, sg - 226), (sx - 5, sg - 290), (sx + 106, sg - 226)],
           m=ROOF)
    # Ladder up to the shack.
    for y in range(sg - 112, sg, 16):
        m.rect(sx - 70, y, sx - 40, y + 4, m=WOOD)
    m.rect(sx - 72, sg - 120, sx - 66, int(island(sx - 69)) + 6, m=WOOD)
    m.rect(sx - 44, sg - 120, sx - 38, int(island(sx - 41)) + 6, m=WOOD)
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

    def footing(x0, x1, base):
        """A stone plinth a little wider than the walls, grounded."""
        m.rect(x0 - 8, base - 10, x1 + 8, base + 4, m=STONE)
        settle(m, x0 - 8, x1 + 8, base - 12, base + 6, [STONE], STONE,
               max_gap=90)

    # Bombed church: nave walls with a broken roofline, a cracked spire.
    g = int(ground(380)) + 8
    broken_top(m, 220, 520, g, g - 230, STONE, seed=11, drop=80)
    m.rect(246, g - 160, 494, g - 12, carve=True)
    for wx in (290, 380, 450):
        arch(m, wx + 15, g - 150, 30, 60)
    m.rect(250, g - 60, 330, g - 12, m=WOOD)                  # pews
    broken_top(m, 520, 600, g, g - 420, STONE, seed=12, drop=60)
    arch(m, 560, g - 340, 30, 70)
    footing(220, 600, g)

    # Houses: stone walls on a plinth, timber floor, arched door and
    # windows, a half roof on its beam, a chimney.
    for x0, x1, seed in ((760, 960, 21), (1480, 1720, 22), (1960, 2200, 23)):
        hg = int(ground((x0 + x1) / 2)) + 8
        broken_top(m, x0, x1, hg, hg - 214, STONE, seed=seed, drop=40)
        m.rect(x0 + 26, hg - 150, x1 - 26, hg - 12, carve=True)
        m.rect(x0 + 20, hg - 96, x1 - 20, hg - 84, m=WOOD)     # floor
        arch(m, x0 + 68, hg - 160, 34, 46)
        arch(m, x1 - 13, hg - 80, 34, 68)                       # door
        m.rect(x0 - 10, hg - 206, x0 + (x1 - x0) * 0.6, hg - 196, m=WOOD)
        m.poly([(x0 - 24, hg - 196), (x0 + (x1 - x0) * 0.45, hg - 290),
                (x0 + (x1 - x0) * 0.55, hg - 250), (x0 + 30, hg - 196)],
               m=ROOF)
        m.rect(x0 + 40, hg - 300, x0 + 66, hg - 230, m=STONE)  # chimney
        footing(x0, x1, hg)

    # Sandbag barricades, each bag grounded, and rubble heaps.
    for x, n in ((1000, 3), (1420, 2)):
        sg = int(ground(x)) + 4
        for row in range(n):
            for k in range(n - row):
                m.ellipse(x + k * 40 + row * 20, sg - 14 - row * 24, 22, 14,
                          m=SAND)
        settle(m, x - 24, x + n * 40, sg - 40, sg + 4, [SAND], SAND)
    for x in (680, 1820, 2280):
        m.blob(x, int(ground(x)) - 10, 34, m=ROCK, wobble=0.3, seed=x)
    # A toppled water tank half sunk in the crater's mud.
    m.ellipse(1200, 1092, 70, 40, m=METAL)
    m.ellipse(1200, 1136, 120, 30, m=SOIL)
    settle(m, 1120, 1280, 1040, 1140, [METAL, SOIL], SOIL)
    m.blob(600, 1010, 70, carve=True, wobble=0.2, seed=31)       # cellar
    tunnel(m, 620, 860, 1010, 30, 33)
    return m


# --------------------------------------------------------------- backyard

def backyard():
    """The redesign's arena (redesign/ArenaScene.dc.html): a backyard at
    dusk, two soil mounds around a puddle, a stack of toy blocks on the
    left, a big tin can on the right."""
    m = Mask(SOIL)

    def ground(x):
        y = 800 + wave(x, (34, 190, 0.6), (12, 61, 1.3), (5, 23, 0.2))
        y -= 90 * math.exp(-((x - 520) / 260) ** 2)
        y -= 120 * math.exp(-((x - 1820) / 300) ** 2)
        if 1040 <= x <= 1420:  # the puddle, under the water line
            t = math.cos(math.pi * (x - 1230) / 190) * 0.5 + 0.5
            y += (1150 - y) * min(1, t * 1.35)
        return shores(x, y)

    m.below(ground)

    # Toy blocks, stacked and grounded. They sit on the painter's 72 px
    # block grid so each block gets one colour and one letter.
    size = 72
    bx = 4 * size
    g = round(ground(bx + size) / size) * size
    for (dx, k) in ((0, 0), (size, 0), (0, 1)):
        x0 = bx + dx
        m.rect(x0, g - size * (k + 1), x0 + size, g - size * k, m=TOY)
    settle(m, bx, bx + 2 * size, g - 2 * size, g + 4, [TOY], SOIL, max_gap=80)

    # A big tin can, a little sunk into the mound.
    cx = 1640
    cg = int(ground(cx + 50))
    m.rect(cx, cg - 170, cx + 110, cg + 8, m=CAN)
    m.ellipse(cx + 55, cg - 170, 55, 12, m=CAN)
    settle(m, cx, cx + 110, cg - 180, cg + 10, [CAN], SOIL)

    # A burrow under the left mound and a pebble cave on the right.
    m.blob(640, 980, 70, carve=True, wobble=0.22, seed=41)
    tunnel(m, 660, 900, 982, 30, 43)
    m.blob(2050, 990, 80, carve=True, wobble=0.2, seed=42)
    return m


MAPS = {'backyard': backyard, 'castle': castle, 'wreck': wreck, 'ruins': ruins}

if __name__ == '__main__':
    # A map with a painting (assets/maps/<map>/art.webp) gets its mask from
    # tool/art/convert_art.py; it is only overwritten here on request.
    force = '--code' in sys.argv
    for name in [a for a in sys.argv[1:] if a != '--code'] or MAPS:
        out = ROOT / 'assets' / 'maps' / name / 'mask.png'
        if (out.parent / 'art.webp').exists() and not force:
            print(f'skipped {name}: painted (art.webp); --code to overwrite')
            continue
        MAPS[name]().write(out)
        print(f'wrote {out} ({out.stat().st_size} bytes)')
