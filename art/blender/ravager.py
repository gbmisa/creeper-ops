"""Ravager: armoured mantis, rears up and brings two bone scythes down.
Run: blender -b --python art/blender/ravager.py -- <out.glb>
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
from legs import Legs  # noqa: E402

HIP_Z = 0.55
LEGS = Legs()
for name, hx, fx, side, ph in [("FL", -0.1, 0.22, 1, 0.0), ("FR", -0.1, 0.22, -1, 0.5),
                               ("BL", -0.38, -0.78, 1, 0.5), ("BR", -0.38, -0.78, -1, 0.0)]:
    LEGS.add(name, (hx, side * 0.13, HIP_Z), (fx, side * 0.62, 0.0), side, ph, knee_up=0.3, knee_out=0.1)
SHOULDER, ELBOW, TIP = (0.16, 0.15, 1.0), (0.6, 0.32, 1.3), (0.95, 0.25, 0.5)


def side_pt(p, s):
    return (p[0], s * p[1], p[2])


def build():
    bones = [("root", (0, 0, 0), (0, 0, 0.1), None),
             ("body", (-0.25, 0, HIP_Z), (0.0, 0, HIP_Z), "root"),
             ("abdomen", (-0.3, 0, 0.62), (-1.1, 0, 0.62), "body"),
             ("thorax", (-0.12, 0, 0.6), (0.18, 0, 1.08), "body"),
             ("head", (0.15, 0, 1.12), (0.55, 0, 1.05), "thorax")]
    for side, s in (("L", 1), ("R", -1)):
        bones.append(("arm_" + side, side_pt(SHOULDER, s), side_pt(ELBOW, s), "thorax"))
        bones.append(("blade_" + side, side_pt(ELBOW, s), side_pt(TIP, s), "arm_" + side))
    arm = lib.armature("ravager", bones + LEGS.bones("body"))
    b = lib.Builder("ravager")
    b.ball((-0.55, 0, 0.62), 0.42, "chitin", "abdomen", scale=(1.6, 1.0, 0.85), seg=10, rings=7)
    b.ball((-0.58, 0, 0.8), 1.0, "plate", "abdomen", scale=(0.62, 0.44, 0.3), seg=12, rings=8, smooth=False)
    for s in (1, -1):
        b.limb((-0.42, s * 0.36, 0.84), (-0.58, s * 0.66, 0.7), 0.13, 0.0, "bone", "abdomen", seg=4)
        b.limb((-0.78, s * 0.3, 0.8), (-0.98, s * 0.55, 0.64), 0.1, 0.0, "bone", "abdomen", seg=4)
        b.ball((-0.5, s * 0.2, 1.04), 0.11, "sick", "abdomen", seg=6, rings=5)
    b.ball((-0.82, 0, 1.0), 0.12, "sick", "abdomen", seg=6, rings=5)
    b.limb((-0.2, 0, 0.55), (0.2, 0, 1.1), 0.21, 0.14, "chitin", "thorax", seg=8, smooth=True)
    b.ball((0.05, 0, 0.98), 0.1, "glow", "thorax", seg=7, rings=5)  # tier gland at the neck
    b.ball((0.2, 0, 1.12), 0.14, "chitin", "head", seg=8, rings=6)
    b.limb((0.2, 0, 1.12), (0.58, 0, 1.02), 0.13, 0.025, "chitin", "head", seg=6)
    for s in (1, -1):
        b.ball((0.3, s * 0.1, 1.2), 0.045, "eye", "head", seg=5, rings=4)
        b.limb((0.3, s * 0.08, 1.24), (0.2, s * 0.22, 1.5), 0.02, 0.0, "bone", "head", seg=4)  # feelers
        sd = "L" if s > 0 else "R"
        b.limb(side_pt(SHOULDER, s), side_pt(ELBOW, s), 0.08, 0.06, "chitin", "arm_" + sd)
        b.ball(side_pt(ELBOW, s), 0.07, "plate", "arm_" + sd, seg=5, rings=4, smooth=False)
        mid = (0.88, s * 0.3, 0.95)
        b.limb(side_pt(ELBOW, s), mid, 0.07, 0.05, "bone", "blade_" + sd)
        b.limb(mid, side_pt(TIP, s), 0.05, 0.0, "bone", "blade_" + sd)
        for k in range(3):  # serrations on the inner edge
            f = 0.3 + 0.2 * k
            at = (0.88 + 0.07 * f, s * (0.3 - 0.05 * f), 0.95 - 0.45 * f)
            b.limb(at, (at[0] - 0.1, at[1], at[2] + 0.02), 0.025, 0.0, "bone", "blade_" + sd, seg=3)
    LEGS.mesh(b, 0.06, 0.045, 0.022)
    b.finish(arm)
    return arm


def rot(arm, bone, axis, ang):
    return lib.world_rot(arm, bone, axis, ang)


def arms(arm, raise_, strike, spread=0.0):
    """raise_ lifts the scythes up and back, strike swings them forward and down."""
    p = {}
    for side, s in (("L", 1), ("R", -1)):
        p["arm_" + side] = (rot(arm, "arm_" + side, (0, 1, 0), -0.7 * raise_ + 0.5 * strike).normalized() @
                            rot(arm, "arm_" + side, (0, 0, 1), s * spread), None)
        p["blade_" + side] = (rot(arm, "blade_" + side, (0, 1, 0), -0.6 * raise_ + 0.9 * strike), None)
    return p


def walk(arm):
    def pose(t):
        p = LEGS.walk(arm, t, 0.4, lift=0.5, bend=0.4, duty=0.6)
        p["body"] = (rot(arm, "body", (1, 0, 0), 0.04 * math.sin(2 * math.pi * t)),
                     lib.world_loc(arm, "body", (0, 0, 0.025 * math.cos(4 * math.pi * t))))
        p["thorax"] = (rot(arm, "thorax", (0, 1, 0), 0.05 * math.sin(4 * math.pi * t)), None)
        p["abdomen"] = (rot(arm, "abdomen", (0, 0, 1), 0.08 * math.sin(2 * math.pi * t + 1.2)), None)
        p.update(arms(arm, 0.15 + 0.08 * math.sin(2 * math.pi * t), 0.0))
        return p
    lib.action(arm, "walk", 18, pose, step=1, loop=True)


def idle(arm):
    def pose(t):
        w = 2 * math.pi * t
        p = LEGS.all(arm, lambda n, s, i: (0.0, 0.0, 0.0))
        p["thorax"] = (rot(arm, "thorax", (0, 0, 1), 0.15 * math.sin(w)), None)
        p["head"] = (rot(arm, "head", (0, 0, 1), 0.3 * math.sin(w) * lib.pulse(t, 0.2, 0.8)), None)
        p["abdomen"] = (rot(arm, "abdomen", (0, 1, 0), 0.05 * math.sin(w)), None)
        p.update(arms(arm, 0.2 + 0.1 * math.sin(2 * w), 0.0))
        return p
    lib.action(arm, "idle", 48, pose, step=2, loop=True)


def attack(arm):
    def pose(t):
        rear = lib.pulse(t, 0.0, 0.55)
        strike = lib.pulse(t, 0.4, 0.9)
        p = LEGS.all(arm, lambda n, s, i: (0.0, 0.0, 0.0))
        p["thorax"] = (rot(arm, "thorax", (0, 1, 0), -0.4 * rear + 0.45 * strike), None)
        p["body"] = (None, lib.world_loc(arm, "body", (0.12 * strike, 0, 0.05 * rear)))
        p.update(arms(arm, 1.2 * rear, 1.3 * strike, 0.25 * rear))
        return p
    lib.action(arm, "attack", 18, pose, step=1)


def hit(arm):
    def pose(t):
        j = lib.pulse(t, 0.0, 1.0) * (1.0 - t)
        p = LEGS.all(arm, lambda n, s, i: (0.0, 0.1 * j, 0.1 * j))
        p["thorax"] = (rot(arm, "thorax", (0, 1, 0), -0.6 * j), None)
        p["body"] = (rot(arm, "body", (1, 0, 0), 0.2 * j), lib.world_loc(arm, "body", (-0.2 * j, 0, 0.04 * j)))
        p.update(arms(arm, 0.5 * j, 0.0, 0.4 * j))
        return p
    lib.action(arm, "hit", 8, pose, step=1)


def die(arm):
    def pose(t):
        fall = lib.ease(min(1.0, t / 0.5))
        tip = lib.ease(min(1.0, max(0.0, (t - 0.3) / 0.45)))
        sink = lib.ease(min(1.0, max(0.0, (t - 0.7) / 0.3)))
        p = LEGS.all(arm, lambda n, s, i: (0.0, 0.6 * fall, 1.1 * fall))
        p["thorax"] = (rot(arm, "thorax", (0, 1, 0), 0.8 * fall), None)
        p["body"] = (rot(arm, "body", (1, 0, 0), -1.1 * tip), lib.world_loc(arm, "body", (0, 0, -0.3 * fall - 0.3 * sink)))
        p.update(arms(arm, -0.2 * fall, 0.6 * fall, 0.6 * fall))
        return p
    lib.action(arm, "die", 30, pose, step=1)


if __name__ == "__main__":
    out = sys.argv[sys.argv.index("--") + 1]
    lib.reset()
    a = build()
    for fn in (idle, walk, attack, hit, die):
        fn(a)
    lib.export(out)
