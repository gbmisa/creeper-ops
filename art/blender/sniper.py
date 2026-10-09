"""Sniper in three parts (weapon_kit): a tall hexagonal stone tower with a bronze yaw ring
(base); an oak turntable with cheek plates, a counterweight and a quiver of spare bolts (turret);
a jointed arm holding a long ballista: oak stock, bronze bow limbs, iron strings, a winch and a
rune-tipped bolt (arm). Pivots match WeaponMeshes.sniper: Turret y 2.0, Arm at (-0.3, 0.3),
wrist (0.635, 1.268) from the shoulder, Muzzle (2.25, 0.24) ahead of the wrist.
Clips: idle = rune tip breathes; attack = the limbs snap forward, the string and bolt fly, the
winch turns and a fresh bolt drops in; hit = shudder; die = tower sinks, the bow droops.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
import struct_kit as sk  # noqa: E402
import weapon_kit as wk  # noqa: E402
from mathutils import Quaternion, Vector  # noqa: E402

T = Vector((0, 0, 2.0))
A = T + Vector((-0.3, 0, 0.3))
E = A + Vector((0.285, 0, 1.268))
W = A + Vector((0.635, 0, 1.268))
NOCK = W + Vector((-0.3, 0, 0.2))
TIP = [W + Vector((1.05, s * 1.75, 0.12)) for s in (1, -1)]
ROOT = [W + Vector((1.75, s * 0.15, 0.1)) for s in (1, -1)]
CRANK = W + Vector((-0.95, 0, 0.08))
CHUNKS = [("chunk%d" % i, (math.cos(a), math.sin(a))) for i, a in enumerate(k * math.pi / 2 for k in range(4))]

BONES = [("base", (0, 0, 0), (0, 0, 0.5), None, "base")]
BONES += [(n, (x * 0.62, y * 0.62, 0.2), (x * 0.62, y * 0.62, 0.5), "base", "base") for n, (x, y) in CHUNKS]
BONES += [("turret", tuple(T), tuple(T + Vector((0, 0, 0.3))), None, "turret"),
          ("arm", tuple(A), tuple(A + Vector((0, 0, 0.3))), "turret", "arm"),
          ("head", tuple(W), tuple(W + Vector((0.3, 0, 0))), "arm", "arm"),
          ("nock", tuple(NOCK), tuple(NOCK + Vector((0.3, 0, 0))), "head", "arm"),
          ("bolt", tuple(NOCK + Vector((0, 0, 0.04))), tuple(NOCK + Vector((0.3, 0, 0.04))), "head", "arm"),
          ("trail", tuple(W + Vector((2.3, 0, 0.24))), tuple(W + Vector((2.6, 0, 0.24))), "head", "arm"),
          ("crank", tuple(CRANK + Vector((0, 0.3, 0))), tuple(CRANK + Vector((0, 0.6, 0))), "head", "arm"),
          ("flash", tuple(W + Vector((2.25, 0, 0.24))), tuple(W + Vector((2.55, 0, 0.24))), "head", "arm")]
BONES += [("limb%d" % i, tuple(r), tuple(t), "head", "arm") for i, (r, t) in enumerate(zip(ROOT, TIP))]
PIVOTS = {"base": (0, 0, 0), "turret": tuple(T), "arm": tuple(A)}


def geometry(k):
    # base: plinth, tall hex tower, bands, rune slits, foot stones, yaw ring
    k.lathe([(0.85, 0.0), (0.85, 0.14), (0.0, 0.14)], "stone_dark", "base", seg=6, smooth=False)
    k.lathe([(0.65, 0.14), (0.65, 0.3), (0.51, 0.42), (0.45, 1.68), (0.56, 1.82), (0.56, 2.0), (0.0, 2.0)],
            "stone", "base", seg=6, smooth=False)
    for z in (0.8, 1.5):
        k.lathe([(0.49 - (z - 0.42) * 0.05, z), (0.5 - (z - 0.42) * 0.05, z + 0.12), (0.0, z + 0.12)], "bronze", "base", seg=6, smooth=False)
    for i in range(3):
        a = math.pi / 6 + i * 2 * math.pi / 3
        k.box((math.cos(a) * 0.43, math.sin(a) * 0.43, 1.18), (0.08, 0.15, 0.5), "rune", "base", rot=Quaternion((0, 0, 1), a))
    for n, (x, y) in CHUNKS:
        k.box((x * 0.62, y * 0.62, 0.3), (0.28, 0.28, 0.32), "stone_dark", n, rot=Quaternion((0, 0, 1), math.atan2(y, x) + 0.3))
    k.lathe([(0.45, 1.98), (0.6, 1.98), (0.6, 2.1), (0.45, 2.1), (0.45, 1.98)], "bronze_dark", "base", seg=16, cap=False)
    # turret: turntable, cheek plates, counterweight, quiver
    k.lathe([(0.49, 2.0), (0.53, 2.06), (0.53, 2.18), (0.0, 2.18)], "oak", "turret", seg=12, smooth=False)
    for s in (1, -1):
        k.box((A.x, s * 0.3, 2.28), (0.56, 0.08, 0.56), "bronze_dark", "turret")
    k.box((-0.72, 0, 2.3), (0.3, 0.46, 0.3), "iron", "turret")
    k.limb((0.25, 0.36, 2.18), (0.32, 0.4, 2.85), 0.11, 0.12, "oak", "turret", seg=6)
    for dx, dy in ((0.0, 0.0), (0.05, 0.05), (-0.04, 0.05)):
        k.limb((0.3 + dx, 0.39 + dy, 2.8), (0.33 + dx, 0.4 + dy, 3.05), 0.025, 0.025, "oak", "turret", seg=4)
        k.ball((0.33 + dx, 0.4 + dy, 3.08), 0.04, "rune", "turret", seg=4, rings=2)
    # arm
    k.limb(A + Vector((0, -0.38, 0)), A + Vector((0, 0.38, 0)), 0.1, 0.1, "bronze", "arm", seg=8)
    k.ball(tuple(A), 0.2, "bronze", "arm", seg=8, rings=4)
    for s in (1, -1):
        k.limb(A + Vector((0, s * 0.12, 0)), E + Vector((0, s * 0.12, 0)), 0.1, 0.08, "oak", "arm", seg=4)
    k.ball(tuple(E), 0.18, "bronze", "arm", seg=8, rings=4)
    k.limb(E, W, 0.13, 0.13, "bronze_dark", "arm", seg=6)
    p0, mid = A + Vector((-0.12, 0, -0.2)), A + Vector((0.16, 0, 0.7))
    k.limb(p0, p0.lerp(mid, 0.55), 0.08, 0.08, "bronze", "arm", seg=6)
    k.limb(p0.lerp(mid, 0.5), mid, 0.045, 0.045, "iron", "arm", seg=6)
    # head: stock, bronze fittings, limbs, strings, winch, bolt
    k.ball(tuple(W), 0.15, "bronze", "head", seg=6, rings=3)
    k.box(W + Vector((0.5, 0, 0.08)), (3.0, 0.24, 0.22), "oak", "head")
    k.box(W + Vector((0.5, 0, 0.2)), (2.6, 0.08, 0.03), "bronze_dark", "head")  # bolt groove
    k.box(W + Vector((-0.8, 0, 0.08)), (0.4, 0.36, 0.32), "bronze", "head")
    k.box(W + Vector((1.75, 0, 0.08)), (0.3, 0.4, 0.36), "bronze", "head")
    k.box(W + Vector((1.98, 0, 0.08)), (0.12, 0.3, 0.3), "rune", "head")
    for s in (1, -1):
        k.limb(CRANK + Vector((0, s * 0.16, 0)), CRANK + Vector((0, s * 0.3, 0)), 0.05, 0.05, "iron", "head", seg=6)
    k.lathe([(0.2, -0.04), (0.26, 0.0), (0.2, 0.04), (0.16, 0.0), (0.2, -0.04)], "bronze", "crank",
            at=tuple(CRANK + Vector((0, 0.3, 0))), seg=10, cap=False)
    for i in range(3):
        a = i * 2 * math.pi / 3
        c = CRANK + Vector((0, 0.3, 0))
        k.limb(c, c + Vector((math.cos(a) * 0.22, 0, math.sin(a) * 0.22)), 0.03, 0.03, "bronze", "crank", seg=4)
    for i, (r, t) in enumerate(zip(ROOT, TIP)):
        bn = "limb%d" % i
        k.limb(r, r.lerp(t, 0.55), 0.17, 0.13, "bronze_dark", bn, seg=5)
        k.limb(r.lerp(t, 0.5), t, 0.13, 0.07, "bronze", bn, seg=5)
        k.ball(tuple(t), 0.08, "brass", bn, seg=5, rings=3)
        k.limb(t, NOCK, 0.035, 0.035, "iron", bn, seg=4, bone_b="nock")
    k.box(tuple(NOCK), (0.12, 0.12, 0.1), "iron", "nock")
    k.limb(NOCK + Vector((0, 0, 0.04)), NOCK + Vector((2.3, 0, 0.04)), 0.05, 0.05, "oak", "bolt", seg=6)
    k.limb(NOCK + Vector((2.3, 0, 0.04)), NOCK + Vector((2.65, 0, 0.04)), 0.1, 0.0, "rune", "bolt", seg=6)
    for s in (1, -1):
        k.box(NOCK + Vector((0.15, s * 0.07, 0.04)), (0.22, 0.1, 0.02), "cloth", "bolt")
    k.limb(W + Vector((2.3, 0, 0.24)), W + Vector((5.8, 0, 0.24)), 0.13, 0.0, "rune", "trail", seg=6)
    k.ball(W + Vector((2.4, 0, 0.24)), 0.22, "flash_white", "flash", seg=6, rings=4)
    for a in (0.0, math.pi / 2, math.pi, 1.5 * math.pi):
        k.limb(W + Vector((2.35, 0, 0.24)), W + Vector((2.6, math.cos(a) * 0.45, 0.24 + math.sin(a) * 0.45)), 0.05, 0.0, "rune", "flash", seg=4)


def base_pose(t):
    return {"flash": {"scale": wk.HIDE}, "bolt": {"scale": 1.0}, "trail": {"scale": wk.HIDE},
            "arm": {"rot": ((0, 1, 0), 0.08 * math.sin(2 * math.pi * t))},
            "crank": {"rot": ((0, 1, 0), 0.0)}}


def idle(t):
    return base_pose(t)


def attack(t):
    p = base_pose(0.0)
    snap = min(1.0, t / 0.12)
    back = lib.ease(max(0.0, (t - 0.35) / 0.65))
    draw = snap * (1 - back)
    for i, s in enumerate((1, -1)):
        p["limb%d" % i] = {"rot": ((0, 0, 1), -s * 0.3 * draw)}
    p["nock"] = {"loc": (1.05 * draw, 0, 0)}
    p["crank"] = {"rot": ((0, 1, 0), 2 * math.pi * back)}
    if t < 0.5:
        p["bolt"] = {"loc": (14.0 * min(1.0, t / 0.35), 0, 0), "scale": 1.0 if t < 0.35 else wk.HIDE}
    else:
        u = lib.ease(min(1.0, (t - 0.5) / 0.4))
        p["bolt"] = {"loc": (0, 0, 0.6 * (1 - u)), "scale": max(wk.HIDE, u)}
    p["flash"] = {"scale": max(wk.HIDE, 1.3 * lib.pulse(t, -0.02, 0.45))}
    p["trail"] = {"scale": (1.0, max(wk.HIDE, lib.pulse(t, -0.02, 0.5)), 1.0) if t < 0.5 else wk.HIDE}
    p["head"] = {"rot": ((0, 1, 0), -0.15 * lib.pulse(t, 0.0, 0.7)), "loc": (-0.3 * lib.pulse(t, 0.0, 0.8), 0, 0)}
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
        p["limb%d" % i] = {"rot": ((1, 0, 0), s * 0.7 * k)}
    p["arm"] = {"rot": ((0, 1, 0), 0.6 * k)}
    return p


if __name__ == "__main__":
    wk.run("sniper", BONES, PIVOTS, geometry, {
        "idle": (48, idle, True), "attack": (20, attack, False),
        "hit": (10, hit, False), "die": (48, die, False)})
