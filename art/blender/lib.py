"""Shared Blender helpers for Creeper Ops creature models.

Contract with the game (docs/tasks/ART3_MUSE_briefs.md, brief A):
- one mesh skinned to one armature, authored at u = 1, feet at z = 0, facing +X
  (glTF/Godot keep +X, Blender +Z becomes Godot +Y);
- clips idle, walk (loops, 1 m/s ground speed), attack, hit, die;
- a material named "glow" that the game swaps for the tier colour.
Parts are rigid: every vertex belongs 100% to one bone, which suits low poly.
"""
import math
import bmesh
import bpy
from mathutils import Matrix, Quaternion, Vector

FPS = 24

# Linear-ish sRGB hex from the game palette (raider_meshes.gd).
PALETTE = {
    "chitin": ("4a3242", 0.85, 0.05, 0.0),
    "plate": ("6a5a48", 0.95, 0.0, 0.0),
    "bone": ("cbbd96", 0.7, 0.0, 0.0),
    "sick": ("6fd820", 0.5, 0.0, 2.0),
    "glow": ("a8ff5a", 0.4, 0.0, 3.0),
    "eye": ("ffe27a", 0.3, 0.0, 4.0),
    "robe": ("6e3a7c", 0.85, 0.0, 0.0),
}


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.render.fps = FPS


def _srgb(h):
    c = [int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)]
    return [x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in c]


