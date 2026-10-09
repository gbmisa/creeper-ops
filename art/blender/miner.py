"""Miner, military: a compact drilling rig. A concrete pad with a hazard edge, a four-legged olive
derrick, a gunmetal motor housing with a turning rotary table and drill string (spin), an ore
hopper with an amber ore lamp (gem) and a spoil pile. Same height as SupportMeshes.miner (~2.4 m).
Clips: idle = the drill turns, the lamp breathes; attack = a pump stroke ships ore (the drill
punches down, the lamp flares, an ore puff rises from the hopper); hit = shake;
die = the derrick wilts, the lamp bursts, the rig sinks. Game id: miner.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
import mil_kit as mk  # noqa: E402
import struct_kit as sk  # noqa: E402
from mathutils import Quaternion, Vector  # noqa: E402

LEGS = [(x, y) for x in (1, -1) for y in (1, -1)]


def build():
    arm = lib.armature("miner", [("root", (0, 0, 0), (0, 0, 0.1), None),
                                 ("base", (0, 0, 0), (0, 0, 0.5), "root"),
                                 ("derrick", (0, 0, 0.3), (0, 0, 2.2), "base"),
                                 ("spin", (0, 0, 1.2), (0, 0, 1.5), "base"),
                                 ("gem", (0.55, -0.45, 1.05), (0.55, -0.45, 1.3), "base"),
                                 ("puff", (0.55, -0.45, 1.0), (0.55, -0.45, 1.2), "base")])
    b = lib.Builder("miner")
    mk.slab(b, 0.78, 0.22, "base", mat="concrete")
    mk.hazard_band(b, 0.78, 0.13, 0.08, "base", n=6)
    for x, y in LEGS:  # derrick legs to a crown block
        b.limb(Vector((x * 0.62, y * 0.62, 0.22)), Vector((x * 0.12, y * 0.12, 2.15)), 0.05, 0.04, "olive", "derrick", seg=4)
    for z, h in ((0.9, 0.42), (1.55, 0.25)):  # cross members
        for side in range(4):
            q = Quaternion((0, 0, 1), side * math.pi / 2)
            b.limb(q @ Vector((-h, h, z)), q @ Vector((h, h, z)), 0.025, 0.025, "steel", "derrick", seg=4)
    b.box((0, 0, 2.2), (0.36, 0.36, 0.14), "gunmetal", "derrick")
    b.ball((0, 0, 2.33), 0.05, "lamp_red", "derrick", seg=4, rings=2)
    b.lathe([(0.34, 0.22), (0.34, 0.5), (0.26, 0.6), (0.0, 0.6)], "gunmetal", "base", seg=8, smooth=False)
    b.box((-0.38, 0.0, 0.62), (0.3, 0.42, 0.36), "olive_dark", "base")  # motor
    b.limb(Vector((-0.38, 0.22, 0.62)), Vector((-0.38, 0.3, 0.62)), 0.12, 0.12, "steel", "base", seg=8)
    # spin: rotary table + drill string with four teeth (a quarter turn per loop)
    b.lathe([(0.26, 0.6), (0.3, 0.66), (0.3, 0.74), (0.0, 0.74)], "steel", "spin", seg=12, smooth=False)
    for i in range(4):
        a = i * math.pi / 2
        b.box((math.cos(a) * 0.27, math.sin(a) * 0.27, 0.76), (0.1, 0.06, 0.08), "hazard", "spin",
              rot=Quaternion((0, 0, 1), a))
    b.limb(Vector((0, 0, 0.74)), Vector((0, 0, 2.05)), 0.06, 0.06, "gunmetal", "spin", seg=6)
    for z in (1.1, 1.5, 1.9):
        b.limb(Vector((0, 0, z)), Vector((0, 0, z + 0.06)), 0.09, 0.09, "steel", "spin", seg=6)
    # ore hopper, lamp, spoil
    b.box((0.55, -0.45, 0.55), (0.42, 0.36, 0.5), "olive", "base")
    b.box((0.55, -0.45, 0.82), (0.46, 0.4, 0.04), "gunmetal", "base")
    b.box((0.55, -0.64, 0.55), (0.24, 0.01, 0.1), "khaki", "base")
    b.ball((0.55, -0.45, 1.05), 0.08, "lamp_amber", "gem", seg=6, rings=3)
    b.limb(Vector((0.55, -0.45, 0.84)), Vector((0.55, -0.45, 0.98)), 0.025, 0.025, "steel", "base", seg=4)
    for x, y, r in ((-0.5, 0.55, 0.16), (-0.35, 0.68, 0.12), (-0.62, 0.38, 0.1)):
        b.ball((x, y, 0.24), r, "khaki", "base", scale=(1, 1, 0.6), seg=6, rings=3)
    b.ball((0.55, -0.45, 1.0), 0.2, "dust", "puff", seg=6, rings=4)
    b.finish(arm)
    return arm


def idle(arm, t):
    return {"spin": (lib.world_rot(arm, "spin", (0, 0, 1), math.pi / 2 * t), None),
            "gem": (None, None, ((1 + 0.15 * math.sin(2 * math.pi * t)),) * 3),
            "puff": (None, None, (0.01, 0.01, 0.01))}


def attack(arm, t):
    p = idle(arm, t)
    stroke = lib.pulse(t, 0.0, 0.6)
    p["spin"] = (p["spin"][0], lib.world_loc(arm, "spin", (0, 0, -0.18 * stroke)))
    f = lib.pulse(t, 0.3, 0.9)
    p["gem"] = (None, None, ((1 + 0.8 * f),) * 3)
    u = max(0.0, (t - 0.35) / 0.65)
    p["puff"] = (None, lib.world_loc(arm, "puff", (0, 0, 0.8 * u)), ((0.6 + 1.2 * u),) * 3 if 0.35 < t < 0.97 else (0.01,) * 3)
    return p


if __name__ == "__main__":
    sk.run(build, idle, attack, attack_frames=16, top="spin", wilt={"derrick": (1, 0, 0)}, pop=("gem",), fall=0.6)
