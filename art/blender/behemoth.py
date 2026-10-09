"""Behemoth: hulking plated beast on four pillar legs; rears and stomps.
Run: blender -b --python art/blender/behemoth.py -- <out.glb>
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
from legs import Legs  # noqa: E402

BODY_Z = 0.85
LEGS = Legs()
for name, x, side, ph in [("BL", -0.6, 1, 0.0), ("FL", 0.4, 1, 0.25), ("BR", -0.6, -1, 0.5), ("FR", 0.4, -1, 0.75)]:
    LEGS.add(name, (x, side * 0.45, 0.72), (x * 1.05, side * 0.52, 0.0), side, ph, knee_up=0.0, knee_out=0.0, pillar=True)


def build():
    arm = lib.armature("behemoth", [("root", (0, 0, 0), (0, 0, 0.1), None),
                                    ("body", (-0.1, 0, BODY_Z), (0.2, 0, BODY_Z), "root"),
                                    ("head", (0.55, 0, 0.7), (1.0, 0, 0.66), "body")] + LEGS.bones("body"))
    b = lib.Builder("behemoth")
    b.ball((-0.1, 0, 0.9), 0.6, "chitin", "body", scale=(1.4, 1.05, 0.85), seg=14, rings=9)
    b.ball((-0.1, 0, 0.56), 0.45, "plate", "body", scale=(1.3, 0.8, 0.35), seg=10, rings=5, smooth=False)
    for x, h in ((-0.55, 1.68), (-0.12, 1.82), (0.3, 1.62)):  # bone plates down the hump
        b.limb((x, 0, 1.25), (x - 0.2, 0, h), 0.2, 0.0, "plate", "body", seg=4)
    for s in (1, -1):
        for x in (0.25, -0.15, -0.55):
            b.ball((x, s * 0.6, 0.92), 0.2, "plate", "body", scale=(1.2, 0.4, 1.0), seg=6, rings=4, smooth=False)
        b.ball((-0.35, s * 0.42, 1.2), 0.2, "sick", "body", seg=7, rings=5)
        b.ball((-0.72, s * 0.28, 1.12), 0.14, "sick", "body", seg=6, rings=5)
    b.ball((-0.88, 0, 1.02), 0.22, "glow", "body", seg=8, rings=6)  # tier spore gland
    b.ball((0.78, 0, 0.66), 0.3, "chitin", "head", scale=(1.15, 1.0, 0.9), seg=10, rings=7)
    b.ball((0.86, 0, 0.86), 0.2, "plate", "head", scale=(1.0, 1.4, 0.4), seg=6, rings=4, smooth=False)
    b.ball((1.04, 0, 0.6), 0.1, "glow", "head", seg=6, rings=5)  # glowing maw
    for s in (1, -1):
        b.limb((0.9, s * 0.15, 0.52), (1.15, s * 0.3, 0.6), 0.075, 0.05, "bone", "head")
        b.limb((1.15, s * 0.3, 0.6), (1.28, s * 0.33, 0.86), 0.05, 0.0, "bone", "head")
        b.ball((0.98, s * 0.17, 0.78), 0.05, "eye", "head", seg=5, rings=4)
    LEGS.mesh(b, 0.16, 0.13, 0.12, joint="plate", tip="chitin", seg=8)
    for n, (_h, _k, foot, _s, _p) in LEGS.legs.items():
        b.ball((foot.x, foot.y, 0.07), 0.17, "bone", "lo_" + n, scale=(1.2, 1.2, 0.5), seg=8, rings=4, smooth=False)
    b.finish(arm)
    return arm


def rot(arm, bone, axis, ang):
    return lib.world_rot(arm, bone, axis, ang)


def still(arm, fn=None):
    return LEGS.all(arm, fn or (lambda n, s, i: (0.0, 0.0, 0.0)))


def walk(arm):
    def pose(t):
        p = LEGS.walk(arm, t, 0.4, lift=0.6, bend=0.5, duty=0.7)
        stomp = abs(math.sin(2 * math.pi * t))  # 0 at each footfall: sharp drop, slow rise
        p["body"] = (rot(arm, "body", (1, 0, 0), 0.06 * math.sin(2 * math.pi * t)),
                     lib.world_loc(arm, "body", (0, 0, 0.16 * stomp - 0.08)))
        p["head"] = (rot(arm, "head", (0, 0, 1), 0.08 * math.sin(2 * math.pi * t)) @ rot(arm, "head", (0, 1, 0), 0.08 * (1 - stomp)), None)
        return p
    lib.action(arm, "walk", 14, pose, step=1, loop=True)


def idle(arm):
    def pose(t):
        w = 2 * math.pi * t
        p = still(arm)
        p["body"] = (rot(arm, "body", (0, 1, 0), 0.04 * math.sin(w)), lib.world_loc(arm, "body", (0, 0, 0.04 * math.sin(w))))
        p["head"] = (rot(arm, "head", (0, 0, 1), 0.2 * math.sin(w)).normalized() @
                     rot(arm, "head", (0, 1, 0), 0.08 * math.sin(2 * w)), None)
        return p
    lib.action(arm, "idle", 60, pose, step=2, loop=True)


def attack(arm):
    def pose(t):
        rear = lib.pulse(t, 0.0, 0.6)
        slam = lib.pulse(t, 0.5, 0.85)
        p = still(arm, lambda n, s, i: (0.0, 0.9 * rear if n[0] == "F" else 0.0, 0.0))
        p["body"] = (rot(arm, "body", (0, 1, 0), -0.38 * rear + 0.12 * slam),
                     lib.world_loc(arm, "body", (-0.08 * rear + 0.1 * slam, 0, 0.1 * rear - 0.08 * slam)))
        p["head"] = (rot(arm, "head", (0, 1, 0), -0.3 * rear + 0.4 * slam), None)
        return p
    lib.action(arm, "attack", 24, pose, step=1)


def hit(arm):
    def pose(t):
        j = lib.pulse(t, 0.0, 1.0) * (1.0 - t)
        p = still(arm)
        p["body"] = (rot(arm, "body", (1, 0, 0), 0.18 * j) @ rot(arm, "body", (0, 1, 0), -0.15 * j), lib.world_loc(arm, "body", (-0.12 * j, 0, 0.04 * j)))
        p["head"] = (rot(arm, "head", (0, 0, 1), 0.6 * j), None)
        return p
    lib.action(arm, "hit", 10, pose, step=1)


def die(arm):
    def pose(t):
        buckle = lib.ease(min(1.0, t / 0.4))
        tip = lib.ease(min(1.0, max(0.0, (t - 0.3) / 0.45)))
        sink = lib.ease(min(1.0, max(0.0, (t - 0.7) / 0.3)))
        p = still(arm, lambda n, s, i: (0.0, 0.0, 1.4 * buckle if n[0] == "F" else 0.9 * tip))
        p["body"] = (rot(arm, "body", (0, 1, 0), 0.3 * buckle - 0.25 * tip).normalized() @
                     rot(arm, "body", (1, 0, 0), 0.6 * tip),
                     lib.world_loc(arm, "body", (0.05 * buckle, 0, -0.3 * buckle - 0.15 * tip - 0.4 * sink)))
        p["head"] = (rot(arm, "head", (0, 1, 0), 0.4 * buckle), None)
        return p
    lib.action(arm, "die", 36, pose, step=1)


if __name__ == "__main__":
    out = sys.argv[sys.argv.index("--") + 1]
    lib.reset()
    a = build()
    for fn in (idle, walk, attack, hit, die):
        fn(a)
    lib.export(out)
