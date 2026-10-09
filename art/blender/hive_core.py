"""Hive core: fleshy base, four bone ribs cupping a beating glow heart. Static (walk = idle).
Real metres, scale 1. Game id: hive_core.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402

RIBS = 4


def rib(i):
    a = i * 2 * math.pi / RIBS + math.pi / 4
    return (math.cos(a) * 0.7, math.sin(a) * 0.7, 0.3), (math.cos(a) * 0.2, math.sin(a) * 0.2, 1.5)


def build():
    bones = [("root", (0, 0, 0), (0, 0, 0.1), None),
             ("base", (0, 0, 0), (0, 0, 0.35), "root"),
             ("heart", (0, 0, 0.75), (0, 0, 1.15), "base")]
    bones += [("rib%d" % i, *rib(i), "base") for i in range(RIBS)]
    arm = lib.armature("hive_core", bones)
    b = lib.Builder("hive_core")
    b.lathe([(0.85, 0.0), (0.8, 0.12), (0.62, 0.3), (0.4, 0.38), (0.0, 0.4)], "core_flesh", "base", seg=12)
    for k in range(6):  # veins up the mound
        a = k * math.pi / 3
        b.limb((math.cos(a) * 0.82, math.sin(a) * 0.82, 0.03), (math.cos(a) * 0.35, math.sin(a) * 0.35, 0.38), 0.05, 0.03, "sick", "base", seg=4)
    for i in range(RIBS):
        lo, hi = rib(i)
        mid = tuple((a + c) * 0.5 + (d * 0.25) for a, c, d in zip(lo, hi, (lo[0], lo[1], 0)))
        b.limb(lo, mid, 0.09, 0.07, "bone", "rib%d" % i, seg=6)
        b.limb(mid, hi, 0.07, 0.0, "bone", "rib%d" % i, seg=6)
    b.ball((0, 0, 1.15), 0.42, "core_glow", "heart", seg=12, rings=9)
    b.ball((0, 0, 1.15), 0.3, "core_flesh", "heart", scale=(1.5, 0.35, 1.45), seg=8, rings=6)  # dark cleft
    b.finish(arm)
    return arm


def beat(t, strong=1.0):
    """Double heartbeat (lub-dub) over one loop."""
    return strong * (lib.pulse(t, 0.0, 0.18) + 0.6 * lib.pulse(t, 0.22, 0.4))


def pose(arm, t, strong=1.0, flex=1.0):
    h = beat(t, strong)
    p = {"heart": (None, None, (1 + 0.14 * h,) * 3)}
    for i in range(RIBS):
        lo, _hi = rib(i)
        axis = (-lo[1], lo[0], 0)  # tangent: rotating about it opens the rib outward
        p["rib%d" % i] = (lib.world_rot(arm, "rib%d" % i, axis, 0.06 * h * flex), None)
    return p


def clips(arm):
    lib.action(arm, "idle", 30, lambda t: pose(arm, t), step=1, loop=True)
    lib.action(arm, "walk", 30, lambda t: pose(arm, t), step=1, loop=True)
    lib.action(arm, "attack", 20, lambda t: pose(arm, t, 2.0, 2.0), step=1)

    def hit(t):
        j = lib.pulse(t, 0.0, 1.0) * (1.0 - t)
        p = pose(arm, 0.5)
        p["heart"] = (None, lib.world_loc(arm, "heart", (0.05 * j, 0, 0)), (1 - 0.12 * j,) * 3)
        p["base"] = (None, None, (1 + 0.04 * j, 1 + 0.04 * j, 1 - 0.06 * j))
        return p
    lib.action(arm, "hit", 10, hit, step=1)

    def die(t):  # last spasm, the heart bursts and dims, the ribs splay and the mound sinks
        k = lib.ease(min(1.0, t / 0.6))
        p = pose(arm, (t * 3) % 1.0, 2.0 * (1 - k), 3.0)
        p["heart"] = (None, lib.world_loc(arm, "heart", (0, 0, -0.5 * k)), (max(0.01, 1 + 0.4 * lib.pulse(t, 0.0, 0.3) - k),) * 3)
        for i in range(RIBS):
            lo, _hi = rib(i)
            p["rib%d" % i] = (lib.world_rot(arm, "rib%d" % i, (-lo[1], lo[0], 0), 0.9 * k), None)
        p["base"] = (None, lib.world_loc(arm, "base", (0, 0, -0.3 * lib.ease(max(0.0, (t - 0.5) / 0.5)))))
        return p
    lib.action(arm, "die", 40, die, step=1)


if __name__ == "__main__":
    out = sys.argv[sys.argv.index("--") + 1]
    lib.reset()
    a = build()
    clips(a)
    lib.export(out)
