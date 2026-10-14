# blender -b --python operative_build.py
# Builds godot/assets/models/operative/body.glb from the CC0 Quaternius Universal Base Character (male) and
# Universal Animation Library. The skin mesh is split into Head / Arms / Torso (by dominant bone weight per face) so
# the game can hide the head from the player's own camera and reuse the arms as viewmodel arms.
import bpy, bmesh, os

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "..", "operative", "src")
OUT = os.path.join(HERE, "..", "..", "godot", "assets", "models", "operative", "body.glb")
OLIVE = (0.30, 0.34, 0.22)  # uniform dye, times texture luminance
BOOT = (0.16, 0.13, 0.10)
SLEEVE = (0.18, 0.20, 0.12)  # linear
GLOVE = (0.025, 0.025, 0.022)
DROP_SKIN = ("Arms",)  # base skin parts replaced by the outfit (Ranger arms carry their own skin)
CLIPS = {  # UAL1 name -> name in the game
    "Idle_Loop": "idle", "Walk_Loop": "walk", "Jog_Fwd_Loop": "jog", "Sprint_Loop": "sprint",
    "Crouch_Idle_Loop": "crouch_idle", "Crouch_Fwd_Loop": "crouch_walk", "Jump_Start": "jump_start",
    "Jump_Loop": "jump", "Jump_Land": "jump_land", "Pistol_Idle_Loop": "pistol_idle",
    "Pistol_Aim_Neutral": "pistol_aim", "Pistol_Reload": "pistol_reload", "Death01": "death",
}
HEAD = {"neck_01", "Head"}
ARM_KEYS = ("upperarm", "lowerarm", "hand", "index", "middle", "pinky", "ring", "thumb")

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=os.path.join(SRC, "Superhero_Male_FullBody.gltf"))
for name in ("Icosphere", "Eyebrows", "Eyes"):
    o = bpy.data.objects.get(name)
    if o:
        bpy.data.objects.remove(o, do_unlink=True)
arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
arm.name = "Operative"
body = bpy.data.objects["SuperHero_Male"]

mat = body.data.materials[0]


def part_of(gname: str) -> int:
    if gname in HEAD:
        return 1
    if any(gname.startswith(k) for k in ARM_KEYS):
        return 2
    return 0


# Per-face class by the dominant group of its vertices, then separate by material slot.
names = {g.index: g.name for g in body.vertex_groups}
vclass = []
for v in body.data.vertices:
    best = max(v.groups, key=lambda g: g.weight, default=None)
    vclass.append(part_of(names[best.group]) if best else 0)
body.data.materials.append(mat)
body.data.materials.append(mat)
bpy.context.view_layer.objects.active = body
bpy.ops.object.mode_set(mode="EDIT")
bm = bmesh.from_edit_mesh(body.data)
for f in bm.faces:
    votes = [vclass[v.index] for v in f.verts]
    f.material_index = max(set(votes), key=votes.count)
bmesh.update_edit_mesh(body.data)
bpy.ops.mesh.select_all(action="SELECT")
bpy.ops.mesh.separate(type="MATERIAL")
bpy.ops.object.mode_set(mode="OBJECT")
parts = [o for o in bpy.data.objects if o.type == "MESH"]
for o in parts:
    gn = {g.index: g.name for g in o.vertex_groups}
    votes = [0, 0, 0]
    for v in o.data.vertices:
        best = max(v.groups, key=lambda g: g.weight, default=None)
        votes[part_of(gn[best.group]) if best else 0] += 1
    o.name = ["Torso", "Head", "Arms"][votes.index(max(votes))]
    o.data.name = o.name
    o.data.materials.clear()
    o.data.materials.append(mat)
    print("PART", o.name, len(o.data.vertices))

# Clothes: Quaternius Modular Outfits (Fantasy), Male Ranger parts, rebound to our armature and dyed olive.
RANGER = ["Male_Ranger_Body", "Male_Ranger_Legs", "Male_Ranger_Feet_Boots", "Male_Ranger_Arms"]
for o in [o for o in bpy.data.objects if o.name in ("Torso",) + DROP_SKIN]:
    bpy.data.objects.remove(o, do_unlink=True)
for part in RANGER:
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=os.path.join(SRC, part + ".gltf"))
    for o in set(bpy.data.objects) - before:
        if o.type == "MESH" and o.vertex_groups:
            o.parent = arm
            o.matrix_parent_inverse.identity()
            o.matrix_world = arm.matrix_world.copy()
            for m in o.modifiers:
                if m.type == "ARMATURE":
                    m.object = arm
            o.name = part.replace("Male_Ranger_", "").replace("Feet_", "")
            o.data.name = o.name
            print("CLOTH", o.name, len(o.data.vertices))
        else:
            bpy.data.objects.remove(o, do_unlink=True)
