"""Barracks, military: a concrete ground floor under a corrugated olive Quonset roof, a steel door
with a sandbag blast wall and a green muster lamp, dark windows, a stencilled unit plate, a radio
mast with a red tip and a turning searchlight on the roof (spin). Same footprint and height as
SupportMeshes.barracks (4.8 m square, about 5 m). Clips: idle = the searchlight sweeps, the
lamp breathes; attack = a unit musters (lamp flares, door slides, searchlight snaps round);
hit = shake; die = mast wilts, roof drops, the hut sinks. Game id: barracks.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
import mil_kit as mk  # noqa: E402
import struct_kit as sk  # noqa: E402
from mathutils import Vector  # noqa: E402

R, ZC, L = 2.05, 2.0, 2.1  # roof radius, axis height, half length (along X)


def build():
    arm = lib.armature("barracks", [("root", (0, 0, 0), (0, 0, 0.1), None),
                                    ("base", (0, 0, 0), (0, 0, 0.5), "root"),
                                    ("roof", (0, 0, ZC), (0, 0, ZC + R), "base"),
                                    ("mast", (-1.2, 0.9, ZC + 1.7), (-1.2, 0.9, 5.2), "roof"),
                                    ("spin", (0.6, 0, ZC + R), (0.6, 0, ZC + R + 0.3), "roof"),
                                    ("door", (L + 0.05, 0, 0.3), (L + 0.05, 0, 1.6), "base"),
                                    ("gem", (L + 0.1, -0.85, 1.75), (L + 0.1, -0.85, 1.95), "base")])
    b = lib.Builder("barracks")
    mk.slab(b, 2.4, 0.3, "base")
    b.box((0, 0, 1.15), (2 * L, 2 * R + 0.1, 1.7), "concrete", "base")
    b.box((0, 0, 1.95), (2 * L + 0.04, 2 * R + 0.14, 0.12), "olive_dark", "base")
    for s in (1, -1):  # windows along the sides
        for x in (-1.3, 0.0, 1.3):
            b.box((x, s * (R + 0.06), 1.25), (0.6, 0.04, 0.4), "solar", "base")
            b.box((x, s * (R + 0.08), 1.03), (0.7, 0.06, 0.06), "gunmetal", "base")
    b.limb(Vector((-L, 0, ZC)), Vector((L, 0, ZC)), R, R, "olive", "roof", seg=18, smooth=True)
    for k in range(9):  # corrugation ribs
        x = -L + 0.1 + k * (2 * L - 0.2) / 8
        b.limb(Vector((x, 0, ZC)), Vector((x + 0.06, 0, ZC)), R + 0.04, R + 0.04, "olive_dark", "roof", seg=18, smooth=True)
    for s in (1, -1):  # half-disc end walls above the ground floor
        x = s * (L + 0.03)
        arc = [Vector((x, math.cos(math.pi * i / 12) * R, ZC + math.sin(math.pi * i / 12) * R)) for i in range(13)]
        for p0, p1 in zip(arc, arc[1:]):
            tri = [Vector((x, 0, ZC)), p0, p1] if s > 0 else [Vector((x, 0, ZC)), p1, p0]
            b.poly(tri, ["roof"] * 3, "olive_dark")
    b.box((L + 0.08, 0, 2.55), (0.04, 0.9, 0.5), "solar", "roof")
    b.box((L + 0.08, 0, 2.12), (0.03, 1.4, 0.16), "hazard", "roof")
    b.box((L + 0.06, 0, 0.95), (0.06, 1.05, 1.3), "gunmetal", "base")  # door frame
    b.box((L + 0.1, 0, 0.95), (0.04, 0.9, 1.2), "olive_dark", "door")
    b.box((L + 0.12, 0, 0.95), (0.02, 0.5, 0.08), "hazard", "door")
    b.box((L + 0.1, 0.85, 1.4), (0.03, 0.5, 0.36), "khaki", "base")  # unit plate
    b.ball((L + 0.1, -0.85, 1.75), 0.12, "unit_glow", "gem", seg=6, rings=3)
    for i in range(3):  # sandbag blast wall in front of the door
        for row in range(2):
            b.ball((L + 0.9, -0.55 + i * 0.55 + row * 0.27, 0.42 + row * 0.17), 0.28, "sandbag", "base",
                   scale=(0.6, 1.0, 0.36), seg=6, rings=3)
    b.limb(Vector((-1.2, 0.9, ZC + 1.5)), Vector((-1.2, 0.9, 5.3)), 0.03, 0.015, "steel", "mast", seg=4)
    b.ball((-1.2, 0.9, 5.32), 0.05, "lamp_red", "mast", seg=4, rings=2)
    top = Vector((0.6, 0, ZC + R))
    b.limb(top, top + Vector((0, 0, 0.35)), 0.08, 0.08, "gunmetal", "spin", seg=6)
    b.box(top + Vector((0.1, 0, 0.5)), (0.36, 0.3, 0.3), "olive_dark", "spin")
    b.limb(top + Vector((0.28, 0, 0.5)), top + Vector((0.34, 0, 0.5)), 0.13, 0.13, "lamp_amber", "spin", seg=10)
    b.finish(arm)
    return arm


def idle(arm, t):
    s = 1 + 0.12 * math.sin(2 * math.pi * t)
    return {"spin": (lib.world_rot(arm, "spin", (0, 0, 1), 2 * math.pi * t), None), "gem": (None, None, (s, s, s))}


def attack(arm, t):
    p = idle(arm, 0.0)
    f = lib.pulse(t, 0.0, 1.0)
    p["gem"] = (None, None, ((1 + 0.9 * f),) * 3)
    p["door"] = (None, lib.world_loc(arm, "door", (0, 0.7 * f, 0)))
    p["spin"] = (lib.world_rot(arm, "spin", (0, 0, 1), math.pi * lib.ease(t)), None)
    return p


if __name__ == "__main__":
    sk.run(build, idle, attack, attack_frames=24, top="roof", wilt={"mast": (1, 0, 0)}, pop=("gem",), drop={"spin": 1.0}, fall=0.7)
