#!/usr/bin/env python3
"""Generates the M1 placeholder map mask (assets/maps/sandbox/mask.png).

Only the alpha channel matters: alpha 255 = ground, 0 = empty. Standard
library only, so it runs anywhere: `python3 tool/gen_sandbox_map.py`.
"""
import math
import struct
import sys
import zlib
from pathlib import Path

W, H = 2400, 1200


def surface(x):
    y = 780 + 110 * math.sin(x / 260) + 55 * math.sin(x / 97 + 1.3)
    # Flat-ish plateau under the M1 launcher (x≈300, y≈520).
    if 150 <= x <= 450:
        y = min(y, 560 + 8 * math.sin(x / 40))
    # Low edges so the water line is visible at both sides.
    if x < 90:
        y = max(y, 1150)
    if x > 2260:
        y = max(y, 1150)
    return y


def solid(x, y):
    if y >= surface(x):
        # Cave pocket under the right hills.
        if ((x - 1900) / 150) ** 2 + ((y - 950) / 60) ** 2 <= 1:
            return False
        return True
    # Floating island.
    if ((x - 1450) / 180) ** 2 + ((y - 380) / 45) ** 2 <= 1:
        return True
    # 3 px thin wall: tests that fast shots can't tunnel through.
    if 1000 <= x < 1003 and y >= 330:
        return True
    return False


def write_png(path, rows):
    def chunk(tag, data):
        return (struct.pack('>I', len(data)) + tag + data +
                struct.pack('>I', zlib.crc32(tag + data) & 0xFFFFFFFF))

    raw = b''.join(b'\x00' + row for row in rows)
    png = (b'\x89PNG\r\n\x1a\n' +
           chunk(b'IHDR', struct.pack('>IIBBBBB', W, H, 8, 6, 0, 0, 0)) +
           chunk(b'IDAT', zlib.compress(raw, 9)) +
           chunk(b'IEND', b''))
    path.write_bytes(png)


def main():
    ground = bytes((138, 90, 53, 255))
    empty = bytes(4)
    rows = []
    for y in range(H):
        rows.append(b''.join(ground if solid(x, y) else empty for x in range(W)))
    out = Path(sys.argv[1] if len(sys.argv) > 1 else
               Path(__file__).resolve().parent.parent /
               'assets/maps/sandbox/mask.png')
    write_png(out, rows)
    print(f'wrote {out} ({out.stat().st_size} bytes)')


if __name__ == '__main__':
    main()
