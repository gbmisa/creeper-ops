# Adds low-poly iron sights to an unflipped, unrigged gun glb (FB-H) and re-exports it in place.
# blender -b --python add_irons.py -- <gun.glb> <id>
# Coordinates below are gun space (Godot, muzzle -Z, +Y up, +X right); Blender space is (x, -z, y).
import bpy, bmesh, math, sys
from mathutils import Vector, Matrix

path, gid = sys.argv[-2], sys.argv[-1]

def G(x, y, z):
	return Vector((x, -z, y))

# Parts: ("box", min xyz, max xyz) | ("ring", centre xyz, outer r, inner r, depth along z)
# Sight line notes: rear = aperture centre, front = post tip; both on LINE.
SPECS = {
	"m4a1": [  # A2-style aperture on the carry handle; front post raised to the same line
		("box", (-0.0060, 0.1500, 0.177), (0.0042, 0.1540, 0.189)),
		("ring", (-0.0009, 0.1580, 0.183), 0.0045, 0.0016, 0.004),
		("box", (-0.0085, 0.1520, 0.179), (-0.0065, 0.1640, 0.189)),
		("box", (0.0047, 0.1520, 0.179), (0.0067, 0.1640, 0.189)),
		("box", (-0.0019, 0.1500, -0.2630), (0.0003, 0.1580, -0.2608)),
	],
	"mp5": [  # drum aperture on the rear block; hooded post on the front block
		("box", (-0.0060, 0.1290, 0.034), (0.0060, 0.1320, 0.046)),
		("ring", (0.0, 0.1365, 0.040), 0.0050, 0.0018, 0.005),
		("box", (-0.0100, 0.1290, 0.036), (-0.0075, 0.1430, 0.046)),
		("box", (0.0075, 0.1290, 0.036), (0.0100, 0.1430, 0.046)),
		("box", (-0.0011, 0.1290, -0.2661), (0.0011, 0.1365, -0.2639)),
		("ring", (0.0, 0.1365, -0.265), 0.0085, 0.0070, 0.004),
	],
	"vector": [  # flip-up style aperture and post on the top rail ends
		("box", (-0.0060, 0.1925, 0.229), (0.0060, 0.1995, 0.241)),
		("ring", (0.0, 0.2048, 0.235), 0.0045, 0.0016, 0.004),
		("box", (-0.0085, 0.1925, 0.231), (-0.0065, 0.2110, 0.241)),
		("box", (0.0065, 0.1925, 0.231), (0.0085, 0.2110, 0.241)),
		("box", (-0.0060, 0.1925, -0.191), (0.0060, 0.1960, -0.179)),
		("box", (-0.0011, 0.1925, -0.1861), (0.0011, 0.2048, -0.1839)),
		("box", (-0.0075, 0.1925, -0.189), (-0.0055, 0.2075, -0.181)),
		("box", (0.0055, 0.1925, -0.189), (0.0075, 0.2075, -0.181)),
	],
	"sr25": [  # flip-up rear on the receiver rail, flip-up front on the handguard rail (rail centre x -0.0107)
		("box", (-0.0187, 0.1000, 0.112), (-0.0027, 0.1060, 0.128)),
		("ring", (-0.0107, 0.1170, 0.120), 0.0045, 0.0016, 0.004),
		("box", (-0.0192, 0.1000, 0.115), (-0.0172, 0.1230, 0.125)),
		("box", (-0.0042, 0.1000, 0.115), (-0.0022, 0.1230, 0.125)),
		("box", (-0.0187, 0.0900, -0.308), (-0.0027, 0.0980, -0.292)),
		("box", (-0.0118, 0.0980, -0.3011), (-0.0096, 0.1170, -0.2989)),
		("box", (-0.0177, 0.0980, -0.304), (-0.0157, 0.1200, -0.296)),
		("box", (-0.0057, 0.0980, -0.304), (-0.0037, 0.1200, -0.296)),
	],
	"pkm": [  # U-notch leaf on the solid rear-sight block, blade tops level with the front post tip (0.1408)
		("box", (-0.0290, 0.1300, 0.2850), (-0.0050, 0.1375, 0.2890)),
		("box", (-0.0290, 0.1300, 0.2850), (-0.0185, 0.1408, 0.2890)),
		("box", (-0.0155, 0.1300, 0.2850), (-0.0050, 0.1408, 0.2890)),
	],
}
# PKM: fold the carry handle down to the left so the sight line is clear (no new sights).
FOLD = {"pkm": {"y_min": 0.125, "y_tip": 0.137, "z": (-0.105, 0.128), "hinge": (0.010, 0.120), "deg": 115.0}}

