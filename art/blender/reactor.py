"""Reactor, military: a field generator. A sandbagged concrete containment drum with olive armour
cladding and a hazard band, two radiator banks, twin exhaust stacks, an amber core window, and a
turning turbine ring (spin) round an amber fuel rod (gem). Same size as SupportMeshes.reactor
(r 0.9, about 3 m). Clips: idle = the turbine turns, the core breathes; attack = a power surge
(core flares, the ring spins up, smoke puffs from the stacks); hit = shake; die = rod bursts,
the turbine drops, the drum sinks. Game id: reactor.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
import mil_kit as mk  # noqa: E402
import struct_kit as sk  # noqa: E402
from mathutils import Quaternion, Vector  # noqa: E402

STACKS = [(-0.42, 0.42), (-0.42, -0.42)]


def build():
    arm = lib.armature("reactor", [("root", (0, 0, 0), (0, 0, 0.1), None),
                                   ("base", (0, 0, 0), (0, 0, 0.5), "root"),
                                   ("spin", (0, 0, 2.1), (0, 0, 2.4), "base"),
                                   ("gem", (0, 0, 2.5), (0, 0, 3.0), "base"),
                                   ("smoke", (-0.42, 0, 2.3), (-0.42, 0, 2.5), "base")])
    b = lib.Builder("reactor")
    mk.slab(b, 1.0, 0.16, "base")
    mk.sandbags(b, 0.82, 0.16, "base", rows=1, per=4)
    b.lathe([(0.9, 0.16), (0.9, 1.1), (0.78, 1.35), (0.5, 1.6), (0.3, 1.65), (0.0, 1.65)], "concrete", "base",
            seg=12, smooth=False)
    for i in range(6):  # olive armour cladding panels
        a = i * math.pi / 3 + math.pi / 6
        b.box((math.cos(a) * 0.9, math.sin(a) * 0.9, 0.7), (0.06, 0.5, 0.8), "olive", "base", rot=Quaternion((0, 0, 1), a))
    for i in range(12):
        a = i * math.pi / 6
        b.box((math.cos(a) * 0.905, math.sin(a) * 0.905, 1.18), (0.03, 0.47, 0.1), "hazard" if i % 2 else "rubber",
              "base", rot=Quaternion((0, 0, 1), a))
    b.box((0.9, 0, 0.62), (0.08, 0.42, 0.34), "lamp_amber", "base")  # core window
    b.box((0.93, 0, 0.62), (0.04, 0.5, 0.06), "gunmetal", "base")
    for s in (1, -1):  # radiator banks
        b.box((0.15, s * 1.02, 0.7), (0.9, 0.12, 0.9), "gunmetal", "base")
        for k in range(5):
            b.box((-0.2 + k * 0.18, s * 1.09, 0.7), (0.05, 0.04, 0.84), "steel", "base")
    for x, y in STACKS:
        b.limb(Vector((x, y, 1.3)), Vector((x, y, 2.35)), 0.11, 0.1, "gunmetal", "base", seg=8)
        b.limb(Vector((x, y, 2.2)), Vector((x, y, 2.3)), 0.12, 0.12, "hazard", "base", seg=8)
    b.limb(Vector((0, 0, 1.6)), Vector((0, 0, 2.15)), 0.2, 0.18, "olive_dark", "base", seg=8)
    # spin: turbine ring with six vanes (a sixth of a turn per loop)
    b.lathe([(0.5, -0.05), (0.58, -0.05), (0.58, 0.07), (0.5, 0.07), (0.5, -0.05)], "steel", "spin",
            at=(0, 0, 2.2), seg=18, cap=False)
    for i in range(6):
        a = i * math.pi / 3
        b.box((math.cos(a) * 0.36, math.sin(a) * 0.36, 2.2), (0.3, 0.05, 0.1), "gunmetal", "spin",
              rot=Quaternion((0, 0, 1), a) @ Quaternion((1, 0, 0), 0.5))
    b.lathe([(0.52, -0.02), (0.56, -0.02), (0.56, 0.02), (0.52, 0.02), (0.52, -0.02)], "fire", "spin",
            at=(0, 0, 2.27), seg=18, cap=False)
    b.lathe([(0.0, 2.15), (0.14, 2.2), (0.12, 2.85), (0.0, 2.95)], "lamp_amber", "gem", seg=8, smooth=False)
    for i in range(3):
        a = i * 2 * math.pi / 3
        b.limb(Vector((math.cos(a) * 0.17, math.sin(a) * 0.17, 2.2)), Vector((math.cos(a) * 0.17, math.sin(a) * 0.17, 2.9)),
               0.02, 0.02, "steel", "gem", seg=4)
    for x, y in STACKS:
        b.ball((x, y, 2.5), 0.18, "smoke", "smoke", seg=6, rings=4)
    b.finish(arm)
    return arm


def idle(arm, t):
    return {"spin": (lib.world_rot(arm, "spin", (0, 0, 1), math.pi / 3 * t), None),
            "gem": (None, None, (1 + 0.08 * math.sin(2 * math.pi * t), 1, 1 + 0.08 * math.sin(2 * math.pi * t))),
            "smoke": (None, None, (0.01, 0.01, 0.01))}


def attack(arm, t):
    p = {"spin": (lib.world_rot(arm, "spin", (0, 0, 1), 2 * math.pi / 3 * t * (1 + t)), None)}
    f = lib.pulse(t, 0.0, 0.8)
    p["gem"] = (None, None, (1 + 0.5 * f, 1 + 0.2 * f, 1 + 0.5 * f))
    u = t
    p["smoke"] = (None, lib.world_loc(arm, "smoke", (0, 0, 0.9 * u)), ((0.5 + 1.3 * u),) * 3 if t < 0.95 else (0.01,) * 3)
    return p


if __name__ == "__main__":
    sk.run(build, idle, attack, attack_frames=20, top="spin", pop=("gem",), drop={"spin": 0.5}, fall=0.5)
