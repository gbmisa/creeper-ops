"""Spawn pit: fleshy lipped hole ringed by six bone mandibles over a glowing brood pool.
attack = a raider is spawned (mandibles splay, the pool heaves). Game kind: pit (model hive_pit).
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
import struct_kit as sk  # noqa: E402

TEETH = sk.ring(6, 0.62, 0.22, math.pi / 6)


def build():
    bones = [("root", (0, 0, 0), (0, 0, 0.1), None),
             ("base", (0, 0, 0), (0, 0, 0.3), "root"),
             ("pool", (0, 0, 0.0), (0, 0, 0.2), "base")]
    bones += [("tooth%d" % i, (x, y, z), (x * 0.6, y * 0.6, z + 0.35), "base") for i, (x, y, z, _a) in enumerate(TEETH)]
    arm = lib.armature("pit", bones)
    b = lib.Builder("pit")
    b.lathe([(1.0, 0.0), (0.92, 0.14), (0.78, 0.28), (0.62, 0.3), (0.5, 0.2), (0.42, 0.0), (0.3, -0.05)],
            "hive_skin", "base", seg=14)
    b.lathe([(0.44, -0.02), (0.0, -0.08)], "hive_dark", "base", seg=10)
    for k in range(7):  # veins creeping out across the ground
        a = k * 2 * math.pi / 7 + 0.2
        b.limb((math.cos(a) * 0.7, math.sin(a) * 0.7, 0.2), (math.cos(a) * 1.15, math.sin(a) * 1.15, 0.01), 0.045, 0.015, "sinew", "base", seg=4)
    for x, y, z, a in sk.ring(9, 0.78, 0.29, 0.1):  # warts along the lip
        b.ball((x, y, z), 0.07, "hive_dark", "base", seg=5, rings=3)
    b.lathe([(0.52, 0.0), (0.48, 0.08), (0.42, 0.03)], "hive_dark", "base", seg=14, cap=False)  # dark lip round the pool
    b.ball((0, 0, 0.04), 0.44, "pit_glow", "pool", scale=(1, 1, 0.45), seg=10, rings=6)
    for i, (x, y, z, _a) in enumerate(TEETH):
        mid = (x * 0.98, y * 0.98, z + 0.5)
        tip = (x * 0.42, y * 0.42, z + 0.78)
        b.limb((x, y, z - 0.08), mid, 0.12, 0.09, "bone", "tooth%d" % i, seg=5)
        b.limb(mid, tip, 0.09, 0.0, "bone", "tooth%d" % i, seg=5)
    b.finish(arm)
    return arm


def teeth(arm, t, amount):
    return {"tooth%d" % i: (lib.world_rot(arm, "tooth%d" % i, sk.tangent(x, y), amount(i)), None)
            for i, (x, y, _z, _a) in enumerate(TEETH)}


def idle(arm, t):
    p = teeth(arm, t, lambda i: 0.08 * math.sin(2 * math.pi * t + i * 1.1))
    s = 1 + 0.08 * math.sin(2 * math.pi * t)
    p["pool"] = (None, None, (s, 1 + 0.2 * math.sin(2 * math.pi * t), s))
    return p


def attack(arm, t):
    o = lib.pulse(t, 0.0, 0.85)
    p = teeth(arm, t, lambda i: 1.25 * o)
    heave = min(1.0, 1.6 * lib.pulse(t, 0.1, 0.95))
    p["pool"] = (None, lib.world_loc(arm, "pool", (0, 0, 0.3 * heave)), (1 + 0.2 * heave, 1 + 3.0 * heave, 1 + 0.2 * heave))
    return p


if __name__ == "__main__":
    sk.run(build, idle, attack, attack_frames=24, top=None,
           wilt={"tooth%d" % i: sk.tangent(x, y) for i, (x, y, _z, _a) in enumerate(TEETH)}, pop=("pool",))
