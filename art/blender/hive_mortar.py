"""Hive mortar: squat plated bulb with a thick flesh barrel tilted toward +X and a glowing shell
sac on its back. attack = the sac pumps a shell into the barrel, the barrel kicks, the muzzle flares.
Game kind: mortar. Real metres, scale 1.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
import struct_kit as sk  # noqa: E402
from mathutils import Quaternion  # noqa: E402

TILT = 0.7  # barrel lean toward +X (rad)
B0 = (0.05, 0, 0.55)
B1 = (0.05 + math.sin(TILT) * 0.95, 0, 0.55 + math.cos(TILT) * 0.95)
AXIS = (math.sin(TILT), 0, math.cos(TILT))


def along(p, d):
    return tuple(a + b * d for a, b in zip(p, AXIS))


def lerp(a, b, t):
    return tuple(x + (y - x) * t for x, y in zip(a, b))


def build():
    arm = lib.armature("hive_mortar", [("root", (0, 0, 0), (0, 0, 0.1), None),
                                       ("base", (0, 0, 0), (0, 0, 0.3), "root"),
                                       ("body", (0, 0, 0.3), (0, 0, 0.6), "base"),
                                       ("barrel", B0, B1, "body"),
                                       ("muzzle", lerp(B0, B1, 0.85), B1, "barrel"),
                                       ("sac", (-0.35, 0, 0.55), (-0.5, 0, 0.75), "body"),
                                       ("flash", B1, along(B1, 0.5), "muzzle"),
                                       ("shell", B1, along(B1, 0.3), "body")])
    b = lib.Builder("hive_mortar")
    b.lathe([(0.75, 0.0), (0.7, 0.1), (0.55, 0.2), (0.35, 0.26), (0.0, 0.28)], "hive_skin", "base", seg=12)
    for k in range(6):  # grasping roots
        a = k * math.pi / 3 + 0.25
        b.limb((math.cos(a) * 0.55, math.sin(a) * 0.55, 0.12), (math.cos(a) * 1.05, math.sin(a) * 0.95, 0.0), 0.06, 0.02, "sinew", "base", seg=4)
    b.ball((0, 0, 0.42), 0.42, "hive_skin", "body", scale=(1.1, 1.05, 0.8), seg=10, rings=7)
    for k in range(5):  # overlapping plates
        a = k * 2 * math.pi / 5 + 0.6
        b.ball((math.cos(a) * 0.3, math.sin(a) * 0.3, 0.6), 0.2, "chitin", "body", scale=(1.1, 0.9, 0.45), seg=6, rings=4, smooth=False)
    b.limb(B0, lerp(B0, B1, 0.5), 0.31, 0.26, "hive_skin", "barrel", seg=10, smooth=True)
    b.limb(lerp(B0, B1, 0.5), lerp(B0, B1, 0.85), 0.26, 0.28, "hive_skin", "barrel", seg=10, smooth=True)
    for t in (0.25, 0.5, 0.72):  # chitin bands
        b.ball(lerp(B0, B1, t), 0.32, "chitin", "barrel", scale=(1.0, 1.0, 0.18), seg=10, rings=4, rot=Quaternion((0, 1, 0), TILT))
    b.limb(lerp(B0, B1, 0.85), B1, 0.31, 0.34, "bone", "muzzle", seg=10)
    b.ball(lerp(B0, B1, 0.97), 0.23, "mortar_glow", "muzzle", scale=(1, 1, 0.5), seg=8, rings=5,
           rot=Quaternion((0, 1, 0), TILT))
    for k in range(5):  # muzzle teeth
        a = k * 2 * math.pi / 5
        d = (math.cos(a) * math.cos(TILT) * 0.31, math.sin(a) * 0.31, -math.cos(a) * math.sin(TILT) * 0.31)
        base = tuple(p + q for p, q in zip(B1, d))
        b.limb(base, (base[0] + 0.06 + d[0] * 0.3, base[1] + d[1] * 0.3, base[2] + 0.12 + d[2] * 0.3), 0.04, 0.0, "bone", "muzzle", seg=3)
    b.ball((-0.45, 0, 0.62), 0.28, "mortar_glow", "sac", scale=(1.0, 1.2, 1.1), seg=8, rings=6)
    b.limb((-0.3, 0, 0.7), (0.0, 0, 0.75), 0.06, 0.06, "sinew", "sac", seg=5)  # feed tube
    b.limb(B1, along(B1, 0.35), 0.15, 0.0, "mortar_glow", "flash", seg=8)
    b.ball(B1, 0.27, "mortar_glow", "shell", seg=8, rings=6)
    b.finish(arm)
    return arm


def idle(arm, t):
    w = 2 * math.pi * t
    s = 1 + 0.08 * math.sin(w)
    return {"barrel": (lib.world_rot(arm, "barrel", (1, 0, 0), 0.06 * math.sin(w)), None),
            "sac": (None, None, (s, s, s)),
            "muzzle": (None, None, (1, 1 + 0.05 * math.sin(2 * w), 1)),
            "flash": HIDE, "shell": HIDE}


HIDE = (None, None, (0.01, 0.01, 0.01))


def attack(arm, t):
    pump = lib.pulse(t, 0.0, 0.45)
    kick = lib.pulse(t, 0.4, 0.75)
    flare = lib.pulse(t, 0.4, 0.8)
    back = (-math.sin(TILT) * 0.45 * kick, 0, -math.cos(TILT) * 0.45 * kick)
    f = (t - 0.45) / 0.55 if t > 0.45 else 0.0
    return {"sac": (None, None, (1 + 0.3 * pump - 0.5 * kick, 1 + 0.3 * pump - 0.5 * kick, 1 + 0.2 * pump - 0.3 * kick)),
            "flash": (None, None, (max(0.01, flare),) * 3),
            "shell": (None, lib.world_loc(arm, "shell", tuple(a * 1.5 * f for a in AXIS)), (1.0 if f > 0 else 0.01,) * 3),
            "barrel": (lib.world_rot(arm, "barrel", (0, 1, 0), -0.25 * kick), lib.world_loc(arm, "barrel", back),
                       (1 + 0.12 * pump, 1 - 0.2 * kick, 1 + 0.12 * pump)),
            "muzzle": (None, None, (1 + 0.9 * flare, 1 + 0.5 * flare, 1 + 0.9 * flare)),
            "base": (None, None, (1 + 0.06 * kick, 1 - 0.1 * kick, 1 + 0.06 * kick))}


if __name__ == "__main__":
    sk.run(build, idle, attack, attack_frames=24, top="barrel", wilt={"barrel": (0, 1, 0)}, pop=("sac",))
