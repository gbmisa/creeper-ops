# blender -b --python export_attach.py -- in.glb out.glb kind value [--noglass] [--flip]
# Free-pack attachment -> game GLB. kind: sight (value = axis_h m: scaled so the lens centre sits that high above the base,
# origin = bottom centre, front/objective end toward -Z), muzzle (value = length m, origin = rear centre, extends -Z),
# under (value = longest side m, origin = top centre, hangs down). --noglass drops the lens faces (the rig draws its own
# reticle quad, so a 1x sight stays see-through); --flip swaps front/back. Assumes the source is up = Z, long axis = Y.
import bpy, sys, math
from mathutils import Vector, Matrix
a = sys.argv[sys.argv.index("--")+1:]
src, out, kind, val = a[0], a[1], a[2], float(a[3])
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
meshes = [o for o in bpy.data.objects if o.type == 'MESH']
for o in meshes:
    m = o.matrix_world.copy(); o.parent = None; o.matrix_world = m
for o in list(bpy.data.objects):
    if o.type != 'MESH': bpy.data.objects.remove(o)
bpy.ops.object.select_all(action='DESELECT')
for o in meshes: o.select_set(True)
bpy.context.view_layer.objects.active = meshes[0]
if len(meshes) > 1: bpy.ops.object.join()
ob = bpy.context.view_layer.objects.active
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
me = ob.data
def glass_idx(): return {i for i, m in enumerate(me.materials) if m and 'glass' in m.name.lower()}
gi = glass_idx()
gz = [sum((me.vertices[v].co.z for v in p.vertices)) / len(p.vertices) for p in me.polygons if p.material_index in gi]
zmin = min(v.co.z for v in me.vertices)
lens_h = (sum(gz) / len(gz) - zmin) if gz else None
def ends():
    ys = [v.co.y for v in me.vertices]; y0, y1 = min(ys), max(ys); L = y1 - y0
    def area(lo, hi):
        p = [v.co for v in me.vertices if lo <= v.co.y <= hi]
        return (max(q.x for q in p) - min(q.x for q in p)) * (max(q.z for q in p) - min(q.z for q in p))
    return area(y0, y0 + 0.2 * L), area(y1 - 0.2 * L, y1)
back_a, front_a = ends()   # glTF -Z is Blender +Y, so the front must be at +Y
swap = (back_a > front_a * 1.1) if kind == 'sight' else False
if "--flip" in a: swap = not swap
if swap: me.transform(Matrix.Rotation(math.pi, 4, 'Z'))
if kind == 'sight' and lens_h: s = val / lens_h
else:
    ext = [max(v.co[i] for v in me.vertices) - min(v.co[i] for v in me.vertices) for i in range(3)]
    s = val / max(ext)
me.transform(Matrix.Scale(s, 4))
vs = [v.co for v in me.vertices]
mn = Vector(map(min, *vs)); mx = Vector(map(max, *vs)); c = (mn + mx) / 2
if kind == 'sight': off = Vector((-c.x, -c.y, -mn.z))
elif kind == 'muzzle': off = Vector((-c.x, -mn.y, -c.z))
else: off = Vector((-c.x, -c.y, -mx.z))
me.transform(Matrix.Translation(off))
if "--noglass" in a:
    import bmesh
    bm = bmesh.new(); bm.from_mesh(me); gi = glass_idx()
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.material_index in gi], context='FACES'); bm.to_mesh(me); bm.free()
for m in me.materials:
    if not m or not m.use_nodes: continue
    b = next((n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'), None)
    if b: b.inputs['Metallic'].default_value = 0.6; b.inputs['Roughness'].default_value = 0.45
bpy.ops.export_scene.gltf(filepath=out, export_format='GLB', export_animations=False, export_yup=True)
vs = [v.co for v in me.vertices]
print("@@", kind, "scale", round(s, 3), "swap", swap, "areas", round(back_a, 5), round(front_a, 5), "lens_h", lens_h and round(lens_h * s, 4),
      "size xyz(m)", [round(max(v[i] for v in vs) - min(v[i] for v in vs), 3) for i in range(3)])
