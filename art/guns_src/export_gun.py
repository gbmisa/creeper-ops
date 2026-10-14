# blender -b in.blend --python export_gun.py -- out.glb length_m flip(0/1) [ak]
import bpy, sys, math
from mathutils import Vector, Matrix
a = sys.argv[sys.argv.index("--")+1:]
out, length, flip = a[0], float(a[1]), int(a[2])
special = a[3] if len(a) > 3 else ""
sc = bpy.context.scene
for o in list(bpy.data.objects):
    if o.type not in ('MESH', 'ARMATURE'): bpy.data.objects.remove(o)
dg = bpy.context.evaluated_depsgraph_get()
mn = Vector((1e9,)*3); mx = Vector((-1e9,)*3)
for o in bpy.data.objects:
    if o.type == 'MESH':
        for c in o.bound_box:
            w = o.matrix_world @ Vector(c); mn = Vector(map(min, mn, w)); mx = Vector(map(max, mx, w))
size = mx - mn; ctr = (mx + mn) / 2
along_x = size.x > size.y
L = max(size.x, size.y)
# muzzle -> Blender +Y (Godot -Z after glTF Y-up conversion)
ang = (-math.pi/2 if along_x else 0.0) + (math.pi if flip else 0.0)
M = Matrix.Rotation(ang, 4, 'Z') @ Matrix.Scale(length / L, 4) @ Matrix.Translation(-ctr)
root = bpy.data.objects.new("Gun", None); sc.collection.objects.link(root)
for o in list(bpy.data.objects):
    if o is root or o.parent: continue
    o.parent = root; o.matrix_parent_inverse = Matrix.Identity(4)
root.matrix_world = M
# bake root transform into children's parent inverse is not needed: glTF keeps the node
if special == "ak":
    arm = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
    mesh = next(o for o in bpy.data.objects if o.type == 'MESH')
    gi = mesh.vertex_groups["Magazine"].index
    vs = [v.co for v in mesh.data.vertices if any(g.group == gi and g.weight > 0.5 for g in v.groups)]
    mc = sum(vs, Vector()) / len(vs)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode='EDIT')
    inv = arm.matrix_world.inverted() @ mesh.matrix_world
    b = arm.data.edit_bones.new("Magazine"); h = inv @ mc
    b.head = h; b.tail = h + Vector((0, 0, 0.3))
    bpy.ops.object.mode_set(mode='OBJECT')
    print("@@ groups", mesh.vertex_groups.keys())
    # gun-space axes in armature space: barrel direction = original X (+/-), down = -Z
    fwd = Vector((1 if not flip else -1, 0, 0)) if along_x else Vector((0, 1 if not flip else -1, 0))
    def key(pb, f, v_arm):
        rot = pb.bone.matrix_local.to_3x3().inverted()
        pb.location = rot @ v_arm; pb.keyframe_insert("location", frame=f)
    arm.animation_data_create()
    bolt = arm.pose.bones["Bolt"]; mag = arm.pose.bones["Magazine"]
    stroke = 0.12 * L  # bolt travel in source units
    for name, keys in (("Fire", [(0, 0), (2, 1), (5, 0)]), ):
        act = bpy.data.actions.new(name); act.use_fake_user = True; arm.animation_data.action = act
        for f, t in keys: key(bolt, f, -fwd * stroke * t)
        key(mag, 0, Vector())
    act = bpy.data.actions.new("Reload"); act.use_fake_user = True; arm.animation_data.action = act
    down = Vector((0, 0, -1))
    for f, v in ((0, Vector()), (8, down * 0.06 * L - fwd * 0.02 * L), (14, down * 0.5 * L), (22, down * 0.06 * L - fwd * 0.02 * L), (28, Vector())):
        key(mag, f, v)
    for f, t in ((0, 0), (30, 0), (34, 1.2), (38, 0)): key(bolt, f, -fwd * stroke * t)
    arm.animation_data.action = None
def to_principled(m):
    if not m.use_nodes or not m.node_tree: return
    nt = m.node_tree
    src = next((n for n in nt.nodes if n.type == 'BSDF_PRINCIPLED'), None) or next((n for n in nt.nodes if n.type == 'BSDF_DIFFUSE'), None)
    col = list(src.inputs[0].default_value) if src else list(m.diffuse_color)
    if col[0] > 0.95 and col[1] > 0.95 and col[2] > 0.95: col = [0.12, 0.12, 0.13, 1]  # untextured white -> gunmetal
    nt.nodes.clear()
    o = nt.nodes.new('ShaderNodeOutputMaterial'); b = nt.nodes.new('ShaderNodeBsdfPrincipled')
    nt.links.new(b.outputs[0], o.inputs[0])
    b.inputs['Base Color'].default_value = col
    n = m.name.lower(); metal = any(k in n for k in ('metal', 'barrel', 'black', 'magazine', 'scope')) or (not 'wood' in n and max(col[:3]) < 0.3)
    b.inputs['Metallic'].default_value = 0.75 if metal else 0.0
    b.inputs['Roughness'].default_value = 0.42 if metal else 0.72
for m in bpy.data.materials: to_principled(m)
bpy.ops.export_scene.gltf(filepath=out, export_format='GLB', export_animations=True, export_animation_mode='ACTIONS', export_apply=False, export_yup=True)
print("@@ wrote", out, "L", round(L, 2), "along_x", along_x, "acts", [x.name for x in bpy.data.actions])
