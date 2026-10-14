# blender -b --python art/tools/glb_cleanup.py -- raw.glb out.glb --tris 3000 --size 0.6 [--concept concept.png]
# Game-ready pass for a gen3d.py mesh: one object, decimated to ~tris, origin at the bottom centre, longest side
# [--rotate x,y,z degrees] [--flip = turn 180 deg about Y] [--center = origin at bbox centre, for guns] [--no-colour]
# scaled to --size metres, flat-shaded material in the concept image's dominant colour (no texture yet).
import bpy, sys, argparse, math
import numpy as np
from mathutils import Vector
ap = argparse.ArgumentParser()
ap.add_argument("src"); ap.add_argument("out")
ap.add_argument("--tris", type=int, default=3000)
ap.add_argument("--size", type=float, default=1.0)
ap.add_argument("--concept")
ap.add_argument("--rotate", default="0,0,0", help="euler degrees in Blender axes (Z up, glTF -Z forward = +Y) applied to the raw mesh")
ap.add_argument("--flip", action="store_true", help="turn 180 degrees about Y (muzzle pointing the wrong way)")
ap.add_argument("--auto-orient", action="store_true", help="long axis -> +Y, pick the direction whose height profile matches the concept (needs --concept)")
ap.add_argument("--origin", default="bottom", choices=["bottom", "center", "top", "back"], help="back = rear end centre (muzzle devices)")
ap.add_argument("--center", action="store_true", help="same as --origin center")
ap.add_argument("--voxel-div", type=float, default=160.0, help="remesh voxel = longest side / this (higher keeps thin parts)")
ap.add_argument("--relax", type=int, default=0, help="Laplacian-smooth passes on the voxel mesh before decimating (removes voxel lumps)")
ap.add_argument("--angle", type=float, default=0.0, help="smooth shading: edges sharper than this many degrees stay hard (0 = flat faces)")
ap.add_argument("--match", help="existing game glb: refit the result to its exact bounding box (keeps scale/origin/mounts)")
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
def profile_mesh(co, axis, n=48):  # height extent per bin along `axis` (silhouette column heights)
    t = (co[:, axis] - co[:, axis].min()) / max(1e-9, np.ptp(co[:, axis]))
    b = np.minimum((t * n).astype(int), n - 1)
    out = np.zeros(n)
    for i in range(n):
        z = co[b == i, 2]
        out[i] = np.ptp(z) if len(z) else 0
    return out / max(1e-9, np.ptp(co[:, 2]))


def profile_concept(path, n=48):
    img = bpy.data.images.load(path)
    w, h = img.size
    px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)
    solid = px[..., :3].min(2) < 0.75
    ys, xs = np.where(solid)
    solid = solid[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    out = np.zeros(n)
    cols = np.array_split(np.arange(solid.shape[1]), n)
    for i, c in enumerate(cols):
        r = np.where(solid[:, c].any(1))[0]
        out[i] = (r.max() - r.min()) if len(r) else 0
    return out / solid.shape[0]


rx, ry, rz = (math.radians(float(v)) for v in a.rotate.split(","))
if a.auto_orient and a.concept:
    co = np.array([v.co[:] for v in ob.data.vertices])
    long_axis = 0 if np.ptp(co[:, 0]) > np.ptp(co[:, 1]) else 1
    want = profile_concept(a.concept)
    cands = (90, -90) if long_axis == 0 else (0, 180)
    best = None
    for deg in cands:
        c, sn = math.cos(math.radians(deg)), math.sin(math.radians(deg))
        rot = np.stack([co[:, 0] * c - co[:, 1] * sn, co[:, 0] * sn + co[:, 1] * c, co[:, 2]], 1)
        err = np.abs(profile_mesh(rot, 1) - want).mean()
        if best is None or err < best[0]:
            best = (err, deg)
    rx, ry, rz = 0.0, 0.0, math.radians(best[1])
    print("AUTO-ORIENT rz=%d err=%.3f" % (best[1], best[0]))
ob.rotation_mode = "XYZ"
ob.rotation_euler = (rx, ry + (math.pi if a.flip else 0), rz)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.mesh.remove_doubles(threshold=0.0001)
bpy.ops.object.mode_set(mode="OBJECT")
rm = ob.modifiers.new("rm", "REMESH")  # clean manifold first; raw surface-net meshes block the collapse
rm.mode = "VOXEL"
rm.voxel_size = max(ob.dimensions) / a.voxel_div
bpy.ops.object.modifier_apply(modifier="rm")
if a.relax:
    sm = ob.modifiers.new("sm", "SMOOTH")
    sm.factor, sm.iterations = 0.6, a.relax
    bpy.ops.object.modifier_apply(modifier="sm")
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
org = "center" if a.center else a.origin
oz = {"bottom": lo.z, "top": hi.z}.get(org, (lo.z + hi.z) / 2)
oy = lo.y if org == "back" else (lo.y + hi.y) / 2
for v in ob.data.vertices:
    v.co = (v.co - Vector(((lo.x + hi.x) / 2, oy, oz))) * s
if a.match:  # per-axis affine refit onto the old model's bounds (identical bbox, so mounts and view data still fit)
    keep = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=a.match)
    old = [o for o in bpy.data.objects if o not in keep and o.type == "MESH"]
    pts = [o.matrix_world @ Vector(c) for o in old for c in o.bound_box]
    olo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    ohi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    nco = [v.co.copy() for v in ob.data.vertices]
    nlo = Vector((min(c.x for c in nco), min(c.y for c in nco), min(c.z for c in nco)))
    nhi = Vector((max(c.x for c in nco), max(c.y for c in nco), max(c.z for c in nco)))
    for v in ob.data.vertices:
        v.co = olo + Vector(((v.co[i] - nlo[i]) / max(1e-9, nhi[i] - nlo[i]) * (ohi[i] - olo[i]) for i in range(3)))
    for o in old:
        bpy.data.objects.remove(o)
    for o in bpy.data.objects:
        o.select_set(o == ob)
    bpy.context.view_layer.objects.active = ob
if a.angle > 0:
    bpy.ops.object.shade_smooth_by_angle(angle=math.radians(a.angle), keep_sharp_edges=False)
    wn = ob.modifiers.new("wn", "WEIGHTED_NORMAL")
    wn.keep_sharp = True
    wn.weight = 50
else:
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
bpy.ops.export_scene.gltf(filepath=a.out, export_format="GLB", use_selection=False, export_apply=True)
