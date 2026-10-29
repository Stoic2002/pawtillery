#!/usr/bin/env python3
"""Turns painted art on a magenta background into game assets.

Maps: art/src/<map>.webp (3:1, landscape on #FF00FF) becomes
  assets/maps/<map>/mask.png  the sim's ground (alpha > 128 = ground)
  assets/maps/<map>/art.webp  what is drawn, same size
scaled to the world size (3600 x 1200).

Pets: art/src/pets.webp (two rows of five on #FF00FF, in the family order
below) becomes assets/pets/<family>.webp, each trimmed and scaled to a
fixed height.

The magenta is keyed out by how much purer it is than green (soft edge
between two thresholds), and what is left of it on the edges is pulled
out of the colour (despill). Specks of ground too small to matter are
dropped and pin holes filled. Needs Pillow. Run from the project root:

    python3 tool/art/convert_art.py            # everything
    python3 tool/art/convert_art.py castle pets
"""
import sys
from collections import deque
from pathlib import Path

from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / 'art' / 'src'

WORLD = (3600, 1200)
MAPS = ['backyard', 'castle', 'wreck', 'ruins']
FAMILIES = [
    'cat', 'dog', 'rabbit', 'bird', 'hamster',
    'duck', 'chicken', 'turtle', 'goat', 'monkey',
]
PET_HEIGHT = 240

# min(R, B) - G: fully opaque below KEY_LO, fully clear above KEY_HI.
KEY_LO, KEY_HI = 70, 180
# Inside the art a colour leaning magenta by more than this is pulled
# back (pink flowers and purple flags keep their colour); within EDGE px
# of the background all of the magenta lean goes.
SPILL = 40
EDGE = 5
# Ground or holes smaller than this many pixels are noise.
SPECK = 400


def key(img):
    """RGB -> RGBA with the magenta keyed out and despilled."""
    data = img.convert('RGB').tobytes()
    n = len(data) // 3
    alpha = bytearray(n)
    for j in range(n):
        r, g, b = data[3 * j], data[3 * j + 1], data[3 * j + 2]
        k = min(r, b) - g
        alpha[j] = (0 if k >= KEY_HI else 255 if k <= KEY_LO else
                    round(255 * (KEY_HI - k) / (KEY_HI - KEY_LO)))
    # Pixels within EDGE of the background: the smallest alpha around.
    edge = Image.frombytes('L', img.size, bytes(alpha)).filter(
        ImageFilter.MinFilter(2 * EDGE + 1)).tobytes()
    out = bytearray(4 * n)
    for j in range(n):
        a = alpha[j]
        if a == 0:
            continue
        r, g, b = data[3 * j], data[3 * j + 1], data[3 * j + 2]
        lean = min(r, b) - g
        cut = lean if edge[j] < 255 else lean - SPILL
        if cut > 0:
            r -= cut
            b -= cut
        out[4 * j:4 * j + 4] = bytes((r, g, b, a))
    return Image.frombytes('RGBA', img.size, bytes(out))


def resize(img, size):
    """Premultiplied, so clear pixels' colour never bleeds into edges."""
    return img.convert('RGBa').resize(size, Image.LANCZOS).convert('RGBA')


def components(solid, w, h, want):
    """Yields each 4-connected region of pixels whose solid flag == want."""
    seen = bytearray(w * h)
    for start in range(w * h):
        if seen[start] or solid[start] != want:
            continue
        region = [start]
        seen[start] = 1
        queue = deque([start])
        while queue:
            i = queue.popleft()
            x, y = i % w, i // w
            for j in (i - 1 if x > 0 else -1, i + 1 if x < w - 1 else -1,
                      i - w if y > 0 else -1, i + w if y < h - 1 else -1):
                if j >= 0 and not seen[j] and solid[j] == want:
                    seen[j] = 1
                    region.append(j)
                    queue.append(j)
        yield region


