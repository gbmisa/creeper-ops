"""Castle trebuchet: stone plinth, two A-frames, a throwing arm with a hinged counterweight and a sling.
Real metres, scale 1, throws toward +X. Idle = cocked (long end down at the back). Game id: trebuchet.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402

AXLE = (0.0, 0.0, 3.0)
SHORT, LONG = 1.0, -3.4
COCK, THROW = -0.9, 2.1


def build():
    arm = lib.armature("trebuchet", [("root", (0, 0, 0), (0, 0, 0.1), None),
                                     ("frame", (0, 0, 0.0), (0, 0, 1.0), "root"),
                                     ("arm", AXLE, (LONG, 0, 3.0), "frame"),
                                     ("cw", (SHORT, 0, 3.0), (SHORT, 0, 2.2), "arm"),
                                     ("sling", (LONG, 0, 3.0), (LONG, 0, 2.4), "arm"),
                                     ("stone", (LONG, 0, 2.4), (LONG, 0, 2.1), "sling"),
                                     ("beacon", (0, 0, 3.3), (0, 0, 3.7), "frame")])
    b = lib.Builder("trebuchet")
    b.box((0, 0, 0.2), (2.6, 2.6, 0.4), "stone", "frame")
    for s in (1, -1):
        b.box((0, s * 0.9, 0.48), (2.4, 0.18, 0.16), "oak", "frame")  # sole beams
        b.limb((-1.0, s * 0.9, 0.4), (0, s * 0.9, 3.0), 0.12, 0.1, "oak", "frame")
        b.limb((1.0, s * 0.9, 0.4), (0, s * 0.9, 3.0), 0.12, 0.1, "oak", "frame")
        b.limb((-0.55, s * 0.9, 1.6), (0.55, s * 0.9, 1.6), 0.07, 0.07, "oak", "frame")  # cross brace
        b.ball((0, s * 0.9, 3.0), 0.14, "bronze", "frame", seg=6, rings=4, smooth=False)
        b.limb((-1.2, s * 0.55, 0.62), (-1.2, s * 0.85, 0.62), 0.22, 0.22, "oak", "frame", seg=8)  # winch drums
    for x in (-1.0, 1.0):
        b.box((x, 0, 0.48), (0.16, 1.9, 0.14), "oak", "frame")
    b.limb((0, -1.0, 3.0), (0, 1.0, 3.0), 0.1, 0.1, "bronze", "frame", seg=8)  # axle
    b.limb((0, 0, 3.05), (0, 0, 3.32), 0.04, 0.04, "iron", "frame", seg=4)
    b.ball((0, 0, 3.45), 0.22, "glow", "beacon", seg=8, rings=6)
    b.limb((SHORT + 0.15, 0, 3.0), (LONG, 0, 3.0), 0.14, 0.08, "oak", "arm", seg=6)
    b.box((SHORT - 0.1, 0, 3.0), (0.4, 0.3, 0.3), "bronze_dark", "arm")
    for s in (1, -1):
        b.limb((SHORT, s * 0.32, 3.0), (SHORT, s * 0.32, 2.85), 0.035, 0.035, "iron", "cw", seg=4)
    b.box((SHORT, 0, 2.45), (0.9, 0.9, 0.8), "bronze", "cw")
    b.box((SHORT, 0, 2.45), (0.95, 0.95, 0.12), "iron", "cw")
    for s in (1, -1):
        b.limb((LONG, 0, 3.0), (LONG, s * 0.14, 2.42), 0.02, 0.02, "dark", "sling", seg=3)
    b.ball((LONG, 0, 2.4), 0.16, "oak", "sling", scale=(1.2, 1.2, 0.5), seg=6, rings=4, smooth=False)  # pouch
    b.ball((LONG, 0, 2.3), 0.32, "stone", "stone", seg=8, rings=6, smooth=False)
    b.finish(arm)
    return arm


def R(arm, bone, ang):
    return lib.world_rot(arm, bone, (0, 1, 0), ang)


def rig(arm, a, sling_lag=0.0, stone=1.0, beacon=1.0):
    """Arm at angle a; the counterweight hangs plumb and the sling trails by sling_lag."""
    return {"arm": (R(arm, "arm", a), None),
            "cw": (R(arm, "cw", -a), None),
            "sling": (R(arm, "sling", -a + sling_lag), None),
            "stone": (None, None, (max(0.01, stone),) * 3),
            "beacon": (None, None, (beacon,) * 3)}


def clips(arm):
    def idle(t):
        return rig(arm, COCK + 0.01 * math.sin(2 * math.pi * t), 0.05 * math.sin(2 * math.pi * t), 1.0,
                   1 + 0.12 * lib.pulse(t, 0.0, 0.3))
    lib.action(arm, "idle", 48, idle, step=2, loop=True)
    lib.action(arm, "walk", 48, idle, step=2, loop=True)

    def attack(t):  # 3 s: swing over in 0.35 s, release, then winch back down and reload
        swing = t / 0.12
        if swing < 1.0:
            a = COCK + (THROW - COCK) * swing * swing
            lag = 1.6 * swing
            stone = 1.0
        else:
            back = lib.ease(min(1.0, (t - 0.18) / 0.72)) if t > 0.18 else 0.0
            a = THROW + (COCK - THROW) * back
            lag = 1.6 * (1.0 - min(1.0, (t - 0.12) / 0.1)) + 0.3 * math.sin(20 * t) * (1 - back)
            stone = 0.0 if t < 0.85 else (t - 0.85) / 0.15
        return rig(arm, a, lag, stone, 1.4 if t < 0.15 else 1.0)
    lib.action(arm, "attack", 72, attack, step=1)

    def hit(t):
        j = lib.pulse(t, 0.0, 1.0) * (1.0 - t)
        p = rig(arm, COCK + 0.08 * j, 0.3 * j)
        p["frame"] = (lib.world_rot(arm, "frame", (1, 0, 0), 0.03 * math.sin(30 * t) * j), None)
        return p
    lib.action(arm, "hit", 10, hit, step=1)

    def die(t):  # the frame racks over, the arm drops and the beacon goes out
        k = lib.ease(min(1.0, t / 0.7))
        p = rig(arm, COCK + (0.9 - COCK) * lib.ease(min(1.0, t / 0.4)), -0.5 * k, 1.0 - k, max(0.01, 1.0 - k))
        p["frame"] = (lib.world_rot(arm, "frame", (1, 0, 0), 0.45 * k), lib.world_loc(arm, "frame", (0, 0, -0.3 * k)))
        return p
    lib.action(arm, "die", 36, die, step=1)


if __name__ == "__main__":
    out = sys.argv[sys.argv.index("--") + 1]
    lib.reset()
    a = build()
    clips(a)
    lib.export(out)
