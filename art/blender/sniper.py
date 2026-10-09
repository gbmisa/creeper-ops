"""Sniper in three parts (weapon_kit), military: a steel lattice watchtower on concrete footings
with an armoured olive cabin, hazard band and ladder (base); a gunmetal turntable with a sloped
gun shield, an ammo can and a rangefinder (turret); a jointed box-beam arm holding a long
anti-materiel rifle: olive stock and handguard, fluted barrel, muzzle brake, red-lensed scope,
magazine and a folded bipod (arm).
Pivots match WeaponMeshes.sniper: Turret y 2.0, Arm at (-0.3, 0.3), wrist (0.635, 1.268) from
the shoulder, Muzzle (2.25, 0.24) ahead of the wrist. Bone names are kept from the ballista
version (limb0/1 = bipod legs, nock = bolt handle, bolt = tracer round, crank = spent casing).
Clips: idle = scope lens breathes; attack = flash, recoil, the bolt cycles and a casing flies,
a tracer streaks out; hit = shudder; die = tower sinks, sandbags fly, the rifle droops.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
import mil_kit as mk  # noqa: E402
import weapon_kit as wk  # noqa: E402
from mathutils import Quaternion, Vector  # noqa: E402

T = Vector((0, 0, 2.0))
A = T + Vector((-0.3, 0, 0.3))
E = A + Vector((0.285, 0, 1.268))
W = A + Vector((0.635, 0, 1.268))
BORE = W + Vector((0, 0, 0.24))
NOCK = W + Vector((-0.3, 0.2, 0.24))
ROOT = [BORE + Vector((1.5, s * 0.08, -0.1)) for s in (1, -1)]
TIP = [BORE + Vector((2.0, s * 0.12, -0.2)) for s in (1, -1)]
CRANK = W + Vector((-0.3, 0, 0.24))
MUZ = BORE + Vector((2.25, 0, 0))
X = Vector((1, 0, 0))
CHUNKS = [("chunk%d" % i, (math.cos(a), math.sin(a))) for i, a in enumerate(k * math.pi / 2 for k in range(4))]

BONES = [("base", (0, 0, 0), (0, 0, 0.5), None, "base")]
BONES += [(n, (x * 0.62, y * 0.62, 0.2), (x * 0.62, y * 0.62, 0.5), "base", "base") for n, (x, y) in CHUNKS]
BONES += [("turret", tuple(T), tuple(T + Vector((0, 0, 0.3))), None, "turret"),
          ("arm", tuple(A), tuple(A + Vector((0, 0, 0.3))), "turret", "arm"),
          ("head", tuple(W), tuple(W + X * 0.3), "arm", "arm"),
          ("nock", tuple(NOCK), tuple(NOCK + X * 0.3), "head", "arm"),
          ("bolt", tuple(BORE + X * 2.3), tuple(BORE + X * 2.6), "head", "arm"),
          ("trail", tuple(BORE + X * 2.3), tuple(BORE + X * 2.6), "head", "arm"),
          ("crank", tuple(CRANK + Vector((0, 0.3, 0))), tuple(CRANK + Vector((0, 0.6, 0))), "head", "arm"),
          ("flash", tuple(MUZ), tuple(MUZ + X * 0.3), "head", "arm")]
BONES += [("limb%d" % i, tuple(r), tuple(t), "head", "arm") for i, (r, t) in enumerate(zip(ROOT, TIP))]
PIVOTS = {"base": (0, 0, 0), "turret": tuple(T), "arm": tuple(A)}
LEGS = [(x, y) for x in (1, -1) for y in (1, -1)]


def tower(k):
    mk.slab(k, 0.95, 0.16, "base")
    for x, y in LEGS:
        k.box((x * 0.72, y * 0.72, 0.24), (0.3, 0.3, 0.16), "concrete", "base")
        k.limb(Vector((x * 0.72, y * 0.72, 0.3)), Vector((x * 0.5, y * 0.5, 1.56)), 0.065, 0.055, "olive_dark", "base", seg=4)
    for side in range(4):  # X braces on every face
        q = Quaternion((0, 0, 1), side * math.pi / 2)
        for z0, z1, h0, h1 in ((0.32, 0.94, 0.71, 0.61), (0.94, 1.54, 0.61, 0.51)):
            for s in (1, -1):
                a, b = q @ Vector((h0 * s, h0, z0)), q @ Vector((-h1 * s, h1, z1))
                k.limb(a, b, 0.025, 0.025, "steel", "base", seg=4)
            k.limb(q @ Vector((-h1, h1, z1)), q @ Vector((h1, h1, z1)), 0.035, 0.035, "gunmetal", "base", seg=4)
    mk.ladder(k, -0.52, 0, 0.16, 1.56, "base", face=(-1, 0))
    for n, (x, y) in CHUNKS:  # sandbag piles between the legs
        q = Quaternion((0, 0, 1), math.atan2(y, x) + math.pi / 2)
        for dz, sh in ((0.0, (0.0, 0.0)), (0.0, (0.3, 0.0)), (0.0, (-0.3, 0.0)), (0.14, (0.15, 0.0)), (0.14, (-0.15, 0.0))):
            off = q @ Vector((sh[0], 0, 0))
            k.ball((x * 0.86 + off.x, y * 0.86 + off.y, 0.26 + dz), 0.17, "sandbag", n, scale=(1.0, 0.6, 0.42),
                   seg=6, rings=3, rot=q)
    # armoured cabin
    k.box((0, 0, 1.55), (1.34, 1.34, 0.06), "gunmetal", "base")
    mk.square(k, 0.6, 1.58, 1.95, "olive", "base")
    mk.hazard_band(k, 0.6, 1.66, 0.08, "base", n=6)
    for side in range(4):
        q = Quaternion((0, 0, 1), side * math.pi / 2)
        k.box(tuple(q @ Vector((0, 0.605, 1.83))), tuple(abs(c) for c in q @ Vector((0.7, 0.02, 0.07))), "rubber", "base")
    k.lathe([(0.48, 1.94), (0.6, 1.94), (0.6, 2.04), (0.48, 2.04), (0.48, 1.94)], "gunmetal", "base", seg=16, cap=False)


def geometry(k):
    tower(k)
    # turret: turntable, sloped shield, ammo can, rangefinder
    mk.turntable(k, 0.56, 2.0, 2.13, "turret")
    for s in (1, -1):
        k.box((A.x, s * 0.3, 2.32), (0.56, 0.07, 0.42), "olive", "turret")
        k.ball((A.x, s * 0.35, A.z), 0.07, "steel", "turret", seg=6, rings=3)
    k.box((0.22, 0, 2.27), (0.1, 0.66, 0.3), "olive_dark", "turret", rot=Quaternion((0, 1, 0), -0.35))
    mk.crate(k, (-0.68, 0.18, 2.26), (0.3, 0.22, 0.26), "turret")
    k.box((-0.62, -0.2, 2.24), (0.22, 0.3, 0.2), "gunmetal", "turret")
    k.limb((-0.5, -0.2, 2.26), (-0.42, -0.2, 2.26), 0.06, 0.06, "steel", "turret", seg=8)
    # arm: axle, twin box beams, elbow, forearm
    k.limb(A + Vector((0, -0.38, 0)), A + Vector((0, 0.38, 0)), 0.08, 0.08, "steel", "arm", seg=8)
    for s in (1, -1):
        k.limb(A + Vector((0, s * 0.12, 0)), E + Vector((0, s * 0.12, 0)), 0.085, 0.075, "olive", "arm", seg=4)
    k.limb(E + Vector((0, -0.2, 0)), E + Vector((0, 0.2, 0)), 0.1, 0.1, "steel", "arm", seg=8)
    k.limb(E, W, 0.1, 0.1, "gunmetal", "arm", seg=4)
    # head: receiver, stock, handguard, fluted barrel, brake, scope, magazine
    k.ball(tuple(W), 0.13, "steel", "head", seg=6, rings=3)
    k.box(W + Vector((0, 0, 0.12)), (0.24, 0.16, 0.2), "gunmetal", "head")
    k.box(BORE + Vector((-0.35, 0, -0.02)), (0.9, 0.2, 0.22), "olive", "head")
    k.box(BORE + Vector((-0.95, 0, -0.06)), (0.4, 0.14, 0.3), "olive_dark", "head")
    k.box(BORE + Vector((-1.17, 0, -0.06)), (0.05, 0.16, 0.32), "rubber", "head")
    k.box(BORE + Vector((-0.1, 0, -0.24)), (0.18, 0.12, 0.26), "gunmetal", "head", rot=Quaternion((0, 1, 0), 0.2))
    k.limb(BORE + X * 0.1, BORE + X * 0.95, 0.11, 0.1, "olive", "head", seg=8)
    k.limb(BORE + X * 0.95, BORE + X * 2.05, 0.08, 0.075, "gunmetal", "head", seg=8)
    for x in (1.15, 1.45, 1.75):
        k.limb(BORE + X * x, BORE + X * (x + 0.05), 0.095, 0.095, "steel", "head", seg=8)
    mk.muzzle_brake(k, BORE + X * 2.03, 0.12, "head", length=0.22)
    so = BORE + Vector((-0.55, 0, 0.24))
    for x in (0.25, 0.75):
        k.box(so + Vector((x, 0, -0.1)), (0.08, 0.08, 0.14), "gunmetal", "head")
    k.limb(so, so + X * 1.05, 0.08, 0.08, "gunmetal", "head", seg=8)
    k.limb(so + X * 0.85, so + X * 1.15, 0.08, 0.12, "gunmetal", "head", seg=8)
    k.limb(so + X * 1.15, so + X * 1.19, 0.11, 0.11, "lamp_red", "head", seg=8)
    k.limb(so - X * 0.08, so, 0.055, 0.075, "rubber", "head", seg=8)
    k.limb(NOCK - Vector((0, 0.1, 0)), NOCK, 0.02, 0.02, "steel", "nock", seg=4)
    k.ball(tuple(NOCK), 0.045, "gunmetal", "nock", seg=6, rings=3)
    for i, (r, t) in enumerate(zip(ROOT, TIP)):  # folded bipod
        k.limb(r, t, 0.03, 0.025, "gunmetal", "limb%d" % i, seg=4)
        k.ball(tuple(t), 0.04, "rubber", "limb%d" % i, seg=4, rings=2)
    # spent casing, tracer round, tracer streak, flash
    k.limb(CRANK + Vector((0, 0.3, 0)), CRANK + Vector((0.18, 0.3, 0)), 0.04, 0.04, "brass", "crank", seg=6)
    k.limb(BORE + X * 2.3, BORE + X * 2.75, 0.04, 0.0, "lamp_amber", "bolt", seg=6)
    k.limb(BORE + X * 2.3, BORE + X * 5.0, 0.03, 0.01, "lamp_amber", "trail", seg=4)
    mk.flash(k, MUZ, 0.2, "flash")


def base_pose(t):
    return {"flash": {"scale": wk.HIDE}, "bolt": {"scale": wk.HIDE}, "trail": {"scale": wk.HIDE},
            "crank": {"scale": wk.HIDE}, "arm": {"rot": ((0, 1, 0), 0.05 * math.sin(2 * math.pi * t))}}


def idle(t):
    return base_pose(t)


def attack(t):
    p = base_pose(0.0)
    f = lib.pulse(t, -0.02, 0.45)
    p["flash"] = {"scale": max(wk.HIDE, 1.3 * f)}
    p["trail"] = {"scale": (1.0, max(wk.HIDE, lib.pulse(t, -0.02, 0.5)), 1.0) if t < 0.5 else wk.HIDE}
    if t < 0.35:
        p["bolt"] = {"loc": (14.0 * t / 0.35, 0, 0), "scale": 1.0}
    cyc = lib.pulse(t, 0.3, 0.75)
    p["nock"] = {"loc": (-0.3 * cyc, 0, 0)}
    if 0.4 <= t < 0.98:
        u = (t - 0.4) / 0.58
        p["crank"] = {"loc": (-0.2 * u, 1.4 * u, 0.9 * u - 1.6 * u * u), "rot": ((1, 0, 0.3), 8 * u), "scale": 1.0}
    rc = lib.pulse(t, 0.0, 0.7)
    p["head"] = {"rot": ((0, 1, 0), -0.15 * rc), "loc": (-0.3 * rc, 0, 0)}
    for i, s in enumerate((1, -1)):
        p["limb%d" % i] = {"rot": ((1, 0, 0), s * 0.15 * rc)}
    return p


def hit(t):
    p = base_pose(0.0)
    p.update(wk.hit_common(t))
    return p


def die(t):
    p = base_pose(t)
    p.update(wk.die_common(t, CHUNKS))
    k = lib.ease(min(1.0, t / 0.7))
    for i, s in enumerate((1, -1)):
        p["limb%d" % i] = {"rot": ((1, 0, 0), s * 0.9 * k)}
    p["arm"] = {"rot": ((0, 1, 0), 0.6 * k)}
    return p


if __name__ == "__main__":
    wk.run("sniper", BONES, PIVOTS, geometry, {
        "idle": (48, idle, True), "attack": (20, attack, False),
        "hit": (10, hit, False), "die": (48, die, False)})
