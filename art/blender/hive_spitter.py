"""Spitter turret: a rooted fleshy neck with a plated head, a hinged jaw and a glowing throat
sac. Faces +X. attack = rears back, the sac swells, then it lunges and spits. Game kind: spitter.
Real metres, scale 1. Not the raider spitter.py.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
import struct_kit as sk  # noqa: E402


def build():
    arm = lib.armature("hive_spitter", [("root", (0, 0, 0), (0, 0, 0.1), None),
                                        ("base", (0, 0, 0), (0, 0, 0.25), "root"),
                                        ("neck1", (0, 0, 0.25), (0.05, 0, 0.6), "base"),
                                        ("neck2", (0.05, 0, 0.6), (0.15, 0, 0.86), "neck1"),
                                        ("sac", (-0.08, 0, 0.5), (-0.08, 0, 0.7), "neck1"),
                                        ("head", (0.15, 0, 0.9), (0.5, 0, 0.94), "neck2"),
                                        ("jaw", (0.18, 0, 0.82), (0.5, 0, 0.78), "head"),
                                        ("spit", (0.52, 0, 0.88), (0.75, 0, 0.88), "head")])
    b = lib.Builder("hive_spitter")
    b.lathe([(0.55, 0.0), (0.5, 0.1), (0.36, 0.22), (0.2, 0.3), (0.0, 0.32)], "hive_skin", "base", seg=12)
    for k in range(5):  # roots
        a = k * 2 * math.pi / 5 + 0.3
        b.limb((math.cos(a) * 0.35, math.sin(a) * 0.4, 0.1), (math.cos(a) * 0.85, math.sin(a) * 0.75, 0.0), 0.05, 0.02, "sinew", "base", seg=4)
    b.limb((0, 0, 0.2), (0.05, 0, 0.62), 0.24, 0.19, "hive_skin", "neck1", seg=8, smooth=True)
    b.limb((0.05, 0, 0.6), (0.15, 0, 0.88), 0.19, 0.2, "hive_skin", "neck2", seg=8, smooth=True)
    for z, bone in ((0.36, "neck1"), (0.52, "neck1"), (0.7, "neck2")):  # back plates
        b.ball((-0.04 + (z - 0.36) * 0.25, 0, z), 0.16, "chitin", bone, scale=(0.7, 1.15, 0.45), seg=6, rings=4, smooth=False)
    for s in (1, -1):
        b.ball((-0.06, s * 0.19, 0.52), 0.15, "spit_glow", "sac", scale=(0.9, 0.8, 1.25), seg=8, rings=6)
    b.ball((0.3, 0, 0.94), 0.27, "chitin", "head", scale=(1.35, 1.0, 0.75), seg=9, rings=6)
    b.ball((0.28, 0, 1.1), 0.19, "plate", "head", scale=(1.5, 1.1, 0.4), seg=6, rings=4, smooth=False)
    for s in (1, -1):
        b.limb((0.22, s * 0.12, 1.06), (0.05, s * 0.2, 1.22), 0.05, 0.0, "bone", "head", seg=4)  # horns
        b.ball((0.46, s * 0.1, 0.98), 0.035, "eye", "head", seg=5, rings=4)
        b.ball((0.4, s * 0.15, 1.0), 0.028, "eye", "head", seg=5, rings=4)
    b.ball((0.5, 0, 0.88), 0.14, "spit_glow", "head", seg=7, rings=5)
    b.ball((0.34, 0, 0.78), 0.2, "chitin", "jaw", scale=(1.3, 0.9, 0.45), seg=8, rings=5)
    for s in (1, 0, -1):
        b.limb((0.5, s * 0.07, 0.82), (0.53, s * 0.07, 0.9), 0.025, 0.0, "bone", "jaw", seg=3)
        b.limb((0.52, s * 0.07 + 0.035, 0.92), (0.54, s * 0.07 + 0.035, 0.85), 0.022, 0.0, "bone", "head", seg=3)
    b.ball((0.6, 0, 0.88), 0.19, "spit_glow", "spit", scale=(1.3, 1, 1), seg=8, rings=6)
    b.finish(arm)
    return arm


def R(arm, bone, axis, ang):
    return lib.world_rot(arm, bone, axis, ang)


def pose(arm, lean=0.0, yaw=0.0, nod=0.0, jaw=0.0, sac=1.0, spit=0.0):
    return {"neck1": (R(arm, "neck1", (0, 0, 1), yaw) @ R(arm, "neck1", (0, 1, 0), lean), None),
            "neck2": (R(arm, "neck2", (0, 1, 0), lean * 0.6), None),
            "head": (R(arm, "head", (0, 1, 0), nod), None),
            "jaw": (R(arm, "jaw", (0, 1, 0), jaw), None),
            "sac": (None, None, (sac, sac, sac)),
            "spit": (None, lib.world_loc(arm, "spit", (1.2 * spit, 0, 0.1 * spit)), (1.1 if spit > 0 else 0.01,) * 3)}


def idle(arm, t):
    w = 2 * math.pi * t
    return pose(arm, lean=0.05 * math.sin(w), yaw=0.18 * math.sin(w + 1.0), nod=-0.08 * math.sin(2 * w),
                jaw=0.3 + 0.1 * math.sin(2 * w), sac=1 + 0.1 * math.sin(2 * w))


def attack(arm, t):
    back = lib.pulse(t, 0.0, 0.55)
    lunge = lib.pulse(t, 0.45, 0.85)
    shot = (t - 0.5) / 0.5 if t > 0.5 else 0.0
    return pose(arm, lean=-0.5 * back + 0.4 * lunge, nod=-0.35 * back - 0.2 * lunge,
                jaw=0.1 + 0.9 * lunge, sac=1 + 0.9 * back - 0.35 * lunge, spit=shot)


if __name__ == "__main__":
    sk.run(build, idle, attack, attack_frames=20, top="neck1", wilt={"neck1": (0, 1, 0)}, pop=("sac",))
