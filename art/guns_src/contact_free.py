# blender -b --python contact_free.py -- out.png cell_w cell_h cols_per_row "label|old.glb|new.glb|note" ...
# Side-view (muzzle right) contact sheet: each row = current model (left) beside the free candidate (right), labelled.
# Rows are laid out top to bottom. new.glb may be '-' (no candidate: old only).
import bpy, sys
from mathutils import Vector
a = sys.argv[sys.argv.index("--")+1:]
out, cw, ch = a[0], float(a[1]), float(a[2])
rows = [r.split("|") for r in a[4:]]
bpy.ops.wm.read_factory_settings(use_empty=True)
sc = bpy.context.scene
def load(path, x, z):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    new = [o for o in bpy.data.objects if o not in before]
    ms = [o for o in new if o.type == 'MESH' and not o.name.startswith('Icosphere')]
    pts = [o.matrix_world @ v.co for o in ms for v in o.data.vertices]
    mn = Vector(map(min, *pts)); mx = Vector(map(max, *pts)); c = (mn + mx) / 2
    root = bpy.data.objects.new("r", None); sc.collection.objects.link(root)
    for o in new:
        if not o.parent: o.parent = root
    root.location = Vector((0, x - c.y, z - c.z)) - Vector((c.x, 0, 0))
    for o in new:
        if o.name.startswith('Icosphere'): o.hide_render = True  # bone-shape helpers
def label(txt, x, z):
    t = bpy.data.curves.new("t", 'FONT'); t.body = txt; t.size = ch * 0.11; t.align_x = 'CENTER'
    o = bpy.data.objects.new("t", t); sc.collection.objects.link(o)
    o.rotation_euler = (1.5708, 0, 1.5708); o.location = (0, x, z)
n = len(rows)
for i, r in enumerate(rows):
    z = -i * ch
    label(r[0] + "  CURRENT", -cw / 2, z + ch * 0.42); load(r[1], -cw / 2, z)
    if r[2] != '-':
        label(r[0] + "  FREE: " + (r[3] if len(r) > 3 else ""), cw / 2, z + ch * 0.42); load(r[2], cw / 2, z)
    else:
        label(r[0] + "  no free candidate", cw / 2, z)
cam = bpy.data.cameras.new("c"); cam.type = 'ORTHO'
W = 2 * cw + 0.2; H = n * ch + 0.1
cam.ortho_scale = max(W, H * 1800 / 1100)
co = bpy.data.objects.new("c", cam); sc.collection.objects.link(co)
co.location = (20, 0, -(n - 1) * ch / 2); co.rotation_euler = (1.5708, 0, 1.5708); sc.camera = co
sc.render.resolution_x = 1800; sc.render.resolution_y = 1100
sc.render.engine = 'BLENDER_WORKBENCH'
sh = sc.display.shading; sh.light = 'STUDIO'; sh.color_type = 'TEXTURE'; sh.show_cavity = False
sc.view_settings.view_transform = 'Standard'
w = bpy.data.worlds.new("w"); w.color = (0.55, 0.57, 0.6); sc.world = w
for o in bpy.data.objects:
    if o.type == 'MESH':
        for m in o.data.materials:
            if m and m.use_nodes:
                b = next((n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'), None)
                if b: m.diffuse_color = b.inputs[0].default_value
sc.render.filepath = out
bpy.ops.render.render(write_still=True)
print("@@ rendered", out)
