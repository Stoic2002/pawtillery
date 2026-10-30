#!/usr/bin/env python3
"""Turns painted art on a magenta background into game assets.

Sources are WebP or PNG (a PNG wins when both are there).

Maps: art/src/<map>.webp (3:1, landscape on #FF00FF) becomes
  assets/maps/<map>/mask.png  the sim's ground (alpha > 128 = ground)
  assets/maps/<map>/art.webp  what is drawn, ART_SCALE times as big
scaled to the world size (3600 x 1200).

Pets: art/src/pet_<family>.webp (four poses in a row on #FF00FF) becomes
assets/pets/<family>_<pose>.webp, lined up to swap without the pet moving.

Backgrounds: art/src/<map>_bg.webp (a 3:1 painting, no magenta) becomes
assets/maps/<map>/background.webp.

Menu: art/src/menu_bg.webp (a painting, no magenta) becomes
assets/menu/background.webp, behind the main menu, and a soft, out-of-focus
background_soft.webp behind the other screens.

Sprite sheets: art/src/<sheet>.webp (items in a grid on #FF00FF, in the
order of SHEETS below) becomes assets/sprites/<prefix>_<name>.webp, each
item cut out with every loose bit (a spark, a puff, a motion line) whose
centre lies in its grid cell.

The magenta is keyed out by how much purer it is than green (soft edge
between two thresholds), and what is left of it on the edges is pulled
out of the colour (despill). Specks of ground too small to matter are
dropped and pin holes filled. Needs Pillow. Run from the project root:

    python3 tool/art/convert_art.py            # everything
    python3 tool/art/convert_art.py castle pet_cat craft
"""
import sys
from collections import deque
from pathlib import Path

from PIL import Image, ImageChops, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / 'art' / 'src'

WORLD = (3600, 1200)
# The painting is kept this many times finer than the world (and its
# mask), so it stays sharp when the camera zooms in.
ART_SCALE = 2
# Unsharp mask on the painting (radius, percent, threshold).
SHARPEN = (1.5, 70, 2)
# WebP quality of the painting: as low as it looks the same in play.
ART_QUALITY = 72
MAPS = ['backyard', 'castle', 'wreck', 'ruins']
FAMILIES = [
    'cat', 'dog', 'rabbit', 'bird', 'hamster',
    'duck', 'chicken', 'turtle', 'goat', 'monkey',
]
PET_HEIGHT = 240
POSES = ['idle', 'walkA', 'walkB', 'air']
# Painted backgrounds are kept this wide: a map's fills the screen behind the
# terrain, the menu's the screen.
BG_WIDTH = 4000
MENU_WIDTH = 2880
# The out-of-focus menu painting behind the other screens.
SOFT_WIDTH = 960
SOFT_BLUR = 7
SOFT_WASH = (255, 239, 214)
SOFT_WASH_SHARE = 0.3
# The head is about this much of a pet's height from the top.
HEAD_SHARE = 0.45
# min(R, B) - G from here up is a pocket of background left inside a pet.
PET_POCKET = 90

# min(R, B) - G: fully opaque below KEY_LO, fully clear above KEY_HI.
KEY_LO, KEY_HI = 70, 180
# Inside the art a colour leaning magenta by more than this is pulled
# back (pink flowers and purple flags keep their colour); within EDGE px
# of the background all of the magenta lean goes.
SPILL = 40
EDGE = 5
# Ground or holes smaller than this many pixels are noise.
SPECK = 400

