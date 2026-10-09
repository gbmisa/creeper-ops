"""Relay, military: a triangular steel lattice radio mast on a hazard-banded concrete footing with
a junction box and guy-line stakes, and a turning directional antenna yard on top with a cyan
packet lamp at each end and a cyan beacon in the middle. Same silhouette as SupportMeshes.relay
(Spin at 2.95). Clips: idle = the yard turns, lamps breathe; attack = a packet passes (a cyan spark
runs up the mast, the yard jolts, lamps flare); hit = shake; die = beacon bursts, the yard falls,
the mast sinks. About 3.6 m tall.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
import struct_kit as sk  # noqa: E402
import mil_kit as mk  # noqa: E402
from mathutils import Quaternion, Vector  # noqa: E402

Q45 = Quaternion((0, 0, 1), math.pi / 4)


def build():
    arm = lib.armature("relay", [("root", (0, 0, 0), (0, 0, 0.1), None),
                                 ("base", (0, 0, 0), (0, 0, 0.5), "root"),
                                 ("spin", (0, 0, 2.95), (0, 0, 3.3), "base"),
                                 ("gem", (0, 0, 3.2), (0, 0, 3.6), "spin"),
                                 ("spark", (0, 0, 0.4), (0, 0, 0.6), "base")])
    b = lib.Builder("relay")
    mk.slab(b, 0.5, 0.3, "base", mat="concrete", chamfer=0.06)
    mk.hazard_band(b, 0.5, 0.2, 0.08, "base", n=4)
    legs = [(math.cos(a), math.sin(a)) for a in (math.pi / 2 + i * 2 * math.pi / 3 for i in range(3))]
    r0, r1, z0, z1 = 0.3, 0.12, 0.3, 2.86
    for x, y in legs:
        b.limb(Vector((x * r0, y * r0, z0)), Vector((x * r1, y * r1, z1)), 0.04, 0.03, "olive_dark", "base", seg=4)
    n = 7
    for j in range(n):  # zig-zag braces on each face
        za, zb = z0 + (z1 - z0) * j / n, z0 + (z1 - z0) * (j + 1) / n
        ra, rb = r0 + (r1 - r0) * j / n, r0 + (r1 - r0) * (j + 1) / n
        for i in range(3):
            (xa, ya), (xb, yb) = legs[i], legs[(i + 1) % 3]
            p, q = (Vector((xa * ra, ya * ra, za)), Vector((xb * rb, yb * rb, zb))) if j % 2 else \
                (Vector((xb * ra, yb * ra, za)), Vector((xa * rb, ya * rb, zb)))
            b.limb(p, q, 0.014, 0.014, "steel", "base", seg=4)
    b.lathe([(0.2, 2.82), (0.2, 2.96), (0.0, 2.96)], "gunmetal", "base", seg=6, smooth=False)
    b.box((0.0, -0.32, 0.55), (0.3, 0.14, 0.4), "olive", "base")
    b.box((0.0, -0.395, 0.62), (0.08, 0.01, 0.06), "arc_blue", "base")
    for x, y in legs:  # guy lines to ground stakes
        st = Vector((x * 1.0, y * 1.0, 0.0))
        b.box(tuple(st + Vector((0, 0, 0.05))), (0.1, 0.1, 0.1), "concrete_dark", "base")
        b.limb(st + Vector((0, 0, 0.08)), Vector((x * 0.2, y * 0.2, 1.9)), 0.008, 0.008, "steel", "base", seg=3)
    b.lathe([(0.12, 2.95), (0.18, 3.0), (0.1, 3.08), (0.0, 3.08)], "gunmetal", "spin", seg=8, smooth=False)
    b.box((0, 0, 3.05), (1.6, 0.1, 0.1), "olive", "spin")
    for sx in (-0.8, 0.8):
        b.box((sx, 0, 3.05), (0.16, 0.2, 0.2), "gunmetal", "spin")
        b.ball((sx, 0, 3.26), 0.08, "arc_blue", "spin", seg=6, rings=3)
        for d in (0.25, 0.45, 0.65):  # yagi elements
            b.box((sx * (1 - d / 0.8 * 0.5), 0, 3.05), (0.03, 0.5 - d * 0.3, 0.03), "steel", "spin")
        b.limb((sx * 0.5, 0, 3.05), (sx, 0, 2.85), 0.025, 0.025, "steel", "spin", seg=4)
        b.ball((sx, 0, 2.82), 0.05, "hazard", "spin", seg=4, rings=2)
    b.ball((0, 0, 3.42), 0.14, "arc_blue", "gem", scale=(1, 1, 1.6), seg=8, rings=4)
    b.lathe([(0.0, 3.18), (0.12, 3.18), (0.12, 3.24), (0.0, 3.24)], "gunmetal", "gem", seg=8, smooth=False)
    b.ball((0, 0, 0.5), 0.26, "flash_white", "spark", seg=6, rings=4)
    b.ball((0, 0, 0.5), 0.38, "arc_blue", "spark", scale=(1, 1, 1.8), seg=6, rings=3)
    b.finish(arm)
    return arm


def idle(arm, t):
    p = {"spin": (lib.world_rot(arm, "spin", (0, 0, 1), math.pi * t), None)}  # 2-fold yard: half a turn loops
    p["gem"] = (None, lib.world_loc(arm, "gem", (0, 0, 0.08 * math.sin(2 * math.pi * t))), (1 + 0.1 * math.sin(2 * math.pi * t),) * 3)
    p["spark"] = (None, None, (0.01, 0.01, 0.01))
    return p


def attack(arm, t):
    p = idle(arm, 0.0)
    jolt = lib.ease(min(1.0, t / 0.7))
    p["spin"] = (lib.world_rot(arm, "spin", (0, 0, 1), math.pi * jolt), None)
    f = lib.pulse(t, 0.5, 1.0)
    p["gem"] = (None, lib.world_loc(arm, "gem", (0, 0, 0.2 * f)), (1 + 0.8 * f,) * 3)
    u = min(1.0, t / 0.6)
    p["spark"] = (None, lib.world_loc(arm, "spark", (0, 0, 2.7 * u)), (1.0,) * 3 if t < 0.65 else (0.01,) * 3)
    return p


if __name__ == "__main__":
    sk.run(build, idle, attack, attack_frames=12, top="spin", pop=("gem",), drop={"spin": 2.8}, fall=0.5)
