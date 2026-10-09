"""Mortar in three parts (weapon_kit): a squat crenellated stone tower with a bronze yaw ring
(base); an oak turntable with cheek plates, a counterweight and a pile of shells (turret); a
heavy arm whose forked cradle holds a wide iron bowl on verdigris trunnions, an ember glowing
inside (arm). Pivots match WeaponMeshes.mortar: Turret y 1.3, Arm at (-0.45, 0.3), wrist
(0.838, 1.345), bowl 0.1 ahead and 0.45 above the wrist, tilted 0.25 forward.
Clips: idle = ember breathes; attack = arm dips, the bowl kicks, a fireball and a smoke puff
leave the mouth; hit = shudder; die = tower sinks, merlons fall, the bowl tips and spills.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
import struct_kit as sk  # noqa: E402
import weapon_kit as wk  # noqa: E402
from mathutils import Quaternion, Vector  # noqa: E402

T = Vector((0, 0, 1.3))
A = T + Vector((-0.45, 0, 0.3))
E = A + Vector((0.321, 0, 1.156))
W = A + Vector((0.838, 0, 1.345))
B = W + Vector((0.1, 0, 0.45))
MZ = B + Vector((0, 0, 0.6))  # bowl mouth at rest (untilted); the bowl bone carries the tilt
TILT = 0.25
CHUNKS = [("chunk%d" % i, (math.cos(a), math.sin(a))) for i, a in enumerate(math.pi / 4 + k * math.pi / 2 for k in range(4))]

BONES = [("base", (0, 0, 0), (0, 0, 0.5), None, "base")]
BONES += [(n, (x * 0.84, y * 0.84, 1.3), (x * 0.84, y * 0.84, 1.6), "base", "base") for n, (x, y) in CHUNKS]
BONES += [("turret", tuple(T), tuple(T + Vector((0, 0, 0.3))), None, "turret"),
          ("arm", tuple(A), tuple(A + Vector((0, 0, 0.3))), "turret", "arm"),
          ("head", tuple(W), tuple(W + Vector((0.3, 0, 0))), "arm", "arm"),
          ("bowl", tuple(B), tuple(B + Vector((0, 0, 0.4))), "head", "arm"),
          ("ember", tuple(B + Vector((0, 0, 0.25))), tuple(B + Vector((0, 0, 0.5))), "bowl", "arm"),
          ("flash", tuple(MZ), tuple(MZ + Vector((0, 0, 0.3))), "bowl", "arm"),
          ("smoke", tuple(MZ), tuple(MZ + Vector((0, 0, 0.3))), "head", "arm")]
PIVOTS = {"base": (0, 0, 0), "turret": tuple(T), "arm": tuple(A)}
BOWL = [(0.0, -0.32), (0.62, -0.3), (0.88, -0.05), (0.92, 0.18), (0.84, 0.36), (0.98, 0.42), (0.98, 0.58),
        (0.66, 0.58), (0.58, 0.2)]


def geometry(k):
    # base
    k.lathe([(1.15, 0.0), (1.15, 0.14), (0.0, 0.14)], "stone_dark", "base", seg=8, smooth=False)
    k.lathe([(0.96, 0.14), (0.96, 0.3), (0.75, 0.42), (0.67, 1.0), (0.85, 1.12), (0.85, 1.3), (0.0, 1.3)],
            "stone", "base", seg=8, smooth=False)
    k.lathe([(0.71, 0.5), (0.725, 0.64), (0.0, 0.64)], "bronze", "base", seg=8, smooth=False)
    k.lathe([(0.87, 1.06), (0.88, 1.13), (0.0, 1.13)], "verdigris", "base", seg=8, smooth=False)
    for i in range(4):
        a = math.pi / 8 + i * math.pi / 2
        k.box((math.cos(a) * 0.65, math.sin(a) * 0.65, 0.78), (0.09, 0.17, 0.4), "rune", "base", rot=Quaternion((0, 0, 1), a))
    for n, (x, y) in CHUNKS:
        k.box((x * 0.84, y * 0.84, 1.5), (0.34, 0.34, 0.4), "stone", n, rot=Quaternion((0, 0, 1), math.atan2(y, x)))
    k.lathe([(0.52, 1.28), (0.68, 1.28), (0.68, 1.4), (0.52, 1.4), (0.52, 1.28)], "bronze_dark", "base", seg=16, cap=False)
    # turret
    k.lathe([(0.56, 1.3), (0.6, 1.36), (0.6, 1.48), (0.0, 1.48)], "oak", "turret", seg=12, smooth=False)
    for x, y, _z, _a in sk.ring(8, 0.56, 1.42, math.pi / 8):
        k.ball((x, y, 1.42), 0.045, "iron", "turret", seg=4, rings=2)
    for s in (1, -1):
        k.box((A.x, s * 0.35, 1.6), (0.66, 0.09, 0.6), "bronze_dark", "turret")
    k.box((-0.95, 0, 1.6), (0.4, 0.62, 0.36), "iron", "turret")
    k.box((-0.95, 0, 1.8), (0.44, 0.66, 0.06), "verdigris", "turret")
    for x, y, z in ((0.25, 0.42, 1.6), (0.25, -0.42, 1.6), (0.25, 0.0, 1.68)):  # shell pile
        k.ball((x, y, z), 0.14, "iron", "turret", seg=6, rings=4)
        k.ball((x, y, z + 0.1), 0.05, "mortar_glow", "turret", seg=4, rings=2)
    # arm
    k.limb(A + Vector((0, -0.45, 0)), A + Vector((0, 0.45, 0)), 0.12, 0.12, "bronze", "arm", seg=8)
    k.ball(tuple(A), 0.23, "bronze", "arm", seg=8, rings=4)
    for s in (1, -1):
        k.limb(A + Vector((0, s * 0.14, 0)), E + Vector((0, s * 0.16, 0)), 0.16, 0.13, "oak", "arm", seg=4)
    k.ball(tuple(E), 0.22, "bronze", "arm", seg=8, rings=4)
    k.limb(E, W, 0.19, 0.17, "bronze", "arm", seg=6)
    p0, mid = A + Vector((-0.12, 0, -0.2)), A + Vector((0.18, 0, 0.64))
    k.limb(p0, p0.lerp(mid, 0.55), 0.1, 0.1, "bronze", "arm", seg=6)
    k.limb(p0.lerp(mid, 0.5), mid, 0.055, 0.055, "iron", "arm", seg=6)
    # head: forked cradle with verdigris trunnion caps
    k.ball(tuple(W), 0.2, "bronze", "head", seg=6, rings=3)
    for s in (1, -1):
        fork = W + Vector((0.1, s * 1.25, 0.25))
        k.limb(W, fork, 0.11, 0.1, "bronze_dark", "head", seg=5)
        k.limb(fork, B + Vector((0, s * 1.25, 0.05)), 0.1, 0.09, "bronze_dark", "head", seg=5)
        k.ball(B + Vector((0, s * 1.27, 0)), 0.17, "verdigris", "head", seg=6, rings=3)
    # bowl, built upright at B; the bowl bone tilts it forward in every clip
    k.lathe(BOWL, "iron", "bowl", at=tuple(B), seg=14, smooth=False)
    k.lathe([(0.9, 0.0), (1.02, 0.0), (1.02, 0.12), (0.9, 0.12), (0.9, 0.0)], "bronze", "bowl", at=tuple(B), seg=14, cap=False)
    k.lathe([(0.96, 0.5), (1.04, 0.5), (1.04, 0.6), (0.96, 0.6), (0.96, 0.5)], "bronze", "bowl", at=tuple(B), seg=14, cap=False)
    k.limb(B + Vector((0, -1.2, 0)), B + Vector((0, 1.2, 0)), 0.12, 0.12, "verdigris", "bowl", seg=8)
    for i in range(4):
        a = i * math.pi / 2 + math.pi / 4
        k.box(B + Vector((math.cos(a) * 0.9, math.sin(a) * 0.9, 0.2)), (0.06, 0.16, 0.22), "rune", "bowl", rot=Quaternion((0, 0, 1), a))
    k.ball(B + Vector((0, 0, 0.25)), 0.42, "flame", "ember", seg=8, rings=5)
    # fireball and smoke
    for x, y, z, r in ((0.5, 0.3, 0.45, 0.45), (-0.45, 0.35, 0.6, 0.42), (0.1, -0.5, 0.7, 0.42), (0.0, 0.0, 1.45, 0.4)):
        k.ball(MZ + Vector((x, y, z)), r, "fire", "flash", seg=8, rings=5)
    k.ball(MZ + Vector((0, 0, 0.75)), 0.55, "flash_white", "flash", seg=8, rings=5)
    for x, y, z, r in ((0, 0, 0, 0.4), (0.3, 0.15, 0.2, 0.3), (-0.25, -0.2, 0.25, 0.32)):
        k.ball(MZ + Vector((x, y, z)), r, "smoke", "smoke", seg=6, rings=4)


def base_pose(t):
    return {"bowl": {"rot": ((0, 1, 0), TILT)}, "ember": {"scale": 1 + 0.25 * math.sin(2 * math.pi * t)},
            "arm": {"rot": ((0, 1, 0), 0.12 * math.sin(2 * math.pi * t))},
            "flash": {"scale": wk.HIDE}, "smoke": {"scale": wk.HIDE}}


def idle(t):
    return base_pose(t)


def attack(t):
    p = base_pose(0.0)
    pre = lib.ease(min(1.0, t / 0.28))
    back = lib.ease(max(0.0, (t - 0.28) / 0.72))
    kick = lib.pulse(t, 0.27, 0.8)
    p["arm"] = {"rot": ((0, 1, 0), 0.14 * pre * (1 - back) - 0.3 * kick)}
    p["bowl"] = {"rot": ((0, 1, 0), TILT), "loc": (0, 0, -0.35 * kick)}
    p["ember"] = {"scale": 1 + 0.5 * pre if t < 0.3 else max(0.3, 1.5 - 4 * (t - 0.3)) if t < 0.7 else 0.3 + 0.7 * (t - 0.7) / 0.3}
    p["flash"] = {"scale": max(wk.HIDE, 1.2 * lib.pulse(t, 0.25, 0.5))}
    if 0.3 <= t < 0.97:
        u = (t - 0.3) / 0.7
        p["smoke"] = {"loc": (0.2 * u, 0, 1.1 * u), "scale": 0.8 + 1.0 * u}
    return p


def hit(t):
    p = base_pose(0.0)
    p.update(wk.hit_common(t))
    p["bowl"] = {"rot": ((0, 1, 0), TILT + 0.6 * lib.pulse(t, 0.0, 1.0) * (1 - t))}
    return p


def die(t):
    p = base_pose(t)
    p.update(wk.die_common(t, CHUNKS))
    k = lib.ease(min(1.0, t / 0.7))
    p["bowl"] = {"rot": ((0, 1, 0), TILT + 0.9 * k)}
    p["arm"] = {"rot": ((0, 1, 0), 0.45 * k)}
    p["ember"] = {"scale": max(wk.HIDE, 1 + 0.6 * lib.pulse(t, 0, 0.3) - 1.2 * lib.ease(min(1.0, t / 0.45)))}
    return p


if __name__ == "__main__":
    wk.run("mortar", BONES, PIVOTS, geometry, {
        "idle": (48, idle, True), "attack": (24, attack, False),
        "hit": (10, hit, False), "die": (48, die, False)})
