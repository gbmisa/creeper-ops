"""Player weapons as three glbs (base, turret, arm) so the game keeps yawing its Turret node and
pitching its Arm node (docs/tasks/ART3_A4_structure_models.md).
A weapon lists bones as (name, head, tail, parent, part) in assembled space (Blender, Z up) and
builds every primitive through Kit, which keeps only the current part and moves it so that part's
pivot is the origin. Poses are {bone: {"rot": (axis, ang), "loc": (x, y, z), "scale": s}} in
assembled armature space; bones missing from the current part are skipped.
Pivots come from WeaponMeshes: turret = (0, 0, Turret.y); arm = turret + (at.x, 0, at.y).
Writes <dir>/<id>_base.glb, _turret.glb and _arm.glb; with PREVIEW=path, also the assembled weapon.
"""
import math
import os
import sys

import lib
from mathutils import Vector

PARTS = ("base", "turret", "arm")
HIDE = 0.01


class Kit:
    def __init__(self, name, bones, part, pivots):
        self.part = part
        self.off = Vector(pivots[part]) if part else Vector()
        self.owner = {b[0]: b[4] for b in bones}
        self.b = lib.Builder(name)

    def _keep(self, bone):
        return self.part is None or self.owner[bone] == self.part

    def _p(self, p):
        return tuple(Vector(p) - self.off)

    def box(self, at, size, mat, bone, rot=None):
        if self._keep(bone):
            self.b.box(self._p(at), size, mat, bone, rot=rot)

    def ball(self, at, r, mat, bone, **kw):
        if self._keep(bone):
            self.b.ball(self._p(at), r, mat, bone, **kw)

    def lathe(self, profile, mat, bone, at=(0, 0, 0), **kw):
        if self._keep(bone):
            self.b.lathe(profile, mat, bone, at=self._p(at), **kw)

    def limb(self, a, b, r0, r1, mat, bone, **kw):
        if self._keep(bone):
            self.b.limb(self._p(a), self._p(b), r0, r1, mat, bone, **kw)

    def tube(self, pts, mat, bone, seg=12):
        """Barrel along a line: pts = [(point, radius), ...]; each pair is one tapered section."""
        for (a, ra), (b, rb) in zip(pts, pts[1:]):
            self.limb(a, b, ra, rb, mat, bone, seg=seg)


def _armature(name, bones, part, pivots):
    off = Vector(pivots[part]) if part else Vector()
    keep = [b for b in bones if part is None or b[4] == part]
    names = {b[0] for b in keep}
    return lib.armature(name, [(n, tuple(Vector(h) - off), tuple(Vector(t) - off), p if p in names else None)
                               for n, h, t, p, _part in keep])


def convert(arm, spec):
    out = {}
    for bn, s in spec.items():
        if bn not in arm.data.bones:
            continue
        q = lib.world_rot(arm, bn, *s["rot"]) if "rot" in s else None
        loc = lib.world_loc(arm, bn, s["loc"]) if "loc" in s else None
        sc = s.get("scale")
        out[bn] = (q, loc, (sc,) * 3 if isinstance(sc, (int, float)) else sc)
    return out


def sink(t):
    """Shared by every part's die so the turret sinks with the base it no longer sits on."""
    return 1.0 * lib.ease(max(0.0, (t - 0.25) / 0.75))


def die_common(t, debris=()):
    """Base sinks; the turret sinks the same and tips over; the arm droops; debris flies out."""
    s, k = sink(t), lib.ease(min(1.0, t / 0.7))
    p = {"base": {"loc": (0, 0, -s), "scale": (1 + 0.1 * s, 1 + 0.1 * s, max(0.3, 1 - 0.5 * s))},
         "turret": {"loc": (0, 0, -s), "rot": ((1, 0.3, 0), 0.6 * k)},
         "arm": {"rot": ((0, 1, 0), 1.0 * k)}}
    for i, (bn, (x, y)) in enumerate(debris):
        d = 3.2 * k
        p[bn] = {"loc": (x * d, y * d, 1.6 * k - 1.9 * k * k), "rot": ((y, -x, 0), 3 * k),
                 "scale": 1.3}
    return p


def hit_common(t):
    j = lib.pulse(t, 0.0, 1.0) * (1.0 - t)
    return {"turret": {"rot": ((0.3, 0, 1), 0.35 * j * math.sin(14 * t))},
            "arm": {"rot": ((0, 1, 0), -0.4 * j)}}


def run(name, bones, pivots, geometry, clips):
    """clips: {name: (frames, pose_fn(t) -> spec, loop)}; walk is copied from idle."""
    out = sys.argv[sys.argv.index("--") + 1]
    d = os.path.dirname(out)
    targets = [(p, os.path.join(d, "%s_%s.glb" % (name, p))) for p in PARTS]
    if os.environ.get("PREVIEW"):
        targets.append((None, os.environ["PREVIEW"]))
    clips = dict(clips)
    clips["walk"] = clips["idle"]
    for part, path in targets:
        lib.reset()
        arm = _armature(name, bones, part, pivots)
        k = Kit(name, bones, part, pivots)
        geometry(k)
        k.b.finish(arm)
        for clip in ("idle", "walk", "attack", "hit", "die"):
            frames, fn, loop = clips[clip]
            lib.action(arm, clip, frames, lambda t, fn=fn: convert(arm, fn(t)), step=1, loop=loop)
        lib.export(path)