def add_box(bm, a, b):
	vs = [bm.verts.new(G(x, y, z)) for x in (a[0], b[0]) for y in (a[1], b[1]) for z in (a[2], b[2])]
	for f in ((0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)):
		bm.faces.new([vs[i] for i in f])

def add_ring(bm, c, ro, ri, d, n=12):
	rings = []
	for z in (c[2] + d / 2, c[2] - d / 2):
		for r in (ro, ri):
			rings.append([bm.verts.new(G(c[0] + r * math.cos(2 * math.pi * i / n), c[1] + r * math.sin(2 * math.pi * i / n), z)) for i in range(n)])
	bo, bi, fo, fi = rings
	for i in range(n):
		j = (i + 1) % n
		bm.faces.new((bo[i], bo[j], bi[j], bi[i]))
		bm.faces.new((fo[i], fi[i], fi[j], fo[j]))
		bm.faces.new((bo[i], fo[i], fo[j], bo[j]))
		bm.faces.new((bi[i], bi[j], fi[j], fi[i]))

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=path)
obj = next(o for o in bpy.context.scene.objects if o.type == "MESH")
inv = obj.matrix_world.inverted()
bm = bmesh.new()
bm.from_mesh(obj.data)
if gid in FOLD:
	f = FOLD[gid]
	hx, hy = f["hinge"]
	rot = Matrix.Rotation(-math.radians(f["deg"]), 4, Vector((0, 1, 0)))  # about Blender +Y (gun -Z): tips the handle toward gun -X (left)
	pivot = obj.matrix_world.inverted() @ G(hx, hy, 0.0)
	moved = 0
	for face in bm.faces:
		cw = obj.matrix_world @ face.calc_center_median()
		gy, gz = cw.z, -cw.y
		top = max((obj.matrix_world @ v.co).z for v in face.verts)
		if (gy > f["y_min"] or top > f["y_tip"]) and f["z"][0] < gz < f["z"][1]:
			for v in face.verts:
				v.tag = True
			moved += 1
	for v in bm.verts:
		if v.tag:
			w = obj.matrix_world @ v.co
			p = Vector((w.x - hx, 0.0, w.z - hy))
			p = rot @ p
			v.co = inv @ Vector((hx + p.x, w.y, hy + p.z))
	print("folded faces", moved)
new = []
for part in SPECS.get(gid, []):
	before = set(bm.faces)
	tmp = bmesh.new()
	(add_box if part[0] == "box" else add_ring)(tmp, *part[1:])
	for v in tmp.verts:
		v.co = inv @ v.co
	me = bpy.data.meshes.new("tmp")
	tmp.to_mesh(me)
	bm.from_mesh(me)
	bpy.data.meshes.remove(me)
	new += [fc for fc in bm.faces if fc not in before]
if new:  # sights take the material of the gun face nearest the rear sight
	bm.faces.ensure_lookup_table()
	ref = obj.matrix_world.inverted() @ G(*SPECS[gid][1][1])
	old = [fc for fc in bm.faces if fc not in set(new)]
	mat = min(old, key=lambda fc: (fc.calc_center_median() - ref).length).material_index
	for fc in new:
		fc.material_index = mat
	print("added faces", len(new), "material", mat)
bmesh.ops.recalc_face_normals(bm, faces=new)
bm.normal_update()
bm.to_mesh(obj.data)
obj.data.update()
bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_yup=True, export_apply=False)
print("exported", path)
