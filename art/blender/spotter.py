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
    LEGS.add(n, (hx, s * 0.08, 0.22), (fx, s * 0.32, 0.0), s, ph, knee_up=0.16)


def build():
    arm = lib.armature("spotter", [("root", (0, 0, 0), (0, 0, 0.1), None),
                                   ("body", (0, 0, 0.25), (0.15, 0, 0.25), "root"),
                                   ("stalk", (0, 0, 0.35), (0.05, 0, 1.15), "body"),
                                   ("eye", (0.06, 0, 1.2), (0.26, 0, 1.24), "stalk")] + LEGS.bones("body"))
    b = lib.Builder("spotter")
    b.ball((-0.02, 0, 0.26), 0.2, "chitin", "body", scale=(1.2, 1.0, 0.75), seg=8, rings=6)
    b.ball((-0.05, 0, 0.38), 0.1, "plate", "body", scale=(1.4, 1.2, 0.4), seg=6, rings=4, smooth=False)
    b.ball((-0.18, 0, 0.3), 0.06, "sick", "body", seg=5, rings=4)
    b.limb((0, 0, 0.32), (0.05, 0, 1.12), 0.05, 0.035, "bone", "stalk", seg=6, smooth=True)
    for z in (0.55, 0.8):
        b.ball((0.02 + z * 0.03, 0, z), 0.05, "plate", "stalk", scale=(1, 1, 0.5), seg=6, rings=3, smooth=False)
    b.ball((0.08, 0, 1.26), 0.16, "glow", "eye", seg=10, rings=8)
    b.ball((0.2, 0, 1.28), 0.07, "chitin", "eye", scale=(0.5, 1, 1), seg=8, rings=6)  # pupil
    b.ball((0.06, 0, 1.36), 0.15, "plate", "eye", scale=(1.15, 1.15, 0.45), seg=8, rings=4, smooth=False)  # brow lid
    LEGS.mesh(b, 0.028, 0.022, 0.012)
    b.finish(arm)
    return Kit(arm, LEGS, walk_frames=14, swing=0.45, lift=0.55, bend=0.35, duty=0.5, bob=0.015, roll_die=2.6)


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
        p["stalk"] = (lib.world_rot(k.arm, "stalk", (0, 1, 0), 0.25 * lean), None)
        p["eye"] = (lib.world_rot(k.arm, "eye", (0, 1, 0), -0.2 * lean), None, (1 + 0.3 * flare,) * 3)
        p["body"] = body_pose(k.arm, loc=(0, 0, -0.03 * lean))
    k.attack(20, mark)
    k.hit()
    k.die(lambda t: {"stalk": (lib.world_rot(k.arm, "stalk", (0, 1, 0), 1.0 * lib.ease(min(1.0, t / 0.5))), None)})


run(build, clips)
