"""Roost: three curved bone masts hold a hanging leather brood sac; flyers drop out of a glowing
slit underneath. attack = launch (the sac swells and jerks, the slit gapes, the masts flex).
Game kind: roost. Real metres, scale 1.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
import struct_kit as sk  # noqa: E402

MASTS = sk.ring(3, 0.6, 0.2, math.pi / 2)
NEST = 1.5


def build():
    bones = [("root", (0, 0, 0), (0, 0, 0.1), None),
             ("base", (0, 0, 0), (0, 0, 0.3), "root"),
             ("nest", (0, 0, 2.05), (0, 0, NEST), "base"),
             ("lipL", (0, 0.06, NEST - 0.38), (0, 0.2, NEST - 0.45), "nest"),
             ("lipR", (0, -0.06, NEST - 0.38), (0, -0.2, NEST - 0.45), "nest"),
             ("flyer", (0, 0, NEST - 0.45), (0.25, 0, NEST - 0.45), "nest")]
    bones += [("mast%d" % i, (x, y, z), (x * 0.25, y * 0.25, 2.2), "base") for i, (x, y, z, _a) in enumerate(MASTS)]
    arm = lib.armature("roost", bones)
    b = lib.Builder("roost")
    b.lathe([(0.85, 0.0), (0.78, 0.12), (0.6, 0.24), (0.3, 0.3), (0.0, 0.32)], "hive_skin", "base", seg=12)
    for k in range(6):
        a = k * math.pi / 3
        b.limb((math.cos(a) * 0.65, math.sin(a) * 0.65, 0.1), (math.cos(a) * 1.1, math.sin(a) * 0.95, 0.0), 0.05, 0.02, "sinew", "base", seg=4)
    for i, (x, y, z, a) in enumerate(MASTS):
        c, s = math.cos(a), math.sin(a)
        pts = [(c * 0.62, s * 0.62, 0.1), (c * 0.8, s * 0.8, 0.9), (c * 0.62, s * 0.62, 1.7), (c * 0.15, s * 0.15, 2.25)]
        rs = [0.11, 0.09, 0.07, 0.05]
        for j in range(3):
            b.limb(pts[j], pts[j + 1], rs[j], rs[j + 1], "bone", "mast%d" % i, seg=6)
        b.limb(pts[2], (c * 0.95, s * 0.95, 1.95), 0.05, 0.0, "bone", "mast%d" % i, seg=4)  # thorn
        b.ball((c * 0.78, s * 0.78, 0.55), 0.09, "sick", "mast%d" % i, seg=5, rings=4)
        for z0, z1 in ((1.7, NEST + 0.15), (1.25, NEST - 0.15)):  # cradle strands
            b.limb(lerp_mast(pts, z0), (c * 0.36, s * 0.36, z1), 0.085, 0.07, "bone", "mast%d" % i, seg=6, bone_b="nest")
    b.ball((0, 0, 2.25), 0.1, "bone", "nest", seg=6, rings=4)
    b.limb((0, 0, 2.2), (0, 0, NEST + 0.3), 0.06, 0.09, "sinew", "nest", seg=5)  # stalk
    b.ball((0, 0, NEST), 0.4, "bat_skin", "nest", scale=(1.0, 1.0, 1.15), seg=10, rings=8)
    for k in range(5):  # ribbing over the sac
        a = k * 2 * math.pi / 5
        b.limb((math.cos(a) * 0.12, math.sin(a) * 0.12, NEST + 0.42), (math.cos(a) * 0.41, math.sin(a) * 0.41, NEST), 0.03, 0.035, "sinew", "nest", seg=4)
        b.limb((math.cos(a) * 0.41, math.sin(a) * 0.41, NEST), (math.cos(a) * 0.2, math.sin(a) * 0.2, NEST - 0.4), 0.035, 0.02, "sick", "nest", seg=4)
    b.ball((0, 0, NEST - 0.4), 0.3, "glow", "nest", scale=(0.8, 1.0, 0.55), seg=8, rings=5)
    for s, lip in ((1, "lipL"), (-1, "lipR")):
        b.ball((0, s * 0.11, NEST - 0.4), 0.13, "bat_skin", lip, scale=(1.3, 0.45, 0.6), seg=7, rings=5)
    b.ball((0, 0, NEST - 0.5), 0.17, "bat_skin", "flyer", scale=(1.4, 1, 0.8), seg=6, rings=4)
    for s in (1, -1):
        b.ball((0.2, s * 0.06, NEST - 0.47), 0.045, "glow", "flyer", seg=5, rings=4)
    for s in (1, -1):
        b.poly([(0.1, 0, NEST - 0.46), (-0.2, s * 0.75, NEST - 0.36), (-0.28, s * 0.15, NEST - 0.5)], ["flyer"] * 3, "bat_wing")
    b.finish(arm)
    return arm


def lerp_mast(pts, z):
    """Point on the mast polyline at height z."""
    for a, b in zip(pts, pts[1:]):
        if a[2] <= z <= b[2]:
            t = (z - a[2]) / (b[2] - a[2])
            return tuple(x + (y - x) * t for x, y in zip(a, b))
    return pts[-1]


def masts(arm, amount):
    return {"mast%d" % i: (lib.world_rot(arm, "mast%d" % i, sk.tangent(x, y), amount), None)
            for i, (x, y, _z, _a) in enumerate(MASTS)}


def lips(arm, o):
    return {"lipL": (lib.world_rot(arm, "lipL", (1, 0, 0), -1.3 * o), None),
            "lipR": (lib.world_rot(arm, "lipR", (1, 0, 0), 1.3 * o), None),
            "flyer": (None, None, (0.01, 0.01, 0.01))}


def idle(arm, t):
    w = 2 * math.pi * t
    p = masts(arm, 0.015 * math.sin(w))
    p.update(lips(arm, 0.1 + 0.1 * math.sin(2 * w)))
    s = 1 + 0.1 * math.sin(2 * w)
    p["nest"] = (lib.world_rot(arm, "nest", (1, 0, 0), 0.08 * math.sin(w)) @ lib.world_rot(arm, "nest", (0, 1, 0), 0.06 * math.cos(w)),
                 None, (s, s, s))
    return p


def attack(arm, t):
    swell = lib.pulse(t, 0.0, 0.5)
    drop = lib.pulse(t, 0.4, 0.8)
    p = masts(arm, 0.08 * swell - 0.05 * drop)
    p.update(lips(arm, 0.1 + 0.9 * lib.pulse(t, 0.3, 0.9)))
    f = (t - 0.45) / 0.55 if t > 0.45 else 0.0
    p["flyer"] = (lib.world_rot(arm, "flyer", (0, 1, 0), -0.6 * f), lib.world_loc(arm, "flyer", (1.6 * f, 0, -0.5 * f + 1.6 * f * f)),
                  (min(1.0, 0.4 + 2 * f) if f > 0 else 0.01,) * 3)
    s = 1 + 0.3 * swell - 0.15 * drop
    p["nest"] = (lib.world_rot(arm, "nest", (1, 0, 0), 0.15 * drop), lib.world_loc(arm, "nest", (0, 0, 0.12 * drop - 0.05 * swell)), (s, s, s))
    return p


if __name__ == "__main__":
    sk.run(build, idle, attack, attack_frames=24, top="nest",
           drop={"nest": 1.0}, fall=0.5, wilt={**{"mast%d" % i: sk.tangent(x, y) for i, (x, y, _z, _a) in enumerate(MASTS)}}, pop=())
