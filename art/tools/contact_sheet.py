#!/usr/bin/env python3
"""python3 art/tools/contact_sheet.py out.png [id ...]: side-view renders of the built models in one labelled sheet."""
import glob, os, subprocess, sys
from PIL import Image, ImageDraw
out = sys.argv[1]
want = sys.argv[2:]
files = sorted(f for d in ("guns", "attachments", "utility") for f in glob.glob(f"godot/assets/models/{d}/*.glb"))
files = [f for f in files if not want or os.path.basename(f)[:-4] in want]
W = os.environ.get("TMPDIR", "/tmp")
tiles = []
for f in files:
    p = f"{W}/cs_{os.path.basename(f)}.png"
    r = subprocess.run(["blender", "-b", "--python", "art/tools/glb_preview.py", "--", f, p, "side"], capture_output=True, text=True)
    stats = next((l for l in r.stdout.splitlines() if "STATS" in l), "")
    im = Image.open(p).convert("RGB").resize((384, 384))
    ImageDraw.Draw(im).text((6, 4), os.path.basename(f)[:-4] + " " + stats.replace("STATS ", ""), fill=(255, 255, 0))
    tiles.append(im)
cols = 4
sheet = Image.new("RGB", (cols * 384, ((len(tiles) + cols - 1) // cols) * 384))
for n, t in enumerate(tiles):
    sheet.paste(t, ((n % cols) * 384, (n // cols) * 384))
sheet.save(out)
