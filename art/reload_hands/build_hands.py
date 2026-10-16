# F102: builds art/reload_hands/reload_hands.blend: every reloading gun lined up along X, with one left-hand
# marker per reload anchor (empty + hand proxy). Edit the markers, then run the "export_hands.py" text block.
# Run: blender -b --python art/reload_hands/build_hands.py   (from the repo root)
import bpy, json, math, os
from mathutils import Matrix, Vector

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
HERE = os.path.join(ROOT, "art", "reload_hands")
SPACING = 0.9
COLORS = {"mag": (0.9, 0.5, 0.1, 1), "charge": (0.2, 0.6, 1.0, 1), "pouch": (0.5, 0.5, 0.5, 1),
          "stop": (0.8, 0.2, 0.8, 1), "press": (0.9, 0.9, 0.2, 1), "slap": (1.0, 0.2, 0.2, 1),
          "lock": (0.2, 0.9, 0.5, 1), "grip": (0.3, 0.3, 0.3, 1)}


def g2b(v):  # Godot (x, y up, z back) -> Blender (x, y forward, z up), same as the glTF importer
    return Vector((v[0], -v[2], v[1]))


def frame(f, n):  # hand frame: Y = fingers, Z = palm normal, X = Y x Z
    y = g2b(f).normalized()
    z = g2b(n)
    z = (z - y * z.dot(y)).normalized()
    x = y.cross(z)
    return Matrix((x, y, z)).transposed().to_4x4()


def mat(name, col):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.diffuse_color = col
    m.use_nodes = True
    bsdf = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = col
    return m


def box(name, size, at, m, parent, coll):
    me = bpy.data.meshes.new(name)
    sx, sy, sz = [s * 0.5 for s in size]
    vs = [(x, y, z) for x in (-sx, sx) for y in (-sy, sy) for z in (-sz, sz)]
    fs = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    me.from_pydata([Vector(v) + Vector(at) for v in vs], [], fs)
    me.materials.append(m)
    ob = bpy.data.objects.new(name, me)
    coll.objects.link(ob)
    ob.parent = parent
    ob.hide_select = True  # select the empty, not the proxy
    return ob


def hand_proxy(empty, m, coll):
    # anchor point = where palm meets the object; the wrist is 7.5 cm back along the fingers, 3 cm off the palm
    box(empty.name + ".palm", (0.075, 0.08, 0.025), (0, -0.035, -0.015), m, empty, coll)
    box(empty.name + ".fingers", (0.07, 0.07, 0.018), (0, 0.04, -0.012), m, empty, coll)
    box(empty.name + ".thumb", (0.02, 0.05, 0.02), (0.045, 0.0, -0.01), m, empty, coll)


def label(text, at, coll):
    cu = bpy.data.curves.new(text, "FONT")
    cu.body = text
    cu.size = 0.04
    ob = bpy.data.objects.new("label." + text, cu)
    ob.location = at
    ob.rotation_euler = (math.radians(90), 0, 0)
    coll.objects.link(ob)


def main():
    data = json.load(open(os.path.join(HERE, "anchors.json")))
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    for i, (gun, row) in enumerate(sorted(data.items())):
        coll = bpy.data.collections.new(gun)
        scene.collection.children.link(coll)
        root = bpy.data.objects.new(gun + ".root", None)
        root.empty_display_type = "ARROWS"
        root.empty_display_size = 0.05
        root.location = (i * SPACING, 0, 0)
        root["rh_gun"] = gun
        coll.objects.link(root)
        before = set(bpy.data.objects)
        bpy.ops.import_scene.gltf(filepath=os.path.join(ROOT, row["glb"]))
        for ob in set(bpy.data.objects) - before:
            for c in ob.users_collection:
                c.objects.unlink(ob)
            coll.objects.link(ob)
            if ob.parent is None:
                ob.parent = root
                if row["flip"]:
                    ob.matrix_basis = Matrix.Rotation(math.pi, 4, "Z") @ ob.matrix_basis
            ob.hide_select = ob.type != "ARMATURE"
        label(gun, (i * SPACING - 0.1, 0.0, 0.25), coll)
        anchors = dict(row["anchors"])
        anchors["grip"] = row["grip"]
        for a, h in anchors.items():
            e = bpy.data.objects.new("%s.%s" % (gun, a), None)
            e.empty_display_type = "ARROWS"
            e.empty_display_size = 0.03
            e.matrix_basis = Matrix.Translation(g2b(h["p"])) @ frame(h["f"], h["n"])
            e.parent = root
            e["rh_gun"] = gun
            e["rh_anchor"] = a
            if a == "grip":
                e["rh_note"] = "reference only (rest pose), not exported"
            coll.objects.link(e)
            hand_proxy(e, mat("hand_" + a, COLORS.get(a, (1, 1, 1, 1))), coll)
    txt = bpy.data.texts.new("export_hands.py")
    txt.from_string(open(os.path.join(HERE, "export_hands.py")).read())
    out = os.path.join(HERE, "reload_hands.blend")
    bpy.ops.wm.save_as_mainfile(filepath=out)
    print("saved", out)


main()
