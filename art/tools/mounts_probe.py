# blender -b --python art/tools/mounts_probe.py -- out.json [--render dir] id [id ...]
# Measures attachment/hand mount points of godot/assets/models/guns/<id>.glb from its geometry (heuristics on the
# silhouette: muzzle tip, receiver top, underside, grip/mag protrusions). Output is in the game's glTF axes
# (muzzle -Z, up +Y, origin = bbox centre, metres). --render writes a side view with the points as coloured balls.
import bpy, sys, json, math, os
import numpy as np
from mathutils import Vector
args = sys.argv[sys.argv.index("--") + 1:]
out = args[0]; args = args[1:]
rdir = None
if args and args[0] == "--render":
    rdir = args[1]; args = args[2:]


def load(i):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=f"godot/assets/models/guns/{i}.glb")
    pts = []
    for o in bpy.data.objects:
        if o.type == "MESH":
            pts += [o.matrix_world @ v.co for v in o.data.vertices]
    p = np.array([(v.x, v.z, -v.y) for v in pts])  # glTF axes
    return p


def measure(p):
    zmin, zmax = p[:, 2].min(), p[:, 2].max()
    L = zmax - zmin
    N = 48
    t = (p[:, 2] - zmin) / L  # 0 = muzzle ... 1 = butt
    b = np.minimum((t * N).astype(int), N - 1)
    top = np.full(N, np.nan); bot = np.full(N, np.nan)
    for k in range(N):
        s = p[b == k]
        if len(s):
            top[k], bot[k] = s[:, 1].max(), s[:, 1].min()
    zc = lambda k: zmin + (k + 0.5) / N * L  # slice centre z
    H = np.nanmax(top) - np.nanmin(bot)
    sl = lambda a, c: slice(int(a * N), int(c * N))
    mu = p[t < 0.03]
    muzzle = (0.0, float((mu[:, 1].max() + mu[:, 1].min()) / 2), float(zmin))
    base = float(np.nanmedian(bot[sl(0.18, 0.34)]))  # underside of the handguard/barrel (t=0 is the muzzle)
    prot = [k for k in range(N) if not np.isnan(bot[k]) and bot[k] < base - 0.07 * H]
    groups, cur = [], []
    for k in prot:  # contiguous runs, ordered from the muzzle: the last run is the grip (nearest the butt)
        if cur and k != cur[-1] + 1:
            groups.append(cur); cur = []
        cur.append(k)
    if cur: groups.append(cur)
    groups = [g for g in groups if np.mean(g) / N < 0.8]  # drop a stock that reaches below the barrel line
    def spot(g, f, at=0.5):
        lo = float(np.nanmin(bot[g])); k = g[min(len(g) - 1, int(at * len(g)))]
        return (0.0, lo + f * (base - lo), float(zc(k)))
    fb = (0.0, base, float(zmin + 0.7 * L))
    if not groups:
        grip = mag = fb
    elif len(groups) > 1:  # separate grip and mag runs, ordered from the muzzle
        mag, grip = spot(groups[-2], 0.8), spot(groups[-1], 0.6)
    elif L < 0.35:  # pistol: one run, the grip is the mag
        grip = mag = spot(groups[0], 0.6)
    else:  # rifle: grip and mag merged in one run: mag in front, grip behind
        mag, grip = spot(groups[0], 0.8, 0.3), spot(groups[0], 0.6, 0.85)
    if L >= 0.35 and abs(grip[2] - mag[2]) < 0.04 * L:  # grip run not separated from the mag: take the underside near 70 % back
        k = int(0.7 * N); lo = float(bot[k]); grip = (0.0, lo + 0.6 * (base - lo), float(zc(k)))
    rt = float(np.nanpercentile(top[sl(0.35, 0.65)], 60))
    rail = (0.0, rt, float(zmin + 0.5 * L))
    under = (0.0, base, float(zmin + 0.26 * L))
    grip_l = (0.0, base + 0.015, float(zmin + 0.3 * L))
    ads = float(np.nanpercentile(top[sl(0.1, 0.8)], 85))
    r = lambda v: [round(float(x), 4) for x in v]
    return {"muzzle": r(muzzle), "rail": r(rail), "under": r(under), "grip_r": r(grip), "grip_l": r(grip_l), "mag_l": r(mag), "ads_y": round(ads, 4), "length": round(float(L), 3)}


def render(i, m, path):
    sc = bpy.context.scene
    for k, c in (("muzzle", (1, 0, 0)), ("rail", (0, 1, 0)), ("under", (0, 0.4, 1)), ("grip_r", (1, 1, 0)), ("grip_l", (1, 0, 1)), ("mag_l", (0, 1, 1))):
        x, y, z = m[k]
        bpy.ops.mesh.primitive_uv_sphere_add(radius=0.012, location=(x + 0.04, -z, y))
        mat = bpy.data.materials.new(k); mat.use_nodes = True
        nd = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
        nd.inputs["Base Color"].default_value = (*c, 1); nd.inputs["Emission Color"].default_value = (*c, 1); nd.inputs["Emission Strength"].default_value = 3
        bpy.context.active_object.data.materials.append(mat)
    ys = m["ads_y"]  # ads line as a thin bar
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0.045, 0, ys)); bpy.context.active_object.scale = (0.002, m["length"], 0.002)
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam
    cam.data.type = "ORTHO"; cam.data.ortho_scale = m["length"] * 1.15
    cam.location = (3, 0, 0); cam.rotation_euler = (math.radians(90), 0, math.radians(90))
    sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN")); sun.data.energy = 3; sun.rotation_euler = (0.8, 0, 0.6); sc.collection.objects.link(sun)
    sc.world = bpy.data.worlds.new("w"); sc.world.color = (0.35, 0.35, 0.4)
    sc.render.resolution_x = sc.render.resolution_y = 512
    try: sc.render.engine = "BLENDER_EEVEE_NEXT"
    except TypeError: sc.render.engine = "BLENDER_EEVEE"
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)


res = json.load(open(out)) if os.path.exists(out) else {}
for i in args:
    m = measure(load(i))
    res[i] = m
    print("MOUNT", i, json.dumps(m))
    if rdir:
        os.makedirs(rdir, exist_ok=True); render(i, m, f"{rdir}/{i}_mounts.png")
json.dump(res, open(out, "w"), indent=1, sort_keys=True)
