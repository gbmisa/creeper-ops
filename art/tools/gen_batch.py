#!/usr/bin/env python3
"""Generate the Range 5 art set through gen3d.py: python3 art/tools/gen_batch.py [id ...] (default all missing)."""
import os, subprocess, sys
V = ", orthographic side view, muzzle pointing right, entire weapon in frame, plain white background, matte"
G = {
 "mp5": "Heckler & Koch MP5 submachine gun with fixed stock", "glock18": "Glock 18 machine pistol",
 "revolver": "Smith & Wesson Model 29 .44 Magnum revolver, 6 inch barrel", "vector": "KRISS Vector submachine gun",
 "m4a1": "M4A1 carbine with collapsed stock and rail, no optic", "scarh": "FN SCAR-H battle rifle",
 "saiga12": "Saiga-12 semi-automatic shotgun with box magazine", "sks": "SKS carbine with wooden stock",
 "sr25": "Knight's Armament SR-25 designated marksman rifle with 20 round magazine, no optic",
 "mosin": "Mosin-Nagant M91/30 bolt action rifle with wooden stock", "pkm": "PKM general purpose machine gun with ammo box",
}
S = {"reddot": "compact red dot sight", "holo": "EOTech holographic weapon sight", "acog3x": "Trijicon ACOG 3x scope",
     "lpvo": "1-6x LPVO rifle scope with mount", "scope8x": "long 8x tactical sniper scope with mount rings"}
A = {"suppressor": "rifle suppressor silencer", "compensator": "muzzle compensator brake", "flashhider": "birdcage flash hider",
     "vgrip": "tactical vertical foregrip handle only, short rubberized cylinder grip with a picatinny rail clamp on top, isolated gun accessory, no barrel",
     "agrip": "angled foregrip, a single short sloped rubber hand stop block with a rail clamp on top, tiny isolated gun accessory, not a pistol, no barrel, no trigger",
     "laser": "tactical laser aiming module, small rectangular black box with one round lens at the front and a rail clamp underneath, isolated gun accessory"}
U = {"grapple": "grappling hook launcher gun with a separate hook head, sci-fi military", "frag": "M67 fragmentation hand grenade",
     "smoke": "smoke grenade canister", "flash": "flashbang stun grenade", "stim": "autoinjector stim pen", "binoculars": "military binoculars"}
jobs = {}
for k, v in G.items(): jobs[k] = v + V
for k, v in S.items(): jobs[k] = v + V.replace("entire weapon", "entire object")
for k, v in A.items(): jobs[k] = v + V.replace("entire weapon", "entire object")
for k, v in U.items(): jobs[k] = v + ", single object, plain white background, matte"
ids = sys.argv[1:] or list(jobs)
for i in ids:
    out = f"art/gen/{i}"
    if os.path.exists(f"art/gen/{i}_raw.glb"): continue
    subprocess.run([sys.executable, "art/tools/gen3d.py", "--prompt", jobs[i], "--out", out, "--octree", "384"] + ["--side"] + (["--seed", os.environ["SEED"]] if "SEED" in os.environ else []), check=False)
    if os.path.exists(out + ".glb"): os.rename(out + ".glb", f"art/gen/{i}_raw.glb")
