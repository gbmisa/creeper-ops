"""Beam in three parts (weapon_kit): a tall slim octagonal stone tower with a bronze yaw ring
(base); an oak turntable with cheek plates, a counterweight and a rune lantern (turret); a
staff arm holding a big bronze lens ring with a cyan inner lens and a ruby focus (arm).
Pivots match WeaponMeshes.beam: Turret y 2.4, Arm at (-0.2, 0.3), wrist (0.907, 1.42) from the
shoulder, Muzzle 0.95 ahead of the wrist. The ring faces +X.
Clips: idle = the lens turns, the ruby breathes; attack = the lens spins up and a red beam
lances out; hit = shudder; die = tower sinks, the ring drops off the arm.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
import struct_kit as sk  # noqa: E402
import weapon_kit as wk  # noqa: E402
from mathutils import Quaternion, Vector  # noqa: E402

T = Vector((0, 0, 2.4))
A = T + Vector((-0.2, 0, 0.3))
E = A + Vector((0.221, 0, 1.281))
W = A + Vector((0.907, 0, 1.42))
C = W + Vector((0.6, 0, 0))  # ring centre
M = W + Vector((0.95, 0, 0))
CHUNKS = [("chunk%d" % i, (math.cos(a), math.sin(a))) for i, a in enumerate(math.pi / 4 + k * math.pi / 2 for k in range(4))]

BONES = [("base", (0, 0, 0), (0, 0, 0.5), None, "base")]
BONES += [(n, (x * 0.74, y * 0.74, 0.2), (x * 0.74, y * 0.74, 0.5), "base", "base") for n, (x, y) in CHUNKS]
BONES += [("turret", tuple(T), tuple(T + Vector((0, 0, 0.3))), None, "turret"),
          ("arm", tuple(A), tuple(A + Vector((0, 0, 0.3))), "turret", "arm"),
          ("head", tuple(W), tuple(W + Vector((0.3, 0, 0))), "arm", "arm"),
          ("lens", tuple(C), tuple(C + Vector((0.3, 0, 0))), "head", "arm"),  # bone y = +X: spin axis
          ("ruby", tuple(C), tuple(C + Vector((0.3, 0, 0))), "head", "arm"),
          ("ray", tuple(M), tuple(M + Vector((0.3, 0, 0))), "head", "arm")]
PIVOTS = {"base": (0, 0, 0), "turret": tuple(T), "arm": tuple(A)}


def ring_x(k, c, r, thick, mat, bone, n=18):
    """A ring in the YZ plane round centre c (axis +X), built from short tapered segments."""
    pts = [c + Vector((0, math.cos(2 * math.pi * i / n) * r, math.sin(2 * math.pi * i / n) * r)) for i in range(n + 1)]
    for a, b in zip(pts, pts[1:]):
        k.limb(a, b, thick, thick, mat, bone, seg=5)


def geometry(k):
    # base
    k.lathe([(0.95, 0.0), (0.95, 0.16), (0.0, 0.16)], "stone_dark", "base", seg=8, smooth=False)
    k.lathe([(0.76, 0.16), (0.76, 0.34), (0.6, 0.48), (0.5, 2.1), (0.62, 2.24), (0.62, 2.4), (0.0, 2.4)],
            "stone", "base", seg=8, smooth=False)
    for z in (1.0, 1.9):
        k.lathe([(0.6 - z * 0.05, z), (0.61 - z * 0.05, z + 0.12), (0.0, z + 0.12)], "bronze", "base", seg=8, smooth=False)
    for i in range(4):
        a = math.pi / 8 + i * math.pi / 2
        k.box((math.cos(a) * 0.5, math.sin(a) * 0.5, 1.45), (0.08, 0.15, 0.6), "rune", "base", rot=Quaternion((0, 0, 1), a))
    for n, (x, y) in CHUNKS:
        k.box((x * 0.74, y * 0.74, 0.34), (0.34, 0.34, 0.36), "stone_dark", n, rot=Quaternion((0, 0, 1), math.atan2(y, x)))
    k.lathe([(0.44, 2.38), (0.58, 2.38), (0.58, 2.5), (0.44, 2.5), (0.44, 2.38)], "bronze_dark", "base", seg=16, cap=False)
    # turret
    k.lathe([(0.47, 2.4), (0.51, 2.46), (0.51, 2.58), (0.0, 2.58)], "oak", "turret", seg=12, smooth=False)
    for s in (1, -1):
        k.box((A.x, s * 0.3, 2.68), (0.52, 0.08, 0.56), "bronze_dark", "turret")
    k.box((-0.62, 0, 2.7), (0.3, 0.44, 0.3), "iron", "turret")
    k.limb((-0.62, 0, 2.85), (-0.62, 0, 3.4), 0.03, 0.03, "bronze", "turret", seg=4)
    k.ball((-0.62, 0, 3.5), 0.13, "rune", "turret", scale=(1, 1, 1.6), seg=6, rings=3, smooth=False)
    # arm: staff
    k.limb(A + Vector((0, -0.38, 0)), A + Vector((0, 0.38, 0)), 0.1, 0.1, "bronze", "arm", seg=8)
    k.ball(tuple(A), 0.19, "bronze", "arm", seg=8, rings=4)
    for s in (1, -1):
        k.limb(A + Vector((0, s * 0.12, 0)), E + Vector((0, s * 0.12, 0)), 0.1, 0.08, "oak", "arm", seg=4)
    k.ball(tuple(E), 0.18, "bronze", "arm", seg=8, rings=4)
    k.limb(E, W, 0.12, 0.11, "bronze_dark", "arm", seg=6)
    p0, mid = A + Vector((-0.1, 0, -0.2)), A + Vector((0.12, 0, 0.7))
    k.limb(p0, p0.lerp(mid, 0.55), 0.08, 0.08, "bronze", "arm", seg=6)
    k.limb(p0.lerp(mid, 0.5), mid, 0.045, 0.045, "iron", "arm", seg=6)
    # head: wrist, three spokes to a fixed bronze ring
    k.ball(tuple(W), 0.16, "bronze", "head", seg=6, rings=3)
    ring_x(k, C, 1.02, 0.1, "bronze", "head")
    for i in range(3):
        a = i * 2 * math.pi / 3 + math.pi / 2
        k.limb(W, C + Vector((0, math.cos(a) * 1.0, math.sin(a) * 1.0)), 0.06, 0.05, "bronze", "head", seg=4)
    # lens: cyan inner ring with three crystal studs (3-fold so the turn reads), spins on +X
    ring_x(k, C + Vector((0.02, 0, 0)), 0.82, 0.08, "rune", "lens")
    for i in range(3):
        a = i * 2 * math.pi / 3
        k.ball(C + Vector((0.02, math.cos(a) * 0.82, math.sin(a) * 0.82)), 0.13, "brass", "lens", seg=5, rings=3)
        k.limb(C + Vector((0.02, 0, 0)), C + Vector((0.02, math.cos(a) * 0.78, math.sin(a) * 0.78)), 0.03, 0.03, "bronze_dark", "lens", seg=4)
    k.limb(C - Vector((0.4, 0, 0)), C, 0.0, 0.2, "ruby", "ruby", seg=6)
    k.limb(C, C + Vector((0.45, 0, 0)), 0.2, 0.0, "ruby", "ruby", seg=6)
    # ray (attack only)
    k.limb(M, M + Vector((6.0, 0, 0)), 0.26, 0.03, "ray_red", "ray", seg=8)
    k.limb(M, M + Vector((6.6, 0, 0)), 0.11, 0.07, "flash_white", "ray", seg=6)
    k.ball(M + Vector((0.1, 0, 0)), 0.38, "flash_white", "ray", seg=6, rings=4)


def base_pose(t):
    return {"lens": {"rot": ((1, 0, 0), 2 * math.pi / 3 * t)}, "ruby": {"scale": 1 + 0.15 * math.sin(2 * math.pi * t)},
            "arm": {"rot": ((0, 1, 0), 0.08 * math.sin(2 * math.pi * t))}, "ray": {"scale": wk.HIDE}}


def idle(t):
    return base_pose(t)


def attack(t):
    p = base_pose(0.0)
    p["lens"] = {"rot": ((1, 0, 0), 4 * math.pi * t * t + 1.0)}
    f = lib.pulse(t, 0.08, 1.0) if t > 0.08 else 0.0
    p["ray"] = {"scale": (0.4 + 0.8 * f, max(wk.HIDE, min(1.0, t / 0.2)), 0.4 + 0.8 * f) if t < 0.95 else wk.HIDE}
    p["ruby"] = {"scale": 2.2 if t < 0.08 else 1 + 0.6 * f}
    p["head"] = {"loc": (-0.12 * f, 0, 0)}
    return p


def hit(t):
    p = base_pose(0.0)
    p.update(wk.hit_common(t))
    return p


def die(t):
    p = base_pose(t)
    p.update(wk.die_common(t, CHUNKS))
    k = lib.ease(min(1.0, t / 0.7))
    p["lens"] = {"rot": ((1, 0, 0), 2 * math.pi * t), "loc": (0.9 * k, 0, -2.6 * k * k)}
    p["ruby"] = {"scale": max(wk.HIDE, 1 + 0.6 * lib.pulse(t, 0, 0.3) - 1.2 * lib.ease(min(1.0, t / 0.4)))}
    return p


if __name__ == "__main__":
    wk.run("beam", BONES, PIVOTS, geometry, {
        "idle": (48, idle, True), "attack": (12, attack, False),
        "hit": (10, hit, False), "die": (48, die, False)})