# Sheet: (columns, rows, output prefix, longest side px, item names in
# reading order). Icon names are weapon ids.
SHEETS = {
    'weapons_throw': (3, 3, 'icon', 192, [
        'rock', 'bottleRocket', 'snifferRocket',
        'grenade', 'cluster', 'twinSling',
        'stickyBomb', 'miniNuke', 'coconut']),
    'weapons_sky': (4, 2, 'icon', 192, [
        'homingMissile', 'thunderCloud', 'flowerpotRain', 'bomber',
        'gasRaid', 'satellite', 'meteorShower', 'eggStrike']),
    'weapons_effects': (4, 2, 'icon', 192, [
        'napalm', 'poisonGas', 'iceBomb', 'clay',
        'mine', 'seedMines', 'firecracker', 'blackHole']),
    'weapons_close': (3, 3, 'icon', 192, [
        'shotgun', 'laserPointer', 'punch',
        'startleCrow', 'headbutt', 'seedSpitter',
        'hairball', 'boneBoomerang', 'drillCarrot']),
    'weapons_tools': (3, 3, 'icon', 192, [
        'digClaws', 'grapple', 'shield',
        'firstAid', 'teleport', 'swap',
        'fortress', 'skip', 'boomDuck']),
    'craft': (3, 3, 'craft', 400, [
        'plane', 'jet', 'satellite',
        'cloud', 'bomb', 'missile',
        'egg', 'flowerpot', 'meteor']),
    'objects': (4, 2, 'obj', 160, [
        'gas', 'bomblet', 'hairballBomb', 'seedMine',
        'mine', 'barrel', 'healthCrate', 'weaponCrate']),
}
# On a sheet only pixels this magenta count as background, and only
# within EDGE px of them is an edge softened: purple items (a portal, a
# black hole) keep their colour inside their outline.
SHEET_CORE = 200
# A patch of those is background (also inside a slingshot's fork) when
# its mean green is below this.
SHEET_GREEN = 18
# Loose bits smaller than this many pixels are noise.
SHEET_SPECK = 30


def source(name):
    """art/src/<name>.png (an upscaler's output) if there is one, else
    art/src/<name>.webp."""
    png = SRC / f'{name}.png'
    return Image.open(png if png.exists() else SRC / f'{name}.webp')


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
    keyed = key(source(name))
    art = resize(keyed, WORLD)
    w, h = art.size
    alpha = bytearray(art.getchannel('A').tobytes())
    solid = bytearray(1 if a > 128 else 0 for a in alpha)

    dropped = filled = 0
    drop = bytearray(w * h)
    fill = bytearray(w * h)
    for region in list(components(solid, w, h, 1)):
        if len(region) < SPECK:
            dropped += 1
            for i in region:
                solid[i] = 0
                drop[i] = 255
    for region in list(components(solid, w, h, 0)):
        touches_edge = any(i % w in (0, w - 1) or i // w in (0, h - 1)
                           for i in region)
        if not touches_edge and len(region) < SPECK:
            filled += 1
            for i in region:
                solid[i] = 1
                fill[i] = 255

    # What is drawn: ART_SCALE times finer than the mask, with the same
    # specks dropped and pin holes filled.
    big_size = (w * ART_SCALE, h * ART_SCALE)
    art = resize(keyed, big_size)
    up = [Image.frombytes('L', (w, h), bytes(m)).resize(big_size,
                                                       Image.NEAREST)
          for m in (drop, fill)]
    big_alpha = ImageChops.lighter(
        ImageChops.subtract(art.getchannel('A'), up[0]), up[1])
    art.putalpha(big_alpha)
    # A light sharpen, inside the ground only: across the soft edge it
    # would pull in the clear pixels' black.
    sharp = art.convert('RGB').filter(ImageFilter.UnsharpMask(*SHARPEN))
    sharp.putalpha(big_alpha)
    inside = big_alpha.point(lambda a: 255 if a == 255 else 0)
    art = Image.composite(sharp, art, inside)

    out = ROOT / 'assets' / 'maps' / name
    out.mkdir(parents=True, exist_ok=True)
    mask = Image.new('RGBA', (w, h))
    mask.putdata([(0, 0, 0, 255) if s else (0, 0, 0, 0) for s in solid])
    mask.save(out / 'mask.png', optimize=True)
    art.save(out / 'art.webp', quality=ART_QUALITY, alpha_quality=100, method=6)
    print(f'{name}: {w}x{h} (art {big_size[0]}x{big_size[1]}), ground {sum(solid) * 100 // (w * h)} %, '
          f'{dropped} specks dropped, {filled} pin holes filled, '
          f'art {(out / "art.webp").stat().st_size // 1024} KB')


def fit_width(img, width):
    return (width, round(img.height * width / img.width))


def convert_background(name):
    img = source(f'{name}_bg').convert('RGB')
    img = img.resize(fit_width(img, BG_WIDTH), Image.LANCZOS)
    out = ROOT / 'assets' / 'maps' / name / 'background.webp'
    img.save(out, quality=78, method=6)
    print(f'{name} background: {img.size[0]}x{img.size[1]}, '
          f'{out.stat().st_size // 1024} KB')


