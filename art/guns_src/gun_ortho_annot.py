import sys, re
from PIL import Image, ImageDraw
iy = {}
for l in open(sys.argv[1]):
    m = re.match(r"@@ (\w+) side half=([\d.]+) iron_y=([\d.]+)", l)
    if m: iy[m[1]] = float(m[3])
def py(y): return int(300 - (y - 0.05) * 2000)
groups = [sys.argv[2:]]
for g in iy:
    for v in ("side", "rear"):
        im = Image.open(f"{g}_{v}.png").convert("RGB"); d = ImageDraw.Draw(im); W, H = im.size
        for k in range(-15, 16):
            y = py(0.05 + k * 0.01); d.line([(0, y), (W, y)], fill=(225, 225, 225) if k % 5 else (170, 170, 170))
        d.line([(0, py(iy[g])), (W, py(iy[g]))], fill=(255, 0, 0))
        if v == "rear":
            for k in range(-15, 16):
                x = 300 + k * 20; d.line([(x, 0), (x, H)], fill=(225, 225, 225) if k % 5 else (170, 170, 170))
            d.line([(300, 0), (300, H)], fill=(0, 160, 0))
        # redraw gun on top of grid: grid lines only where the pixel was white
        src = Image.open(f"{g}_{v}.png").convert("RGB"); px = src.load(); out = im.load()
        for yy in range(H):
            for xx in range(W):
                r, gg, b = px[xx, yy]
                if gg < 128 and r > 128: out[xx, yy] = (200, 0, 200) if out[xx, yy] != (255, 0, 0) and out[xx, yy] != (0, 160, 0) else (90, 0, 0)
        d.text((5, 5), f"{g} {v} iron_y={iy[g]}", fill=(0, 0, 0))
        im.save(f"a_{g}_{v}.png")
