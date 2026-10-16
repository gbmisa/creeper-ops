# Scratch low-poly gun builder (FB-I, Opus). blender -b --python scratch_gun.py -- <id> <out.glb>
# Parts are authored in gun space (Godot: muzzle -Z, +Y up, +X right, bore at y 0) by scratch_<id>.py's PARTS.
# The mesh is joined, re-centred on its bbox (the game's contract) and printed sight points are shifted to match.
import bpy, bmesh, math, sys, importlib.util, os
from mathutils import Vector

gid, out = sys.argv[-2], sys.argv[-1]
spec = importlib.util.spec_from_file_location("s", os.path.join(os.path.dirname(__file__), "scratch_%s.py" % gid))
S = importlib.util.module_from_spec(spec); spec.loader.exec_module(S)

bpy.ops.wm.read_factory_settings(use_empty=True)
MATS = {}
for name, (hexc, rough, metal) in S.MATS.items():
	m = bpy.data.materials.new(name); m.use_nodes = True
	b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
	c = [int(hexc[i:i + 2], 16) / 255.0 for i in (0, 2, 4)]
	b.inputs["Base Color"].default_value = [x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c] + [1]
	b.inputs["Roughness"].default_value = rough
	b.inputs["Metallic"].default_value = metal
	MATS[name] = m
mesh = bpy.data.meshes.new(gid)
for m in MATS.values(): mesh.materials.append(m)
MI = {n: i for i, n in enumerate(MATS)}
bm = bmesh.new()

def G(x, y, z):  # gun space -> Blender (glTF export turns Blender +Y into Godot -Z)
	return Vector((x, -z, y))

def face(vs, mat):
	f = bm.faces.new(vs); f.material_index = MI[mat]; return f

def box(lo, hi, mat):
	(x0, y0, z0), (x1, y1, z1) = lo, hi
	v = [bm.verts.new(G(x, y, z)) for x in (x0, x1) for y in (y0, y1) for z in (z0, z1)]
	for q in ((0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)):
		face([v[i] for i in q], mat)

def prism(pts, hw, mat, x0=0.0):  # side profile [(z, y)] (any winding), extruded +-hw in x
	a = [bm.verts.new(G(x0 - hw, y, z)) for z, y in pts]
	b = [bm.verts.new(G(x0 + hw, y, z)) for z, y in pts]
	face(a, mat); face(list(reversed(b)), mat)
	n = len(pts)
	for i in range(n):
		j = (i + 1) % n
		face([a[i], b[i], b[j], a[j]], mat)

def cyl(x, y, z0, z1, r, mat, seg=10):  # along z
	a = [bm.verts.new(G(x + r * math.cos(t), y + r * math.sin(t), z0)) for t in [2 * math.pi * k / seg for k in range(seg)]]
	b = [bm.verts.new(G(x + r * math.cos(t), y + r * math.sin(t), z1)) for t in [2 * math.pi * k / seg for k in range(seg)]]
	face(a, mat); face(list(reversed(b)), mat)
	for i in range(seg):
		j = (i + 1) % seg
		face([a[i], a[j], b[j], b[i]], mat)

def ring(c, ro, ri, depth, mat, seg=12):  # aperture: annulus along z, hole on the sight line
	x, y, z = c
	def lay(r, zz): return [bm.verts.new(G(x + r * math.cos(t), y + r * math.sin(t), zz)) for t in [2 * math.pi * k / seg for k in range(seg)]]
	oa, ob, ia, ib = lay(ro, z - depth / 2), lay(ro, z + depth / 2), lay(ri, z - depth / 2), lay(ri, z + depth / 2)
	for i in range(seg):
		j = (i + 1) % seg
		face([oa[i], oa[j], ob[j], ob[i]], mat); face([ia[j], ia[i], ib[i], ib[j]], mat)
		face([oa[j], oa[i], ia[i], ia[j]], mat); face([ob[i], ob[j], ib[j], ib[i]], mat)

for p in S.PARTS:
	{"box": box, "prism": prism, "cyl": cyl, "ring": ring}[p[0]](*p[1:])
bm.normal_update()
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
bm.to_mesh(mesh); bm.free()
ob = bpy.data.objects.new(gid, mesh)
root = bpy.data.objects.new("Gun", None)
bpy.context.scene.collection.objects.link(root); bpy.context.scene.collection.objects.link(ob)
ob.parent = root
# re-centre on the bbox (Blender coords), then report the shift in gun space
vs = [v.co for v in mesh.vertices]
lo = Vector(map(min, *vs)); hi = Vector(map(max, *vs)); c = (lo + hi) / 2
for v in mesh.vertices: v.co -= c
shift = Vector((-c.x, -c.z, c.y))  # subtract from gun-space points: gun = (bx, bz, -by)
gs = Vector((c.x, c.z, -c.y))
size = hi - lo
print("@@ size x %.3f y(len) %.3f z(h) %.3f  faces %d" % (size.x, size.y, size.z, len(mesh.polygons)))
for k, p in S.POINTS.items():
	q = Vector(p) - gs
	print("@@ %s [%.4f, %.4f, %.4f]" % (k, q.x, q.y, q.z))
bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_yup=True, export_apply=True)
print("@@ wrote", out)
