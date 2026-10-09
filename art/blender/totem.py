"""Totem (structure id beacon), military: a teleport beacon. A hex steel deploy pad with a
hazard-striped rim and corner bollards, a tapering olive transmitter mast with armoured corner
ribs and teal signal strips, a gunmetal emitter head and a spinning teal beacon above it.
attack = the Operative deploys here (strips flare, the beacon spins up, a teal ring rises).
Real metres, scale 1, about 2.7 m tall. Game id: totem.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
import struct_kit as sk  # noqa: E402
import mil_kit as mk  # noqa: E402
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
    b.lathe([(1.0, 0.0), (1.0, 0.12), (0.92, 0.16), (0.0, 0.16)], "gunmetal", "base", seg=6, smooth=False)
    for k in range(12):  # hazard rim
        a = k * math.pi / 6 + math.pi / 12
        r = 0.97 * math.cos(math.pi / 6) / math.cos((a % (math.pi / 3)) - math.pi / 6)
        b.box((math.cos(a) * r, math.sin(a) * r, 0.08), (0.05, 0.5, 0.08), "hazard" if k % 2 else "rubber", "base",
              rot=Quaternion((0, 0, 1), a))
    b.lathe([(0.8, 0.16), (0.8, 0.22), (0.0, 0.22)], "steel", "base", seg=6, smooth=False)
    for k in range(6):  # bollards
        a = k * math.pi / 3
        b.limb((math.cos(a) * 0.85, math.sin(a) * 0.85, 0.16), (math.cos(a) * 0.85, math.sin(a) * 0.85, 0.4), 0.06, 0.06,
               "olive_dark", "base", seg=6)
        b.ball((math.cos(a) * 0.85, math.sin(a) * 0.85, 0.42), 0.04, "lamp_amber", "base", seg=4, rings=2)
    mk.square(b, 0.42, 0.22, TOP, "olive", "shaft", top_half=0.26)
    mk.column_trim(b, 0.42, 0.26, 0.22, TOP, "shaft", seams=(0.25, 0.7), mat="gunmetal", corner="gunmetal")
    for k in range(4):  # armoured corner ribs
        a = k * math.pi / 2 + math.pi / 4
        c, s = math.cos(a), math.sin(a)
        b.poly([(c * 0.6, s * 0.6, 0.22), (c * 0.9, s * 0.9, 0.22), (c * 0.45, s * 0.45, 1.4)], ["shaft"] * 3, "olive_dark")
    b.box((0.0, -0.43, 0.5), (0.3, 0.06, 0.24), "olive_dark", "shaft")
    for k in range(4):  # teal signal strips on each face
        a = k * math.pi / 2
        n = (math.cos(a), math.sin(a))
        for z, h in ((0.75, 0.5), (1.32, 0.42), (1.75, 0.2)):
            r = 0.42 - (z - 0.22) * (0.16 / (TOP - 0.22)) + 0.012
            b.box((n[0] * r, n[1] * r, z), (0.03, 0.08, h), "teal", "runes",
                  rot=Quaternion((0, 0, 1), a) @ Quaternion((0, 1, 0), -0.08))
    b.lathe([(0.3, TOP), (0.42, TOP + 0.08), (0.42, TOP + 0.2), (0.2, TOP + 0.3), (0.0, TOP + 0.3)], "gunmetal", "shaft",
            seg=8, smooth=False)
    for s in (1, -1):
        b.limb((0, s * 0.36, TOP + 0.1), (0, s * 0.36, TOP + 0.75), 0.025, 0.02, "steel", "shaft", seg=4)
    b.ball((0, 0, 2.9), 0.18, "teal", "crystal", scale=(1, 1, 1.8), seg=4, rings=2, smooth=False)
    b.lathe([(0.26, -0.03), (0.3, 0.0), (0.26, 0.03), (0.22, 0.0), (0.26, -0.03)], "steel", "crystal", at=(0, 0, 2.9),
            seg=12, cap=False)
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
