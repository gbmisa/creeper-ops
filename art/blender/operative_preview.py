# blender -b --python operative_preview.py -- out.png [clip] [frame] : renders body.glb front 3/4 view.
import bpy, os, sys, math
args = sys.argv[sys.argv.index("--") + 1:]
out, clip, frame = args[0], (args[1] if len(args) > 1 else "walk"), int(args[2]) if len(args) > 2 else 8
HERE = os.path.dirname(os.path.abspath(__file__))
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=os.path.join(HERE, "..", "..", "godot", "assets", "models", "operative", "body.glb"))
arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
arm.animation_data_create()
arm.animation_data.action = bpy.data.actions.get(clip) or next(a for a in bpy.data.actions if a.name.startswith(clip))
if arm.animation_data.action.slots:
    arm.animation_data.action_slot = arm.animation_data.action.slots[0]
for t in arm.animation_data.nla_tracks:
    t.mute = True
sc = bpy.context.scene
sc.frame_set(frame)
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
sc.collection.objects.link(cam)
cam.location = (2.2, -3.0, 1.4)
cam.rotation_euler = (math.radians(82), 0, math.radians(36))
sc.camera = cam
sun = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
sun.data.energy = 3.0
sun.rotation_euler = (math.radians(50), 0, math.radians(30))
sc.collection.objects.link(sun)
sc.world = bpy.data.worlds.new("w")
sc.world.color = (0.35, 0.35, 0.4)
sc.render.resolution_x, sc.render.resolution_y = 480, 640
try:
    sc.render.engine = "BLENDER_EEVEE_NEXT"
except TypeError:
    sc.render.engine = "BLENDER_EEVEE"
sc.render.filepath = out
bpy.ops.render.render(write_still=True)
