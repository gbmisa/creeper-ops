"""Warden: squat biped behind a broad bone-rimmed shield; slams the shield into the ground (aura pulse)."""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
from bug_kit import Kit, body_pose, run  # noqa: E402
from legs import Legs  # noqa: E402

LEGS = Legs()
for n, s, ph in (("L", 1, 0.0), ("R", -1, 0.5)):
    LEGS.add(n, (-0.05, s * 0.18, 0.36), (0.0, s * 0.3, 0.0), s, ph, knee_up=0.0, knee_out=0.05, pillar=True)


def build():
    arm = lib.armature("warden", [("root", (0, 0, 0), (0, 0, 0.1), None),
                                  ("body", (-0.05, 0, 0.4), (-0.05, 0, 0.7), "root"),
                                  ("head", (0.0, 0, 0.88), (0.15, 0, 0.92), "body"),
                                  ("shield", (0.15, 0, 0.6), (0.32, 0, 0.6), "body")] + LEGS.bones("body"))
    b = lib.Builder("warden")
    b.ball((-0.05, 0, 0.56), 0.34, "chitin", "body", scale=(0.8, 1.15, 1.0), seg=10, rings=7)
    for s in (1, -1):
        b.ball((-0.02, s * 0.32, 0.78), 0.14, "plate", "body", scale=(1.0, 0.8, 0.6), seg=6, rings=4, smooth=False)
        b.ball((-0.22, s * 0.2, 0.74), 0.08, "sick", "body", seg=5, rings=4)
        b.limb((-0.15, s * 0.28, 0.86), (-0.28, s * 0.36, 1.06), 0.05, 0.0, "bone", "body", seg=4)
    b.ball((0.05, 0, 0.9), 0.13, "chitin", "head", seg=7, rings=5)
    b.ball((0.06, 0, 0.98), 0.1, "plate", "head", scale=(1.2, 1.2, 0.5), seg=6, rings=4, smooth=False)
    for s in (1, -1):
        b.ball((0.15, s * 0.05, 0.9), 0.025, "eye", "head", seg=5, rings=4)
        b.limb((0.0, s * 0.3, 0.66), (0.3, s * 0.2, 0.6), 0.06, 0.05, "chitin", "shield", seg=5)  # arms
    b.box((0.34, 0, 0.58), (0.08, 0.72, 0.74), "plate", "shield")
    b.box((0.37, 0, 0.58), (0.03, 0.8, 0.1), "bone", "shield")
    b.box((0.37, 0, 0.58), (0.03, 0.1, 0.82), "bone", "shield")
    b.ball((0.39, 0, 0.58), 0.1, "glow", "shield", scale=(0.6, 1, 1), seg=8, rings=6)
    for s in (1, -1):
        for z in (0.93, 0.22):
            b.limb((0.36, s * 0.34, z), (0.45, s * 0.42, z + (0.12 if z > 0.5 else -0.1)), 0.04, 0.0, "bone", "shield", seg=4)
    LEGS.mesh(b, 0.07, 0.06, 0.06, joint="plate", tip="chitin")
    b.finish(arm)
    return Kit(arm, LEGS, walk_frames=16, swing=0.3, lift=0.45, bend=0.7, duty=0.55, bob=0.025,
               head="head", roll_die=1.4)


def clips(k):
    k.idle()
    k.walk()

    def slam(t, p):
        lift = lib.pulse(t, 0.0, 0.55)
        hit = lib.pulse(t, 0.45, 0.85)
        p["shield"] = (lib.world_rot(k.arm, "shield", (0, 1, 0), -0.35 * lift + 0.25 * hit),
                       lib.world_loc(k.arm, "shield", (0.05 * hit, 0, 0.18 * lift - 0.12 * hit)))
        p["body"] = body_pose(k.arm, pitch=-0.1 * lift + 0.18 * hit, loc=(0, 0, 0.04 * lift - 0.06 * hit))
    k.attack(20, slam)
    k.hit()
    k.die()


run(build, clips)
