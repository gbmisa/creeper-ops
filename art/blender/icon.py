"""Render one build-menu icon: a glb at its idle pose, 3/4 view from above, transparent background.
Run: blender -b --python art/blender/icon.py -- <in.glb> <out.png> [size]
icons.sh renders the whole set (assembled weapons come from weapon_kit's PREVIEW glb).
"""
import math
import os
import sys

import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1:]
src, out = args[0], args[1]
px = int(args[2]) if len(args) > 2 else 160

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
sc = bpy.context.scene
arm = next((o for o in sc.objects if o.type == "ARMATURE"), None)
if arm and arm.animation_data:
    ad = arm.animation_data
    for tr in list(ad.nla_tracks):
        ad.nla_tracks.remove(tr)
    idle = bpy.data.actions.get("idle")
    if idle:
        ad.action = idle
        sc.frame_set(int(idle.frame_range[0]))
dg = bpy.context.evaluated_depsgraph_get()
pts = []
for o in sc.objects:
    if o.type == "MESH":
        ev = o.evaluated_get(dg)
        m = ev.to_mesh()
        pts += [ev.matrix_world @ v.co for v in m.vertices]
        ev.to_mesh_clear()
lo = Vector((min(p.x for p in pts), min(p.y for p in pts), max(0.0, min(p.z for p in pts))))
hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
centre = (lo + hi) * 0.5
radius = max((p - centre).length for p in pts if p.z >= lo.z - 0.01)

cam_data = bpy.data.cameras.new("cam")
cam_data.type = "ORTHO"
cam_data.ortho_scale = radius * 2.05
cam = bpy.data.objects.new("cam", cam_data)
sc.collection.objects.link(cam)
sc.camera = cam
d = Vector((1.0, -1.25, 0.95)).normalized()
cam.location = centre + d * radius * 4
cam.rotation_euler = (centre - cam.location).to_track_quat("-Z", "Y").to_euler()

for energy, rot in ((3.2, (50, 0, 30)), (1.2, (60, 0, 200))):
    ld = bpy.data.lights.new("sun", "SUN")
    ld.energy = energy
    lo_ = bpy.data.objects.new("sun", ld)
    lo_.rotation_euler = tuple(math.radians(a) for a in rot)
    sc.collection.objects.link(lo_)
world = bpy.data.worlds.new("w")
world.color = (0.5, 0.52, 0.48)
sc.world = world
try:
    sc.render.engine = "BLENDER_EEVEE"
except TypeError:
    sc.render.engine = "BLENDER_WORKBENCH"
sc.render.resolution_x = sc.render.resolution_y = px
sc.render.film_transparent = True
sc.render.image_settings.color_mode = "RGBA"
sc.render.filepath = out
bpy.ops.render.render(write_still=True)
print("[icon]", os.path.basename(out), "r=%.2f" % radius)
