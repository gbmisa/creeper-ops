# blender -b --python measure_gun.py -- gun.glb gun_id mounts.json
# Measures an exported gun (muzzle -Z, Y up, origin at bbox centre) and writes its row in mounts.json:
# ads_y (top of the centreline = iron sight line), rail, muzzle, under, grip_r, grip_l, mag_l, length.
# --rail-top: rail y = receiver top instead of ads_y - 0.015 (needed when the iron sights stand well above the receiver).
# Prints FLIP if the muzzle looks like it points +Z (the thin end should be at -Z); re-export with flip toggled.
import bpy, sys, json
from mathutils import Vector
a = sys.argv[sys.argv.index("--")+1:]
glb, gid, path = a[:3]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=glb)
bpy.context.view_layer.update()
vs = []
dg = bpy.context.evaluated_depsgraph_get()
for o in bpy.data.objects:
    if o.type == 'MESH' and o.parent:  # skip the importer's parentless bone-shape Icosphere; evaluated, so skinned guns (AK, Mosin) measure with their armature applied
        e = o.evaluated_get(dg)
        vs += [e.matrix_world @ v.co for v in e.to_mesh().vertices]
# glTF import turns Godot -Z (muzzle) into Blender +Y; Godot Y up = Blender Z. Convert to Godot space.
g = [Vector((v.x, v.z, -v.y)) for v in vs]
zs = [p.z for p in g]; zmin, zmax = min(zs), max(zs); L = zmax - zmin
def band(z0, z1): return [p for p in g if z0 <= p.z <= z1]
def yext(ps): return max(p.y for p in ps) - min(p.y for p in ps) if ps else 0
front, rear = band(zmin, zmin + 0.15 * L), band(zmax - 0.15 * L, zmax)
if yext(front) > yext(rear) * 1.1 and "--noflip" not in sys.argv:
    print("@@ FLIP", gid, round(yext(front), 3), round(yext(rear), 3)); sys.exit(0)
centre = [p for p in g if abs(p.x) < 0.008] or g
ads_y = max(p.y for p in centre)
tip = band(zmin, zmin + 0.01)
muzzle_y = sum(p.y for p in tip) / len(tip)
bore = muzzle_y
low = [p for p in g if p.y < bore - 0.03]
def centroid(ps): return sum(ps, Vector()) / len(ps) if ps else Vector()
grip = [p for p in low if zmin + 0.35 * L < p.z < zmin + 0.75 * L] or low
fore = band(zmin + 0.12 * L, zmin + 0.4 * L)
grip_r = centroid(grip); grip_r.x = 0
under_y = min(p.y for p in fore) if fore else bore - 0.03
row = {"length": round(L, 3), "ads_y": round(ads_y, 4),
       "muzzle": [0.0, round(muzzle_y, 4), round(zmin, 4)],
       "rail": [0.0, round(ads_y - 0.015, 4), round(-0.06 * L, 4)],
       "under": [0.0, round(under_y, 4), round(zmin + 0.28 * L, 4)],
       "grip_r": [0.0, round(grip_r.y, 4), round(grip_r.z, 4)],
       "grip_l": [0.0, round(under_y, 4), round(zmin + 0.3 * L, 4)],
       "mag_l": [0.0, round(grip_r.y, 4), round(grip_r.z - 0.04 * L, 4)]}
if "--rail-top" in sys.argv:  # sight bases sit ON the receiver: rail y = median centreline top over +-5 cm around the rail point
    rz = row["rail"][2]
    tops = sorted(max(p.y for p in band(z, z + 0.005) if abs(p.x) < 0.01) for z in [rz - 0.05 + 0.005 * i for i in range(20)] if [p for p in band(z, z + 0.005) if abs(p.x) < 0.01])
    row["rail"][1] = round(tops[len(tops) // 2], 4)
d = json.load(open(path))
d[gid] = row
json.dump(d, open(path, "w"), indent=1, sort_keys=True)
print("@@ mounts", gid, row)
