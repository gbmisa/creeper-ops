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
# polish: higher budgets, fine voxels, smooth normals, cleaned textures; --match keeps the committed model's exact bbox
BUDGET = {G: (10000, 420, 1024), A: (2000, 300, 512), U: (2000, 300, 512)}
BASE = os.environ.get("OLDREF", "HEAD")  # git ref holding the models whose bbox must be kept
for i in sys.argv[1:] or list(T):
    d, size, _old_tris, origin, *rest = T[i]
    tris, vdiv, tex = BUDGET[d]
    cx = list(rest[0]) if rest else ["--auto-orient"]
    tx = list(rest[1]) if len(rest) > 1 else []
    if "--no-orient" in cx: cx.remove("--no-orient")
    out = f"godot/assets/models/{d}/{i}.glb"
    os.makedirs(os.path.dirname(out), exist_ok=True)
    mid, old = f"{W}/{i}_c.glb", f"{W}/{i}_old.glb"
    if not os.path.exists(old):
        open(old, "wb").write(subprocess.run(["git", "show", f"{BASE}:{out}"], check=True, capture_output=True).stdout)
    c = subprocess.run(["blender", "-b", "--python", "art/tools/glb_cleanup.py", "--", f"art/gen/{i}_raw.glb", mid, "--tris", str(tris),
                    "--size", str(size), "--origin", origin, "--concept", f"art/gen/{i}.png", "--voxel-div", str(vdiv), "--relax", "3",
                    "--angle", "35", "--match", old] + cx, check=True, capture_output=True, text=True)
    assert "CLEAN" in c.stdout, c.stdout[-400:]
    r = subprocess.run(["blender", "-b", "--python", "art/tools/glb_texture.py", "--", mid, out, "--concept", f"art/gen/{i}.png",
                        "--tex", str(tex), "--clean"] + tx, check=True, capture_output=True, text=True)
    assert "TEXTURED" in r.stdout, r.stdout[-400:]
    print(i, [l for l in r.stdout.splitlines() if "TEXTURED" in l])
