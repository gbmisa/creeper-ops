"""Spore Bat: small fast flyer, membrane wings, spore gland under the tail; dives to drop spores.
Origin at the body centre. Game id: spore_bat.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
import flyer_kit as fk  # noqa: E402
import lib  # noqa: E402

SPAN, CHORD = 1.1, 0.8


def build():
    arm = lib.armature("spore_bat", [("root", (0, 0, 0), (0, 0, 0.1), None),
                                     ("body", (-0.2, 0, 0), (0.2, 0, 0), "root"),
                                     ("head", (0.25, 0, 0.03), (0.55, 0, 0.06), "body")] + fk.wing_bones(SPAN, CHORD))
    b = lib.Builder("spore_bat")
    b.ball((0, 0, 0), 0.28, "bat_skin", "body", scale=(1.4, 0.85, 0.8), seg=10, rings=7)
    b.ball((0.02, 0, 0.12), 0.16, "plate", "body", scale=(1.6, 1.0, 0.35), seg=6, rings=4, smooth=False)
    b.ball((-0.32, 0, -0.08), 0.11, "glow", "body", seg=7, rings=5)
    b.limb((-0.3, 0, 0), (-0.62, 0, -0.04), 0.07, 0.0, "bat_skin", "body", seg=5)
    for s in (1, -1):
        b.limb((-0.12, s * 0.08, -0.16), (-0.24, s * 0.1, -0.34), 0.025, 0.0, "bone", "body", seg=4)  # dangling claws
    b.ball((0.38, 0, 0.05), 0.19, "bat_skin", "head", scale=(1.1, 1.0, 0.95), seg=8, rings=6)
    for s in (1, -1):
        b.ball((0.52, s * 0.08, 0.1), 0.04, "sick", "head", seg=5, rings=4)
        b.limb((0.36, s * 0.13, 0.18), (0.4, s * 0.2, 0.42), 0.05, 0.0, "bone", "head", seg=4)  # ears
        b.limb((0.55, s * 0.04, -0.04), (0.6, s * 0.03, -0.14), 0.02, 0.0, "bone", "head", seg=3)  # fangs
    fk.wing_mesh(b, SPAN, CHORD, "bat_wing")
    b.finish(arm)
    return arm


def body(arm, pitch=0.0, roll=0.0, loc=(0, 0, 0)):
    return (lib.world_rot(arm, "body", (0, 1, 0), pitch) @ lib.world_rot(arm, "body", (1, 0, 0), roll), lib.world_loc(arm, "body", loc))


def clips(arm):
    def walk(t):
        p = fk.flap(arm, t, amp=0.75)
        p["body"] = body(arm, loc=(0, 0, -0.06 * math.sin(2 * math.pi * t)))
        return p
    lib.action(arm, "walk", 10, walk, step=1, loop=True)

    def idle(t):
        p = fk.flap(arm, t * 2 % 1.0, amp=0.55, bias=0.15)
        p["body"] = body(arm, pitch=0.05 * math.sin(2 * math.pi * t), loc=(0, 0, -0.05 * math.sin(4 * math.pi * t)))
        p["head"] = (lib.world_rot(arm, "head", (0, 0, 1), 0.3 * math.sin(2 * math.pi * t)), None)
        return p
    lib.action(arm, "idle", 24, idle, step=1, loop=True)

    def attack(t):
        dive = lib.pulse(t, 0.0, 0.7)
        p = fk.blend(fk.flap(arm, t * 2 % 1.0), fk.folded(arm, 1.0), dive)
        p["body"] = body(arm, pitch=0.7 * dive - 0.3 * lib.pulse(t, 0.6, 1.0), loc=(0.25 * dive, 0, -0.35 * dive))
        return p
    lib.action(arm, "attack", 16, attack, step=1)

    def hit(t):
        j = lib.pulse(t, 0.0, 1.0) * (1.0 - t)
        p = fk.blend(fk.flap(arm, 0.25), fk.folded(arm, 0.6), j)
        p["body"] = body(arm, roll=0.6 * j, loc=(-0.1 * j, 0, 0.08 * j))
        return p
    lib.action(arm, "hit", 8, hit, step=1)

    def die(t):
        fold = lib.ease(min(1.0, t / 0.4))
        p = fk.blend(fk.flap(arm, t * 3 % 1.0, amp=0.9), fk.folded(arm, 1.0), fold)
        p["body"] = body(arm, pitch=1.2 * t, roll=6.0 * t * t, loc=(0, 0, -2.2 * t * t))
        return p
    lib.action(arm, "die", 30, die, step=1)


if __name__ == "__main__":
    out = sys.argv[sys.argv.index("--") + 1]
    lib.reset()
    a = build()
    clips(a)
    lib.export(out)
