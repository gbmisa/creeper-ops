"""Contact sheet: one row per clip, 4 frames each. python3 sheet.py <frames_dir> <out.png>"""
import sys, os
from PIL import Image
d, out = sys.argv[1], sys.argv[2]
clips = ["idle", "walk", "attack", "hit", "die"]
ims = [[Image.open(f"{d}/{c}_{n}.png") for n in range(4)] for c in clips]
w, h = ims[0][0].size
s = Image.new("RGB", (w * 4 // 2, h * 5 // 2))
for r, row in enumerate(ims):
    for c, im in enumerate(row):
        s.paste(im.resize((w // 2, h // 2)), (c * w // 2, r * h // 2))
s.save(out)
