"""Relay: a slender four-sided stone pylon on a stepped foot, a bronze collar with rune slits,
and a turning bronze yard on top with a cyan crystal at each end and a big one in the middle.
Same silhouette as SupportMeshes.relay (Spin at 2.95). Clips: idle = the yard turns, crystals
breathe; attack = a packet passes (a cyan spark runs up the pylon, the yard jolts, crystals
flare); hit = shake; die = crystal bursts, the yard falls, the pylon sinks. About 3.6 m tall.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
import struct_kit as sk  # noqa: E402
from mathutils import Quaternion  # noqa: E402

Q45 = Quaternion((0, 0, 1), math.pi / 4)


def build():
    arm = lib.armature("relay", [("root", (0, 0, 0), (0, 0, 0.1), None),
                                 ("base", (0, 0, 0), (0, 0, 0.5), "root"),
                                 ("spin", (0, 0, 2.95), (0, 0, 3.3), "base"),
                                 ("gem", (0, 0, 3.2), (0, 0, 3.6), "spin"),
                                 ("spark", (0, 0, 0.4), (0, 0, 0.6), "base")])
    b = lib.Builder("relay")
    b.lathe([(0.62, 0.0), (0.62, 0.16), (0.48, 0.16), (0.48, 0.3), (0.0, 0.3)], "node_stone_dark", "base", seg=4, smooth=False)
    b.lathe([(0.4, 0.3), (0.4, 0.42), (0.26, 0.56), (0.17, 2.82), (0.28, 2.9), (0.28, 2.96), (0.0, 2.96)],
            "node_stone", "base", seg=4, smooth=False)
    b.lathe([(0.23, 1.55), (0.25, 1.72), (0.0, 1.72)], "bronze", "base", seg=8, smooth=False)
    for i in range(4):
        a = math.pi / 4 + i * math.pi / 2
        b.box((math.cos(a) * 0.14, math.sin(a) * 0.14, 2.2), (0.05, 0.09, 0.5), "rune", "base", rot=Quaternion((0, 0, 1), a))
        b.box((math.cos(a) * 0.175, math.sin(a) * 0.175, 0.9), (0.05, 0.1, 0.36), "rune", "base", rot=Quaternion((0, 0, 1), a))
    b.lathe([(0.12, 2.95), (0.18, 3.0), (0.1, 3.08), (0.0, 3.08)], "bronze", "spin", seg=6, smooth=False)
    b.box((0, 0, 3.05), (1.6, 0.12, 0.12), "bronze", "spin")
    for sx in (-0.8, 0.8):
        b.box((sx, 0, 3.05), (0.14, 0.2, 0.2), "bronze_dark", "spin")
        b.ball((sx, 0, 3.32), 0.09, "rune", "spin", scale=(1, 1, 2.4), seg=5, rings=2, smooth=False)
        b.limb((sx * 0.5, 0, 3.05), (sx, 0, 2.85), 0.03, 0.03, "bronze_dark", "spin", seg=4)
        b.ball((sx, 0, 2.82), 0.05, "brass", "spin", seg=4, rings=2)
    b.ball((0, 0, 3.45), 0.18, "rune", "gem", scale=(1, 1, 2.2), seg=6, rings=2, smooth=False)
    b.ball((0, 0, 0.5), 0.3, "flash_white", "spark", seg=6, rings=4)
    b.ball((0, 0, 0.5), 0.45, "rune", "spark", scale=(1, 1, 1.8), seg=6, rings=3)
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
