"""Totem (structure id beacon): hex plinth, four-sided stone obelisk cut with teal runes, a crystal
floating above. attack = the Operative deploys here (runes flare, crystal spins up, a light ring
rises). Real metres, scale 1, about 2.7 m tall. Game id: totem.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
import struct_kit as sk  # noqa: E402
from mathutils import Quaternion  # noqa: E402

TOP = 2.3


def build():
    arm = lib.armature("totem", [("root", (0, 0, 0), (0, 0, 0.1), None),
                                 ("base", (0, 0, 0), (0, 0, 0.3), "root"),
                                 ("shaft", (0, 0, 0.3), (0, 0, TOP), "base"),
                                 ("runes", (0, 0, 0.5), (0, 0, 1.9), "shaft"),
                                 ("crystal", (0, 0, 2.55), (0, 0, 2.9), "base"),
                                 ("ring", (0, 0, 0.32), (0, 0, 0.5), "base")])
    b = lib.Builder("totem")
    b.lathe([(0.75, 0.0), (0.75, 0.16), (0.62, 0.2), (0.62, 0.3), (0.0, 0.3)], "stone_dark", "base", seg=6, smooth=False)
    for k in range(6):  # bronze corner caps
        a = k * math.pi / 3
        b.box((math.cos(a) * 0.68, math.sin(a) * 0.68, 0.2), (0.14, 0.14, 0.12), "bronze", "base", rot=Quaternion((0, 0, 1), a))
    b.lathe([(0.44, 0.3), (0.36, 1.2), (0.27, TOP), (0.0, TOP + 0.12)], "stone", "shaft", seg=4, smooth=False)
    b.lathe([(0.5, 0.3), (0.47, 0.42), (0.0, 0.42)], "bronze_dark", "shaft", seg=4, smooth=False)
    b.lathe([(0.31, 1.95), (0.33, 2.02), (0.29, 2.08)], "bronze", "shaft", seg=4, smooth=False)
    for k in range(4):  # rune channels on each face
        a = k * math.pi / 2 + math.pi / 4  # face normals of the 4-sided lathe
        n = (math.cos(a), math.sin(a))
        for z, h in ((0.75, 0.5), (1.32, 0.42), (1.75, 0.2)):
            r = (0.44 - (z - 0.3) * 0.09) * math.cos(math.pi / 4) + 0.01
            b.box((n[0] * r, n[1] * r, z), (0.04, 0.1, h), "teal", "runes",
                  rot=Quaternion((0, 0, 1), a) @ Quaternion((0, 1, 0), -0.09))
    b.ball((0, 0, 2.7), 0.16, "teal", "crystal", scale=(1, 1, 2.2), seg=6, rings=2, smooth=False)
    for s in (1, -1):
        b.ball((0, s * 0.24, 2.62), 0.05, "teal", "crystal", scale=(1, 1, 2), seg=4, rings=2, smooth=False)
    b.lathe([(0.58, 0.3), (0.64, 0.33), (0.58, 0.36), (0.52, 0.33), (0.58, 0.3)], "teal", "ring", seg=16, cap=False)
    b.finish(arm)
    return arm


def pose(arm, t, spin=1.0, float_=0.05, glow=1.0, ring=None):
    p = {"crystal": (Quaternion((0, 1, 0), 2 * math.pi * t * spin),  # bone-local y = up
                     lib.world_loc(arm, "crystal", (0, 0, float_ * math.sin(2 * math.pi * t)))),
         "runes": (None, None, (glow, 1, glow))}
    p["ring"] = (None, None, (0.01, 0.01, 0.01)) if ring is None else ring
    return p


def idle(arm, t):
    return pose(arm, t, spin=1.0, glow=1 + 0.06 * math.sin(4 * math.pi * t))


def attack(arm, t):
    flare = lib.pulse(t, 0.0, 0.9)
    u = lib.ease(t)
    ring = (None, lib.world_loc(arm, "ring", (0, 0, 2.6 * u)), (1 + 1.2 * u, 1, 1 + 1.2 * u) if t < 0.95 else (0.01,) * 3)
    p = pose(arm, t, spin=4.0, float_=0.25 * flare, glow=1 + 0.5 * flare, ring=ring)
    p["crystal"] = (p["crystal"][0], lib.world_loc(arm, "crystal", (0, 0, 0.3 * flare)), (1 + 0.5 * flare,) * 3)
    return p


if __name__ == "__main__":
    sk.run(build, idle, attack, attack_frames=30, idle_frames=48, top="shaft",
           wilt={"shaft": (1, 0, 0)}, drop={"crystal": 2.3}, fall=1.2)
