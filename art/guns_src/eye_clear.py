# F58 ADS rule addition: the iron-sight eye never sits inside the gun.
# blender -b --python eye_clear.py -- <repo root>
# For every long gun with iron sight points in art/gen/mounts.json: the eye is on the sight line, `relief` behind the
# rear point (AdsPose). Grow relief in 5 mm steps from the kind's value until every vertex is >= CLEAR from the eye;
# write `relief_min` only when it had to grow (other guns keep the kind's relief exactly), else remove it.
# Keep REL / CLEAR in step with TacticalConfig.ADS_RELIEF / ADS_EYE_CLEAR. Pistols (0.25) and optics are skipped.
import bpy, sys, json
from mathutils import Vector

root = sys.argv[-1]
path = root + "/art/gen/mounts.json"
M = json.load(open(path))
REL = {"notch": 0.16, "aperture": 0.08}
CLEAR = 0.03
PISTOLS = ("glock18", "m1911", "revolver")
for gid, r in sorted(M.items()):
	if "sight_rear" not in r or gid in PISTOLS:
		continue
	kind = r.get("sight_kind") or "notch"
	kind = "notch" if kind == "none" else kind  # as AdsPose.kind
	if kind not in REL:
		continue
	bpy.ops.wm.read_factory_settings(use_empty=True)
	bpy.ops.import_scene.gltf(filepath=root + "/godot/assets/models/guns/%s.glb" % gid)
	bpy.context.view_layer.update()
	dg = bpy.context.evaluated_depsgraph_get()
	g = []
	for o in bpy.data.objects:
		if o.type == 'MESH' and o.parent:  # evaluated, so skinned guns measure posed (as measure_gun.py)
			e = o.evaluated_get(dg)
			g += [Vector((w.x, w.z, -w.y)) for w in [e.matrix_world @ v.co for v in e.to_mesh().vertices]]
	rear, front = Vector(r["sight_rear"]), Vector(r["sight_front"])
	ax = (rear - front).normalized()
	t = REL[kind]
	while t < 0.6 and min((p - (rear + ax * t)).length for p in g) < CLEAR:
		t += 0.005
	if t > REL[kind] + 1e-6:
		r["relief_min"] = round(t, 3)
	else:
		r.pop("relief_min", None)
	print("@@ %s %s relief %.3f" % (gid, kind, t))
json.dump(M, open(path, "w"), indent=1, sort_keys=True)
