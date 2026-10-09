"""Skitter: small fast spider-bug, three legs a side, tripod gait.
Run: blender -b --python art/blender/skitter.py -- <out.glb>
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
from mathutils import Quaternion, Vector  # noqa: E402

HIP_X = [0.14, 0.04, -0.06]
FOOT_X = [0.44, 0.08, -0.34]
HIP_Z, FOOT_Y, SWING = 0.33, 0.55, 0.6
SIDES = {"L": 1.0, "R": -1.0}
TRIPOD_A = {"L0", "R1", "L2"}


def leg_points(side, i):
    s = SIDES[side]
    hip = Vector((HIP_X[i], s * 0.1, HIP_Z))
    foot = Vector((FOOT_X[i], s * FOOT_Y, 0.0))
    knee = (hip + foot) * 0.5 + Vector((0.0, s * 0.06, 0.26))
    return hip, knee, foot


def build_rig():
    bones = [("root", (0, 0, 0), (0, 0, 0.1), None),
             ("body", (0, 0, HIP_Z), (0.15, 0, HIP_Z), "root"),
             ("abdomen", (-0.05, 0, 0.36), (-0.5, 0, 0.42), "body"),
             ("head", (0.15, 0, 0.32), (0.36, 0, 0.32), "body")]
    for side, s in SIDES.items():
        bones.append(("fang_" + side, (0.32, s * 0.05, 0.27), (0.48, s * 0.02, 0.14), "head"))
        for i in range(3):
            hip, knee, foot = leg_points(side, i)
            bones.append(("up_%s%d" % (side, i), hip, knee, "body"))
            bones.append(("lo_%s%d" % (side, i), knee, foot, "up_%s%d" % (side, i)))
    return lib.armature("skitter", bones)


def build_mesh(arm):
    b = lib.Builder("skitter")
    b.ball((-0.25, 0, 0.4), 0.3, "chitin", "abdomen", scale=(1.35, 1.0, 0.75), seg=10, rings=7)
    for i, x in enumerate([-0.08, -0.22, -0.36]):  # dorsal plates
        b.ball((x, 0, 0.6 - i * 0.015), 0.09, "plate", "abdomen", scale=(0.8, 1.6, 0.35), seg=6, rings=4, smooth=False)
    b.ball((-0.47, 0, 0.5), 0.1, "glow", "abdomen", seg=7, rings=5)  # tier spore gland
    for s in (1, -1):
        b.ball((-0.2, s * 0.24, 0.48), 0.07, "sick", "abdomen", seg=6, rings=4)
        b.ball((-0.34, s * 0.2, 0.42), 0.05, "sick", "abdomen", seg=6, rings=4)
        b.limb((-0.12, s * 0.1, 0.62), (-0.16, s * 0.14, 0.76), 0.03, 0.0, "bone", "abdomen", seg=4)
    b.ball((0.05, 0, 0.34), 0.17, "chitin", "body", scale=(1.2, 1.0, 0.8), seg=8, rings=6)
    b.ball((0.06, 0, 0.44), 0.08, "plate", "body", scale=(1.4, 1.3, 0.4), seg=6, rings=4, smooth=False)
    b.ball((0.26, 0, 0.32), 0.12, "chitin", "head", scale=(1.1, 1.0, 0.85), seg=8, rings=6)
    for s in (1, -1):
        b.ball((0.35, s * 0.06, 0.37), 0.028, "eye", "head", seg=5, rings=4)
        b.ball((0.32, s * 0.09, 0.4), 0.018, "eye", "head", seg=5, rings=4)
        b.limb((0.32, s * 0.05, 0.27), (0.42, s * 0.04, 0.2), 0.035, 0.022, "bone", "fang_" + ("L" if s > 0 else "R"))
        b.limb((0.42, s * 0.04, 0.2), (0.48, s * 0.015, 0.13), 0.022, 0.0, "bone", "fang_" + ("L" if s > 0 else "R"))
    for side in SIDES:
        for i in range(3):
            hip, knee, foot = leg_points(side, i)
            b.limb(hip, knee, 0.063, 0.045, "chitin", "up_%s%d" % (side, i))
            b.ball(knee, 0.034, "plate", "up_%s%d" % (side, i), seg=5, rings=4, smooth=False)
            claw = foot + (knee - foot).normalized() * 0.06
            b.limb(knee, claw, 0.045, 0.022, "chitin", "lo_%s%d" % (side, i))
            b.limb(claw, foot, 0.016, 0.0, "bone", "lo_%s%d" % (side, i), seg=4)
    return b.finish(arm)


def leg_pose(arm, side, i, yaw, lift, bend):
    """yaw: + swings the foot forward; lift: + raises it; bend: + folds the shin in."""
    s = SIDES[side]
    hip, knee, foot = leg_points(side, i)
    out = (foot - hip)
    out.z = 0.0
    k = out.normalized().cross(Vector((0, 0, 1)))
    q_up = Quaternion((0, 0, 1), -s * yaw) @ Quaternion(k, lift)
    q_lo = Quaternion(k, -bend)
    name = "%s%d" % (side, i)
    return {"up_" + name: (lib.local_q(arm, "up_" + name, q_up), None),
            "lo_" + name: (lib.local_q(arm, "lo_" + name, q_lo), None)}


def all_legs(arm, fn):
    pose = {}
    for side in SIDES:
        for i in range(3):
            pose.update(leg_pose(arm, side, i, *fn(side, i)))
    return pose


def walk(arm):
    def pose(t):
        def leg(side, i):
            ph = (t + (0.0 if side + str(i) in TRIPOD_A else 0.5)) % 1.0
            if ph < 0.5:
                return (SWING * (1.0 - 4.0 * ph), 0.0, 0.0)
            u = (ph - 0.5) * 2.0
            return (SWING * (-1.0 + 2.0 * lib.ease(u)), 0.85 * math.sin(math.pi * u), 0.5 * math.sin(math.pi * u))
        p = all_legs(arm, leg)
        bob = 0.018 * math.cos(4.0 * math.pi * t)
        p["body"] = (lib.world_rot(arm, "body", (1, 0, 0), 0.05 * math.sin(2 * math.pi * t)), lib.world_loc(arm, "body", (0, 0, bob)))
        p["abdomen"] = (lib.world_rot(arm, "abdomen", (0, 0, 1), 0.08 * math.sin(2 * math.pi * t + 1.0)), None)
        return p
    lib.action(arm, "walk", lib.FPS, pose, step=1, loop=True)


def idle(arm):
    def pose(t):
        w = 2 * math.pi * t
        tap = lib.pulse(t, 0.55, 0.75)
        p = all_legs(arm, lambda side, i: (0.0, 0.35 * tap if side + str(i) == "L0" else 0.0, 0.2 * tap if side + str(i) == "L0" else 0.0))
        p["body"] = (None, lib.world_loc(arm, "body", (0, 0, 0.01 * math.sin(w))))
        p["abdomen"] = (lib.world_rot(arm, "abdomen", (0, 1, 0), 0.06 * math.sin(w)), None)
        p["head"] = (lib.world_rot(arm, "head", (0, 0, 1), 0.25 * math.sin(w) * lib.pulse(t, 0.1, 0.5)), None)
        for side, s in SIDES.items():
            p["fang_" + side] = (lib.world_rot(arm, "fang_" + side, (0, 0, 1), s * 0.25 * abs(math.sin(3 * w))), None)
        return p
    lib.action(arm, "idle", lib.FPS * 2, pose, step=2, loop=True)


def attack(arm):
    def pose(t):
        rear = lib.pulse(t, 0.0, 0.5)
        lunge = lib.pulse(t, 0.3, 0.8)
        front = lambda side, i: (0.3 * rear, 0.9 * rear if i == 0 else 0.0, 0.5 * rear if i == 0 else 0.0)
        p = all_legs(arm, front)
        p["body"] = (lib.world_rot(arm, "body", (0, 1, 0), -0.35 * rear + 0.3 * lunge),
                     lib.world_loc(arm, "body", (0.14 * lunge, 0, 0.05 * rear - 0.04 * lunge)))
        snap = 0.5 * rear - 0.45 * lunge
        for side, s in SIDES.items():
            p["fang_" + side] = (lib.world_rot(arm, "fang_" + side, (0, 0, 1), s * snap), None)
        return p
    lib.action(arm, "attack", 14, pose, step=1)


def hit(arm):
    def pose(t):
        j = lib.pulse(t, 0.0, 1.0) * (1.0 - t)
        p = all_legs(arm, lambda side, i: (0.0, 0.6 * j, 0.4 * j))
        p["body"] = (lib.world_rot(arm, "body", (0, 1, 0), -0.5 * j), lib.world_loc(arm, "body", (-0.16 * j, 0, 0.06 * j)))
        p["abdomen"] = (lib.world_rot(arm, "abdomen", (0, 1, 0), 0.3 * j), None)
        return p
    lib.action(arm, "hit", 8, pose, step=1)


def die(arm):
    def pose(t):
        flail = math.sin(t * 40.0) * lib.pulse(t, 0.0, 0.35)
        roll = math.pi * lib.ease(min(1.0, max(0.0, (t - 0.2) / 0.5)))
        curl = lib.ease(min(1.0, t / 0.6))
        p = all_legs(arm, lambda side, i: (0.3 * flail * (1 if i % 2 else -1), -0.35 * curl, 0.9 * curl))
        hop = 0.12 * lib.pulse(t, 0.2, 0.7)
        sink = -0.2 * lib.ease(min(1.0, max(0.0, (t - 0.6) / 0.4)))
        p["body"] = (lib.world_rot(arm, "body", (1, 0, 0), roll), lib.world_loc(arm, "body", (0, 0, hop + sink)))
        p["abdomen"] = (lib.world_rot(arm, "abdomen", (0, 1, 0), -0.3 * curl), None)
        return p
    lib.action(arm, "die", 29, pose, step=1)


def main():
    out = sys.argv[sys.argv.index("--") + 1]
    lib.reset()
    arm = build_rig()
    build_mesh(arm)
    for fn in (idle, walk, attack, hit, die):
        fn(arm)
    lib.export(out)


main()
