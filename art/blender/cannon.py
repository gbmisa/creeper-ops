"""Autocannon in three parts (weapon_kit), military: a sandbagged concrete pillbox column with an
olive armour collar, hazard band, firing slit and ladder (base); a gunmetal turntable with sloped
olive gun-shield cheeks, an ammo box and a radio whip (turret); a hydraulic box-beam arm holding a
gunmetal autocannon with a cooling jacket, muzzle brake, belt feed and amber optic (arm).
Pivots match WeaponMeshes.cannon: Turret y 1.6, Arm at (-0.35, 0.35), wrist (0.695, 1.323)
from the shoulder, Muzzle 1.5 ahead of the wrist.
Clips: idle = whip sways, optic breathes; attack = recoil, muzzle flash; hit = shudder;
die = column sinks, corner sandbags fly, turret tips over, arm droops.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
import mil_kit as mk  # noqa: E402
import weapon_kit as wk  # noqa: E402
from mathutils import Quaternion, Vector  # noqa: E402

T = Vector((0, 0, 1.6))
A = T + Vector((-0.35, 0, 0.35))
E = A + Vector((0.151, 0, 1.241))
W = A + Vector((0.695, 0, 1.323))
M = W + Vector((1.5, 0, 0))
CAPS = [(math.cos(a), math.sin(a)) for a in (math.pi / 4 + k * math.pi / 2 for k in range(4))]
CHUNKS = [("chunk%d" % i, c) for i, c in enumerate(CAPS)]

BONES = [("base", (0, 0, 0), (0, 0, 0.5), None, "base")]
BONES += [(n, (x * 0.85, y * 0.85, 0.3), (x * 0.85, y * 0.85, 0.6), "base", "base") for n, (x, y) in CHUNKS]
BONES += [("turret", tuple(T), tuple(T + Vector((0, 0, 0.3))), None, "turret"),
          ("flag", (-0.55, 0.25, 1.86), (-0.55, 0.25, 2.1), "turret", "turret"),
          ("arm", tuple(A), tuple(A + Vector((0, 0, 0.3))), "turret", "arm"),
          ("head", tuple(W), tuple(W + Vector((0.3, 0, 0))), "arm", "arm"),
          ("barrel", tuple(W), tuple(W + Vector((0.3, 0, 0))), "head", "arm"),
          ("flash", tuple(M), tuple(M + Vector((0.3, 0, 0))), "barrel", "arm"),
          ("gem", tuple(W - Vector((0.85, 0, 0))), tuple(W - Vector((0.55, 0, 0))), "head", "arm")]
PIVOTS = {"base": (0, 0, 0), "turret": tuple(T), "arm": tuple(A)}
BARREL = [(-0.6, 0.05), (-0.55, 0.32), (-0.35, 0.44), (-0.1, 0.44), (-0.02, 0.33), (0.5, 0.3), (0.54, 0.37),
          (0.66, 0.37), (0.7, 0.29), (1.2, 0.27), (1.3, 0.43), (1.48, 0.43)]


def geometry(k):
    # base: slab, sandbags, tapering concrete column, armour collar, hazard band, slit, ladder, yaw ring
    mk.slab(k, 1.0, 0.16, "base")
    mk.sandbags(k, 0.62, 0.16, "base", rows=1, per=3)
    mk.square(k, 0.6, 0.16, 1.2, "concrete", "base", top_half=0.5)
    mk.column_trim(k, 0.6, 0.5, 0.16, 1.2, "base")
    mk.square(k, 0.58, 1.2, 1.5, "olive", "base")
    mk.hazard_band(k, 0.58, 1.27, 0.1, "base", n=6)
    k.box((0.52, 0, 0.85), (0.04, 0.5, 0.1), "rubber", "base")
    mk.ladder(k, -0.55, 0, 0.16, 1.2, "base", face=(-1, 0))
    mk.rivets(k, [(x * 0.59, y * 0.4, 1.42) for x, y in ((1, 1), (1, -1), (-1, 1), (-1, -1))]
              + [(x * 0.4, y * 0.59, 1.42) for x, y in ((1, 1), (1, -1), (-1, 1), (-1, -1))], "base")
    for n, (x, y) in CHUNKS:
        for z, s in ((0.3, 1.0), (0.46, 0.85)):
            k.ball((x * 0.88, y * 0.88, z), 0.2 * s, "sandbag", n, scale=(1.4, 0.8, 0.55), seg=8, rings=4,
                   rot=Quaternion((0, 0, 1), math.atan2(y, x) + math.pi / 2))
    k.lathe([(0.56, 1.5), (0.66, 1.5), (0.66, 1.6), (0.56, 1.6), (0.56, 1.5)], "gunmetal", "base", seg=16, cap=False)
    # turret: turntable, sloped shield cheeks, glacis, ammo box, radio whip
    mk.turntable(k, 0.62, 1.6, 1.74, "turret")
    for s in (1, -1):
        k.box((A.x + 0.05, s * 0.34, 1.98), (0.7, 0.07, 0.5), "olive", "turret",
              rot=Quaternion((1, 0, 0), -s * 0.18))
        k.box((A.x + 0.05, s * 0.38, 2.2), (0.7, 0.04, 0.05), "hazard", "turret")
        k.ball((A.x, s * 0.4, A.z), 0.07, "steel", "turret", seg=6, rings=3)
    k.box((0.18, 0, 1.84), (0.12, 0.62, 0.2), "olive_dark", "turret", rot=Quaternion((0, 1, 0), -0.5))
    mk.crate(k, (-0.75, 0.0, 1.9), (0.36, 0.5, 0.3), "turret")
    mk.antenna(k, (-0.55, 0.25, 1.74), 1.25, "turret", tip_bone="flag")
    # arm: axle, twin olive box beams, elbow, forearm, hydraulic ram
    k.limb(A + Vector((0, -0.44, 0)), A + Vector((0, 0.44, 0)), 0.09, 0.09, "steel", "arm", seg=8)
    for s in (1, -1):
        k.limb(A + Vector((0, s * 0.14, 0)), E + Vector((0, s * 0.14, 0)), 0.1, 0.085, "olive", "arm", seg=4)
    k.limb(E + Vector((0, -0.24, 0)), E + Vector((0, 0.24, 0)), 0.12, 0.12, "steel", "arm", seg=8)
    k.limb(E, W, 0.12, 0.11, "gunmetal", "arm", seg=4)
    p0, mid = A + Vector((-0.14, 0, -0.2)), A + Vector((0.083, 0, 0.683))
    k.limb(p0, p0.lerp(mid, 0.55), 0.08, 0.08, "gunmetal", "arm", seg=8)
    k.limb(p0.lerp(mid, 0.5), mid, 0.04, 0.04, "brake", "arm", seg=8)
    # head: receiver, belt feed, ammo drum, optic (gem); the gun itself recoils on "barrel"
    k.ball(tuple(W), 0.15, "steel", "head", seg=6, rings=3)
    k.box(W + Vector((-0.2, 0, 0.02)), (0.85, 0.56, 0.42), "olive", "head")
    k.box(W + Vector((-0.2, 0, 0.21)), (0.6, 0.3, 0.04), "olive_dark", "head")
    k.box(W + Vector((-0.1, 0.32, -0.06)), (0.42, 0.22, 0.3), "olive_dark", "head")
    k.box(W + Vector((-0.1, 0.44, -0.06)), (0.3, 0.02, 0.07), "hazard", "head")
    for i in range(5):
        k.box(W + Vector((0.05 - i * 0.08, 0.24, 0.1 - i * 0.03)), (0.05, 0.1, 0.06), "brass", "head")
    k.box(W + Vector((-0.35, -0.12, 0.31)), (0.34, 0.1, 0.12), "gunmetal", "head")
    k.ball(W + Vector((-0.17, -0.12, 0.31)), 0.06, "lamp_amber", "gem", seg=6, rings=3)
    k.tube([(W + Vector((x, 0, 0)), r) for x, r in ((-0.55, 0.18), (0.2, 0.18), (0.2, 0.22), (0.95, 0.22), (0.95, 0.14), (1.22, 0.14))],
           "gunmetal", "barrel", seg=10)
    for x in (0.32, 0.5, 0.68, 0.86):
        k.limb(W + Vector((x, 0, 0)), W + Vector((x + 0.04, 0, 0)), 0.245, 0.245, "rubber", "barrel", seg=10)
    mk.muzzle_brake(k, M - Vector((0.28, 0, 0)), 0.2, "barrel", length=0.3)
    mk.flash(k, M + Vector((0.02, 0, 0)), 0.26, "flash")


def base_pose(t):
    return {"flag": {"rot": ((1, 0.4, 0), 0.09 * math.sin(4 * math.pi * t))},
            "arm": {"rot": ((0, 1, 0), 0.1 * math.sin(2 * math.pi * t))},
            "gem": {"scale": 1 + 0.12 * math.sin(2 * math.pi * t)}, "flash": {"scale": wk.HIDE}}


def idle(t):
    return base_pose(t)


def attack(t):
    p = base_pose(t)
    f = lib.pulse(t, -0.02, 0.55)
    rc = 0.45 * math.sin(math.pi * t) ** 0.5
    p["barrel"] = {"loc": (-rc, 0, 0)}
    p["head"] = {"rot": ((0, 1, 0), -0.35 * rc)}
    p["flash"] = {"scale": max(wk.HIDE, 1.3 * f) if t < 0.9 else wk.HIDE}
    p["gem"] = {"scale": 1 + 0.6 * f}
    return p


def hit(t):
    p = base_pose(0.0)
    p.update(wk.hit_common(t))
    return p


def die(t):
    p = base_pose(t)
    p.update(wk.die_common(t, CHUNKS))
    p["gem"] = {"scale": max(wk.HIDE, 1 + 0.6 * lib.pulse(t, 0, 0.3) - 1.2 * lib.ease(min(1.0, t / 0.4)))}
    return p


if __name__ == "__main__":
    wk.run("cannon", BONES, PIVOTS, geometry, {
        "idle": (48, idle, True), "attack": (7, attack, False),
        "hit": (10, hit, False), "die": (48, die, False)})
