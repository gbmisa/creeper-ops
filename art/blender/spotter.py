"""Spotter: small scuttler with one big glowing eye on a tall stalk; stares and pulses to mark a target."""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
from bug_kit import Kit, body_pose, run  # noqa: E402
from legs import Legs  # noqa: E402

LEGS = Legs()
for n, hx, fx, s, ph in [("FL", 0.05, 0.22, 1, 0.0), ("FR", 0.05, 0.22, -1, 0.5),
                         ("BL", -0.05, -0.22, 1, 0.5), ("BR", -0.05, -0.22, -1, 0.0)]:
    LEGS.add(n, (hx, s * 0.1, 0.26), (fx * 1.2, s * 0.42, 0.0), s, ph, knee_up=0.2)


def build():
    arm = lib.armature("spotter", [("root", (0, 0, 0), (0, 0, 0.1), None),
                                   ("body", (0, 0, 0.25), (0.15, 0, 0.25), "root"),
                                   ("stalk", (0, 0, 0.38), (0.05, 0, 0.9), "body"),
                                   ("eye", (0.06, 0, 0.98), (0.26, 0, 1.02), "stalk")] + LEGS.bones("body"))
    b = lib.Builder("spotter")
    b.ball((-0.02, 0, 0.3), 0.27, "chitin", "body", scale=(1.2, 1.0, 0.75), seg=8, rings=6)
    for k in range(3):  # bone spikes round the base
        a = 2.1 + k * 1.05
        b.limb((0.2 * math.cos(a), 0.2 * math.sin(a), 0.4), (0.32 * math.cos(a), 0.32 * math.sin(a), 0.58), 0.05, 0.0, "bone", "body", seg=4)
    b.ball((-0.05, 0, 0.48), 0.13, "plate", "body", scale=(1.4, 1.2, 0.4), seg=6, rings=4, smooth=False)
    b.ball((-0.18, 0, 0.3), 0.06, "sick", "body", seg=5, rings=4)
    b.limb((0, 0, 0.36), (0.05, 0, 0.9), 0.075, 0.05, "bone", "stalk", seg=6, smooth=True)
    for z in (0.55, 0.72):
        b.ball((0.02 + z * 0.03, 0, z), 0.05, "plate", "stalk", scale=(1, 1, 0.5), seg=6, rings=3, smooth=False)
    b.ball((0.08, 0, 1.02), 0.19, "glow", "eye", seg=10, rings=8)
    b.ball((0.23, 0, 1.04), 0.085, "chitin", "eye", scale=(0.5, 1, 1), seg=8, rings=6)  # pupil
    b.ball((0.06, 0, 1.14), 0.18, "plate", "eye", scale=(1.15, 1.15, 0.45), seg=8, rings=4, smooth=False)  # brow lid
    LEGS.mesh(b, 0.028, 0.022, 0.012)
    b.finish(arm)
    return Kit(arm, LEGS, walk_frames=14, swing=0.45, lift=0.55, bend=0.35, duty=0.5, bob=0.015, roll_die=2.6, sink=0.06)


def clips(k):
    def look(t):
        w = 2 * math.pi * t
        return {"stalk": (lib.world_rot(k.arm, "stalk", (1, 0, 0), 0.1 * math.sin(w)), None),
                "eye": (lib.world_rot(k.arm, "eye", (0, 0, 1), 0.7 * math.sin(w) * lib.pulse(t, 0.05, 0.95)), None)}
    k.idle(look)
    k.walk(lambda t: {"stalk": (lib.world_rot(k.arm, "stalk", (0, 1, 0), -0.08 + 0.06 * math.sin(4 * math.pi * t)), None)})

    def mark(t, p):
        lean = lib.ease(min(1.0, t / 0.3)) * (1.0 - lib.ease(max(0.0, (t - 0.8) / 0.2)))
        flare = lib.pulse(t, 0.35, 0.7)
        p["stalk"] = (lib.world_rot(k.arm, "stalk", (0, 1, 0), 0.55 * lean), None)
        p["eye"] = (lib.world_rot(k.arm, "eye", (0, 1, 0), -0.2 * lean), None, (1 + 0.3 * flare,) * 3)
        p["body"] = body_pose(k.arm, loc=(0, 0, -0.03 * lean))
    k.attack(20, mark)
    k.hit()
    k.die(lambda t: {"stalk": (lib.world_rot(k.arm, "stalk", (0, 1, 0), 1.0 * lib.ease(min(1.0, t / 0.5))), None)})


run(build, clips)
