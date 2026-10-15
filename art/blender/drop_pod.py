"""Drop pod, military: a scorched gunmetal heat shield, an olive armoured capsule with steel ribs,
four hazard-striped blast doors over a lit cradle, a stencilled nose cone, four steel grid fins
and an aerial. Clips (static-structure contract, re-purposed): walk = falling (retro flame,
judder, doors shut), attack = touchdown (squash, doors blow open, the nose vents),
idle = landed and open, die = sinks away. Real metres, scale 1, about 2.3 m tall. Game id: drop_pod.
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
             ("flame", (0, 0, 0.05), (0, 0, -0.6), "base"),
             ("dust", (0, 0, 0.02), (0, 0, 0.2), "root")]
    bones += [("door%d" % i, (x, y, z), (x, y, z + 1.2), "base") for i, (x, y, z, _a) in enumerate(DOORS)]
    bones += [("fin%d" % i, (x, y, z), (x * 1.6, y * 1.6, z + 0.3), "cap") for i, (x, y, z, _a) in enumerate(FINS)]
    arm = lib.armature("drop_pod", bones)
    b = lib.Builder("drop_pod")
    b.lathe([(0.3, 0.0), (0.6, 0.12), (0.62, 0.3), (0.5, 0.42), (0.0, 0.42)], "gunmetal", "base", seg=8, smooth=False)
    b.lathe([(0.63, 0.14), (0.64, 0.24), (0.0, 0.24)], "smoke_dark", "base", seg=8, smooth=False)  # scorch band
    b.lathe([(0.45, 0.02), (0.0, 0.0)], "fire", "base", seg=8)  # hot underside
    b.lathe([(0.36, 0.4), (0.36, 1.62), (0.0, 1.62)], "unit_glow", "body", seg=8)  # cradle light, seen when open
    for k in range(4):  # steel ribs between the doors
        a = k * math.pi / 2
        b.box((math.cos(a) * 0.46, math.sin(a) * 0.46, 1.02), (0.14, 0.14, 1.25), "steel", "body", rot=Quaternion((0, 0, 1), a))
    b.lathe([(0.56, 1.6), (0.52, 1.85), (0.36, 2.1), (0.12, 2.28), (0.0, 2.3)], "olive_dark", "cap", seg=8, smooth=False)
    b.lathe([(0.58, 1.6), (0.58, 1.7), (0.0, 1.7)], "gunmetal", "cap", seg=8, smooth=False)
    for k in range(8):  # hazard collar
        a = k * math.pi / 4 + math.pi / 8
        b.box((math.cos(a) * 0.535, math.sin(a) * 0.535, 1.78), (0.04, 0.2, 0.1), "hazard" if k % 2 else "rubber",
              "cap", rot=Quaternion((0, 0, 1), a) @ Quaternion((0, 1, 0), 0.15))
    b.limb((0.15, 0, 2.2), (0.15, 0, 2.6), 0.02, 0.01, "rubber", "cap", seg=4)  # aerial
    b.ball((0.15, 0, 2.61), 0.035, "lamp_red", "cap", seg=5, rings=3)
    for i, (x, y, z, a) in enumerate(FINS):  # grid fins
        size = (0.34, 0.05, 0.4) if i % 2 == 0 else (0.05, 0.34, 0.4)
        b.box((x * 1.25, y * 1.25, z + 0.05), size, "steel", "fin%d" % i)
        b.box((x * 1.25, y * 1.25, z + 0.05), tuple(c * 0.7 if c > 0.1 else c * 1.4 for c in size), "rubber", "fin%d" % i)
    for i, (x, y, z, a) in enumerate(DOORS):
        q = Quaternion((0, 0, 1), a)
        b.box((x + math.cos(a) * 0.04, y + math.sin(a) * 0.04, z + 0.6), (0.14, 0.64, 1.18), "olive", "door%d" % i, rot=q)
        for dz in (0.12, 1.1):
            b.box((x * 1.18, y * 1.18, z + dz), (0.05, 0.66, 0.08), "gunmetal", "door%d" % i, rot=q)
        for j in range(3):  # hazard chevrons near the door foot
            off = (j - 1) * 0.2
            b.box((x * 1.19 - math.sin(a) * off, y * 1.19 + math.cos(a) * off, z + 0.28), (0.03, 0.12, 0.14),
                  "hazard", "door%d" % i, rot=q @ Quaternion((1, 0, 0), 0.6))
        b.box((x * 1.19, y * 1.19, z + 0.75), (0.03, 0.3, 0.12), "khaki", "door%d" % i, rot=q)  # stencil
    b.limb((0, 0, 0.0), (0, 0, -2.2), 0.66, 0.0, "fire", "flame", seg=10)
    b.lathe([(0.3, -0.02), (0.55, -0.1), (0.3, -0.18), (0.2, -0.1), (0.3, -0.02)], "flash_white", "flame", seg=12, cap=False)
    b.limb((0, 0, -1.6), (0, 0, -2.3), 0.12, 0.0, "fire", "flame", seg=6)  # flicker tip
    b.lathe([(0.7, 0.02), (0.9, 0.12), (0.7, 0.2), (0.55, 0.1), (0.7, 0.02)], "dust", "dust", seg=16, cap=False)
    b.finish(arm)
    return arm


HIDE = (None, None, (0.01, 0.01, 0.01))


def doors(arm, o):
    return {"door%d" % i: (lib.world_rot(arm, "door%d" % i, sk.tangent(x, y), 0.85 * o), None)
            for i, (x, y, _z, _a) in enumerate(DOORS)}


def fins(arm, amt):
    return {"fin%d" % i: (lib.world_rot(arm, "fin%d" % i, sk.tangent(x, y), amt), None)
            for i, (x, y, _z, _a) in enumerate(FINS)}


def idle(arm, t):  # landed, doors open, cradle breathing, vents puffing
    p = doors(arm, 1.0)
    p["flame"] = p["dust"] = HIDE
    s = 1 + 0.03 * math.sin(2 * math.pi * t)
    p["body"] = (None, None, (1, s, 1))
    return p


def walk(arm, t):  # falling
    w = 2 * math.pi * t
    p = doors(arm, 0.0)
    p["dust"] = HIDE
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
    p["base"] = (None, None, (1 + 0.15 * hit, 1 - 0.25 * hit, 1 + 0.15 * hit))
    d = min(1.0, t / 0.6)
    p["dust"] = (None, None, (1 + 2.2 * d, 1 - 0.5 * d, 1 + 2.2 * d) if t < 0.9 else (0.01,) * 3)
    pop = lib.pulse(t, 0.25, 0.65)
    p["cap"] = (None, lib.world_loc(arm, "cap", (0, 0, 0.18 * pop)))
    p.update(fins(arm, 0.4 * pop))
    return p


def hit(arm, t):
    j = lib.pulse(t, 0.0, 1.0) * (1.0 - t)
    p = idle(arm, 0.0)
    p["base"] = (lib.world_rot(arm, "base", (1, 0, 0), 0.25 * j * math.sin(9 * t)), lib.world_loc(arm, "base", (0.12 * j, 0, 0.08 * j)))
    return p


def die(arm, t):  # recall: doors fold back up, then it sinks into the ground
    p = doors(arm, 1.0 - lib.ease(min(1.0, t / 0.35)))
    p["flame"] = p["dust"] = HIDE
    s = lib.ease(max(0.0, (t - 0.3) / 0.7))
    p["base"] = (None, lib.world_loc(arm, "base", (0, 0, -2.4 * s)), (1 - 0.3 * s,) * 3)
    return p


if __name__ == "__main__":
    out = sys.argv[sys.argv.index("--") + 1]
    lib.reset()
    a = build()
    lib.action(a, "idle", 48, lambda t: idle(a, t), step=2, loop=True)
    lib.action(a, "walk", 12, lambda t: walk(a, t), step=1, loop=True)
    lib.action(a, "attack", 30, lambda t: attack(a, t), step=1)
    lib.action(a, "hit", 10, lambda t: hit(a, t), step=1)
    lib.action(a, "die", 40, lambda t: die(a, t), step=1)
    lib.export(out)