def material(name):
    if name in bpy.data.materials:
        return bpy.data.materials[name]
    hexc, rough, metal, emit = PALETTE[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    col = _srgb(hexc) + [1.0]
    bsdf.inputs["Base Color"].default_value = col
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metal
    if emit > 0.0:
        bsdf.inputs["Emission Color"].default_value = col
        bsdf.inputs["Emission Strength"].default_value = emit
    return m


class Builder:
    """Collects primitives into one bmesh, tagging material and bone per part."""

    def __init__(self, name):
        self.name = name
        self.bm = bmesh.new()
        self.mats = []
        self.groups = {}

    def _mat_index(self, mat):
        if mat not in self.mats:
            self.mats.append(mat)
        return self.mats.index(mat)

    def _tag(self, verts, mat, bone, smooth):
        mi = self._mat_index(mat)
        faces = {f for v in verts for f in v.link_faces}
        for f in faces:
            f.material_index = mi
            f.smooth = smooth
        self.groups.setdefault(bone, []).extend(verts)

    def ball(self, at, r, mat, bone, scale=(1, 1, 1), seg=8, rings=6, smooth=True, rot=None):
        m = Matrix.Translation(Vector(at))
        if rot is not None:
            m = m @ rot.to_matrix().to_4x4()
        m = m @ Matrix.Diagonal(Vector(scale).to_4d())
        res = bmesh.ops.create_uvsphere(self.bm, u_segments=seg, v_segments=rings, radius=r, matrix=m)
        self._tag(res["verts"], mat, bone, smooth)

    def box(self, at, size, mat, bone, rot=None):
        m = Matrix.Translation(Vector(at))
        if rot is not None:
            m = m @ rot.to_matrix().to_4x4()
        m = m @ Matrix.Diagonal(Vector(size).to_4d())
        res = bmesh.ops.create_cube(self.bm, size=1.0, matrix=m)
        self._tag(res["verts"], mat, bone, False)

    def lathe(self, profile, mat, bone, at=(0, 0, 0), seg=8, smooth=True):
        """Surface of revolution round +Z through (radius, height) points, bottom up; open ends are capped."""
        rings = []
        for r, h in profile:
            rings.append([self.bm.verts.new((at[0] + r * math.cos(2 * math.pi * k / seg),
                                             at[1] + r * math.sin(2 * math.pi * k / seg), at[2] + h)) for k in range(seg)])
        for lo, hi in zip(rings, rings[1:]):
            for k in range(seg):
                self.bm.faces.new((lo[k], lo[(k + 1) % seg], hi[(k + 1) % seg], hi[k]))
        for ring, (r, _h) in ((rings[0], profile[0]), (rings[-1], profile[-1])):
            if r > 1e-4:
                self.bm.faces.new(ring if ring is rings[-1] else list(reversed(ring)))
        self._tag([v for ring in rings for v in ring], mat, bone, smooth)

    def limb(self, a, b, r0, r1, mat, bone, seg=6, smooth=False, bone_b=None):
        """Tapered cylinder (cone when r1 == 0) from a to b; bone_b skins the b half to another bone."""
        a, b = Vector(a), Vector(b)
        d = b - a
        rot = Vector((0, 0, 1)).rotation_difference(d.normalized())
        m = Matrix.Translation((a + b) * 0.5) @ rot.to_matrix().to_4x4()
        res = bmesh.ops.create_cone(self.bm, cap_ends=True, cap_tris=False, segments=seg,
                                    radius1=r0, radius2=max(r1, 0.0), depth=d.length, matrix=m)
        if bone_b is None:
            self._tag(res["verts"], mat, bone, smooth)
            return
        near_a = [v for v in res["verts"] if (v.co - a).dot(d) < d.length_squared * 0.5]
        self._tag(near_a, mat, bone, smooth)
        self._tag([v for v in res["verts"] if v not in near_a], mat, bone_b, smooth)

    def finish(self, arm):
        bmesh.ops.remove_doubles(self.bm, verts=self.bm.verts, dist=1e-5)
        bmesh.ops.recalc_face_normals(self.bm, faces=self.bm.faces)
        self.bm.verts.index_update()
        me = bpy.data.meshes.new(self.name)
        groups = {b: sorted({v.index for v in vs if v.is_valid}) for b, vs in self.groups.items()}
        self.bm.to_mesh(me)
        self.bm.free()
        for m in self.mats:
            me.materials.append(material(m))
        ob = bpy.data.objects.new(self.name, me)
        bpy.context.scene.collection.objects.link(ob)
        for b, idx in groups.items():
            vg = ob.vertex_groups.new(name=b)
            vg.add(idx, 1.0, "REPLACE")
        ob.parent = arm
        mod = ob.modifiers.new("Armature", "ARMATURE")
        mod.object = arm
        return ob


def armature(name, bones):
    """bones: list of (name, head, tail, parent or None)."""
    data = bpy.data.armatures.new(name + "_rig")
    arm = bpy.data.objects.new(name + "_rig", data)
    bpy.context.scene.collection.objects.link(arm)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    for bn, head, tail, parent in bones:
        eb = data.edit_bones.new(bn)
        eb.head, eb.tail = Vector(head), Vector(tail)
        if parent:
            eb.parent = data.edit_bones[parent]
    bpy.ops.object.mode_set(mode="OBJECT")
    for pb in arm.pose.bones:
        pb.rotation_mode = "QUATERNION"
    return arm


def local_q(arm, bone, q):
    """Armature-space rotation quaternion as the bone's local pose quaternion."""
    m = arm.data.bones[bone].matrix_local.to_3x3()
    return (m.inverted() @ q.to_matrix() @ m).to_quaternion()


def world_rot(arm, bone, axis, angle):
    return local_q(arm, bone, Quaternion(Vector(axis), angle))


def world_loc(arm, bone, offset):
    """Armature-space offset as the bone's local pose location."""
    return arm.data.bones[bone].matrix_local.to_3x3().inverted() @ Vector(offset)


def action(arm, name, frames, pose_fn, step=2, loop=False):
    """Bake an action by sampling pose_fn(t in 0..1) -> {bone: (quat, loc[, scale]) with None = rest}."""
    act = bpy.data.actions.new(name)
    act.use_fake_user = True
    ad = arm.animation_data or arm.animation_data_create()
    ad.action = act
    keys = list(range(0, frames + 1, step))
    if keys[-1] != frames:
        keys.append(frames)
    for f in keys:
        t = f / frames
        pose = pose_fn(t)
        for pb in arm.pose.bones:
            q, loc, *sc = pose.get(pb.name, (None, None))
            pb.rotation_quaternion = q if q is not None else Quaternion()
            pb.location = loc if loc is not None else Vector()
            pb.scale = Vector(sc[0]) if sc and sc[0] is not None else Vector((1, 1, 1))
            pb.keyframe_insert("rotation_quaternion", frame=f)
            pb.keyframe_insert("location", frame=f)
            pb.keyframe_insert("scale", frame=f)
    track = ad.nla_tracks.new()
    track.name = name
    track.strips.new(name, 0, act)
    ad.action = None
    return act


def ease(t):
    return t * t * (3.0 - 2.0 * t)


def pulse(t, a, b):
    """0 outside [a, b], smooth bump to 1 in the middle."""
    if t <= a or t >= b:
        return 0.0
    return math.sin(math.pi * (t - a) / (b - a))


def export(path):
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_animations=True,
                              export_animation_mode="ACTIONS", export_force_sampling=True,
                              export_yup=True, export_apply=False, export_skins=True)