def convert_menu():
    img = source('menu_bg').convert('RGB')
    out = ROOT / 'assets' / 'menu'
    out.mkdir(parents=True, exist_ok=True)
    img.resize(fit_width(img, MENU_WIDTH), Image.LANCZOS).save(
        out / 'background.webp', quality=82, method=6)
    # The other screens: the same camp, out of focus and washed towards
    # the UI's cream so that cards and titles stand out. Small: it is blurry.
    soft = img.resize(fit_width(img, SOFT_WIDTH), Image.LANCZOS).filter(
        ImageFilter.GaussianBlur(SOFT_BLUR))
    wash = Image.new('RGB', soft.size, SOFT_WASH)
    Image.blend(soft, wash, SOFT_WASH_SHARE).save(
        out / 'background_soft.webp', quality=80, method=6)
    print(f'menu background: {MENU_WIDTH} wide, '
          f'{(out / "background.webp").stat().st_size // 1024} KB, soft '
          f'{(out / "background_soft.webp").stat().st_size // 1024} KB')


def key_sheet(img):
    """Like key(), but only near clear background: inside an item's
    outline every colour stays as painted."""
    data = img.convert('RGB').tobytes()
    n = len(data) // 3
    core = bytearray(n)
    for j in range(n):
        if min(data[3 * j], data[3 * j + 2]) - data[3 * j + 1] >= SHEET_CORE:
            core[j] = 1
    # Background shows through as pure magenta (green near 0); a patch with
    # more green in it is a painted streak (a black hole's swirl).
    w, h = img.size
    for region in list(components(core, w, h, 1)):
        green = sum(data[3 * i + 1] for i in region) / len(region)
        for i in region:
            core[i] = 255 if green < SHEET_GREEN else 0
    band = Image.frombytes('L', img.size, bytes(core)).filter(
        ImageFilter.MaxFilter(2 * EDGE + 1)).tobytes()
    out = bytearray(4 * n)
    for j in range(n):
        if core[j]:
            continue
        r, g, b = data[3 * j], data[3 * j + 1], data[3 * j + 2]
        a = 255
        if band[j]:
            k = min(r, b) - g
            a = (0 if k >= KEY_HI else 255 if k <= KEY_LO else
                 round(255 * (KEY_HI - k) / (KEY_HI - KEY_LO)))
            if a == 0:
                continue
            if k > 0:
                r -= k
                b -= k
        out[4 * j:4 * j + 4] = bytes((r, g, b, a))
    return Image.frombytes('RGBA', img.size, bytes(out))


def convert_sheet(sheet):
    cols, rows, prefix, longest, names = SHEETS[sheet]
    items = cut_cells(key_sheet(source(sheet)), cols, rows)
    out = ROOT / 'assets' / 'sprites'
    out.mkdir(parents=True, exist_ok=True)
    for name, item in zip(names, items):
        if item is None:
            sys.exit(f'{sheet}: nothing found for {name}')
        cw, ch = item.size
        scale = min(1, longest / max(cw, ch))
        if scale < 1:
            item = resize(item, (round(cw * scale), round(ch * scale)))
        path = out / f'{prefix}_{name}.webp'
        item.save(path, quality=90, alpha_quality=100, method=6)
        print(f'{prefix}_{name}: {item.size[0]}x{item.size[1]}, '
              f'{path.stat().st_size // 1024} KB')


