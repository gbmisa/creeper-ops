# blender -b --python art/tools/glb_preview.py -- in.glb out.png : grey-clay 3/4 render + mesh stats (tris, size).
import bpy, sys, math
from mathutils import Vector
src, out = sys.argv[sys.argv.index("--") + 1:][:2]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
meshes = [o for o in bpy.data.objects if o.type == "MESH"]
tris = sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in meshes)
pts = [o.matrix_world @ Vector(c) for o in meshes for c in o.bound_box]
lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
c, r = (lo + hi) / 2, (hi - lo).length / 2
print("STATS tris=%d size=%.3f,%.3f,%.3f" % (tris, *(hi - lo)))
sc = bpy.context.scene
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
sc.collection.objects.link(cam)
sc.camera = cam
d = Vector((1.0, -1.3, 0.8)).normalized() * r * 3.2
cam.location = c + d
cam.rotation_euler = (c - cam.location).to_track_quat("-Z", "Y").to_euler()
sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
sun.data.energy = 3.5
sun.rotation_euler = (math.radians(45), 0, math.radians(35))
sc.collection.objects.link(sun)
sc.world = bpy.data.worlds.new("w")
sc.world.color = (0.4, 0.4, 0.45)
sc.render.resolution_x = sc.render.resolution_y = 512
try:
    sc.render.engine = "BLENDER_EEVEE_NEXT"
except TypeError:
    sc.render.engine = "BLENDER_EEVEE"
sc.render.filepath = out
bpy.ops.render.render(write_still=True)