def convert_map(name):
    art = resize(key(Image.open(SRC / f'{name}.webp')), WORLD)
    w, h = art.size
    alpha = bytearray(art.getchannel('A').tobytes())
    solid = bytearray(1 if a > 128 else 0 for a in alpha)

    dropped = filled = 0
    for region in list(components(solid, w, h, 1)):
        if len(region) < SPECK:
            dropped += 1
            for i in region:
                solid[i] = 0
                alpha[i] = 0
    for region in list(components(solid, w, h, 0)):
        touches_edge = any(i % w in (0, w - 1) or i // w in (0, h - 1)
                           for i in region)
        if not touches_edge and len(region) < SPECK:
            filled += 1
            for i in region:
                solid[i] = 1
                alpha[i] = 255
    art.putalpha(Image.frombytes('L', (w, h), bytes(alpha)))

    out = ROOT / 'assets' / 'maps' / name
    out.mkdir(parents=True, exist_ok=True)
    mask = Image.new('RGBA', (w, h))
    mask.putdata([(0, 0, 0, 255) if s else (0, 0, 0, 0) for s in solid])
    mask.save(out / 'mask.png', optimize=True)
    art.save(out / 'art.webp', quality=88, alpha_quality=100, method=6)
    print(f'{name}: {w}x{h}, ground {sum(solid) * 100 // (w * h)} %, '
          f'{dropped} specks dropped, {filled} pin holes filled, '
          f'art {(out / "art.webp").stat().st_size // 1024} KB')


def convert_pets():
    """Each pet is a group of connected pieces: the ten biggest are the
    pets (two rows of five), every smaller piece (a whisker, a feather tip)
    joins the nearest of them. Pets may overlap side by side, so each is
    cut out by its own pixels, not by a box."""
    sheet = key(Image.open(SRC / 'pets.webp'))
    w, h = sheet.size
    alpha = sheet.getchannel('A').tobytes()
    solid = bytearray(1 if v > 128 else 0 for v in alpha)
    pieces = []
    for region in components(solid, w, h, 1):
        xs = [i % w for i in region]
        ys = [i // w for i in region]
        pieces.append((region, (min(xs), min(ys), max(xs) + 1, max(ys) + 1)))
    pieces.sort(key=lambda p: -len(p[0]))
    if len(pieces) < len(FAMILIES):
        sys.exit(f'pets: found {len(pieces)} pieces, need {len(FAMILIES)}')
    pets = [[p] for p in pieces[:len(FAMILIES)]]

    def gap(a, b):
        dx = max(0, a[0] - b[2], b[0] - a[2])
        dy = max(0, a[1] - b[3], b[1] - a[3])
        return dx * dx + dy * dy

    for piece in pieces[len(FAMILIES):]:
        nearest = min(pets, key=lambda pet: min(gap(piece[1], q[1])
                                                 for q in pet))
        nearest.append(piece)

    def box(pet):
        return (min(q[1][0] for q in pet), min(q[1][1] for q in pet),
                max(q[1][2] for q in pet), max(q[1][3] for q in pet))

    # Reading order: top row then bottom row, left to right.
    mid = h / 2
    pets.sort(key=lambda pet: ((box(pet)[1] + box(pet)[3]) / 2 > mid,
                               box(pet)[0]))
    out = ROOT / 'assets' / 'pets'
    out.mkdir(parents=True, exist_ok=True)
    for name, pet in zip(FAMILIES, pets):
        x0, y0, x1, y1 = box(pet)
        own = bytearray(w * h)
        for region, _ in pet:
            for i in region:
                own[i] = 1
        # Its pixels at full strength, the soft edge around them kept.
        keep = Image.frombytes('L', (w, h), bytes(
            alpha[i] if own[i] or _near(own, i, w, h) else 0
            for i in range(w * h)))
        img = sheet.copy()
        img.putalpha(keep)
        img = img.crop((max(0, x0 - 2), max(0, y0 - 2),
                        min(w, x1 + 2), min(h, y1 + 2)))
        pw, ph = img.size
        img = resize(img, (round(pw * PET_HEIGHT / ph), PET_HEIGHT))
        img.save(out / f'{name}.webp', quality=92, alpha_quality=100,
                 method=6)
        print(f'pet {name}: {img.size[0]}x{img.size[1]}, '
              f'{len(pet)} pieces')


def _near(own, i, w, h):
    """A soft-edge pixel right next to this pet."""
    x, y = i % w, i // w
    for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
        nx, ny = x + dx, y + dy
        if 0 <= nx < w and 0 <= ny < h and own[ny * w + nx]:
            return True
    return False


if __name__ == '__main__':
    targets = sys.argv[1:] or MAPS + ['pets']
    for t in targets:
        convert_pets() if t == 'pets' else convert_map(t)
