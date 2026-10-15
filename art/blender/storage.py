"""Storage, military: an energy cell bank. An olive cylindrical tank banded in steel on a concrete
pad with a hazard edge, a blue charge gauge window, a valve wheel, a ladder and a domed gunmetal
lid with a vent and a blue status lamp (gem). Same size as SupportMeshes.storage (r 0.85,
about 2.6 m). Clips: idle = the gauge and lamp breathe; attack = a charge pulse (a blue ring runs
up the tank, the lamp flares, the valve turns); hit = shake; die = lamp bursts, tank sinks.
Game id: storage.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
import mil_kit as mk  # noqa: E402
import struct_kit as sk  # noqa: E402
from mathutils import Vector  # noqa: E402


def build():
    arm = lib.armature("storage", [("root", (0, 0, 0), (0, 0, 0.1), None),
                                   ("base", (0, 0, 0), (0, 0, 0.5), "root"),
                                   ("gauge", (0.83, 0, 0.5), (0.83, 0, 1.4), "base"),
                                   ("valve", (0.0, -0.9, 1.25), (0.0, -1.1, 1.25), "base"),
                                   ("gem", (0, 0, 2.25), (0, 0, 2.6), "base"),
                                   ("ring", (0, 0, 0.3), (0, 0, 0.5), "base")])
    b = lib.Builder("storage")
    mk.slab(b, 0.95, 0.16, "base", mat="concrete")
    mk.hazard_band(b, 0.95, 0.09, 0.08, "base", n=8)
    b.lathe([(0.82, 0.16), (0.82, 1.75), (0.7, 1.95), (0.42, 2.08), (0.0, 2.1)], "olive", "base", seg=16, smooth=False)
    for z in (0.35, 1.0, 1.65):
        b.lathe([(0.84, z), (0.85, z + 0.06), (0.84, z + 0.12), (0.0, z + 0.12)], "steel", "base", seg=16, smooth=False)
    b.box((0.83, 0, 0.95), (0.04, 0.3, 0.9), "gunmetal", "base")
    b.box((0.83, 0, 0.95), (0.06, 0.18, 0.8), "arc_blue", "gauge")
    b.box((0.0, -0.84, 0.6), (0.36, 0.06, 0.25), "khaki", "base")  # stencil plate
    b.limb(Vector((0.0, -0.82, 1.25)), Vector((0.0, -0.92, 1.25)), 0.06, 0.06, "gunmetal", "base", seg=6)
    for i in range(4):  # valve wheel spokes + rim (rim built from short segments, in the XZ plane)
        a = i * math.pi / 2
        c = Vector((0.0, -0.95, 1.25))
        b.limb(c, c + Vector((math.cos(a) * 0.16, 0, math.sin(a) * 0.16)), 0.015, 0.015, "steel", "valve", seg=4)
    pts = [Vector((math.cos(2 * math.pi * i / 12) * 0.17, -0.95, 1.25 + math.sin(2 * math.pi * i / 12) * 0.17)) for i in range(13)]
    for p, q in zip(pts, pts[1:]):
        b.limb(p, q, 0.025, 0.025, "hazard", "valve", seg=4)
    mk.ladder(b, -0.8, 0, 0.16, 1.85, "base", face=(-1, 0), w=0.26)
    b.limb(Vector((0.3, 0.2, 2.0)), Vector((0.3, 0.2, 2.3)), 0.06, 0.06, "gunmetal", "base", seg=6)
    b.limb(Vector((0.3, 0.2, 2.3)), Vector((0.42, 0.2, 2.3)), 0.06, 0.06, "gunmetal", "base", seg=6)
    b.lathe([(0.0, 2.08), (0.16, 2.08), (0.16, 2.2), (0.0, 2.2)], "gunmetal", "base", seg=8, smooth=False)
    b.ball((0, 0, 2.32), 0.12, "arc_blue", "gem", seg=8, rings=4)
    b.lathe([(0.84, 0.0), (0.92, 0.04), (0.84, 0.08), (0.8, 0.04), (0.84, 0.0)], "arc_blue", "ring", at=(0, 0, 0.3), seg=16, cap=False)
    b.finish(arm)
    return arm


def idle(arm, t):
    s = 1 + 0.08 * math.sin(2 * math.pi * t)
    return {"gem": (None, None, (s, s, s)), "gauge": (None, None, (1, s, 1)), "ring": (None, None, (0.01, 0.01, 0.01))}


def attack(arm, t):
    p = idle(arm, 0.0)
    f = lib.pulse(t, 0.4, 1.0)
    p["gem"] = (None, None, ((1 + 0.7 * f),) * 3)
    u = lib.ease(t)
    p["ring"] = (None, lib.world_loc(arm, "ring", (0, 0, 1.6 * u)), (1.0, 1.0, 1.0) if t < 0.92 else (0.01,) * 3)
    p["valve"] = (lib.world_rot(arm, "valve", (0, 1, 0), math.pi / 2 * u), None)
    return p


if __name__ == "__main__":
    sk.run(build, idle, attack, attack_frames=16, pop=("gem",))
