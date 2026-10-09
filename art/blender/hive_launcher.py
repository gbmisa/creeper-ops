"""Spore launcher: tall ribbed flesh stalk topped by a glowing spore pod inside four bone petals.
attack = a squeeze wave runs up the stalk, the petals fling open and the pod fires. Game kind: launcher.
Real metres, scale 1.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
import struct_kit as sk  # noqa: E402

PETALS = sk.ring(4, 0.2, 1.32, math.pi / 4)
TOP = 1.32


def build():
    bones = [("root", (0, 0, 0), (0, 0, 0.1), None),
             ("base", (0, 0, 0), (0, 0, 0.3), "root"),
             ("stalk1", (0, 0, 0.3), (0, 0, 0.8), "base"),
             ("stalk2", (0, 0, 0.8), (0, 0, TOP), "stalk1"),
             ("pod", (0, 0, TOP), (0, 0, TOP + 0.3), "stalk2"),
             ("wave", (0, 0, 0.3), (0, 0, 0.5), "base"),
             ("shot", (0, 0, TOP + 0.14), (0, 0, TOP + 0.4), "base")]
    bones += [("petal%d" % i, (x, y, z), (x * 2.5, y * 2.5, z + 0.4), "stalk2") for i, (x, y, z, _a) in enumerate(PETALS)]
    arm = lib.armature("launcher", bones)
    b = lib.Builder("launcher")
    b.lathe([(0.6, 0.0), (0.52, 0.12), (0.34, 0.26), (0.22, 0.34), (0.0, 0.36)], "hive_skin", "base", seg=12)
    for k in range(6):  # roots
        a = k * math.pi / 3 + 0.4
        b.limb((math.cos(a) * 0.42, math.sin(a) * 0.42, 0.08), (math.cos(a) * 0.95, math.sin(a) * 0.8, 0.0), 0.05, 0.02, "sinew", "base", seg=4)
    b.lathe([(0.26, 0.25), (0.29, 0.45), (0.24, 0.62), (0.25, 0.82)], "hive_skin", "stalk1", seg=10)
    b.lathe([(0.25, 0.8), (0.2, 1.0), (0.19, 1.18), (0.25, TOP)], "hive_skin", "stalk2", seg=10)
    for z, bone in ((0.42, "stalk1"), (0.66, "stalk1"), (0.92, "stalk2"), (1.12, "stalk2")):  # bone rings
        b.lathe([(0.3, z - 0.035), (0.33, z), (0.3, z + 0.035)], "chitin", bone, seg=10)
    for k in range(3):  # glowing veins up the stalk
        a = k * 2 * math.pi / 3
        for z0, z1, bone in ((0.3, 0.8, "stalk1"), (0.8, TOP, "stalk2")):
            r0, r1 = (0.28, 0.25) if bone == "stalk1" else (0.24, 0.24)
            b.limb((math.cos(a) * r0, math.sin(a) * r0, z0), (math.cos(a + 0.4) * r1, math.sin(a + 0.4) * r1, z1), 0.025, 0.025, "spore_glow", bone, seg=4)
    b.ball((0, 0, TOP + 0.14), 0.22, "spore_glow", "pod", seg=10, rings=7)
    for i, (x, y, z, a) in enumerate(PETALS):
        mid = (math.cos(a) * 0.4, math.sin(a) * 0.4, z + 0.2)
        tip = (math.cos(a) * 0.12, math.sin(a) * 0.12, z + 0.5)
        b.limb((x, y, z - 0.04), mid, 0.11, 0.11, "bone", "petal%d" % i, seg=5)
        b.limb(mid, tip, 0.11, 0.0, "bone", "petal%d" % i, seg=5)
        b.poly([(x * 0.5, y * 0.5, z), mid, tip], ["petal%d" % i] * 3, "chitin")
    b.lathe([(0.3, 0.24), (0.38, 0.3), (0.3, 0.36)], "spore_glow", "wave", seg=12)
    b.ball((0, 0, TOP + 0.14), 0.2, "spore_glow", "shot", seg=8, rings=6)
    b.finish(arm)
    return arm


def petals(arm, amount):
    return {"petal%d" % i: (lib.world_rot(arm, "petal%d" % i, sk.tangent(x, y), amount), None)
            for i, (x, y, _z, _a) in enumerate(PETALS)}


def idle(arm, t):
    w = 2 * math.pi * t
    p = petals(arm, 0.1 + 0.08 * math.sin(w))
    p["stalk1"] = (lib.world_rot(arm, "stalk1", (1, 0, 0), 0.04 * math.sin(w)), None)
    p["stalk2"] = (lib.world_rot(arm, "stalk2", (0, 1, 0), 0.05 * math.sin(w + 1.2)), None)
    s = 1 + 0.18 * math.sin(2 * w)
    p["pod"] = (None, None, (s, s, s))
    p["wave"] = p["shot"] = (None, None, (0.01, 0.01, 0.01))
    return p


def attack(arm, t):
    sq1 = lib.pulse(t, 0.0, 0.35)
    sq2 = lib.pulse(t, 0.2, 0.55)
    fire = lib.pulse(t, 0.4, 1.0) ** 0.5
    p = petals(arm, 0.1 + 1.5 * fire)
    u = min(1.0, t / 0.5)
    w = 1.2 * lib.pulse(t, 0.0, 0.55) if t < 0.55 else 0.01
    p["wave"] = (None, lib.world_loc(arm, "wave", (0, 0, u * (TOP - 0.3))), (max(0.01, w), 1, max(0.01, w)))
    f = (t - 0.5) / 0.5 if t > 0.5 else 0.0
    p["shot"] = (None, lib.world_loc(arm, "shot", (0, 0, 1.2 * f)), (1.0 if f > 0 else 0.01,) * 3)
    p["stalk1"] = (None, None, (1 - 0.25 * sq1, 1 + 0.12 * sq1, 1 - 0.25 * sq1))
    p["stalk2"] = (None, None, (1 - 0.3 * sq2, 1 + 0.15 * sq2, 1 - 0.3 * sq2))
    pod = 1 + 0.45 * sq2 - 0.6 * fire
    p["pod"] = (None, lib.world_loc(arm, "pod", (0, 0, 0.12 * fire)), (pod, pod, pod))
    return p


if __name__ == "__main__":
    sk.run(build, idle, attack, attack_frames=24, top="stalk2",
           wilt={"stalk1": (1, 0, 0), **{"petal%d" % i: sk.tangent(x, y) for i, (x, y, _z, _a) in enumerate(PETALS)}},
           pop=("pod",))
