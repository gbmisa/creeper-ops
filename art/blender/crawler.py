"""War wagon (unit id crawler): oak hull plated in bronze, four wheels, rune sprayer turret.
Real metres: the game uses it at scale 1. The walk loop turns the wheels exactly once (1 m/s).
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
from mathutils import Quaternion  # noqa: E402

WHEEL_R = 0.38
WHEELS = [("w%d" % i, x, s) for i, (x, s) in enumerate(((0.62, 1), (-0.62, 1), (0.62, -1), (-0.62, -1)))]


def build():
    bones = [("root", (0, 0, 0), (0, 0, 0.1), None),
             ("hull", (0, 0, 0.75), (0.5, 0, 0.75), "root"),
             ("turret", (0, 0, 1.07), (0, 0, 1.3), "hull"),
             ("barrel", (0.1, 0, 1.26), (1.0, 0, 1.32), "turret")]
    bones += [(n, (x, s * 0.72, WHEEL_R), (x, s * 0.92, WHEEL_R), "root") for n, x, s in WHEELS]
    arm = lib.armature("crawler", bones)
    b = lib.Builder("crawler")
    b.box((0, 0, 0.75), (2.0, 1.2, 0.65), "oak", "hull")
    b.box((1.05, 0, 0.85), (0.6, 1.24, 0.12), "bronze", "hull", rot=Quaternion((0, 1, 0), 0.7))
    for s in (1, -1):
        b.box((0, s * 0.62, 0.82), (2.0, 0.06, 0.42), "bronze_dark", "hull")
        for x in (-0.7, 0.0, 0.7):  # rivets
            b.ball((x, s * 0.66, 0.92), 0.04, "bronze", "hull", seg=5, rings=3, smooth=False)
    b.box((-0.6, 0, 1.1), (0.5, 0.5, 0.06), "cloth", "hull")
    b.limb((-0.85, 0.45, 1.05), (-0.85, 0.45, 2.0), 0.03, 0.03, "oak", "hull", seg=4)  # banner pole
    b.box((-0.62, 0.45, 1.8), (0.42, 0.03, 0.34), "cloth", "hull")
    b.box((-0.62, 0.43, 1.8), (0.12, 0.02, 0.12), "unit_glow", "hull")
    b.limb((0, 0, 0.91), (0, 0, 1.23), 0.4, 0.32, "bronze", "turret", seg=10)
    b.limb((0.1, 0, 1.26), (1.0, 0, 1.32), 0.07, 0.07, "iron", "barrel", seg=8)
    b.limb((1.0, 0, 1.32), (1.2, 0, 1.33), 0.1, 0.0, "unit_glow", "barrel", seg=6)
    for n, x, s in WHEELS:
        b.limb((x, s * 0.65, WHEEL_R), (x, s * 0.79, WHEEL_R), WHEEL_R, WHEEL_R, "oak", n, seg=10)
        b.limb((x, s * 0.78, WHEEL_R), (x, s * 0.84, WHEEL_R), 0.1, 0.06, "bronze", n, seg=6)
        for k in range(3):  # spokes, so the turning shows
            a = k * math.pi / 3
            off = (math.cos(a) * WHEEL_R * 0.9, 0, math.sin(a) * WHEEL_R * 0.9)
            b.limb((x - off[0], s * 0.8, WHEEL_R - off[2]), (x + off[0], s * 0.8, WHEEL_R + off[2]), 0.03, 0.03, "bronze_dark", n, seg=4)
    b.finish(arm)
    return arm


def R(arm, bone, axis, ang):
    return lib.world_rot(arm, bone, axis, ang)


def wheels(arm, ang):
    return {n: (R(arm, n, (0, 1, 0), ang), None) for n, _x, _s in WHEELS}


def clips(arm):
    frames = round(2 * math.pi * WHEEL_R * lib.FPS)  # one turn = one loop at 1 m/s

    def walk(t):
        p = wheels(arm, 2 * math.pi * t)
        p["hull"] = (R(arm, "hull", (1, 0, 0), 0.02 * math.sin(6 * math.pi * t)), lib.world_loc(arm, "hull", (0, 0, 0.015 * math.sin(8 * math.pi * t))))
        return p
    lib.action(arm, "walk", frames, walk, step=1, loop=True)

    def idle(t):
        p = wheels(arm, 0.0)
        p["turret"] = (R(arm, "turret", (0, 0, 1), 0.3 * math.sin(2 * math.pi * t)), None)
        return p
    lib.action(arm, "idle", 72, idle, step=3, loop=True)

    def attack(t):
        kick = lib.pulse(t, 0.0, 0.5)
        p = wheels(arm, 0.0)
        p["barrel"] = (None, lib.world_loc(arm, "barrel", (-0.35 * kick, 0, 0)))
        p["turret"] = (R(arm, "turret", (0, 1, 0), -0.08 * kick), None)
        p["hull"] = (R(arm, "hull", (0, 1, 0), -0.12 * kick), lib.world_loc(arm, "hull", (-0.06 * kick, 0, 0)))
        return p
    lib.action(arm, "attack", 12, attack, step=1)

    def hit(t):
        j = lib.pulse(t, 0.0, 1.0) * (1.0 - t)
        p = wheels(arm, 0.0)
        p["hull"] = (R(arm, "hull", (1, 0, 0), 0.25 * j) @ R(arm, "hull", (0, 1, 0), -0.1 * j), lib.world_loc(arm, "hull", (-0.08 * j, 0, 0.12 * j)))
        return p
    lib.action(arm, "hit", 8, hit, step=1)

    def die(t):  # a wheel gives way, the hull slumps onto its side and the turret is thrown off
        k = lib.ease(min(1.0, t / 0.5))
        p = wheels(arm, 0.0)
        p["w2"] = (R(arm, "w2", (1, 0, 0), 1.57 * k), lib.world_loc(arm, "w2", (0.1 * k, -0.55 * k, -0.3 * k)))
        p["hull"] = (R(arm, "hull", (1, 0, 0), -0.45 * k) @ R(arm, "hull", (0, 1, 0), 0.15 * k), lib.world_loc(arm, "hull", (0, 0, -0.25 * k)))
        pop = lib.ease(min(1.0, t / 0.7))
        p["turret"] = (R(arm, "turret", (1, 0, 0), 1.2 * pop), lib.world_loc(arm, "turret", (-0.3 * pop, 0.9 * pop, 0.6 * math.sin(math.pi * pop) - 0.85 * pop)))
        return p
    lib.action(arm, "die", 30, die, step=1)


if __name__ == "__main__":
    out = sys.argv[sys.argv.index("--") + 1]
    lib.reset()
    a = build()
    clips(a)
    lib.export(out)
