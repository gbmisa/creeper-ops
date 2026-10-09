"""Pulse Cannon in three parts (weapon_kit): an octagonal stone tower with a bronze yaw ring
(base); an oak turntable with cheek plates, a counterweight and a pennant (turret); a jointed
arm holding a banded bronze bombard with a rune crystal in its breech (arm).
Pivots match WeaponMeshes.cannon: Turret y 1.6, Arm at (-0.35, 0.35), wrist (0.695, 1.323)
from the shoulder, Muzzle 1.5 ahead of the wrist.
Clips: idle = pennant flaps, crystal breathes; attack = recoil, muzzle flash; hit = shudder;
die = tower sinks, buttress caps fly, turret tips over, arm droops.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
import struct_kit as sk  # noqa: E402
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
          ("flag", (-0.55, 0, 2.85), (-0.55, 0, 3.1), "turret", "turret"),
          ("arm", tuple(A), tuple(A + Vector((0, 0, 0.3))), "turret", "arm"),
          ("head", tuple(W), tuple(W + Vector((0.3, 0, 0))), "arm", "arm"),
          ("barrel", tuple(W), tuple(W + Vector((0.3, 0, 0))), "head", "arm"),
          ("flash", tuple(M), tuple(M + Vector((0.3, 0, 0))), "barrel", "arm"),
          ("gem", tuple(W - Vector((0.85, 0, 0))), tuple(W - Vector((0.55, 0, 0))), "head", "arm")]
PIVOTS = {"base": (0, 0, 0), "turret": tuple(T), "arm": tuple(A)}
BARREL = [(-0.6, 0.05), (-0.55, 0.32), (-0.35, 0.44), (-0.1, 0.44), (-0.02, 0.33), (0.5, 0.3), (0.54, 0.37),
          (0.66, 0.37), (0.7, 0.29), (1.2, 0.27), (1.3, 0.43), (1.48, 0.43)]


def geometry(k):
    # base: plinth, tapering tower, band, rune slits, buttresses, yaw ring
    k.lathe([(1.0, 0.0), (1.0, 0.14), (0.0, 0.14)], "stone_dark", "base", seg=8, smooth=False)
    k.lathe([(0.81, 0.14), (0.81, 0.3), (0.63, 0.42), (0.56, 1.28), (0.69, 1.42), (0.69, 1.6), (0.0, 1.6)],
            "stone", "base", seg=8, smooth=False)
    k.lathe([(0.6, 0.6), (0.615, 0.74), (0.0, 0.74)], "bronze", "base", seg=8, smooth=False)
    k.lathe([(0.7, 1.36), (0.71, 1.42), (0.0, 1.42)], "bronze_dark", "base", seg=8, smooth=False)
    for i in range(4):
        a = math.pi / 8 + i * math.pi / 2
        k.box((math.cos(a) * 0.545, math.sin(a) * 0.545, 1.0), (0.09, 0.17, 0.55), "rune", "base", rot=Quaternion((0, 0, 1), a))
    for n, (x, y) in CHUNKS:
        a = math.atan2(y, x)
        k.limb((x * 0.86, y * 0.86, 0.14), (x * 0.66, y * 0.66, 0.9), 0.16, 0.08, "stone", "base", seg=4)
        k.box((x * 0.85, y * 0.85, 0.36), (0.3, 0.3, 0.28), "stone_dark", n, rot=Quaternion((0, 0, 1), a))
    k.lathe([(0.6, 1.58), (0.74, 1.58), (0.74, 1.7), (0.6, 1.7), (0.6, 1.58)], "bronze_dark", "base", seg=16, cap=False)
    # turret: turntable, rivets, cheek plates, counterweight, pennant
    k.lathe([(0.6, 1.6), (0.64, 1.66), (0.64, 1.78), (0.0, 1.78)], "oak", "turret", seg=12, smooth=False)
    for x, y, _z, _a in sk.ring(8, 0.6, 1.72, math.pi / 8):
        k.ball((x, y, 1.72), 0.045, "iron", "turret", seg=4, rings=2)
    for s in (1, -1):
        k.box((A.x, s * 0.32, 1.92), (0.62, 0.08, 0.6), "bronze_dark", "turret")
        k.ball((A.x, s * 0.37, A.z), 0.08, "bronze", "turret", seg=6, rings=3)
    k.box((-0.82, 0, 1.92), (0.36, 0.56, 0.32), "iron", "turret")
    k.box((-0.82, 0, 2.1), (0.4, 0.6, 0.06), "bronze", "turret")
    k.limb((-0.55, 0, 1.78), (-0.55, 0, 3.1), 0.035, 0.025, "oak", "turret", seg=4)
    k.ball((-0.55, 0, 3.12), 0.06, "brass", "turret", seg=5, rings=3)
    k.box((-0.92, 0, 2.82), (0.74, 0.03, 0.42), "cloth", "flag")
    k.box((-1.29, 0, 2.82), (0.03, 0.04, 0.42), "brass", "flag")
    # arm: shoulder axle, twin oak beams, elbow, forearm, piston brace
    k.limb(A + Vector((0, -0.42, 0)), A + Vector((0, 0.42, 0)), 0.11, 0.11, "bronze", "arm", seg=8)
    k.ball(tuple(A), 0.21, "bronze", "arm", seg=8, rings=4)
    for s in (1, -1):
        k.limb(A + Vector((0, s * 0.13, 0)), E + Vector((0, s * 0.13, 0)), 0.11, 0.09, "oak", "arm", seg=4)
    k.ball(tuple(E), 0.2, "bronze", "arm", seg=8, rings=4)
    k.limb(E, W, 0.14, 0.13, "bronze_dark", "arm", seg=6)
    p0, mid = A + Vector((-0.14, 0, -0.2)), A + Vector((0.083, 0, 0.683))
    k.limb(p0, p0.lerp(mid, 0.55), 0.09, 0.09, "bronze", "arm", seg=6)
    k.limb(p0.lerp(mid, 0.5), mid, 0.05, 0.05, "iron", "arm", seg=6)
    # head: wrist, straps, breech crystal; the bombard itself recoils on "barrel"
    k.ball(tuple(W), 0.17, "bronze", "head", seg=6, rings=3)
    for s in (1, -1):
        k.box(W + Vector((0.1, s * 0.4, 0)), (0.5, 0.07, 0.4), "iron", "head")
    k.ball(W - Vector((0.85, 0, 0)), 0.2, "rune", "gem", scale=(2.6, 1, 1), seg=6, rings=3, smooth=False)
    k.tube([(W + Vector((x, 0, 0)), r) for x, r in BARREL], "bronze", "barrel", seg=14)
    for x in (-0.2, 0.25):
        k.limb(W + Vector((x, 0, 0)), W + Vector((x + 0.07, 0, 0)), 0.46, 0.46, "bronze_dark", "barrel", seg=14)
    k.limb(M - Vector((0.04, 0, 0)), M + Vector((0.005, 0, 0)), 0.3, 0.3, "stone_dark", "barrel", seg=14)
    k.limb(M, M + Vector((0.65, 0, 0)), 0.26, 0.0, "rune", "flash", seg=8)
    k.ball(M + Vector((0.12, 0, 0)), 0.24, "flash_white", "flash", seg=6, rings=3)
    for a in (0.0, math.pi / 2, math.pi, 1.5 * math.pi):
        k.limb(M + Vector((0.1, 0, 0)), M + Vector((0.25, math.cos(a) * 0.4, math.sin(a) * 0.4)), 0.06, 0.0, "flash_white", "flash", seg=4)


def base_pose(t):
    return {"flag": {"rot": ((0, 0, 1), 0.8 * math.sin(4 * math.pi * t))},
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
