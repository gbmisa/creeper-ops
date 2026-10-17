# Scratch low-poly builder with named parts (F146, Opus). blender -b --python scratch_parts.py -- <id> <out.glb>
# Like scratch_gun.py (gun space: muzzle -Z, +Y up, +X right, metres) but scratch_<id>.py may also define
# NODES = {name: PARTS} (separate meshes parented to the body, so the body stays the first MeshInstance) and
# SHAPES = {node: (key, PARTS)}: the same parts in another pose, exported as a blend shape (glTF morph target).
# Everything is re-centred on the BODY's bbox; printed POINTS are shifted to match. EXTRA = {name: PARTS} are
# exported as their own glbs next to <out> (e.g. arrow.glb), centred on their own bbox.
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
MI = {n: i for i, n in enumerate(MATS)}
bm = None


def G(x, y, z):  # gun space -> Blender (glTF export turns Blender +Y into Godot -Z)
	return Vector((x, -z, y))


def face(vs, mat):
	f = bm.faces.new(vs); f.material_index = MI[mat]; return f


def box(lo, hi, mat):
	(x0, y0, z0), (x1, y1, z1) = lo, hi
	v = [bm.verts.new(G(x, y, z)) for x in (x0, x1) for y in (y0, y1) for z in (z0, z1)]
	for q in ((0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)):
		face([v[i] for i in q], mat)


def _extrude(a, b, mat):
	face(a, mat); face(list(reversed(b)), mat)
	n = len(a)
	for i in range(n):
		j = (i + 1) % n
		face([a[i], b[i], b[j], a[j]], mat)


def prism(pts, hw, mat, x0=0.0):  # side profile [(z, y)], extruded +-hw in x around x0
	_extrude([bm.verts.new(G(x0 - hw, y, z)) for z, y in pts], [bm.verts.new(G(x0 + hw, y, z)) for z, y in pts], mat)


def prismy(pts, hh, mat, y0=0.0):  # top profile [(x, z)], extruded +-hh in y around y0
	_extrude([bm.verts.new(G(x, y0 - hh, z)) for x, z in pts], [bm.verts.new(G(x, y0 + hh, z)) for x, z in pts], mat)


def _circle(axis, c, r, t, seg):
	x, y, z = c
	out = []
	for k in range(seg):
		a = 2 * math.pi * k / seg
		u, v = r * math.cos(a), r * math.sin(a)
		p = {"z": (x + u, y + v, t), "x": (t, y + u, z + v), "y": (x + u, t, z + v)}[axis]
		out.append(bm.verts.new(G(*p)))
	return out


def cyl(x, y, z0, z1, r, mat, seg=10, r1=None):  # along z (r1: radius at z1, for cones)
	_extrude(_circle("z", (x, y, 0), r, z0, seg), _circle("z", (x, y, 0), r if r1 is None else r1, z1, seg), mat)


def cylx(y, z, x0, x1, r, mat, seg=12):
	_extrude(_circle("x", (0, y, z), r, x0, seg), _circle("x", (0, y, z), r, x1, seg), mat)


def cyly(x, z, y0, y1, r, mat, seg=12):
	_extrude(_circle("y", (x, 0, z), r, y0, seg), _circle("y", (x, 0, z), r, y1, seg), mat)


def ring(c, ro, ri, depth, mat, seg=12):  # annulus along z
	x, y, z = c
	def lay(r, zz): return _circle("z", (x, y, 0), r, zz, seg)
	oa, ob, ia, ib = lay(ro, z - depth / 2), lay(ro, z + depth / 2), lay(ri, z - depth / 2), lay(ri, z + depth / 2)
	for i in range(seg):
		j = (i + 1) % seg
		face([oa[i], oa[j], ob[j], ob[i]], mat); face([ia[j], ia[i], ib[i], ib[j]], mat)
		face([oa[j], oa[i], ia[i], ia[j]], mat); face([ob[i], ob[j], ib[j], ib[i]], mat)


def build(name, parts):
	global bm
	mesh = bpy.data.meshes.new(name)
	for m in MATS.values(): mesh.materials.append(m)
	bm = bmesh.new()
	for p in parts:
		{"box": box, "prism": prism, "prismy": prismy, "cyl": cyl, "cylx": cylx, "cyly": cyly, "ring": ring}[p[0]](*p[1:])
	bm.normal_update()
	bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
	bm.to_mesh(mesh); bm.free()
	return mesh


def centre(meshes, ref):
	vs = [v.co for v in ref.vertices]
	lo = Vector(map(min, *vs)); hi = Vector(map(max, *vs)); c = (lo + hi) / 2
	for me in meshes:
		for v in me.vertices: v.co -= c
	return c, hi - lo


def export(objs, path):
	bpy.ops.object.select_all(action="DESELECT")
	for o in objs: o.select_set(True)
	bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_yup=True, export_apply=False,
		use_selection=True, export_morph=True)
	print("@@ wrote", path)


body = build(gid, S.PARTS)
nodes = {n: build(n, p) for n, p in getattr(S, "NODES", {}).items()}
shapes = {n: (k, build(n + "_" + k, p)) for n, (k, p) in getattr(S, "SHAPES", {}).items()}
c, size = centre([body] + list(nodes.values()) + [m for _, m in shapes.values()], body)
root = bpy.data.objects.new("Gun", None)
bpy.context.scene.collection.objects.link(root)
ob = bpy.data.objects.new(gid, body); ob.parent = root
bpy.context.scene.collection.objects.link(ob)
objs = [root, ob]
for n, me in nodes.items():
	o = bpy.data.objects.new(n, me); o.parent = ob
	bpy.context.scene.collection.objects.link(o)
	objs.append(o)
	if n in shapes:
		key, sm = shapes[n]
		assert len(sm.vertices) == len(me.vertices), "shape %s: vertex count differs" % key
		o.shape_key_add(name="Basis")
		sk = o.shape_key_add(name=key)
		for i, v in enumerate(sm.vertices): sk.data[i].co = v.co
gs = Vector((c.x, c.z, -c.y))
print("@@ size x %.3f y(len) %.3f z(h) %.3f  faces %d" % (size.x, size.y, size.z, len(body.polygons)))
for k, p in S.POINTS.items():
	q = Vector(p) - gs
	print("@@ %s [%.4f, %.4f, %.4f]" % (k, q.x, q.y, q.z))
export(objs, out)
for n, p in getattr(S, "EXTRA", {}).items():
	me = build(n, p)
	centre([me], me)
	o = bpy.data.objects.new(n, me)
	bpy.context.scene.collection.objects.link(o)
	export([o], os.path.join(os.path.dirname(out), n + ".glb"))
