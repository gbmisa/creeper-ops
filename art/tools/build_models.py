#!/usr/bin/env python3
"""Raw gen3d meshes -> game models. python3 art/tools/build_models.py [id ...]
Per id: glb_cleanup (remesh, decimate, orient, scale, origin) -> glb_texture (planar concept projection) -> godot/assets/models/<dir>/<id>.glb
Table: id -> (dir, length m, tris, origin, extra cleanup args, extra texture args)"""
import os, subprocess, sys
G, A, U = "guns", "attachments", "utility"
UP = ("--thin", "y", "--right", "x", "--grazing", "0")  # upright round items: project along Y, no flat patch
T = {
 "mp5": (G, .68, 5000, "center"), "glock18": (G, .22, 3500, "center"), "revolver": (G, .30, 4000, "center"),
 "vector": (G, .60, 5000, "center"), "m4a1": (G, .84, 5500, "center"), "scarh": (G, .96, 5500, "center"),
 "saiga12": (G, .95, 5500, "center"), "sks": (G, 1.02, 5000, "center"), "sr25": (G, 1.0, 5500, "center"),
 "mosin": (G, 1.23, 5000, "center"), "pkm": (G, 1.19, 6000, "center"),
 "reddot": (A, .07, 800, "bottom"), "holo": (A, .10, 1000, "bottom"), "acog3x": (A, .16, 1200, "bottom"),
 "lpvo": (A, .28, 1400, "bottom"), "scope8x": (A, .40, 1500, "bottom"),
 "suppressor": (A, .20, 700, "back"), "compensator": (A, .08, 600, "back"), "flashhider": (A, .08, 600, "back"),
 "vgrip": (A, .09, 600, "top"), "agrip": (A, .10, 700, "top"), "laser": (A, .09, 700, "top"),
 "grapple": (U, .35, 2500, "center"), "binoculars": (U, .17, 1500, "center"),
 "frag": (U, .09, 800, "bottom", ["--no-orient"], UP), "smoke": (U, .15, 800, "bottom", ["--no-orient"], UP),
 "flash": (U, .12, 800, "bottom", ["--no-orient"], UP), "stim": (U, .14, 800, "bottom", ["--no-orient"], UP),
}
W = os.environ.get("TMPDIR", "/tmp")
for i in sys.argv[1:] or list(T):
    d, size, tris, origin, *rest = T[i]
    cx = list(rest[0]) if rest else ["--auto-orient"]
    tx = list(rest[1]) if len(rest) > 1 else []
    if "--no-orient" in cx: cx.remove("--no-orient")
    out = f"godot/assets/models/{d}/{i}.glb"
    os.makedirs(os.path.dirname(out), exist_ok=True)
    mid = f"{W}/{i}_c.glb"
    subprocess.run(["blender", "-b", "--python", "art/tools/glb_cleanup.py", "--", f"art/gen/{i}_raw.glb", mid, "--tris", str(tris),
                    "--size", str(size), "--origin", origin, "--concept", f"art/gen/{i}.png"] + cx, check=True, capture_output=True)
    r = subprocess.run(["blender", "-b", "--python", "art/tools/glb_texture.py", "--", mid, out, "--concept", f"art/gen/{i}.png"] + tx,
                       check=True, capture_output=True, text=True)
    print(i, [l for l in r.stdout.splitlines() if "TEXTURED" in l])
