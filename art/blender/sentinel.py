"""Sentinel: 2.4 m robed archer with a bone spine-bow held out on its left (+Y); draws and looses.
Fixed size: the game uses this model at scale 1 whatever the tier's hit size.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402

HAND = (0.95, 0.22, 1.72)  # bow held out in front, toward the target (+X)
NOCK = (0.72, 0.2, 1.72)
TOP, BOT = (0.78, 0.22, 2.9), (0.78, 0.22, 0.55)
CHIN = (0.22, 0.1, 2.0)


def add(a, b):
    return tuple(x + y for x, y in zip(a, b))


def build():
    arm = lib.armature("sentinel", [("root", (0, 0, 0), (0, 0, 0.1), None),
                                    ("body", (0, 0, 0.0), (0, 0, 1.3), "root"),
                                    ("chest", (0, 0, 1.3), (0, 0, 1.9), "body"),
                                    ("head", (0, 0, 1.9), (0, 0, 2.6), "chest"),
                                    ("bow_arm", (0, 0.28, 1.78), HAND, "chest"),
                                    ("bow", HAND, add(HAND, (0, 0, 0.5)), "bow_arm"),
                                    ("draw_arm", (0, -0.28, 1.78), NOCK, "chest"),
                                    ("bolt", NOCK, add(NOCK, (0.5, 0, 0)), "draw_arm")])
    b = lib.Builder("sentinel")
    b.lathe([(0.58, 0.0), (0.5, 0.25), (0.42, 0.5), (0.34, 0.9), (0.28, 1.3)], "robe", "body", seg=9)
    b.limb((0, 0, 0.0), (0, 0, 0.12), 0.6, 0.56, "sick", "body", seg=9)  # glowing hem
    for k in range(5):  # ragged robe strips
        a = 2 * math.pi * (k + 0.5) / 5
        b.limb((0.5 * math.cos(a), 0.5 * math.sin(a), 0.3), (0.62 * math.cos(a), 0.62 * math.sin(a), 0.02), 0.07, 0.0, "robe", "body", seg=3)
    b.lathe([(0.28, 1.3), (0.4, 1.72), (0.44, 1.84), (0.18, 2.0), (0.0, 2.02)], "robe", "chest", seg=9)
    b.limb((-0.3, 0, 1.7), (-0.45, 0, 2.5), 0.1, 0.07, "bone", "chest")  # spine crest
    b.limb((-0.45, 0, 2.5), (-0.35, 0, 3.3), 0.07, 0.0, "bone", "chest")
    b.ball((-0.22, -0.12, 1.6), 0.11, "sick", "chest", seg=6, rings=5)
    for s in (1, -1):
        b.limb((0, s * 0.26, 1.82), (-0.05, s * 0.4, 2.25), 0.07, 0.05, "bone", "chest")
        b.limb((-0.05, s * 0.4, 2.25), (-0.15, s * 0.36, 2.65), 0.05, 0.0, "bone", "chest")
    for s in (1, -1):  # chitin pauldrons
        b.ball((0.0, s * 0.32, 1.84), 0.17, "chitin", "chest", scale=(1.2, 0.9, 0.55), seg=7, rings=5, smooth=False)
    b.lathe([(0.16, 1.95), (0.19, 2.25), (0.1, 2.5), (0.0, 2.72)], "chitin", "head", seg=7)
    b.box((0.17, 0, 2.3), (0.05, 0.22, 0.05), "eye", "head")
    b.limb((0, 0.28, 1.78), (0.45, 0.34, 1.66), 0.1, 0.08, "robe", "bow_arm", seg=6, smooth=True)
    b.limb((0.45, 0.34, 1.66), HAND, 0.08, 0.07, "robe", "bow_arm", seg=6, smooth=True)
    b.ball((0.45, 0.34, 1.66), 0.09, "chitin", "bow_arm", seg=6, rings=4, smooth=False)  # elbow guard
    b.limb((0, -0.28, 1.78), (0.38, -0.2, 1.62), 0.09, 0.075, "robe", "draw_arm", seg=6, smooth=True)
    b.limb((0.38, -0.2, 1.62), NOCK, 0.075, 0.065, "robe", "draw_arm", seg=6, smooth=True)
    for end, mid in ((TOP, (1.1, 0.22, 2.35)), (BOT, (1.1, 0.22, 1.05))):  # recurved spine-bow limbs
        b.limb(HAND, mid, 0.08, 0.05, "bone", "bow")
        b.limb(mid, end, 0.05, 0.015, "bone", "bow")
    b.ball(HAND, 0.09, "plate", "bow", seg=6, rings=4, smooth=False)
    b.limb(TOP, NOCK, 0.018, 0.018, "sick", "bow", seg=4, bone_b="draw_arm")  # string halves bend at the nock
    b.limb(BOT, NOCK, 0.018, 0.018, "sick", "bow", seg=4, bone_b="draw_arm")
    b.limb(add(NOCK, (-0.1, 0, 0)), add(HAND, (0.62, 0, 0)), 0.035, 0.035, "glow", "bolt", seg=5)
    b.limb(add(HAND, (0.62, 0, 0)), add(HAND, (0.8, 0, 0)), 0.07, 0.0, "glow", "bolt", seg=5)
    b.finish(arm)
    return arm


def R(arm, bone, axis, ang):
    return lib.world_rot(arm, bone, axis, ang)


def base(arm, t, sway=0.0, bob=0.0):
    w = 2 * math.pi * t
    return {"body": (R(arm, "body", (1, 0, 0), sway * math.sin(w)), lib.world_loc(arm, "body", (0, 0, bob * math.cos(2 * w)))),
            "chest": (R(arm, "chest", (0, 0, 1), 0.5 * sway * math.sin(w + 0.6)), None)}


def idle(arm):
    def pose(t):
        p = base(arm, t, sway=0.02, bob=0.01)
        p["head"] = (R(arm, "head", (0, 0, 1), 0.25 * math.sin(2 * math.pi * t) * lib.pulse(t, 0.1, 0.8)), None)
        return p
    lib.action(arm, "idle", 60, pose, step=2, loop=True)


def walk(arm):
    def pose(t):
        p = base(arm, t, sway=0.06, bob=0.035)
        p["body"] = (p["body"][0] @ R(arm, "body", (0, 1, 0), 0.06), p["body"][1])  # lean into the stride
        p["bow_arm"] = (R(arm, "bow_arm", (0, 1, 0), 0.05 * math.sin(2 * math.pi * t)), None)
        return p
    lib.action(arm, "walk", 24, pose, step=2, loop=True)


def attack(arm):
    def pose(t):
        draw = lib.ease(min(1.0, t / 0.55)) * (1.0 if t < 0.6 else 0.0)
        snap = lib.pulse(t, 0.6, 0.8)
        reload = lib.ease(max(0.0, (t - 0.8) / 0.2))
        p = base(arm, 0.0)
        p["chest"] = (R(arm, "chest", (0, 0, 1), 0.25 * draw) @ R(arm, "chest", (0, 1, 0), -0.08 * draw), None)
        p["draw_arm"] = (None, lib.world_loc(arm, "draw_arm", tuple((c - n) * draw for c, n in zip(CHIN, NOCK))))
        p["head"] = (R(arm, "head", (0, 0, 1), 0.2 * draw), None)
        p["bow_arm"] = (R(arm, "bow_arm", (0, 1, 0), -0.08 * snap), None)
        gone = 0.0 if 0.6 <= t < 0.8 + 0.1 else 1.0
        p["bolt"] = (None, None, (max(0.01, gone * (reload if t >= 0.8 else 1.0)),) * 3)
        return p
    lib.action(arm, "attack", 30, pose, step=1)


def hit(arm):
    def pose(t):
        j = lib.pulse(t, 0.0, 1.0) * (1.0 - t)
        p = base(arm, 0.0)
        p["chest"] = (R(arm, "chest", (0, 1, 0), -0.5 * j), None)
        p["head"] = (R(arm, "head", (0, 1, 0), -0.5 * j), None)
        p["body"] = (R(arm, "body", (0, 1, 0), -0.1 * j), lib.world_loc(arm, "body", (-0.2 * j, 0, 0)))
        return p
    lib.action(arm, "hit", 10, pose, step=1)


def die(arm):
    def pose(t):
        stagger = lib.pulse(t, 0.0, 0.35)
        kneel = lib.ease(min(1.0, max(0.0, (t - 0.2) / 0.3)))
        fall = lib.ease(min(1.0, max(0.0, (t - 0.5) / 0.4)))
        p = {"body": (R(arm, "body", (0, 1, 0), -0.25 * stagger) @ R(arm, "body", (1, 0, 0), 1.3 * fall),
                      lib.world_loc(arm, "body", (-0.2 * stagger, 0, -0.45 * kneel - 0.1 * fall))),
             "chest": (R(arm, "chest", (0, 1, 0), 0.6 * kneel), None),
             "head": (R(arm, "head", (0, 1, 0), 0.5 * kneel), None),
             "bow_arm": (R(arm, "bow_arm", (1, 0, 0), -0.8 * fall), None),
             "draw_arm": (R(arm, "draw_arm", (0, 1, 0), 0.6 * kneel), None),
             "bolt": (None, None, (max(0.01, 1.0 - kneel),) * 3)}
        return p
    lib.action(arm, "die", 36, pose, step=1)


if __name__ == "__main__":
    out = sys.argv[sys.argv.index("--") + 1]
    lib.reset()
    a = build()
    for fn in (idle, walk, attack, hit, die):
        fn(a)
    lib.export(out)
