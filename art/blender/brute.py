"""Brute: armoured horn-beetle, four thick legs, trots and tosses its horn.
Run: blender -b --python art/blender/brute.py -- <out.glb>
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
from legs import Legs  # noqa: E402

BODY_Z = 0.55
LEGS = Legs()
for name, hx, fx, side, ph in [("FL", 0.3, 0.42, 1, 0.0), ("FR", 0.3, 0.42, -1, 0.5),
                               ("BL", -0.35, -0.49, 1, 0.5), ("BR", -0.35, -0.49, -1, 0.0)]:
    LEGS.add(name, (hx, side * 0.38, 0.52), (fx * 1.1, side * 0.88, 0.0), side, ph, knee_up=0.24, knee_out=0.12)


def build(arm_name="brute"):
    arm = lib.armature(arm_name, [("root", (0, 0, 0), (0, 0, 0.1), None),
                                  ("body", (0, 0, BODY_Z), (0.2, 0, BODY_Z), "root"),
                                  ("head", (0.42, 0, BODY_Z), (0.72, 0, BODY_Z), "body")] + LEGS.bones("body"))
    b = lib.Builder(arm_name)
    b.ball((0.0, 0, 0.32), 0.3, "glow", "body", scale=(1.3, 1.0, 0.6), seg=8, rings=5)
    b.ball((-0.05, 0, 0.5), 0.5, "chitin", "body", scale=(1.35, 1.0, 0.7), seg=12, rings=8)
    for x in (0.28, -0.05, -0.38):  # armour bands down the flanks
        for s in (1, -1):
            b.ball((x, s * 0.43, 0.48), 0.15, "plate", "body", scale=(1.1, 0.45, 0.85), seg=6, rings=4, smooth=False)
    for x, h in ((0.05, 1.05), (-0.35, 1.0), (-0.62, 0.86)):  # ridge spikes
        b.limb((x, 0, 0.78), (x - 0.2, 0, h + 0.12), 0.18, 0.0, "bone", "body", seg=4)
    for at, r in (((-0.45, -0.25, 0.68), 0.2), ((-0.2, 0.3, 0.74), 0.14), ((-0.7, 0.12, 0.6), 0.11)):
        b.ball(at, r, "sick", "body", seg=7, rings=5)
    b.ball((0.56, 0, 0.42), 0.21, "chitin", "head", scale=(1.1, 1.0, 0.9), seg=8, rings=6)
    b.limb((0.62, 0, 0.5), (0.82, 0, 0.64), 0.11, 0.075, "bone", "head")
    b.limb((0.82, 0, 0.64), (1.02, 0, 1.25), 0.09, 0.0, "bone", "head")
    for s in (1, -1):
        b.ball((0.7, s * 0.12, 0.46), 0.05, "eye", "head", seg=5, rings=4)
        b.limb((0.66, s * 0.13, 0.34), (0.8, s * 0.2, 0.26), 0.04, 0.0, "bone", "head", seg=4)
    b.move(["body", "head"], (0, 0, BODY_Z - 0.42))
    LEGS.mesh(b, 0.1, 0.075, 0.045)
    b.finish(arm)
    return arm


def body(arm, rot_axis=None, ang=0.0, loc=(0, 0, 0)):
    q = lib.world_rot(arm, "body", rot_axis, ang) if rot_axis else None
    return (q, lib.world_loc(arm, "body", loc))


def walk(arm):
    def pose(t):
        p = LEGS.walk(arm, t, 0.55, lift=0.85, bend=0.5, duty=0.6)
        p["body"] = body(arm, (1, 0, 0), 0.04 * math.sin(2 * math.pi * t), (0, 0, 0.02 * math.cos(4 * math.pi * t)))
        p["head"] = (lib.world_rot(arm, "head", (0, 1, 0), 0.06 * math.sin(4 * math.pi * t)), None)
        return p
    lib.action(arm, "walk", 14, pose, step=1, loop=True)


def idle(arm):
    def pose(t):
        w = 2 * math.pi * t
        p = LEGS.all(arm, lambda n, s, i: (0.0, 0.0, 0.0))
        p["body"] = body(arm, (0, 1, 0), 0.05 * math.sin(w), (0, 0, 0.03 * math.sin(w)))
        p["head"] = (lib.world_rot(arm, "head", (0, 0, 1), 0.2 * math.sin(w) * lib.pulse(t, 0.3, 0.9)), None)
        return p
    lib.action(arm, "idle", 48, pose, step=2, loop=True)


def attack(arm):
    def pose(t):
        crouch = lib.pulse(t, 0.0, 0.5)
        toss = lib.pulse(t, 0.35, 0.85)
        p = LEGS.all(arm, lambda n, s, i: (0.15 * toss, 0.25 * crouch, 0.2 * crouch))
        p["body"] = body(arm, (0, 1, 0), 0.25 * crouch - 0.3 * toss, (0.32 * toss, 0, -0.12 * crouch))
        p["head"] = (lib.world_rot(arm, "head", (0, 1, 0), 0.4 * crouch - 1.0 * toss), None)
        return p
    lib.action(arm, "attack", 17, pose, step=1)


def hit(arm):
    def pose(t):
        j = lib.pulse(t, 0.0, 1.0) * (1.0 - t)
        p = LEGS.all(arm, lambda n, s, i: (0.0, 0.15 * j, 0.1 * j))
        p["body"] = body(arm, (0, 1, 0), -0.4 * j, (-0.18 * j, 0, 0.05 * j))
        p["head"] = (lib.world_rot(arm, "head", (0, 0, 1), 0.6 * j), None)
        return p
    lib.action(arm, "hit", 8, pose, step=1)


def die(arm):
    def pose(t):
        fall = lib.ease(min(1.0, t / 0.45))
        tip = lib.ease(min(1.0, max(0.0, (t - 0.25) / 0.5)))
        sink = lib.ease(min(1.0, max(0.0, (t - 0.65) / 0.35)))
        p = LEGS.all(arm, lambda n, s, i: (0.0, 0.7 * fall + (0.5 * tip if s > 0 else -0.2 * tip), 0.6 * fall))
        p["body"] = body(arm, (1, 0, 0), 0.9 * tip, (0, 0.05 * tip, -0.22 * fall - 0.25 * sink))
        p["head"] = (lib.world_rot(arm, "head", (0, 1, 0), 0.5 * fall), None)
        return p
    lib.action(arm, "die", 30, pose, step=1)


if __name__ == "__main__":
    out = sys.argv[sys.argv.index("--") + 1]
    lib.reset()
    a = build()
    for fn in (idle, walk, attack, hit, die):
        fn(a)
    lib.export(out)
