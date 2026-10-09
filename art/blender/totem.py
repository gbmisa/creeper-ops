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
                                 ("crystal", (0, 0, 2.75), (0, 0, 3.1), "base"),
                                 ("ring", (0, 0, 0.32), (0, 0, 0.5), "base"),
                                 ("halo", (0, 0, 0.02), (0, 0, 0.2), "base")])
    b = lib.Builder("totem")
    b.lathe([(1.0, 0.0), (1.0, 0.12), (0.88, 0.14), (0.88, 0.24), (0.74, 0.26), (0.74, 0.36), (0.0, 0.36)], "stone_dark", "base", seg=6, smooth=False)
    for k in range(6):  # bronze corner caps
        a = k * math.pi / 3
        b.box((math.cos(a) * 0.9, math.sin(a) * 0.9, 0.18), (0.18, 0.18, 0.16), "bronze", "base", rot=Quaternion((0, 0, 1), a))
    b.lathe([(0.6, 0.36), (0.48, 1.2), (0.38, TOP)], "stone", "shaft", seg=4, smooth=False, cap=False)
    b.lathe([(0.38, TOP), (0.5, TOP + 0.08), (0.5, TOP + 0.16), (0.0, TOP + 0.42)], "brass", "shaft", seg=4, smooth=False)  # flared pyramidion
    for k in range(4):  # corner buttresses
        a = k * math.pi / 2
        c, s = math.cos(a), math.sin(a)
        b.poly([(c * 0.58, s * 0.58, 0.36), (c * 0.95, s * 0.95, 0.36), (c * 0.5, s * 0.5, 1.5)], ["shaft"] * 3, "stone_dark")
        b.box((c * 0.72, s * 0.72, 0.62), (0.12, 0.12, 0.5), "stone_dark", "shaft", rot=Quaternion((0, 0, 1), a))
    b.lathe([(0.68, 0.36), (0.64, 0.5), (0.0, 0.5)], "bronze_dark", "shaft", seg=4, smooth=False)
    for k in range(4):  # rune channels on each face
        a = k * math.pi / 2 + math.pi / 4  # face normals of the 4-sided lathe
        n = (math.cos(a), math.sin(a))
        for z, h in ((0.75, 0.5), (1.32, 0.42), (1.75, 0.2)):
            r = (0.6 - (z - 0.36) * 0.115) * math.cos(math.pi / 4) + 0.01
            b.box((n[0] * r, n[1] * r, z), (0.04, 0.14, h), "teal", "runes",
                  rot=Quaternion((0, 0, 1), a) @ Quaternion((0, 1, 0), -0.09))
    b.ball((0, 0, 2.9), 0.2, "teal", "crystal", scale=(1, 1, 2.0), seg=6, rings=2, smooth=False)
    for s in (1, -1):
        b.ball((0, s * 0.3, 2.82), 0.06, "teal", "crystal", scale=(1, 1, 2), seg=4, rings=2, smooth=False)
    b.lathe([(0.58, 0.3), (0.64, 0.33), (0.58, 0.36), (0.52, 0.33), (0.58, 0.3)], "teal", "ring", seg=16, cap=False)
    b.lathe([(0.9, 0.0), (1.25, 0.02), (1.6, 0.0), (1.25, 0.04), (0.9, 0.0)], "teal", "halo", seg=24, cap=False)  # ground glow
    b.finish(arm)
    return arm


def pose(arm, t, spin=1.0, float_=0.05, glow=1.0, ring=None):
    p = {"crystal": (Quaternion((0, 1, 0), 2 * math.pi * t * spin),  # bone-local y = up
                     lib.world_loc(arm, "crystal", (0, 0, float_ * math.sin(2 * math.pi * t)))),
         "runes": (None, None, (glow, 1, glow))}
    p["ring"] = (None, None, (0.01, 0.01, 0.01)) if ring is None else ring
    p["halo"] = (None, None, (0.01, 0.01, 0.01))
    return p


def idle(arm, t):
    return pose(arm, t, spin=1.0, glow=1 + 0.06 * math.sin(4 * math.pi * t))


def attack(arm, t):
    flare = min(1.0, t / 0.15) if t < 0.75 else 1.0 - 0.7 * lib.ease((t - 0.75) / 0.25)
    u = lib.ease(min(1.0, t / 0.8))
    ring = (None, lib.world_loc(arm, "ring", (0, 0, 2.8 * u)), (1 + 1.4 * u, 1, 1 + 1.4 * u) if t < 0.85 else (0.01,) * 3)
    p = pose(arm, t, spin=4.0, float_=0.25 * flare, glow=1 + 0.5 * flare, ring=ring)
    p["crystal"] = (p["crystal"][0], lib.world_loc(arm, "crystal", (0, 0, 0.3 * flare)), (1 + 0.5 * flare,) * 3)
    p["halo"] = (None, None, (max(0.01, flare), 1, max(0.01, flare)))
    return p


def hit(arm, t):
    j = lib.pulse(t, 0.0, 1.0) * (1.0 - t)
    p = idle(arm, 0.0)
    p["runes"] = (None, None, (1 + 0.12 * j, 1 + 0.1 * j, 1 + 0.12 * j))
    p["crystal"] = (p["crystal"][0], lib.world_loc(arm, "crystal", (0, 0, 0.3 * j)), (1 + 0.4 * j,) * 3)
    p["shaft"] = (lib.world_rot(arm, "shaft", (1, 0, 0), 0.1 * j * math.sin(10 * t)), None)
    return p


if __name__ == "__main__":
    out = sys.argv[sys.argv.index("--") + 1]
    lib.reset()
    a = build()
    lib.action(a, "idle", 48, lambda t: idle(a, t), step=2, loop=True)
    lib.action(a, "walk", 48, lambda t: idle(a, t), step=2, loop=True)
    lib.action(a, "attack", 30, lambda t: attack(a, t), step=1)
    lib.action(a, "hit", 10, lambda t: hit(a, t), step=1)
    lib.action(a, "die", 40, lambda t: sk.die_pose(a, idle, t, {"shaft": (1, 0, 0)}, ("crystal",), {}, 0.7), step=1)
    lib.export(out)
