"""Crawler (unit id crawler), military: a 4x4 armoured car. A sloped olive hull with a hazard-striped
glacis, side armour skirts, stowage boxes, a radio whip with a green unit strobe, chunky rubber
wheels with steel hubs, and a gunmetal sprayer turret whose nozzle glows green (the unit cue).
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
    b.box((0, 0, 0.72), (1.9, 1.16, 0.5), "olive", "hull")
    b.box((0.05, 0, 1.02), (1.5, 1.0, 0.14), "olive", "hull")
    b.box((1.02, 0, 0.82), (0.55, 1.14, 0.12), "olive_dark", "hull", rot=Quaternion((0, 1, 0), 0.75))  # glacis
    b.box((0.97, 0, 0.66), (0.06, 1.17, 0.1), "hazard", "hull")  # bumper band
    b.box((-0.98, 0, 0.75), (0.08, 1.1, 0.46), "olive_dark", "hull")  # rear plate
    for s in (1, -1):
        b.box((0, s * 0.6, 0.68), (1.95, 0.06, 0.3), "olive_dark", "hull")  # side skirts
        b.box((-0.45, s * 0.52, 1.14), (0.5, 0.14, 0.12), "khaki", "hull")  # stowage
        b.box((0.95, s * 0.45, 0.95), (0.08, 0.14, 0.1), "lamp_amber", "hull")  # headlights
    b.limb((-0.8, 0.42, 1.08), (-0.8, 0.42, 2.0), 0.015, 0.01, "rubber", "hull", seg=4)  # radio whip
    b.box((-0.8, 0.42, 1.12), (0.12, 0.12, 0.06), "gunmetal", "hull")
    b.ball((-0.8, 0.42, 2.02), 0.05, "unit_glow", "hull", seg=5, rings=3)
    b.limb((0, 0, 0.98), (0, 0, 1.23), 0.38, 0.32, "gunmetal", "turret", seg=8)
    b.box((0.18, 0, 1.2), (0.34, 0.44, 0.16), "olive_dark", "turret")
    b.limb((0.1, 0, 1.26), (1.0, 0, 1.32), 0.07, 0.07, "steel", "barrel", seg=8)
    b.limb((0.6, 0, 1.3), (0.66, 0, 1.3), 0.095, 0.095, "rubber", "barrel", seg=8)
    b.limb((1.0, 0, 1.32), (1.2, 0, 1.33), 0.1, 0.0, "unit_glow", "barrel", seg=6)
    for n, x, s in WHEELS:
        b.limb((x, s * 0.65, WHEEL_R), (x, s * 0.82, WHEEL_R), WHEEL_R, WHEEL_R, "rubber", n, seg=12)
        b.limb((x, s * 0.81, WHEEL_R), (x, s * 0.85, WHEEL_R), 0.2, 0.16, "steel", n, seg=6)
        for k in range(3):  # tread blocks, so the turning shows
            a = k * math.pi / 3
            off = (math.cos(a) * WHEEL_R * 0.98, 0, math.sin(a) * WHEEL_R * 0.98)
            b.limb((x - off[0], s * 0.83, WHEEL_R - off[2]), (x + off[0], s * 0.83, WHEEL_R + off[2]), 0.035, 0.035, "olive_dark", n, seg=4)
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