import numpy as np


def dyed(img, rgb, name):
    """Copy of img: luminance times rgb (glTF can't carry shader math, so the dye is baked)."""
    px = np.empty(len(img.pixels), dtype=np.float32)
    img.pixels.foreach_get(px)
    px = px.reshape(-1, 4)
    lum = px[:, :3] @ np.array([0.2126, 0.7152, 0.0722], dtype=np.float32)
    out = bpy.data.images.new(name, img.size[0], img.size[1], alpha=True)
    px[:, :3] = np.clip(lum[:, None] * np.array(rgb, dtype=np.float32) * 2.2, 0.0, 1.0)
    out.pixels.foreach_set(px.ravel())
    out.pack()
    return out


def flat(name, rgb, rough):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b.inputs["Base Color"].default_value = (*rgb, 1.0)
    b.inputs["Roughness"].default_value = rough
    return m


olive_img = boots_img = None
for m in [m for m in bpy.data.materials if m.node_tree and m.name.startswith("MI_Ranger")]:
    tex = next(n for n in m.node_tree.nodes if n.type == "TEX_IMAGE" and n.image and "BaseColor" in n.image.name)
    users = [o.name for o in bpy.data.objects if o.type == "MESH" and m.name in [x.name for x in o.data.materials]]
    if any(u.startswith("Boots") for u in users):
        boots_img = boots_img or dyed(tex.image, BOOT, "T_Operative_Boots")
        tex.image = boots_img
    else:
        olive_img = olive_img or dyed(tex.image, OLIVE, "T_Operative_Uniform")
        tex.image = olive_img
sleeve, glove = flat("M_Sleeve", SLEEVE, 0.9), flat("M_Glove", GLOVE, 0.75)
sl = next(o for o in bpy.data.objects if o.name.startswith("Arms.") or (o.name == "Arms" and len(o.data.materials) > 1))
gn = {g.index: g.name for g in sl.vertex_groups}
vhand = []
for v in sl.data.vertices:
    best = max(v.groups, key=lambda g: g.weight, default=None)
    vhand.append(bool(best) and any(gn[best.group].startswith(k) for k in ("hand", "index", "middle", "pinky", "ring", "thumb")))
skin = [i for i, m in enumerate(sl.data.materials) if not m.name.startswith("MI_Ranger")]
sl.data.materials.append(sleeve)
sl.data.materials.append(glove)
si, gi = len(sl.data.materials) - 2, len(sl.data.materials) - 1
for f in sl.data.polygons:
    if f.material_index in skin:
        hands = sum(vhand[v] for v in f.vertices)
        f.material_index = gi if hands * 2 >= len(f.vertices) else si
for o in [o for o in bpy.data.objects if o.name.startswith("Icosphere")]:
    bpy.data.objects.remove(o, do_unlink=True)
sl.name = sl.data.name = "Arms"
for o in bpy.data.objects:
    if o.type == "MESH":
        print("FINAL", o.name, [m.name for m in o.data.materials])

# Animations from UAL1: same skeleton, so its actions drive our armature directly.
before = set(bpy.data.objects)
bpy.ops.import_scene.gltf(filepath=os.path.join(SRC, "UAL1_Standard.glb"))
for o in set(bpy.data.objects) - before:
    bpy.data.objects.remove(o, do_unlink=True)
arm.animation_data_create()
for act in list(bpy.data.actions):
    base = act.name.split("|")[-1] if "|" in act.name else act.name
    if base in CLIPS:
        act.name = CLIPS[base]
        act.use_fake_user = True
        tr = arm.animation_data.nla_tracks.new()
        tr.name = act.name
        st = tr.strips.new(act.name, 0, act)
        if hasattr(st, "action_slot") and act.slots:
            st.action_slot = act.slots[0]
        tr.mute = True
    else:
        bpy.data.actions.remove(act)
print("CLIPS", sorted(a.name for a in bpy.data.actions))
arm.animation_data.action = None

for img in bpy.data.images:  # 4K sources -> 1K keeps the glb small; first person never gets close enough to tell
    if img.size[0] > 1024:
        img.scale(1024, 1024)
        img.pack()
os.makedirs(os.path.dirname(OUT), exist_ok=True)
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", export_animation_mode="NLA_TRACKS",
                          export_yup=True, export_apply=False, export_skins=True)
print("WROTE", OUT)
