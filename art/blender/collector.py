"""Collector: a rune-well obelisk on three stone feet, a glowing green well ring at its foot,
and three turning bronze vanes round a floating green crystal. Same silhouette as
SupportMeshes.collector (Spin at 1.85). Clips: idle = vanes turn, crystal bobs; attack = a
harvest pulse (a green ring runs down the obelisk, crystal flares); hit = shake;
die = crystal bursts, vanes fall, obelisk sinks. Real metres, about 2.7 m tall.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
import struct_kit as sk  # noqa: E402
from mathutils import Quaternion  # noqa: E402

FEET = sk.ring(3, 0.62, 0.0, math.pi / 6)


def build():
    arm = lib.armature("collector", [("root", (0, 0, 0), (0, 0, 0.1), None),
                                     ("base", (0, 0, 0), (0, 0, 0.5), "root"),
                                     ("spin", (0, 0, 1.85), (0, 0, 2.2), "base"),
                                     ("gem", (0, 0, 2.3), (0, 0, 2.7), "spin"),
                                     ("wave", (0, 0, 1.7), (0, 0, 1.9), "base")])
    b = lib.Builder("collector")
    for x, y, _z, a in FEET:
        b.box((x, y, 0.16), (0.58, 0.4, 0.36), "node_stone_dark", "base", rot=Quaternion((0, 0, 1), a))
        b.limb((x * 0.9, y * 0.9, 0.3), (x * 0.4, y * 0.4, 0.9), 0.16, 0.1, "node_stone_dark", "base", seg=4)
    b.lathe([(0.66, 0.0), (0.66, 0.26), (0.44, 0.42), (0.27, 1.7), (0.37, 1.8), (0.37, 1.86), (0.0, 1.86)],
            "node_stone", "base", seg=6, smooth=False)
    b.lathe([(0.52, 0.28), (0.62, 0.3), (0.52, 0.36), (0.46, 0.32), (0.52, 0.28)], "glow_green", "base", seg=12, cap=False)
    b.lathe([(0.34, 1.05), (0.35, 1.16), (0.0, 1.16)], "bronze", "base", seg=6, smooth=False)
    for i in range(3):
        a = math.pi / 6 + i * 2 * math.pi / 3
        r = 0.34
        b.box((math.cos(a) * r, math.sin(a) * r, 0.7), (0.06, 0.12, 0.42), "glow_green", "base", rot=Quaternion((0, 0, 1), a))
        b.box((math.cos(a) * 0.29, math.sin(a) * 0.29, 1.45), (0.06, 0.1, 0.3), "glow_green", "base", rot=Quaternion((0, 0, 1), a))
    b.lathe([(0.25, 1.85), (0.3, 1.92), (0.12, 2.0), (0.0, 2.0)], "bronze", "spin", seg=6, smooth=False)
    for x, y, _z, a in sk.ring(3, 0.15, 1.9, 0.0):
        c, s = math.cos(a), math.sin(a)
        b.limb((x, y, 1.92), (c * 0.7, s * 0.7, 2.25), 0.09, 0.07, "bronze", "spin", seg=5)
        b.box((c * 0.7, s * 0.7, 2.32), (0.14, 0.42, 0.5), "bronze", "spin", rot=Quaternion((0, 0, 1), a + 0.5))
        b.ball((c * 0.75, s * 0.75, 2.58), 0.06, "glow_green", "spin", seg=4, rings=2)
    b.ball((0, 0, 2.45), 0.2, "glow_green", "gem", scale=(1, 1, 2.0), seg=6, rings=2, smooth=False)
    b.lathe([(0.36, 1.64), (0.56, 1.76), (0.36, 1.88), (0.3, 1.76), (0.36, 1.64)], "rune_green", "wave", seg=12, cap=False)
    b.finish(arm)
    return arm


def spin(arm, ang):
    return {"spin": (lib.world_rot(arm, "spin", (0, 0, 1), ang), None)}


def idle(arm, t):
    p = spin(arm, 2 * math.pi / 3 * t)  # 3 vanes: a third of a turn loops seamlessly
    p["gem"] = (lib.world_rot(arm, "gem", (0, 0, 1), -2 * math.pi / 3 * t),
                lib.world_loc(arm, "gem", (0, 0, 0.12 * math.sin(2 * math.pi * t))))
    p["wave"] = (None, None, (0.01, 0.01, 0.01))
    return p


def attack(arm, t):
    p = idle(arm, 0.3 * t)
    f = lib.pulse(t, 0.0, 1.0)
    u = lib.ease(t)
    p["gem"] = (p["gem"][0], lib.world_loc(arm, "gem", (0, 0, 0.25 * f)), (1 + 0.6 * f,) * 3)
    r = 1.05 + 0.4 * u
    p["wave"] = (None, lib.world_loc(arm, "wave", (0, 0, -1.55 * u)), (r, 1, r) if t < 0.95 else (0.01,) * 3)
    return p


if __name__ == "__main__":
    sk.run(build, idle, attack, attack_frames=16, top="spin", pop=("gem",), drop={"spin": 1.7}, fall=0.5)
