"""Spitter: low bug with a swollen glowing sac; squeezes the sac and spits from its nozzle."""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
from bug_kit import Kit, body_pose, bone_rot, run  # noqa: E402
from legs import Legs  # noqa: E402

LEGS = Legs()
for n, hx, fx, s, ph in [("FL", 0.08, 0.38, 1, 0.0), ("FR", 0.08, 0.38, -1, 0.5), ("ML", -0.08, -0.05, 1, 0.5),
                         ("MR", -0.08, -0.05, -1, 0.0), ("BL", -0.25, -0.48, 1, 0.0), ("BR", -0.25, -0.48, -1, 0.5)]:
    LEGS.add(n, (hx, s * 0.13, 0.3), (fx, s * 0.5, 0.0), s, ph, knee_up=0.22)


def build():
    arm = lib.armature("spitter", [("root", (0, 0, 0), (0, 0, 0.1), None),
                                   ("body", (0, 0, 0.32), (0.2, 0, 0.32), "root"),
                                   ("sac", (-0.05, 0, 0.42), (-0.6, 0, 0.5), "body"),
                                   ("head", (0.2, 0, 0.36), (0.5, 0, 0.34), "body")] + LEGS.bones("body"))
    b = lib.Builder("spitter")
    b.ball((-0.2, 0, 0.45), 0.4, "chitin", "sac", scale=(1.3, 1.0, 0.85), seg=10, rings=7)
    b.ball((-0.38, 0, 0.72), 0.17, "glow", "sac", seg=8, rings=6)
    for s in (1, -1):  # glowing veins over the sac
        for x, z in ((-0.05, 0.62), (-0.3, 0.6), (-0.5, 0.48)):
            b.ball((x, s * 0.3, z), 0.06, "sick", "sac", seg=5, rings=4)
        b.limb((-0.1, s * 0.12, 0.74), (-0.5, s * 0.16, 0.66), 0.03, 0.02, "sick", "sac", seg=4)
    b.ball((0.05, 0, 0.32), 0.15, "chitin", "body", scale=(1.3, 1.0, 0.8), seg=8, rings=5)
    b.ball((0.26, 0, 0.36), 0.15, "chitin", "head", seg=8, rings=6)
    b.ball((0.3, 0, 0.47), 0.08, "plate", "head", scale=(1.3, 1.2, 0.4), seg=6, rings=4, smooth=False)
    b.limb((0.36, 0, 0.36), (0.66, 0, 0.33), 0.08, 0.05, "plate", "head")
    b.limb((0.66, 0, 0.33), (0.84, 0, 0.31), 0.05, 0.035, "glow", "head")
    for s in (1, -1):
        b.ball((0.33, s * 0.09, 0.43), 0.035, "eye", "head", seg=5, rings=4)
    LEGS.mesh(b, 0.04, 0.03, 0.014)
    b.finish(arm)
    return Kit(arm, LEGS, walk_frames=18, swing=0.42, head="head")


def clips(k):
    k.idle(lambda t: {"sac": (None, None, (1 + 0.04 * math.sin(4 * math.pi * t),) * 3)})
    k.walk(lambda t: {"sac": bone_rot(k.arm, "sac", (0, 0, 1), 0.1 * math.sin(2 * math.pi * t + 1.0))})

    def spit(t, p):
        load = lib.pulse(t, 0.0, 0.55)
        fire = lib.pulse(t, 0.45, 0.75)
        p["sac"] = (None, None, (1 + 0.2 * load - 0.15 * fire, 1 + 0.15 * load - 0.1 * fire, 1 + 0.2 * load - 0.2 * fire))
        p["head"] = bone_rot(k.arm, "head", (0, 1, 0), 0.25 * load - 0.35 * fire)
        p["body"] = body_pose(k.arm, pitch=0.1 * load - 0.12 * fire, loc=(-0.06 * fire, 0, -0.03 * load))
    k.attack(18, spit)
    k.hit()
    k.die()


run(build, clips)
