"""Collector, military: a field energy mast on a tripod of concrete pads and olive struts, battery
packs with green status lamps, a hazard band and a green charge ring at its foot, three turning
solar panels on steel booms round a caged green energy cell. Same silhouette as
SupportMeshes.collector (Spin at 1.85). Clips: idle = panels turn, cell bobs; attack = a harvest
pulse (a green ring runs down the mast, the cell flares); hit = shake; die = cell bursts, panels
fall, mast sinks. Real metres, about 2.7 m tall.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
import struct_kit as sk  # noqa: E402
import mil_kit as mk  # noqa: E402
from mathutils import Quaternion  # noqa: E402

FEET = sk.ring(3, 0.62, 0.0, math.pi / 6)


def build():
    arm = lib.armature("collector", [("root", (0, 0, 0), (0, 0, 0.1), None),
                                     ("base", (0, 0, 0), (0, 0, 0.5), "root"),
                                     ("spin", (0, 0, 1.85), (0, 0, 2.2), "base"),
                                     ("gem", (0, 0, 2.3), (0, 0, 2.7), "spin"),
                                     ("wave", (0, 0, 1.7), (0, 0, 1.9), "base")])
    b = lib.Builder("collector")
    for x, y, _z, a in FEET:
        b.box((x, y, 0.1), (0.5, 0.4, 0.2), "concrete", "base", rot=Quaternion((0, 0, 1), a))
        b.limb((x * 0.9, y * 0.9, 0.2), (x * 0.35, y * 0.35, 0.95), 0.07, 0.06, "olive_dark", "base", seg=4)
        b.ball((x * 0.9, y * 0.9, 0.22), 0.06, "steel", "base", seg=4, rings=2)
    b.lathe([(0.44, 0.0), (0.44, 0.2), (0.3, 0.32), (0.22, 1.72), (0.3, 1.78), (0.3, 1.86), (0.0, 1.86)],
            "olive", "base", seg=6, smooth=False)
    b.lathe([(0.42, 0.04), (0.48, 0.06), (0.48, 0.14), (0.42, 0.16), (0.42, 0.04)], "glow_green", "base", seg=12, cap=False)
    for i in range(6):
        a = 2 * math.pi * i / 6 + math.pi / 6
        b.box((math.cos(a) * 0.33, math.sin(a) * 0.33, 0.26), (0.03, 0.34, 0.08), "hazard" if i % 2 else "rubber",
              "base", rot=Quaternion((0, 0, 1), a))
    for i in range(3):
        a = math.pi / 6 + i * 2 * math.pi / 3
        c, s = math.cos(a), math.sin(a)
        b.box((c * 0.33, s * 0.33, 0.8), (0.16, 0.3, 0.5), "olive_dark", "base", rot=Quaternion((0, 0, 1), a))
        b.box((c * 0.42, s * 0.42, 0.92), (0.02, 0.16, 0.05), "glow_green", "base", rot=Quaternion((0, 0, 1), a))
        b.box((c * 0.42, s * 0.42, 0.72), (0.02, 0.2, 0.1), "khaki", "base", rot=Quaternion((0, 0, 1), a))
    b.lathe([(0.25, 1.25), (0.27, 1.35), (0.0, 1.35)], "gunmetal", "base", seg=6, smooth=False)
    mk.antenna(b, (0.2, 0.0, 1.86), 0.5, "base")
    b.lathe([(0.24, 1.85), (0.28, 1.9), (0.14, 2.0), (0.0, 2.0)], "gunmetal", "spin", seg=8, smooth=False)
    for x, y, _z, a in sk.ring(3, 0.15, 1.9, 0.0):
        c, s = math.cos(a), math.sin(a)
        b.limb((x, y, 1.94), (c * 0.62, s * 0.62, 2.2), 0.045, 0.04, "steel", "spin", seg=5)
        q = Quaternion((0, 0, 1), a) @ Quaternion((0, 1, 0), -0.5)
        b.box((c * 0.72, s * 0.72, 2.28), (0.06, 0.52, 0.62), "steel", "spin", rot=q)
        b.box((c * 0.74, s * 0.74, 2.29), (0.04, 0.46, 0.56), "solar", "spin", rot=q)
    b.ball((0, 0, 2.45), 0.16, "glow_green", "gem", scale=(1, 1, 1.9), seg=8, rings=4)
    for z in (2.22, 2.68):
        b.lathe([(0.0, z - 0.03), (0.2, z - 0.03), (0.2, z + 0.03), (0.0, z + 0.03)], "gunmetal", "gem", seg=8, smooth=False)
    for i in range(4):
        a = i * math.pi / 2
        b.limb((math.cos(a) * 0.19, math.sin(a) * 0.19, 2.22), (math.cos(a) * 0.19, math.sin(a) * 0.19, 2.68),
               0.02, 0.02, "steel", "gem", seg=4)
    b.lathe([(0.3, 1.64), (0.46, 1.76), (0.3, 1.88), (0.24, 1.76), (0.3, 1.64)], "rune_green", "wave", seg=12, cap=False)
    b.finish(arm)
    return arm


def spin(arm, ang):
    return {"spin": (lib.world_rot(arm, "spin", (0, 0, 1), ang), None)}


def idle(arm, t):
    p = spin(arm, 2 * math.pi / 3 * t)  # 3 vanes: a third of a turn loops seamlessly
    p["gem"] = (lib.world_rot(arm, "gem", (0, 0, 1), -2 * math.pi / 3 * t),
                lib.world_loc(arm, "gem", (0, 0, 0.12 * math.sin(2 * math.pi * t))))
    p["wave"] = (None, None, (0.01, 0.01, 0.01))
    return p


def attack(arm, t):
    p = idle(arm, 0.3 * t)
    f = lib.pulse(t, 0.0, 1.0)
    u = lib.ease(t)
    p["gem"] = (p["gem"][0], lib.world_loc(arm, "gem", (0, 0, 0.25 * f)), (1 + 0.6 * f,) * 3)
    r = 1.05 + 0.4 * u
    p["wave"] = (None, lib.world_loc(arm, "wave", (0, 0, -1.55 * u)), (r, 1, r) if t < 0.95 else (0.01,) * 3)
    return p


if __name__ == "__main__":
    sk.run(build, idle, attack, attack_frames=16, top="spin", pop=("gem",), drop={"spin": 1.7}, fall=0.5)