def cut_cells(img, cols, rows):
    """Every item of a keyed sheet, cropped, in reading order: all the
    loose pieces (a spark, a puff, a whisker) whose centre is in its cell,
    each by its own pixels."""
    w, h = img.size
    alpha = img.getchannel('A').tobytes()
    solid = bytearray(1 if v > 128 else 0 for v in alpha)
    cells = [[] for _ in range(cols * rows)]
    for region in components(solid, w, h, 1):
        if len(region) < SHEET_SPECK:
            continue
        xs = [i % w for i in region]
        ys = [i // w for i in region]
        cx = (min(xs) + max(xs)) / 2
        cy = (min(ys) + max(ys)) / 2
        cell = (min(rows - 1, int(cy * rows / h)) * cols +
                min(cols - 1, int(cx * cols / w)))
        cells[cell].append((region, (min(xs), min(ys),
                                     max(xs) + 1, max(ys) + 1)))
    items = []
    for pieces in cells:
        if not pieces:
            items.append(None)
            continue
        x0 = max(0, min(p[1][0] for p in pieces) - 2)
        y0 = max(0, min(p[1][1] for p in pieces) - 2)
        x1 = min(w, max(p[1][2] for p in pieces) + 2)
        y1 = min(h, max(p[1][3] for p in pieces) + 2)
        cw, ch = x1 - x0, y1 - y0
        own = bytearray(cw * ch)
        for region, _ in pieces:
            for i in region:
                own[(i // w - y0) * cw + i % w - x0] = 255
        # Its pixels, and the soft edge right around them.
        keep = Image.frombytes('L', (cw, ch), bytes(own)).filter(
            ImageFilter.MaxFilter(3))
        item = img.crop((x0, y0, x1, y1))
        item.putalpha(ImageChops.darker(item.getchannel('A'), keep))
        items.append(item)
    return items


def head_profile(frame, height):
    """How much of the frame is in each column, over its top [height]."""
    top = frame.getchannel('A').crop((0, 0, frame.width, height))
    return list(top.resize((frame.width, 1), Image.BOX).tobytes())


def head_shift(idle, frame, height, reach=60):
    """How far right to move [frame] so its head is over the idle head."""
    a = head_profile(idle, height)
    b = head_profile(frame, height)
    def cost(dx):
        total = 0
        for x in range(len(a)):
            i = x - dx
            total += abs(a[x] - (b[i] if 0 <= i < len(b) else 0))
        for i in range(len(b)):
            x = i + dx
            if not 0 <= x < len(a):
                total += b[i]
        return total
    return min(range(-reach, reach + 1), key=cost)


def convert_pet(family):
    """art/src/pet_<family>.webp: four poses in a row, on magenta. Out come
    assets/pets/<family>_<pose>.webp, all the same size and scale, so that
    swapping them moves the legs and not the pet: the head stays put, the
    feet are on the bottom edge, the standing pet centred."""
    # No pet has any magenta in it, so even small pockets between its legs
    # are background.
    keyed = key_sheet(source(f'pet_{family}'))
    r, g, b, a = keyed.split()
    keyed.putalpha(ImageChops.darker(a, ImageChops.subtract(
        ImageChops.darker(r, b), g).point(
            lambda k: 0 if k >= PET_POCKET else 255)))
    frames = cut_cells(keyed, len(POSES), 1)
    if None in frames:
        sys.exit(f'pet_{family}: a pose is missing')
    idle = frames[0]
    placed = []
    for pose, frame in zip(POSES, frames):
        dx = 0 if frame is idle else head_shift(
            idle, frame, round(idle.height * HEAD_SHARE))
        # Walking: on the ground. In the air: the head stays, legs tuck up.
        dy = idle.height - frame.height
        if pose == 'air':
            dy = min(0, dy)
        placed.append((frame, dx, dy))
    half = max(max(abs(dx - idle.width / 2),
                   abs(dx + frame.width - idle.width / 2))
               for frame, dx, _ in placed)
    top = min(dy for _, _, dy in placed)
    w = round(half * 2)
    h = idle.height - top
    k = PET_HEIGHT / idle.height
    out = ROOT / 'assets' / 'pets'
    out.mkdir(parents=True, exist_ok=True)
    size = (round(w * k), round(h * k))
    last = None
    for pose, (frame, dx, dy) in zip(POSES, placed):
        canvas = Image.new('RGBA', (w, h))
        canvas.paste(frame, (round(w / 2 - idle.width / 2) + dx, dy - top))
        img = resize(canvas, size)
        img.save(out / f'{family}_{pose}.webp', quality=90, alpha_quality=100,
                 method=6)
        if pose == 'walkB':
            diff = ImageChops.difference(img.getchannel('A'),
                                         last.getchannel('A'))
            moved = sum(1 for v in diff.tobytes() if v > 128)
            print(f'pet {family}: {size[0]}x{size[1]}, walks differ '
                  f'{moved * 100 // (size[0] * size[1])} %, '
                  f'shifts {[p[1] for p in placed]}')
        last = img


if __name__ == '__main__':
    targets = sys.argv[1:] or (MAPS + [f'{m}_bg' for m in MAPS] +
                               [f'pet_{f}' for f in FAMILIES] +
                               list(SHEETS) + ['menu_bg'])
    for t in targets:
        if t.startswith('pet_'):
            convert_pet(t[4:])
        elif t == 'menu_bg':
            convert_menu()
        elif t in SHEETS:
            convert_sheet(t)
        elif t.endswith('_bg'):
            convert_background(t[:-3])
        else:
            convert_map(t)
