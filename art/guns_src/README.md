Source packs for godot/assets/models/guns (see CREDITS.md there).
Re-export: blender -b <src>.blend --python export_gun.py -- out.glb <length_m> <flip 0/1> [ak]
Lengths: m1911 .22, p90 .50 (flip 1), ak47 .88 (ak), shotgun 1.0, garand 1.1, sniper 1.2
Unrigged guns are joined into one mesh with the scale baked in (the game reads size from the first MeshInstance).
Then measure sight/muzzle/grip mounts into art/gen/mounts.json: blender -b --python measure_gun.py -- gun.glb <id> ../gen/mounts.json [--noflip]
2026-10-14: glock18 Pistol_6 .22, revolver Revolver_2 .30, mp5 SubmachineGun_3 .68, vector SubmachineGun_4 .60, m4a1 AssaultRifle2_1 .84 (all flip 1), mosin mosin9130 1.23 (flip 0)
