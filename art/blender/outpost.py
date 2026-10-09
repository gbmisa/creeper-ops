"""Outpost, military: an octagonal concrete command bunker ringed with sandbags, a steel door and
vision slits, a sandbagged roof, and a steel lattice mast with a turning radar array and a red
beacon. Same footprint and height as SupportMeshes.outpost (r 2.0, about 5.8 m with the whip).
Clips: idle = the radar sweeps, the beacon blinks; attack = a packet launches (radar snaps
round, beacon flares, a signal ring rises off the roof); hit = shake; die = radar and mast
fall, the bunker sinks.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
import struct_kit as sk  # noqa: E402
from mathutils import Quaternion  # noqa: E402


def build():
    arm = lib.armature("outpost", [("root", (0, 0, 0), (0, 0, 0.1), None),
                                   ("base", (0, 0, 0), (0, 0, 0.5), "root"),
                                   ("spin", (0, 0, 4.7), (0, 0, 5.0), "base"),
                                   ("lamp", (0, 0, 5.95), (0, 0, 6.2), "base"),
                                   ("pulse", (0, 0, 3.1), (0, 0, 3.3), "base")])
    b = lib.Builder("outpost")
    b.lathe([(2.1, 0.0), (2.1, 0.35), (1.75, 0.5), (1.6, 2.5), (1.8, 2.65), (1.8, 2.9), (0.0, 2.9)],
            "concrete_dark", "base", seg=8, smooth=False)
    b.lathe([(1.74, 0.55), (1.75, 0.8), (0.0, 0.8)], "hazard", "base", seg=8, smooth=False)
    b.lathe([(1.82, 2.62), (1.84, 2.92), (0.0, 2.92)], "olive", "base", seg=8, smooth=False)
    for i in range(8):
        a = math.pi / 8 + i * math.pi / 4
        ap = 1.66 * math.cos(math.pi / 8)
        if i == 0:
            b.box((ap + 0.1, 0, 0.75), (0.34, 1.4, 1.5), "hazard", "base")
            b.box((ap + 0.2, 0, 0.75), (0.2, 1.1, 1.35), "olive", "base", rot=Quaternion((0, 0, 1), a - math.pi / 8))
        b.box((math.cos(a - math.pi / 8) * (ap - 0.02), math.sin(a - math.pi / 8) * (ap - 0.02), 2.0),
              (0.1, 0.8, 0.2), "rubber", "base", rot=Quaternion((0, 0, 1), a - math.pi / 8))
    for z, ph in ((0.22, 0.2), (0.55, 0.45)):  # two courses of sandbags
        for x, y, _z, a in sk.ring(12, 2.35, 0.0, ph):
            b.ball((x, y, z), 0.42, "khaki", "base", scale=(0.6, 1.5, 0.5), seg=8, rings=4, rot=Quaternion((0, 0, 1), a))
    for x, y, _z, a in sk.ring(10, 1.6, 0.0, 0.0):  # sandbagged roof parapet
        b.ball((x, y, 3.05), 0.3, "khaki", "base", scale=(0.6, 1.6, 0.6), seg=6, rings=3, rot=Quaternion((0, 0, 1), a))
    for x, y, _z, a in sk.ring(3, 0.55, 0.0, math.pi / 6):  # lattice mast
        b.limb((x, y, 2.9), (x * 0.25, y * 0.25, 5.8), 0.08, 0.05, "steel", "base", seg=4)
    for z, r in ((3.6, 0.45), (5.2, 0.24)):
        b.lathe([(r, z), (r, z + 0.06), (0.0, z + 0.06)], "gunmetal", "base", seg=3, smooth=False)
    b.limb((0, 0, 5.8), (0, 0, 5.95), 0.05, 0.05, "gunmetal", "base", seg=6)
    b.ball((0, 0, 6.05), 0.2, "lamp_red", "lamp", seg=6, rings=3)
    b.box((-1.0, 0.8, 3.12), (0.7, 0.5, 0.45), "olive", "base")  # radio crate
    b.limb((-1.0, 0.8, 3.35), (-1.0, 0.8, 4.8), 0.02, 0.008, "rubber", "base", seg=4)
    # radar: collar, boom and a slatted array facing +X
    b.lathe([(0.3, 4.7), (0.3, 4.84), (0.0, 4.84)], "olive_dark", "spin", seg=8, smooth=False)
    b.box((0.5, 0, 4.85), (1.0, 0.14, 0.12), "gunmetal", "spin")
    b.box((1.05, 0, 5.0), (0.14, 2.6, 0.95), "olive", "spin")
    for z in (4.6, 5.0, 5.4):
        b.box((1.13, 0, z), (0.05, 2.64, 0.07), "brake", "spin")
    for y in (-1.3, 1.3):
        b.box((1.13, y, 5.0), (0.06, 0.07, 0.98), "brake", "spin")
    b.box((-0.45, 0, 4.88), (0.45, 0.45, 0.3), "olive_dark", "spin")
    b.lathe([(1.2, 3.1), (1.5, 3.18), (1.2, 3.26), (1.1, 3.18), (1.2, 3.1)], "lamp_amber", "pulse", seg=16, cap=False)
    b.finish(arm)
    return arm


def idle(arm, t):
    p = {"spin": (lib.world_rot(arm, "spin", (0, 0, 1), 2 * math.pi * t), None)}  # 1-fold: a full sweep loops
    p["lamp"] = (None, None, (1.3,) * 3 if (t * 2) % 1.0 < 0.5 else (0.5,) * 3)
    p["pulse"] = (None, None, (0.01, 0.01, 0.01))
    return p


def attack(arm, t):
    p = idle(arm, 0.0)
    snap = lib.ease(min(1.0, t / 0.4))
    p["spin"] = (lib.world_rot(arm, "spin", (0, 0, 1), math.pi * snap), None)
    f = lib.pulse(t, 0.0, 0.6)
    p["lamp"] = (None, None, (1 + 1.2 * f,) * 3)
    u = lib.ease(t)
    r = 1.0 + 1.6 * u
    p["pulse"] = (None, lib.world_loc(arm, "pulse", (0, 0, 2.0 * u)), (r, r, 1) if t < 0.95 else (0.01,) * 3)
    return p


if __name__ == "__main__":
    sk.run(build, idle, attack, attack_frames=14, top="spin", pop=("lamp",), drop={"spin": 3.6}, fall=0.6)
