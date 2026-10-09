"""Import a creature .glb and render a few frames of every clip (checks the export too).
Run: blender -b --python art/blender/preview.py -- <in.glb> <out_dir> [frames_per_clip]
Prints one line per clip: name, frame count. Images: <out_dir>/<clip>_<n>.png
"""
import math
import os
import sys

import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1:]
src, out_dir = args[0], args[1]
per = int(args[2]) if len(args) > 2 else 4
os.makedirs(out_dir, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
sc = bpy.context.scene
arm = next(o for o in sc.objects if o.type == "ARMATURE")
mesh = next(o for o in sc.objects if o.type == "MESH")
print("[preview] tris", sum(len(p.vertices) - 2 for p in mesh.data.polygons), "materials", [m.name for m in mesh.data.materials])

ad = arm.animation_data or arm.animation_data_create()
for tr in list(ad.nla_tracks):
    ad.nla_tracks.remove(tr)


def use(act):
    ad.action = act
    if hasattr(ad, "action_slot") and act.slots:
        ad.action_slot = act.slots[0]


# Measure the posed idle mesh, not the rest pose: hidden parts (flames, projectiles) sit at full size at rest.
idle = bpy.data.actions.get("idle") or next(iter(bpy.data.actions))
use(idle)
sc.frame_set(int(idle.frame_range[0]))
dg = bpy.context.evaluated_depsgraph_get()
ev = mesh.evaluated_get(dg)
pts = [ev.matrix_world @ v.co for v in ev.to_mesh().vertices]
ev.to_mesh_clear()
lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
size = max(hi - lo) or 1.0
centre = (lo + hi) * 0.5

bpy.ops.mesh.primitive_plane_add(size=max(6.0, size * 2.5), location=(centre.x, centre.y, min(0.0, lo.z)))
ground = bpy.context.active_object
gm = bpy.data.materials.new("ground")
gm.diffuse_color = (0.18, 0.2, 0.16, 1)
ground.data.materials.append(gm)

cam_data = bpy.data.cameras.new("cam")
cam = bpy.data.objects.new("cam", cam_data)
sc.collection.objects.link(cam)
sc.camera = cam
cam.location = centre + Vector((1.1, -1.5, 0.9)) * size * 1.0
cam.rotation_euler = (centre - cam.location).to_track_quat("-Z", "Y").to_euler()
cam_data.lens = 40

sun_data = bpy.data.lights.new("sun", "SUN")
sun_data.energy = 3.0
sun = bpy.data.objects.new("sun", sun_data)
sun.rotation_euler = (math.radians(50), 0, math.radians(30))
sc.collection.objects.link(sun)
world = bpy.data.worlds.new("w")
world.color = (0.35, 0.38, 0.45)
sc.world = world

try:
    sc.render.engine = "BLENDER_EEVEE"
except TypeError:
    sc.render.engine = "BLENDER_WORKBENCH"
sc.render.resolution_x, sc.render.resolution_y = 480, 360
sc.render.film_transparent = False

for act in bpy.data.actions:
    use(act)
    a, b = (int(x) for x in act.frame_range)
    print("[preview] clip", act.name, "frames", b - a)
    for n in range(per):
        f = a + round((b - a) * n / max(1, per - 1)) if per > 1 else a
        sc.frame_set(f)
        sc.render.filepath = os.path.join(out_dir, "%s_%d.png" % (act.name, n))
        bpy.ops.render.render(write_still=True)
