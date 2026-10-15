"""Forge, military: an armoured upgrade foundry. A concrete compound wall on a wide slab, four
corner silos with hazard caps, a gunmetal arc-furnace dome with an orange furnace door, an
anvil press, and four steel crane booms holding the turning violet Aether ring (spin) round the
Aether orb (gem). Same footprint and height as SupportMeshes.forge (9 m square, about 8.6 m).
Clips: idle = the ring turns, the orb breathes; attack = an upgrade is forged (orb flares, the
ring spins up, the press stamps, sparks fly from the door); hit = shake; die = the orb bursts,
the ring drops, the booms wilt, the foundry sinks. Game id: forge.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
import mil_kit as mk  # noqa: E402
import struct_kit as sk  # noqa: E402
from mathutils import Quaternion, Vector  # noqa: E402

SILOS = [(math.cos(a) * 4.6, math.sin(a) * 4.6) for a in (math.pi / 4 + i * math.pi / 2 for i in range(4))]
CORE = Vector((0, 0, 6.9))


def build():
    arm = lib.armature("forge", [("root", (0, 0, 0), (0, 0, 0.1), None),
                                 ("base", (0, 0, 0), (0, 0, 0.5), "root"),
                                 ("booms", (0, 0, 4.8), (0, 0, 6.6), "base"),
                                 ("spin", tuple(CORE), tuple(CORE + Vector((0, 0, 0.4))), "base"),
                                 ("gem", tuple(CORE), tuple(CORE + Vector((0, 0, 0.5))), "base"),
                                 ("press", (2.2, 2.2, 3.3), (2.2, 2.2, 3.9), "base"),
                                 ("sparks", (0, 3.5, 1.3), (0, 3.7, 1.3), "base")])
    b = lib.Builder("forge")
    mk.slab(b, 4.5, 0.5, "base")
    mk.hazard_band(b, 4.5, 0.3, 0.14, "base", n=14)
    mk.square(b, 3.4, 0.5, 3.1, "concrete", "base")
    mk.column_trim(b, 3.4, 3.4, 0.5, 3.1, "base", seams=(0.5,))
    mk.square(b, 3.45, 2.8, 3.1, "olive", "base")
    b.lathe([(2.6, 3.1), (2.3, 4.0), (1.4, 4.8), (0.6, 5.1), (0.0, 5.1)], "gunmetal", "base", seg=16, smooth=False)
    for i in range(8):  # dome armour ribs
        a = i * math.pi / 4
        c, s = math.cos(a), math.sin(a)
        b.limb(Vector((c * 2.62, s * 2.62, 3.1)), Vector((c * 1.4, s * 1.4, 4.85)), 0.09, 0.07, "olive_dark", "base", seg=4)
    b.box((0, 3.42, 1.3), (1.8, 0.1, 1.4), "fire", "base")  # furnace door
    b.box((0, 3.5, 2.12), (2.3, 0.2, 0.26), "hazard", "base")
    for x in (-1.05, 1.05):
        b.box((x, 3.5, 1.3), (0.26, 0.22, 1.8), "gunmetal", "base")
    for x, y in SILOS:  # corner silos
        b.lathe([(0.85, 0.0), (0.85, 4.6), (0.6, 5.1), (0.0, 5.2)], "olive", "base", at=(x, y, 0), seg=12, smooth=False)
        for z in (1.2, 3.0):
            b.lathe([(0.87, z), (0.87, z + 0.12), (0.0, z + 0.12)], "steel", "base", at=(x, y, 0), seg=12, smooth=False)
        b.lathe([(0.62, 5.0), (0.66, 5.1), (0.0, 5.25)], "hazard", "base", at=(x, y, 0), seg=12, smooth=False)
        b.limb(Vector((x * 0.85, y * 0.85, 5.0)), Vector((x * 0.25, y * 0.25, 6.55)), 0.16, 0.12, "steel", "booms", seg=6)
        b.ball((x * 0.25, y * 0.25, 6.6), 0.16, "gunmetal", "booms", seg=6, rings=3)
    mk.ladder(b, -3.42, -1.5, 0.5, 3.1, "base", face=(-1, 0), w=0.4)
    b.box((2.2, 2.2, 3.2), (1.2, 0.8, 0.3), "gunmetal", "base")  # press bed
    b.box((2.2, 2.2, 3.7), (0.7, 0.5, 0.5), "olive_dark", "press")
    b.limb(Vector((2.2, 2.2, 3.95)), Vector((2.2, 2.2, 4.5)), 0.08, 0.08, "steel", "press", seg=6)
    # spin: Aether ring with four clamps; gem: the orb in a cage
    pts = [CORE + Vector((math.cos(2 * math.pi * i / 24) * 1.35, math.sin(2 * math.pi * i / 24) * 1.35, 0)) for i in range(25)]
    for p, q in zip(pts, pts[1:]):
        b.limb(p, q, 0.12, 0.12, "void", "spin", seg=6)
    for i in range(4):
        a = i * math.pi / 2
        b.box(CORE + Vector((math.cos(a) * 1.35, math.sin(a) * 1.35, 0)), (0.36, 0.36, 0.36), "gunmetal", "spin",
              rot=Quaternion((0, 0, 1), a))
    b.ball(tuple(CORE), 0.72, "void", "gem", seg=12, rings=8)
    for i in range(3):
        a = i * 2 * math.pi / 3
        b.limb(CORE + Vector((math.cos(a) * 0.78, math.sin(a) * 0.78, -0.8)), CORE + Vector((math.cos(a) * 0.78, math.sin(a) * 0.78, 0.8)),
               0.05, 0.05, "steel", "gem", seg=4)
    for dx, dz in ((-0.4, 0.3), (0.3, 0.5), (0.0, 0.8), (0.5, 0.1)):
        b.ball((dx, 3.7, 1.3 + dz), 0.1, "lamp_amber", "sparks", seg=4, rings=2)
    b.finish(arm)
    return arm


def idle(arm, t):
    s = 1 + 0.08 * math.sin(2 * math.pi * t)
    return {"spin": (lib.world_rot(arm, "spin", (0, 0, 1), math.pi / 2 * t), None),
            "gem": (None, None, (s, s, s)), "sparks": (None, None, (0.01, 0.01, 0.01))}


def attack(arm, t):
    p = {"spin": (lib.world_rot(arm, "spin", (0, 0, 1), 2 * math.pi * t * t), None)}
    f = lib.pulse(t, 0.2, 1.0)
    p["gem"] = (None, None, ((1 + 0.45 * f),) * 3)
    p["press"] = (None, lib.world_loc(arm, "press", (0, 0, -0.35 * lib.pulse(t, 0.1, 0.4))))
    u = max(0.0, (t - 0.25) / 0.75)
    p["sparks"] = (None, lib.world_loc(arm, "sparks", (0, 1.2 * u, 1.0 * u - 1.4 * u * u)),
                   ((1.0 + u),) * 3 if 0.25 < t < 0.95 else (0.01,) * 3)
    return p


if __name__ == "__main__":
    sk.run(build, idle, attack, attack_frames=24, top="spin", wilt={"booms": (1, 0, 0)}, pop=("gem",), drop={"spin": 4.0}, fall=0.4)
