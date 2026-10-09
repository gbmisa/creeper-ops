"""Drop pod: bronze capsule, heat shield underneath, four fins up top, four doors over a glowing cradle.
Clips (static-structure contract, re-purposed): walk = falling (thruster flame, judder, doors shut),
attack = touchdown (squash, doors fall open, cap vents), idle = landed and open, die = sinks away.
Real metres, scale 1, about 2.3 m tall. Game id: drop_pod.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
import struct_kit as sk  # noqa: E402
from mathutils import Quaternion  # noqa: E402

DOORS = sk.ring(4, 0.48, 0.42, math.pi / 4)
FINS = sk.ring(4, 0.42, 1.8, 0.0)


def build():
    bones = [("root", (0, 0, 0), (0, 0, 0.1), None),
             ("base", (0, 0, 0), (0, 0, 0.4), "root"),
             ("body", (0, 0, 0.4), (0, 0, 1.7), "base"),
             ("cap", (0, 0, 1.7), (0, 0, 2.3), "body"),
             ("flame", (0, 0, 0.05), (0, 0, -0.6), "base")]
    bones += [("door%d" % i, (x, y, z), (x, y, z + 1.2), "base") for i, (x, y, z, _a) in enumerate(DOORS)]
    bones += [("fin%d" % i, (x, y, z), (x * 1.6, y * 1.6, z + 0.3), "cap") for i, (x, y, z, _a) in enumerate(FINS)]
    arm = lib.armature("drop_pod", bones)
    b = lib.Builder("drop_pod")
    b.lathe([(0.3, 0.0), (0.6, 0.12), (0.62, 0.3), (0.5, 0.42), (0.0, 0.42)], "iron", "base", seg=8, smooth=False)
    b.lathe([(0.45, 0.02), (0.0, 0.0)], "flame", "base", seg=8)  # hot underside
    b.lathe([(0.36, 0.4), (0.36, 1.62), (0.0, 1.62)], "unit_glow", "body", seg=8)  # cradle glow, seen when open
    for k in range(4):  # corner ribs between the doors
        a = k * math.pi / 2
        b.box((math.cos(a) * 0.46, math.sin(a) * 0.46, 1.02), (0.14, 0.14, 1.25), "bronze_dark", "body", rot=Quaternion((0, 0, 1), a))
    b.lathe([(0.56, 1.6), (0.52, 1.85), (0.36, 2.1), (0.12, 2.28), (0.0, 2.3)], "bronze", "cap", seg=8, smooth=False)
    b.lathe([(0.58, 1.6), (0.58, 1.68), (0.0, 1.68)], "bronze_dark", "cap", seg=8, smooth=False)
    b.limb((0, 0, 2.25), (0, 0, 2.55), 0.03, 0.0, "iron", "cap", seg=4)  # antenna
    b.ball((0, 0, 2.56), 0.04, "teal", "cap", seg=5, rings=3)
    for i, (x, y, z, a) in enumerate(FINS):
        b.box((x * 1.25, y * 1.25, z + 0.05), (0.32, 0.05, 0.42) if i % 2 == 0 else (0.05, 0.32, 0.42), "iron", "fin%d" % i)
    for i, (x, y, z, a) in enumerate(DOORS):
        q = Quaternion((0, 0, 1), a)
        b.box((x, y, z + 0.6), (0.06, 0.62, 1.18), "bronze", "door%d" % i, rot=q)
        b.box((x * 1.04, y * 1.04, z + 0.75), (0.03, 0.08, 0.6), "teal", "door%d" % i, rot=q)  # rune strip
        b.box((x * 1.03, y * 1.03, z + 0.15), (0.05, 0.5, 0.06), "bronze_dark", "door%d" % i, rot=q)
    b.limb((0, 0, 0.0), (0, 0, -1.3), 0.4, 0.0, "flame", "flame", seg=8)
    b.finish(arm)
    return arm


HIDE = (None, None, (0.01, 0.01, 0.01))


def doors(arm, o):
    return {"door%d" % i: (lib.world_rot(arm, "door%d" % i, sk.tangent(x, y), 1.5 * o), None)
            for i, (x, y, _z, _a) in enumerate(DOORS)}


def fins(arm, amt):
    return {"fin%d" % i: (lib.world_rot(arm, "fin%d" % i, sk.tangent(x, y), amt), None)
            for i, (x, y, _z, _a) in enumerate(FINS)}


def idle(arm, t):  # landed, doors open, cradle breathing, vents puffing
    p = doors(arm, 1.0)
    p["flame"] = HIDE
    s = 1 + 0.03 * math.sin(2 * math.pi * t)
    p["body"] = (None, None, (1, s, 1))
    return p


def walk(arm, t):  # falling
    w = 2 * math.pi * t
    p = doors(arm, 0.0)
    p.update(fins(arm, 0.06 * math.sin(3 * w)))
    f = 1 + 0.25 * math.sin(4 * w) + 0.1 * math.sin(7 * w)
    p["flame"] = (None, None, (1 + 0.1 * math.sin(5 * w), f, 1 + 0.1 * math.sin(5 * w)))
    p["base"] = (lib.world_rot(arm, "base", (1, 0, 0), 0.03 * math.sin(2 * w)), lib.world_loc(arm, "base", (0.02 * math.sin(3 * w), 0, 0)))
    return p


def attack(arm, t):  # touchdown
    hit = lib.pulse(t, 0.0, 0.35)
    o = lib.ease(min(1.0, max(0.0, (t - 0.2) / 0.5)))
    p = doors(arm, o)
    p["flame"] = (None, None, (max(0.01, 1 - t * 6),) * 3)
    p["base"] = (None, None, (1 + 0.12 * hit, 1 - 0.18 * hit, 1 + 0.12 * hit))
    pop = lib.pulse(t, 0.25, 0.65)
    p["cap"] = (None, lib.world_loc(arm, "cap", (0, 0, 0.18 * pop)))
    p.update(fins(arm, 0.4 * pop))
    return p


if __name__ == "__main__":
    out = sys.argv[sys.argv.index("--") + 1]
    lib.reset()
    a = build()
    lib.action(a, "idle", 48, lambda t: idle(a, t), step=2, loop=True)
    lib.action(a, "walk", 12, lambda t: walk(a, t), step=1, loop=True)
    lib.action(a, "attack", 30, lambda t: attack(a, t), step=1)
    lib.action(a, "hit", 10, lambda t: sk.hit_pose(a, idle, t, "cap"), step=1)
    lib.action(a, "die", 40, lambda t: sk.die_pose(a, idle, t, {}, (), {}), step=1)
    lib.export(out)
