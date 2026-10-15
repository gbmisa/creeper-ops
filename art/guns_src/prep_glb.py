# blender -b --python prep_glb.py -- in.glb out.blend
# Imports a downloaded free-pack GLB and bakes it for export_gun.py: armature poses applied to the meshes, rigs and
# animation clips dropped (the game's static guns carry none), parents cleared. Never run from the download folder.
import bpy, sys
a = sys.argv[sys.argv.index("--")+1:]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=a[0])
shapes = {pb.custom_shape for o in bpy.data.objects if o.type == 'ARMATURE' for pb in o.pose.bones if pb.custom_shape}
for o in list(bpy.data.objects):
    if o in shapes or (o.type == 'MESH' and o.name.startswith('Icosphere')): bpy.data.objects.remove(o)  # importer's bone-shape helpers
dg = bpy.context.evaluated_depsgraph_get()
for o in [o for o in bpy.data.objects if o.type == 'MESH']:  # evaluated = armature pose + rig scale applied, in world space
    e = o.evaluated_get(dg)
    me = bpy.data.meshes.new_from_object(e, preserve_all_data_layers=True, depsgraph=dg)
    me.transform(e.matrix_world)
    n = bpy.data.objects.new(o.name, me)
    bpy.context.scene.collection.objects.link(n)
    bpy.data.objects.remove(o)
for o in list(bpy.data.objects):
    if o.type != 'MESH': bpy.data.objects.remove(o)
for act in list(bpy.data.actions): bpy.data.actions.remove(act)
bpy.ops.wm.save_as_mainfile(filepath=a[1])
print("@@ prepped", len(bpy.data.objects), "meshes")
