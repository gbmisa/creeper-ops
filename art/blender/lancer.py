"""Lancer: tall thin stilt-walker carrying a glowing spine lance longer than itself; thrusts it."""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import lib  # noqa: E402
from bug_kit import Kit, body_pose, run  # noqa: E402
from legs import Legs  # noqa: E402

LEGS = Legs()
for n, s, ph in (("L", 1, 0.0), ("R", -1, 0.5)):
    LEGS.add(n, (0.0, s * 0.09, 0.5), (0.04, s * 0.2, 0.0), s, ph, knee_up=0.0, knee_out=0.03, pillar=True)


def build():
    arm = lib.armature("lancer", [("root", (0, 0, 0), (0, 0, 0.1), None),
                                  ("body", (0, 0, 0.5), (0, 0, 0.8), "root"),
                                  ("head", (0.05, 0, 1.15), (0.1, 0, 1.4), "body"),
                                  ("lance", (0.05, 0, 0.8), (0.6, 0, 0.82), "body")] + LEGS.bones("body"))
    b = lib.Builder("lancer")
    b.ball((0, 0, 0.5), 0.17, "chitin", "body", scale=(1.0, 1.3, 0.8), seg=8, rings=5)
    b.lathe([(0.3, 0.32), (0.26, 0.48), (0.18, 0.66)], "plate", "body", seg=8, smooth=False)  # chitin skirt
    b.limb((-0.04, 0, 0.5), (0.05, 0, 1.15), 0.2, 0.12, "chitin", "body", seg=7, smooth=True)
    for s in (1, -1):  # chitin pauldrons
        b.ball((0.0, s * 0.19, 1.06), 0.16, "plate", "body", scale=(1.2, 0.9, 0.6), seg=6, rings=4, smooth=False)
        b.limb((-0.02, s * 0.2, 1.1), (-0.12, s * 0.3, 1.3), 0.05, 0.0, "bone", "body", seg=4)
    for z in (0.7, 0.88, 1.04):  # bone ribs round the torso
        b.ball((-0.02 + z * 0.06, 0, z), 0.12 - z * 0.04, "bone", "body", scale=(0.8, 1.1, 0.25), seg=6, rings=3, smooth=False)
    b.ball((-0.08, 0, 0.98), 0.07, "sick", "body", seg=5, rings=4)
    b.ball((0.08, 0, 1.24), 0.11, "chitin", "head", scale=(1.2, 0.9, 1.0), seg=7, rings=5)
    b.limb((0.04, 0, 1.3), (-0.2, 0, 1.52), 0.06, 0.0, "bone", "head", seg=4)
    for s in (1, -1):
        b.ball((0.17, s * 0.05, 1.27), 0.03, "eye", "head", seg=5, rings=4)
        b.limb((-0.03, s * 0.09, 0.98), (0.2, s * 0.06, 0.86), 0.035, 0.03, "bone", "lance", seg=5)
        b.limb((0.2, s * 0.06, 0.86), (0.32, s * 0.02, 0.8), 0.03, 0.02, "bone", "lance", seg=5)
    b.limb((-0.15, 0, 0.78), (1.2, 0, 0.86), 0.055, 0.04, "glow", "lance", seg=6)
    b.limb((1.2, 0, 0.86), (1.45, 0, 0.88), 0.085, 0.0, "bone", "lance", seg=5)
    b.ball((0.3, 0, 0.8), 0.05, "bone", "lance", scale=(1.6, 1, 1), seg=6, rings=4, smooth=False)
    LEGS.mesh(b, 0.075, 0.06, 0.05, mat="bone", joint="chitin", tip="bone")
    b.finish(arm)
    return Kit(arm, LEGS, walk_frames=15, swing=0.65, lift=0.9, bend=1.2, duty=0.55, bob=0.03,
               head="head", roll_die=1.45)


def clips(k):
    k.idle(lambda t: {"lance": (lib.world_rot(k.arm, "lance", (0, 1, 0), 0.04 * math.sin(2 * math.pi * t)), None)})
    k.walk(lambda t: {"lance": (None, lib.world_loc(k.arm, "lance", (0, 0, 0.015 * math.sin(4 * math.pi * t))))})

    def thrust(t, p):
        draw = lib.pulse(t, 0.0, 0.5)
        stab = lib.pulse(t, 0.4, 0.8)
        p["lance"] = (lib.world_rot(k.arm, "lance", (0, 1, 0), -0.08 * draw - 0.17 * stab),
                      lib.world_loc(k.arm, "lance", (-0.25 * draw + 0.5 * stab, 0, 0.03 * draw)))
        p["body"] = body_pose(k.arm, pitch=-0.12 * draw + 0.25 * stab, loc=(-0.05 * draw + 0.22 * stab, 0, -0.04 * stab))
    k.attack(16, thrust)
    k.hit()
    k.die(lambda t: {"lance": (lib.world_rot(k.arm, "lance", (1, 0, 0), -0.9 * lib.ease(min(1.0, t / 0.6))), None)})


run(build, clips)
