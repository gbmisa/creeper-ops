# blender -b --python art/tools/glb_cleanup.py -- raw.glb out.glb --tris 3000 --size 0.6 [--concept concept.png]
# Game-ready pass for a gen3d.py mesh: one object, decimated to ~tris, origin at the bottom centre, longest side
# scaled to --size metres, flat-shaded material in the concept image's dominant colour (no texture yet).
import bpy, sys, argparse
from mathutils import Vector
ap = argparse.ArgumentParser()
ap.add_argument("src"); ap.add_argument("out")
ap.add_argument("--tris", type=int, default=3000)
ap.add_argument("--size", type=float, default=1.0)
ap.add_argument("--concept")
a = ap.parse_args(sys.argv[sys.argv.index("--") + 1:])

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=a.src)
meshes = [o for o in bpy.data.objects if o.type == "MESH"]
for o in bpy.data.objects:
    o.select_set(o in meshes)
bpy.context.view_layer.objects.active = meshes[0]
if len(meshes) > 1:
    bpy.ops.object.join()
ob = bpy.context.view_layer.objects.active
bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.mesh.remove_doubles(threshold=0.0001)
bpy.ops.object.mode_set(mode="OBJECT")
rm = ob.modifiers.new("rm", "REMESH")  # clean manifold first; raw surface-net meshes block the collapse
rm.mode = "VOXEL"
rm.voxel_size = max(ob.dimensions) / 160.0
bpy.ops.object.modifier_apply(modifier="rm")
for _ in range(4):  # collapse stalls on surface-net seams, so repeat until near the target
    tris = sum(len(p.vertices) - 2 for p in ob.data.polygons)
    if tris <= a.tris * 1.15:
        break
    m = ob.modifiers.new("dec", "DECIMATE")
    m.ratio = a.tris / tris
    m.use_collapse_triangulate = True
    bpy.ops.object.modifier_apply(modifier="dec")
pts = [ob.matrix_world @ Vector(c) for c in ob.bound_box]
lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
s = a.size / max(hi - lo)
for v in ob.data.vertices:
    v.co = (v.co - Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z))) * s
for p in ob.data.polygons:
    p.use_smooth = False

col = (0.5, 0.5, 0.5)
if a.concept:  # dominant non-background colour: median of pixels that aren't near-white
    img = bpy.data.images.load(a.concept)
    px = list(img.pixels)
    rs, gs, bs = [], [], []
    for i in range(0, len(px), 4 * 37):
        r, g, b = px[i], px[i + 1], px[i + 2]
        if r + g + b < 2.6:
            rs.append(r); gs.append(g); bs.append(b)
    if rs:
        rs.sort(); gs.sort(); bs.sort()
        col = tuple(c ** 2.2 for c in (rs[len(rs) // 2], gs[len(gs) // 2], bs[len(bs) // 2]))  # sRGB -> linear
mat = bpy.data.materials.new("gen")
mat.use_nodes = True
b = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
b.inputs["Base Color"].default_value = (*col, 1.0)
b.inputs["Roughness"].default_value = 0.8
ob.data.materials.clear()
ob.data.materials.append(mat)
print("CLEAN tris=%d size=%.3f colour=%.2f,%.2f,%.2f" % (sum(len(p.vertices) - 2 for p in ob.data.polygons), a.size, *col))
bpy.ops.export_scene.gltf(filepath=a.out, export_format="GLB", use_selection=False)
