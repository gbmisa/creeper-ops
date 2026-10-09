"""Burrower: flat wedge-headed digger with two bone claws; rakes the ground."""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
from bug_kit import Kit, body_pose, run  # noqa: E402
from legs import Legs  # noqa: E402

LEGS = Legs()
for n, hx, fx, s, ph in [("ML", 0.05, 0.12, 1, 0.0), ("MR", 0.05, 0.12, -1, 0.5),
                         ("BL", -0.15, -0.38, 1, 0.5), ("BR", -0.15, -0.38, -1, 0.0)]:
    LEGS.add(n, (hx, s * 0.12, 0.18), (fx, s * 0.38, 0.0), s, ph, knee_up=0.12)


def build():
    bones = [("root", (0, 0, 0), (0, 0, 0.1), None),
             ("body", (0, 0, 0.2), (0.2, 0, 0.2), "root"),
             ("tail", (-0.15, 0, 0.2), (-0.5, 0, 0.18), "body")]
    for sd, s in (("L", 1), ("R", -1)):
        bones.append(("claw_" + sd, (0.38, s * 0.13, 0.17), (0.7, s * 0.2, 0.08), "body"))
    arm = lib.armature("burrower", bones + LEGS.bones("body"))
    b = lib.Builder("burrower")
    b.ball((0.12, 0, 0.21), 0.28, "chitin", "body", scale=(1.6, 0.85, 0.48), seg=10, rings=6)
    b.limb((0.4, 0, 0.22), (0.66, 0, 0.12), 0.12, 0.0, "plate", "body", seg=4)  # digging wedge
    for x in (0.25, 0.0, -0.18):
        b.ball((x, 0, 0.32), 0.12, "plate", "body", scale=(0.9, 1.6, 0.3), seg=6, rings=3, smooth=False)
    for s in (1, -1):
        b.ball((0.38, s * 0.1, 0.28), 0.025, "eye", "body", seg=4, rings=3)
    b.ball((-0.3, 0, 0.19), 0.15, "chitin", "tail", scale=(1.3, 0.8, 0.6), seg=7, rings=5)
    b.ball((-0.46, 0, 0.21), 0.11, "glow", "tail", seg=7, rings=5)
    for sd, s in (("L", 1), ("R", -1)):
        b.limb((0.38, s * 0.13, 0.17), (0.7, s * 0.21, 0.08), 0.05, 0.035, "bone", "claw_" + sd)
        b.limb((0.7, s * 0.21, 0.08), (0.95, s * 0.09, 0.02), 0.035, 0.0, "bone", "claw_" + sd)
        b.limb((0.7, s * 0.21, 0.08), (0.88, s * 0.2, 0.0), 0.025, 0.0, "bone", "claw_" + sd, seg=4)
    LEGS.mesh(b, 0.035, 0.028, 0.012)
    b.finish(arm)
    return Kit(arm, LEGS, walk_frames=14, swing=0.4, lift=0.45, bend=0.3, duty=0.55, bob=0.01, roll_die=2.8)


def claws(k, ang, spread=0.0):
    return {"claw_L": (lib.world_rot(k.arm, "claw_L", (0, 1, 0), ang) @ lib.world_rot(k.arm, "claw_L", (0, 0, 1), spread), None),
            "claw_R": (lib.world_rot(k.arm, "claw_R", (0, 1, 0), ang) @ lib.world_rot(k.arm, "claw_R", (0, 0, 1), -spread), None)}


def clips(k):
    k.idle(lambda t: claws(k, -0.1 * lib.pulse(t, 0.3, 0.6)))

    def walk_extra(t):
        p = claws(k, 0.15 * math.sin(4 * math.pi * t))
        p["tail"] = (lib.world_rot(k.arm, "tail", (0, 0, 1), 0.15 * math.sin(2 * math.pi * t)), None)
        return p
    k.walk(walk_extra)

    def dig(t, p):
        rake = math.sin(t * 4 * math.pi)
        dip = lib.pulse(t, 0.0, 1.0)
        p.update(claws(k, -0.35 * rake * dip, 0.2 * dip))
        p["body"] = body_pose(k.arm, pitch=0.18 * dip, loc=(0.03 * rake * dip, 0, -0.04 * dip))
        p["tail"] = (lib.world_rot(k.arm, "tail", (0, 1, 0), -0.3 * dip), None)
    k.attack(18, dig)
    k.hit()
    k.die(lambda t: claws(k, -0.6 * lib.ease(min(1.0, t / 0.6)), 0.4))


run(build, clips)
